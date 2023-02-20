module A_Model exposing (..)

import B_Message exposing (..)
import Browser.Navigation as Nav
import C_Data exposing (..)
import Misc.MealCalculator exposing (MealCalculator(..))


type Route
    = HomeRoute
    | MealRoute
    | NotFoundRoute


type alias Model =
    ------------------------------------------------------
    --
    -- One Model To Rule Them All.
    --
    -- As you can see when you put all the models together
    -- you really don't need a heirarchy of components.
    -- Even if we had one hundred widgets/pages/etc,
    -- we'd stil be fine!
    ------------------------------------------------------
    { build : String
    , key : Nav.Key
    , route : Route
    , mealCalcModel : ModelMealCalculator
    }



--  MEAL CALCULATOR


type alias ModelMealCalculator =
    { currentMealCalculator : MealCalculator
    , savedMealCalculators : List MealCalculator
    , edit : Maybe MealEdit
    , inputs : MealInputs
    , foodData : List Livsmedel
    , search : String
    , searchResults : List Livsmedel
    }


type alias MealEdit =
    { id : Int
    , field : InputField
    , value : String
    }


type alias MealInputs =
    { name : String
    , calories : String
    , protein : String
    , fat : String
    , carbs : String
    , weight : String
    , portions : String
    , cookedWeight : String
    }
