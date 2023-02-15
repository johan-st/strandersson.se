module LivsmedelTests exposing (..)

import Expect
import Fuzz exposing (Fuzzer, floatRange, int, intAtLeast, string)
import Livsmedel as Data
import Test exposing (..)


suite : Test
suite =
    describe "FoodData" <|
        [ test "test test test" <|
            \() ->
                let
                    expected =
                        [ { namn = "Köttfärs"
                          , id = 2
                          , energi = 250
                          , kolhydrater = 0
                          , protein = 20
                          , fett = 20
                          }
                        , { namn = "Köttbullar"
                          , id = 3
                          , energi = 250
                          , kolhydrater = 10
                          , protein = 20
                          , fett = 20
                          }
                        ]
                in
                Data.filter "kött" smallSet
                    |> Expect.equalLists
                        expected
        ]


smallSet : List Data.Livsmedel
smallSet =
    [ { namn = "Ägg"
      , id = 1
      , energi = 155
      , kolhydrater = 0.6
      , protein = 13
      , fett = 10.5
      }
    , { namn = "Köttfärs"
      , id = 2
      , energi = 250
      , kolhydrater = 0
      , protein = 20
      , fett = 20
      }
    , { namn = "Köttbullar"
      , id = 3
      , energi = 250
      , kolhydrater = 10
      , protein = 20
      , fett = 20
      }
    ]
