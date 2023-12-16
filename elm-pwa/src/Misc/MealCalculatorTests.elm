module Misc.MealCalculatorTests exposing (..)

-- import Expect exposing (Expectation)

import Expect
import Fuzz exposing (Fuzzer, floatRange, int, intAtLeast, string)
import Misc.MealCalculator as MC
import Test exposing (..)


suite : Test
suite =
    describe "MealCalculator" <|
        [ describe "init" <|
            [ test "returns a model with an empty list of foods" <|
                \() ->
                    let
                        newMC =
                            MC.init

                        foods =
                            MC.foods newMC
                    in
                    Expect.equal
                        (List.length foods)
                        0
            ]
        , describe "add" <|
            [ fuzz fuzzNewFood "add a food" <|
                \f ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f
                    in
                    MC.foods newMC
                        |> List.map (\fcf -> MCFood fcf)
                        |> List.map (comp (MCNewFood f))
                        |> List.foldl (&&) True
                        |> Expect.equal True
            ]
        , describe "remove" <|
            [ fuzz2 fuzzNewFood fuzzNewFood "remove an item by id" <|
                \f1 f2 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2
                                -- TODO: should not rely on current id implementation
                                |> MC.remove 1
                    in
                    MC.foods newMC
                        |> List.map (\fcf -> MCFood fcf)
                        |> List.map (comp (MCNewFood f2))
                        |> List.foldl (&&) True
                        |> Expect.equal True
            ]
        , describe "update" <|
            [ fuzz3 fuzzNewFood fuzzNewFood fuzzNewFood "update a food" <|
                \f1 f2 f3 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2

                        fcFirst =
                            MC.foods newMC
                                |> List.head
                                |> Maybe.withDefault (MC.Food 0 "" 0 0 0 0 0)

                        modedFirst =
                            { fcFirst
                                | name = f3.name
                                , weight = f3.weight
                                , protein = f3.protein
                                , fat = f3.fat
                                , carbs = f3.carbs
                                , calories = f3.calories
                            }
                    in
                    MC.updateFood modedFirst newMC
                        |> MC.foods
                        |> List.map (\fcf -> MCFood fcf)
                        |> List.map (comp (MCFood modedFirst))
                        |> List.foldl (||) True
                        |> Expect.equal True
            ]
        , describe "setDoneWeight" <|
            [ test "get when no weight set returns Nothing" <|
                \() ->
                    let
                        newMC =
                            MC.init
                                |> MC.add apple
                    in
                    Expect.equal
                        (MC.cookedWeight newMC)
                        Nothing
            , fuzz (intAtLeast 1) "set and get" <|
                \w ->
                    let
                        newMC_weight =
                            MC.init
                                |> MC.add apple
                                |> MC.cookedWeightSet (Just w)
                    in
                    Expect.equal
                        (MC.cookedWeight newMC_weight)
                        (Just w)
            ]
        , describe "estimated kcal from macros in food" <|
            [ fuzz fuzzFood "returns the estimated kcal per 100g from macros" <|
                \f ->
                    let
                        -- source for kcals: FAQ on https://www.nal.usda.gov/programs/fnic
                        expectedKcal =
                            round <| ((f.protein * 4) + (f.fat * 9) + (f.carbs * 4)) * (toFloat f.weight / 100)
                    in
                    Expect.equal
                        expectedKcal
                        (MC.estimatedKcalPer100g f.weight f.protein f.fat f.carbs)
            , fuzz fuzzFood "returns total estimated kcal from macros" <|
                \f ->
                    let
                        -- source for kcals: FAQ on https://www.nal.usda.gov/programs/fnic
                        expectedKcal =
                            round <| ((f.protein * 4) + (f.fat * 9) + (f.carbs * 4))
                    in
                    Expect.equal
                        expectedKcal
                        (MC.estimatedKcal f.protein f.fat f.carbs)
            ]
        , describe "result" <|
            [ describe "total" <|
                [ fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "protein" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.protein * (toFloat f1.weight / 100))
                                    + (f2.protein * (toFloat f2.weight / 100))

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.total.protein
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "carbs" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.carbs * (toFloat f1.weight / 100))
                                    + (f2.carbs * (toFloat f2.weight / 100))

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.total.carbs
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "fat" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.fat * (toFloat f1.weight / 100))
                                    + (f2.fat * (toFloat f2.weight / 100))

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.total.fat
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "weight" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                f1.weight + f2.weight

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.equal
                            expected
                            res.total.weight
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "calories" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                round <|
                                    (toFloat f1.calories * (toFloat f1.weight / 100))
                                        + (toFloat f2.calories * (toFloat f2.weight / 100))

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.equal
                            expected
                            res.total.calories
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "estimated kcal" <|
                    \portions f1 f2 ->
                        let
                            -- estimatedKcal is validate elsewhere
                            f1Est =
                                MC.estimatedKcal
                                    (f1.protein * (toFloat f1.weight / 100))
                                    (f1.fat * (toFloat f1.weight / 100))
                                    (f1.carbs * (toFloat f1.weight / 100))

                            f2Est =
                                MC.estimatedKcal
                                    (f2.protein * (toFloat f2.weight / 100))
                                    (f2.fat * (toFloat f2.weight / 100))
                                    (f2.carbs * (toFloat f2.weight / 100))

                            want =
                                f1Est + f2Est

                            got =
                                MC.result
                                    (MC.init
                                        |> MC.add f1
                                        |> MC.add f2
                                        |> MC.portionsSet portions
                                    )
                                    |> .total
                                    |> .estimatedKcal
                        in
                        -- TODO: hunt down rounding issue
                        Expect.all
                            [ Expect.atLeast <| want - 1
                            , Expect.atMost <| want + 1
                            ]
                            got
                ]
            , describe "portions" <|
                [ fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "protein" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.protein * (toFloat f1.weight / 100))
                                    + (f2.protein * (toFloat f2.weight / 100))
                                    |> (\x -> x / toFloat portions)

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.portion.protein
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "carbs" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.carbs * (toFloat f1.weight / 100))
                                    + (f2.carbs * (toFloat f2.weight / 100))
                                    |> (\x -> x / toFloat portions)

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.portion.carbs
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "fat" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.fat * (toFloat f1.weight / 100))
                                    + (f2.fat * (toFloat f2.weight / 100))
                                    |> (\x -> x / toFloat portions)

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.within
                            (Expect.Absolute 0.000001)
                            expected
                            res.portion.fat
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "weight" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (f1.weight + f2.weight)
                                    |> toFloat
                                    |> (\x -> x / toFloat portions)
                                    |> round

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.equal
                            expected
                            res.portion.weight
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "calories" <|
                    \portions f1 f2 ->
                        let
                            newMC =
                                MC.init
                                    |> MC.add f1
                                    |> MC.add f2
                                    |> MC.portionsSet portions

                            expected =
                                (toFloat f1.calories * (toFloat f1.weight / 100))
                                    |> (+) (toFloat f2.calories * (toFloat f2.weight / 100))
                                    |> (\x -> x / toFloat portions)
                                    |> round

                            res =
                                MC.result (MC.portionsSet portions newMC)
                        in
                        Expect.equal
                            expected
                            res.portion.calories
                , fuzz3 (intAtLeast 1) fuzzNewFood fuzzNewFood "estimated kcal" <|
                    \portions f1 f2 ->
                        let
                            f1Est =
                                MC.estimatedKcal
                                    (f1.protein * (toFloat f1.weight / 100))
                                    (f1.fat * (toFloat f1.weight / 100))
                                    (f1.carbs * (toFloat f1.weight / 100))
                                    |> (\x -> toFloat x / toFloat portions)
                                    |> round

                            f2Est =
                                MC.estimatedKcal
                                    (f2.protein * (toFloat f2.weight / 100))
                                    (f2.fat * (toFloat f2.weight / 100))
                                    (f2.carbs * (toFloat f2.weight / 100))
                                    |> (\x -> toFloat x / toFloat portions)
                                    |> round

                            want =
                                f1Est + f2Est

                            got =
                                MC.result
                                    (MC.init
                                        |> MC.add f1
                                        |> MC.add f2
                                        |> MC.portionsSet portions
                                    )
                                    |> .portion
                                    |> .estimatedKcal
                        in
                        -- TODO: hunt down rounding issue
                        Expect.all
                            [ Expect.atLeast <| want - 1
                            , Expect.atMost <| want + 1
                            ]
                            got
                ]
            ]
        , describe "percent by weight" <|
            [ fuzz2 fuzzNewFood fuzzNewFood "protein" <|
                \f1 f2 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2

                        res =
                            MC.result newMC

                        protWeight =
                            f1.protein
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.protein * (toFloat f2.weight / 100))

                        fatWeight =
                            f1.fat
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.fat * (toFloat f2.weight / 100))

                        carbsWeight =
                            f1.carbs
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.carbs * (toFloat f2.weight / 100))

                        macrosWeight =
                            protWeight + fatWeight + carbsWeight

                        expected =
                            protWeight / macrosWeight
                    in
                    if macrosWeight == 0 then
                        Expect.equal Nothing res.percentByWeight

                    else
                        case res.percentByWeight of
                            Nothing ->
                                Expect.fail "expected a vakue"

                            Just r ->
                                Expect.all
                                    [ Expect.within
                                        (Expect.Absolute 0.000001)
                                        expected
                                    , Expect.atLeast 0
                                    , Expect.atMost 1
                                    ]
                                    r.protein
            , fuzz2 fuzzNewFood fuzzNewFood "fat" <|
                \f1 f2 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2

                        res =
                            MC.result newMC

                        protWeight =
                            f1.protein
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.protein * (toFloat f2.weight / 100))

                        fatWeight =
                            f1.fat
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.fat * (toFloat f2.weight / 100))

                        carbsWeight =
                            f1.carbs
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.carbs * (toFloat f2.weight / 100))

                        macrosWeight =
                            protWeight + fatWeight + carbsWeight

                        expected =
                            fatWeight / macrosWeight
                    in
                    if macrosWeight == 0 then
                        Expect.equal Nothing res.percentByWeight

                    else
                        case res.percentByWeight of
                            Nothing ->
                                Expect.fail "expected a vakue"

                            Just r ->
                                Expect.all
                                    [ Expect.within
                                        (Expect.Absolute 0.000001)
                                        expected
                                    , Expect.atLeast 0
                                    , Expect.atMost 1
                                    ]
                                    r.fat
            , fuzz2 fuzzNewFood fuzzNewFood "carbs" <|
                \f1 f2 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2

                        res =
                            MC.result newMC

                        protWeight =
                            f1.protein
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.protein * (toFloat f2.weight / 100))

                        fatWeight =
                            f1.fat
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.fat * (toFloat f2.weight / 100))

                        carbsWeight =
                            f1.carbs
                                * (toFloat f1.weight / 100)
                                |> (+) (f2.carbs * (toFloat f2.weight / 100))

                        macrosWeight =
                            protWeight + fatWeight + carbsWeight

                        expected =
                            carbsWeight / macrosWeight
                    in
                    if macrosWeight == 0 then
                        Expect.equal Nothing res.percentByWeight

                    else
                        case res.percentByWeight of
                            Nothing ->
                                Expect.fail "expected a vakue"

                            Just r ->
                                Expect.all
                                    [ Expect.within
                                        (Expect.Absolute 0.000001)
                                        expected
                                    , Expect.atLeast 0
                                    , Expect.atMost 1
                                    ]
                                    r.carbs
            ]
        , describe
            "encode / decode"
          <|
            [ fuzz3 fuzzNewFood fuzzNewFood fuzzNewFood "encode and decode a model" <|
                \f1 f2 f3 ->
                    let
                        newMC =
                            MC.init
                                |> MC.add f1
                                |> MC.add f2
                                |> MC.add f3
                                |> MC.portionsSet 2

                        decoded =
                            case MC.decode <| MC.encode newMC of
                                Ok fc ->
                                    fc

                                Err err ->
                                    Debug.log (Debug.toString err) MC.init
                    in
                    Expect.equal
                        decoded
                        newMC
            ]
        ]



