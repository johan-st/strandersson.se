module FoodCalculator exposing (FCResult, Food, FoodCalculator(..), NewFood, add, cookedWeight, cookedWeightSet, decode, decoder, encode, encoder, foods, init, portions, portionsSet, remove, result)

import Json.Decode as D
import Json.Encode as E


type FoodCalculator
    = FoodCalculator Internals


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


foods : FoodCalculator -> List Food
foods (FoodCalculator internals) =
    internals.foods


add : NewFood -> FoodCalculator -> FoodCalculator
add newFood (FoodCalculator internals) =
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
    FoodCalculator
        { internals
            | foods = food :: internals.foods
            , doneWeight = internals.doneWeight
            , latestId = id
        }


remove : Int -> FoodCalculator -> FoodCalculator
remove id (FoodCalculator internals) =
    FoodCalculator
        { internals
            | foods =
                internals.foods
                    |> List.filter (\food -> food.id /= id)
        }


portionsSet : Int -> FoodCalculator -> FoodCalculator
portionsSet ports (FoodCalculator internals) =
    FoodCalculator
        { internals
            | portions = ports
        }


portions : FoodCalculator -> Int
portions (FoodCalculator internals) =
    internals.portions


cookedWeightSet : Maybe Int -> FoodCalculator -> FoodCalculator
cookedWeightSet weight (FoodCalculator internals) =
    FoodCalculator
        { internals
            | doneWeight = weight
        }


cookedWeight : FoodCalculator -> Maybe Int
cookedWeight (FoodCalculator internals) =
    internals.doneWeight


result : FoodCalculator -> FCResult
result (FoodCalculator internals) =
    let
        totalWeight =
            case internals.doneWeight of
                Just weight ->
                    weight

                Nothing ->
                    internals.foods
                        |> List.map .weight
                        |> List.sum

        portionWeight =
            round (toFloat totalWeight / toFloat internals.portions)

        totalCalories =
            internals.foods
                |> List.map (\food -> toFloat food.calories * (toFloat food.weight / 100))
                |> List.sum
                |> (\x -> x / toFloat internals.portions)
                |> round

        totalProtein =
            internals.foods
                |> List.map (\food -> food.protein * (toFloat food.weight / 100))
                |> List.sum
                |> (\x -> x / toFloat internals.portions)
                |> (*) 10
                |> round
                |> toFloat
                |> (\x -> x / 10)

        totalCarbs =
            internals.foods
                |> List.map (\food -> food.carbs * (toFloat food.weight / 100))
                |> List.sum
                |> (\x -> x / toFloat internals.portions)
                |> (*) 10
                |> round
                |> toFloat
                |> (\x -> x / 10)

        totalFat =
            internals.foods
                |> List.map (\food -> food.fat * (toFloat food.weight / 100))
                |> List.sum
                |> (\x -> x / toFloat internals.portions)
                |> (*) 10
                |> round
                |> toFloat
                |> (\x -> x / 10)
    in
    { calories = totalCalories
    , protein = totalProtein
    , carbs = totalCarbs
    , fat = totalFat
    , totalWeight = totalWeight
    , portionWeight = portionWeight
    }


type alias FCResult =
    { calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , totalWeight : Int
    , portionWeight : Int
    }


type alias FCError =
    { from : String
    , error : D.Error
    }


init : FoodCalculator
init =
    FoodCalculator
        { foods = []
        , doneWeight = Nothing
        , portions = 1
        , latestId = 0
        }



-- ENCODE/DECODE
-- TODO: add version of encoding to encode & decode


encode : FoodCalculator -> String
encode fc =
    E.encode 0 <|
        encoder fc


encoder : FoodCalculator -> E.Value
encoder fc =
    case fc of
        FoodCalculator _ ->
            encoderV1 fc


encoderV1 : FoodCalculator -> E.Value
encoderV1 (FoodCalculator internals) =
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
decode : String -> Result FCError FoodCalculator
decode str =
    case D.decodeString decoder str of
        Ok fc ->
            Ok fc

        Err err ->
            Err { from = "decode", error = err }


decoder : D.Decoder FoodCalculator
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


fcToCurrent : FoodCalculator -> FoodCalculator
fcToCurrent fc =
    case fc of
        FoodCalculator _ ->
            fc


decoderV1 : D.Decoder FoodCalculator
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
    D.map FoodCalculator internals


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
