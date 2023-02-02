module FoodCalculator exposing (Food, FoodCalculator(..), NewFood, Result, add, foods, init, remove, result)


type FoodCalculator
    = FoodCalculator Internals


type alias Internals =
    { foods : List Food
    , doneWeight : Int
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
            , doneWeight = internals.doneWeight + newFood.weight
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


result : FoodCalculator -> Result
result (FoodCalculator internals) =
    let
        totalWeight =
            internals.foods
                |> List.map .weight
                |> List.sum

        totalCalories =
            internals.foods
                |> List.map (\food -> food.calories * (food.weight // 100))
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
    in
    { calories = totalCalories
    , protein = totalProtein
    , carbs = totalCarbs
    , fat = totalFat
    , unpreparedWeight = totalWeight
    }


type alias Result =
    { calories : Int
    , protein : Float
    , carbs : Float
    , fat : Float
    , unpreparedWeight : Int
    }


init : FoodCalculator
init =
    FoodCalculator
        { foods = []
        , doneWeight = 0
        , portions = 4
        , latestId = 0
        }
