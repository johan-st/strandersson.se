module FoodCalculator exposing (Food, FoodCalculator(..), NewFood, Result, add, foods, init, remove, result, setPortions)


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


setPortions : Int -> FoodCalculator -> FoodCalculator
setPortions portions (FoodCalculator internals) =
    FoodCalculator
        { internals
            | portions = portions
        }


result : FoodCalculator -> Result
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


type alias Result =
    { calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , totalWeight : Int
    , portionWeight : Int
    }


init : FoodCalculator
init =
    FoodCalculator
        { foods = []
        , doneWeight = Nothing
        , portions = 1
        , latestId = 0
        }
