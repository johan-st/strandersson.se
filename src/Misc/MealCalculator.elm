module Misc.MealCalculator exposing
    ( Food
    , MCResult
    , MealCalculator(..)
    , NewFood
    , add
    , cookedWeight
    , cookedWeightSet
    , decode
    , decoder
    , encode
    , encoder
    , estimatedKcal
    , estimatedKcalPer100g
    , foods
    , init
    , portions
    , portionsSet
    , remove
    , result
    , updateFood
    )

import Json.Decode as D
import Json.Encode as E


type MealCalculator
    = MealCalculator Internals


type alias Internals =
    { foods : List Food
    , doneWeight : Maybe Int
    , portions : Int
    , latestId : Int
    }


{-| all macros are in grams per 100g,
weight is in grams
-}
type alias Food =
    { id : Int
    , name : String
    , calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , weight : Int
    }


{-| all macros are in grams per 100g,
weight is in grams
-}
type alias NewFood =
    { name : String
    , calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , weight : Int
    }


type alias MCResult =
    { total : MCResultPartial
    , portion : MCResultPartial
    , percentByWeight : Maybe MCResultPercent
    }


type alias MCResultPartial =
    { calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , weight : Int
    , estimatedKcal : Int
    }


type alias MCResultPercent =
    { protein : Float
    , fat : Float
    , carbs : Float
    }


type alias MCError =
    { from : String
    , error : D.Error
    }


foods : MealCalculator -> List Food
foods (MealCalculator internals) =
    internals.foods |> List.sortBy .id


add : NewFood -> MealCalculator -> MealCalculator
add newFood (MealCalculator internals) =
    let
        id =
            internals.latestId + 1

        food =
            { id = id
            , name = newFood.name
            , calories = newFood.calories
            , protein = newFood.protein
            , carbs = newFood.carbs
            , fat = newFood.fat
            , weight = newFood.weight
            }
    in
    MealCalculator
        { internals
            | foods = food :: internals.foods
            , doneWeight = internals.doneWeight
            , latestId = id
        }


updateFood : Food -> MealCalculator -> MealCalculator
updateFood food (MealCalculator internals) =
    MealCalculator
        { internals
            | foods =
                internals.foods
                    |> List.map
                        (\f ->
                            if f.id == food.id then
                                food

                            else
                                f
                        )
        }


remove : Int -> MealCalculator -> MealCalculator
remove id (MealCalculator internals) =
    MealCalculator
        { internals
            | foods =
                internals.foods
                    |> List.filter (\food -> food.id /= id)
        }


portionsSet : Int -> MealCalculator -> MealCalculator
portionsSet ports (MealCalculator internals) =
    MealCalculator
        { internals
            | portions = ports
        }


portions : MealCalculator -> Int
portions (MealCalculator internals) =
    internals.portions


cookedWeightSet : Maybe Int -> MealCalculator -> MealCalculator
cookedWeightSet weight (MealCalculator internals) =
    MealCalculator
        { internals
            | doneWeight = weight
        }


cookedWeight : MealCalculator -> Maybe Int
cookedWeight (MealCalculator internals) =
    internals.doneWeight


result : MealCalculator -> MCResult
result (MealCalculator internals) =
    let
        totalWeight =
            case internals.doneWeight of
                Just weight ->
                    weight

                Nothing ->
                    internals.foods
                        |> List.map .weight
                        |> List.sum

        totalCalories =
            internals.foods
                |> List.map (\food -> toFloat food.calories * (toFloat food.weight / 100))
                |> List.sum

        totalProtein =
            internals.foods
                |> List.map (\food -> food.protein * (toFloat food.weight / 100))
                |> List.sum

        totalCarbs =
            internals.foods
                |> List.map (\food -> food.carbs * (toFloat food.weight / 100))
                |> List.sum

        totalFat =
            internals.foods
                |> List.map (\food -> food.fat * (toFloat food.weight / 100))
                |> List.sum

        weightMacros =
            totalProtein + totalCarbs + totalFat

        percentByWeight =
            if weightMacros == 0 then
                Nothing

            else
                Just
                    { protein = ratioOf weightMacros totalProtein
                    , fat = ratioOf weightMacros totalFat
                    , carbs = ratioOf weightMacros totalCarbs
                    }

        kcalEstTotal =
            estimatedKcal totalProtein totalFat totalCarbs

        kcalEstPortion =
            toFloat kcalEstTotal / toFloat internals.portions |> round
    in
    { total =
        { calories = totalCalories |> round
        , protein = totalProtein
        , carbs = totalCarbs
        , fat = totalFat
        , weight = totalWeight
        , estimatedKcal = kcalEstTotal
        }
    , portion =
        { calories = totalCalories / toFloat internals.portions |> round
        , protein = totalProtein / toFloat internals.portions
        , carbs = totalCarbs / toFloat internals.portions
        , fat = totalFat / toFloat internals.portions
        , weight = toFloat totalWeight / toFloat internals.portions |> round
        , estimatedKcal = kcalEstPortion
        }
    , percentByWeight = percentByWeight
    }


