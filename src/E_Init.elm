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
import Html exposing (..)
import Json.Decode as D
import Json.Encode
import Misc.MealCalculator as MC exposing (MealCalculator(..))
import Url



-- import Navigation exposing (Location)
-- import UrlParser as Url exposing ((</>))
---------------------------------------------------
-- This is where we hard-code stuff like routes,
-- init states, etc.
-- As we may need to run a 'Cmd' inside an 'init'
-- we populate this stage last.
---------------------------------------------------
--
--
--------------------------
-- routes & reverse routes
--------------------------
-- routeParser : Url.Parser (Route -> a) a
-- routeParser =
--     Url.oneOf
--         [ Url.map HomeRoute Url.top
--         , Url.map SettingsRoute (Url.s "settings")
--         , Url.map DonutsRoute (Url.s "donuts")
--         ]
-- reverseRoute : Route -> String
-- reverseRoute route =
--     case route of
--         SettingsRoute ->
--             "#/settings"
--         DonutsRoute ->
--             "#/donuts"
--         _ ->
--             "#/"
------------------
-- init
------------------


type alias Flags =
    { foodCalculator : Json.Encode.Value
    , build : String
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags _ _ =
    let
        fcNull =
            D.decodeValue (D.null True) flags.foodCalculator

        cmd =
            getLivsmedel

        -- cmd = Cmd.batch [ getLivsmedel ]
    in
    if fcNull == Ok True then
        initBlank flags cmd

    else
        let
            fcRes =
                D.decodeValue MC.decoder flags.foodCalculator
        in
        case fcRes of
            Err _ ->
                initBlank flags cmd

            Ok mc ->
                ( { build = flags.build
                  , key = key
                  , route = routeParser url
                  , topNav = Closed
                  , mealCalcModel =
                        { currentMealCalculator = mc
                        , addManual = Closed
                        , savedMealCalculators = []
                        , edit = Nothing
                        , inputs = initMealcalculatorInputs mc
                        , foodData = []
                        , searchTerm = ""
                        , searchResults = []
                        }
                  }
                , cmd
                )


initBlank : Flags -> Cmd Msg -> ( Model, Cmd Msg )
initBlank flags cmd =
    ( { build = flags.build
      , key = key
      , route = routeParser url
      , topNav = Closed
      , mealCalcModel =
            { currentMealCalculator = MC.init
            , addManual = Closed
            , savedMealCalculators = []
            , edit = Nothing
            , inputs = initMealcalculatorInputs MC.init
            , foodData = []
            , searchTerm = ""
            , searchResults = []
            }
      }
    , cmd
    )


initMealcalculatorInputs : MealCalculator -> Inputs
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
