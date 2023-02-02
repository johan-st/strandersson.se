module FoodCalculatorTests exposing (..)

import Expect exposing (Expectation)
import FoodCalculator as FC
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Event exposing (expect)


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
        , describe "result" <|
            [ test "returns the total Macros for one (1) portion" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.setPortions 1
                    in
                    Expect.equal
                        (FC.result newFC)
                        (FC.Result 332 3.5 76.4 1.3 450 450)
            , test "returns the total Macros for two (2) portion" <|
                \() ->
                    let
                        newFC =
                            FC.init
                                |> FC.add apple
                                |> FC.add orange
                                |> FC.add banana
                                |> FC.setPortions 2
                    in
                    Expect.equal
                        (FC.result newFC)
                        (FC.Result 166 1.8 38.2 0.6 450 225)
            ]
        ]



-- HELPERS


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