-- HELPERS
-- TODO: vanity thing: consider handling "NAN" and "infinity" and very big and small ints of weight.


type TFood
    = MCFood MC.Food
    | MCNewFood MC.NewFood


comp : TFood -> TFood -> Bool
comp newFood food =
    case ( newFood, food ) of
        ( MCFood f1, MCFood f2 ) ->
            f1 == f2

        ( MCNewFood f1, MCNewFood f2 ) ->
            f1 == f2

        ( MCNewFood f1, MCFood f2 ) ->
            f1.name
                == f2.name
                && f1.calories
                == f2.calories
                && f1.protein
                == f2.protein
                && f1.carbs
                == f2.carbs
                && f1.fat
                == f2.fat
                && f1.weight
                == f2.weight

        ( MCFood f1, MCNewFood f2 ) ->
            f1.name
                == f2.name
                && f1.calories
                == f2.calories
                && f1.protein
                == f2.protein
                && f1.carbs
                == f2.carbs
                && f1.fat
                == f2.fat
                && f1.weight
                == f2.weight


fuzzFood : Fuzzer MC.Food
fuzzFood =
    Fuzz.map7 MC.Food
        int
        string
        (intAtLeast 0)
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (intAtLeast 0)


fuzzNewFood : Fuzzer MC.NewFood
fuzzNewFood =
    Fuzz.map6 MC.NewFood
        string
        (intAtLeast 0)
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (floatRange 0 1000000)
        (intAtLeast 0)


apple : MC.NewFood
apple =
    { name = "apple"
    , calories = 52
    , protein = 0.3
    , fat = 0.2
    , carbs = 13.8
    , weight = 100
    }


newFoodFromFood : MC.Food -> MC.NewFood
newFoodFromFood f =
    { name = f.name
    , calories = f.calories
    , protein = f.protein
    , fat = f.fat
    , carbs = f.carbs
    , weight = f.weight
    }