init : MealCalculator
init =
    MealCalculator
        { foods = []
        , doneWeight = Nothing
        , portions = 4
        , latestId = 0
        }


estimatedKcalPer100g : Int -> Float -> Float -> Float -> Int
estimatedKcalPer100g weight protein fat carbs =
    let
        weightIn100s =
            toFloat weight / 100
    in
    proteinGramsToKcal protein
        |> (+) (fatGramsToKcal fat)
        |> (+) (carbsGramsToKcal carbs)
        |> (*) weightIn100s
        |> round


estimatedKcal : Float -> Float -> Float -> Int
estimatedKcal protein fat carbs =
    round <|
        proteinGramsToKcal protein
            + fatGramsToKcal fat
            + carbsGramsToKcal carbs


proteinGramsToKcal : Float -> Float
proteinGramsToKcal grams =
    grams * 4


fatGramsToKcal : Float -> Float
fatGramsToKcal grams =
    grams * 9


carbsGramsToKcal : Float -> Float
carbsGramsToKcal grams =
    grams * 4



-- HELPERS


{-| TODO: rename to appropriate name
-}
ratioOf : Float -> Float -> Float
ratioOf whole part =
    if part == 0 then
        0

    else if whole == 0 then
        1

    else
        part / whole



-- ENCODE/DECODE


encode : MealCalculator -> String
encode fc =
    E.encode 0 <|
        encoder fc


encoder : MealCalculator -> E.Value
encoder fc =
    case fc of
        MealCalculator _ ->
            encoderV1 fc


encoderV1 : MealCalculator -> E.Value
encoderV1 (MealCalculator internals) =
    let
        doneWeight =
            case internals.doneWeight of
                Just weight ->
                    E.int weight

                Nothing ->
                    E.string "not set"
    in
    E.object
        [ ( "version", E.int 1 )
        , ( "foods", E.list encodeFood internals.foods )
        , ( "doneWeight", doneWeight )
        , ( "portions", E.int internals.portions )
        ]


encodeFood : Food -> E.Value
encodeFood food =
    E.object
        [ ( "id", E.int food.id )
        , ( "name", E.string food.name )
        , ( "calories", E.int food.calories )
        , ( "protein", E.float food.protein )
        , ( "carbs", E.float food.carbs )
        , ( "fat", E.float food.fat )
        , ( "weight", E.int food.weight )
        ]


{-| Decode a FoodCalculator from a JSON string
TODO: handle error?
-}
decode : String -> Result MCError MealCalculator
decode str =
    case D.decodeString decoder str of
        Ok fc ->
            Ok fc

        Err err ->
            Err { from = "decode", error = err }


decoder : D.Decoder MealCalculator
decoder =
    D.field "version" D.int
        |> D.andThen
            (\version ->
                case version of
                    1 ->
                        D.map fcToCurrent decoderV1

                    _ ->
                        D.fail "unknown version"
            )


fcToCurrent : MealCalculator -> MealCalculator
fcToCurrent fc =
    case fc of
        MealCalculator _ ->
            fc


decoderV1 : D.Decoder MealCalculator
decoderV1 =
    let
        latestId =
            D.field "foods" (D.list decodeFood) |> D.andThen (\x -> findLatestId x)

        internals =
            D.map4 Internals
                (D.field "foods" (D.list decodeFood))
                (D.field "doneWeight" (D.maybe D.int))
                (D.field "portions" D.int)
                latestId
    in
    D.map MealCalculator internals


decodeFood : D.Decoder Food
decodeFood =
    D.map7 Food
        (D.field "id" D.int)
        (D.field "name" D.string)
        (D.field "calories" D.int)
        (D.field "protein" D.float)
        (D.field "carbs" D.float)
        (D.field "fat" D.float)
        (D.field "weight" D.int)


findLatestId : List Food -> D.Decoder Int
findLatestId fs =
    case List.maximum (List.map .id fs) of
        Just maxId ->
            D.succeed maxId

        Nothing ->
            D.succeed 0
