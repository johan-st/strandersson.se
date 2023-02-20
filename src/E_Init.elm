module E_Init exposing (..)

-- import Date exposing (Date)
-- import Time exposing (Time, now)
-- import Task exposing (perform)
-- import WebData exposing (WebData(..))
-- import WebData.Http as Http

import A_Model exposing (..)
import B_Message exposing (..)
import Browser.Navigation as Nav
import C_Data exposing (..)
import D_Command exposing (getLivsmedel)
import F_Update exposing (..)
import Html exposing (..)
import Json.Decode as D
import Json.Encode
import Misc.MealCalculator as MC exposing (MealCalculator(..))
import Url



---------------------------------------------------
-- This is where we hard-code stuff like routes,
-- init states, etc.
-- As we may need to run a 'Cmd' inside an 'init'
-- we populate this stage last.
---------------------------------------------------
------------------
-- init
------------------


type alias Flags =
    { foodCalculator : Json.Encode.Value
    , build : String
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        fcNull =
            D.decodeValue (D.null True) flags.foodCalculator

        cmd =
            getLivsmedel
    in
    if fcNull == Ok True then
        initBlank flags url key cmd

    else
        let
            fcRes =
                D.decodeValue MC.decoder flags.foodCalculator
        in
        case fcRes of
            Err _ ->
                initBlank flags url key cmd

            Ok mc ->
                ( { build = flags.build
                  , key = key
                  , route = routeParser url
                  , mealCalcModel =
                        { currentMealCalculator = mc
                        , savedMealCalculators = []
                        , edit = Nothing
                        , inputs = initMealcalculatorInputs mc
                        , foodData = []
                        , search = ""
                        , searchResults = []
                        }
                  }
                , cmd
                )


initBlank : Flags -> Url.Url -> Nav.Key -> Cmd Msg -> ( Model, Cmd Msg )
initBlank flags url key cmd =
    ( { build = flags.build
      , key = key
      , route = routeParser url
      , mealCalcModel =
            { currentMealCalculator = MC.init
            , savedMealCalculators = []
            , edit = Nothing
            , inputs = initMealcalculatorInputs MC.init
            , foodData = []
            , search = ""
            , searchResults = []
            }
      }
    , cmd
    )


initMealcalculatorInputs : MealCalculator -> MealInputs
initMealcalculatorInputs mc =
    let
        cookedWeightLocal =
            case cookedWeight mc of
                Nothing ->
                    ""

                Just int ->
                    String.fromInt int
    in
    { name = ""
    , calories = ""
    , protein = ""
    , fat = ""
    , carbs = ""
    , weight = ""
    , portions = String.fromInt <| portions mc
    , cookedWeight = cookedWeightLocal
    }


portions : MealCalculator -> Int
portions (MealCalculator internals) =
    internals.portions


cookedWeight : MealCalculator -> Maybe Int
cookedWeight (MealCalculator internals) =
    internals.doneWeight
