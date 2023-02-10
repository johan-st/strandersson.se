module FoodCalculatorTests exposing (..)

-- import Expect exposing (Expectation)

import Expect
import FoodCalculator as FC
import Fuzz exposing (Fuzzer, floatRange, int, intRange, niceFloat, string)
import Test exposing (..)


suite : Test
suite =
    describe "FoodCalculator" <|
        [ describe "init" <|
            [ test "returns a model with an empty list of foods" <|
                \() ->
                    let
                        newFC =
                            FC.init

                        foods =
                            FC.foods newFC
                    in
                    Expect.equal
                        (List.length foods)
                        0
            ]
        , describe "add" <|
            [ test "add food to the list of foods" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple

                        foods =
                            FC.foods newFC
                    in
                    Expect.equalLists
                        foods
                        [ food 1 apple ]
            ]
        , describe "remove" <|
            [ test "remove an item by id" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.remove 2

                        foods =
                            FC.foods newFC
                    in
                    Expect.equalLists (FC.foods newFC) foods
            ]
        , describe "update" <|
            [ test "update a food" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana

                        foods =
                            FC.foods newFC

                        updatedOrange =
                            food 2 orange
                                |> (\f -> { f | name = "Updated Orange" })

                        updatedFC =
                            FC.updateFood updatedOrange newFC

                        expectedFoods =
                            foods
                                |> List.map
                                    (\f ->
                                        if f.id == updatedOrange.id then
                                            updatedOrange

                                        else
                                            f
                                    )
                    in
                    Expect.equalLists
                        expectedFoods
                        (FC.foods updatedFC)
            ]
        , describe "setDoneWeight" <|
            [ test "get when no weight set returns Nothing" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                    in
                    Expect.equal
                        (FC.cookedWeight newFC)
                        Nothing
            , test "set and get" <|
                \() ->
                    let
                        newFC_weight =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.cookedWeightSet (Just 300)
                    in
                    Expect.equal
                        (FC.cookedWeight newFC_weight)
                        (Just 300)
            ]
        , describe "estimated kcal from macros in food" <|
            [ fuzz fuzzFood "returns the estimated kcal from macros in food" <|
                \f ->
                    let
                        -- source for kcals: FAQ on https://www.nal.usda.gov/programs/fnic
                        expectedKcal =
                            round <| ((f.protein * 4) + (f.fat * 9) + (f.carbs * 4)) * (toFloat f.weight / 100)
                    in
                    Expect.equal
                        (FC.estimatedKcal f)
                        expectedKcal
            ]
        , describe "result" <|
            [ test "returns the total Macros for one (1) portion" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.portionsSet 1
                    in
                    Expect.equal
                        (FC.result newFC)
                        (FC.FCResult 332 3.5 76.4 1.3 450 450)
            , test "returns the total Macros for two (2) portion" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.portionsSet 2
                    in
                    Expect.equal
                        (FC.result newFC)
                        (FC.FCResult 166 1.8 38.2 0.6 450 225)
            ]
        , describe
            "encode / decode"
          <|
            [ test "encode and decode a model" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.portionsSet 2

                        decoded =
                            case FC.decode <| FC.encode newFC of
                                Ok fc ->
                                    fc

                                Err err ->
                                    Debug.log (Debug.toString err) FC.init
                    in
                    Expect.equal
                        decoded
                        newFC
            ]
        ]



-- HELPERS
-- TODO: vanity thing: consider handling "NAN" and "infinity" and very big and small ints of weight.


fuzzFood : Fuzzer FC.Food
fuzzFood =
    Fuzz.map7 FC.Food
        int
        string
        int
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (intRange 0 1000000000)


food : Int -> FC.NewFood -> FC.Food
food id nf =
    { id = id
    , name = nf.name
    , calories = nf.calories
    , protein = nf.protein
    , carbs = nf.carbs
    , fat = nf.fat
    , weight = nf.weight
    }



-- MOCK DATA


apple : FC.NewFood
apple =
    { name = "Apple"
    , calories = 56
    , protein = 0.3
    , carbs = 14.2
    , fat = 0.1
    , weight = 100
    }


orange : FC.NewFood
orange =
    { name = "Orange"
    , calories = 49
    , protein = 0.8
    , carbs = 12.1
    , fat = 0.1
    , weight = 150
    }


banana : FC.NewFood
banana =
    { name = "Banana"
    , calories = 101
    , protein = 1.0
    , carbs = 22
    , fat = 0.5
    , weight = 200
    }
