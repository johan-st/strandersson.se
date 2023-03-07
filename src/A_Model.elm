module A_Model exposing (..)

import B_Message exposing (..)
import C_Data exposing (..)
import Misc.MealCalculator as MC exposing (MealCalculator(..))


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
    , route : Route
    , topNav : MenuState
    , mealCalcModel : ModelMealCalculator
    }


type MenuState
    = Open
    | Closed



--  MEAL CALCULATOR


type alias ModelMealCalculator =
    { currentMealCalculator : MealCalculator
    , savedMealCalculators : List MealCalculator
    , addManual : MenuState
    , edit : Maybe MealEdit
    , inputs : MealInputs
    , foodData : List Livsmedel
    , searchTerm : String
    , searchResults : List Livsmedel
    }


type alias Edit =
    { id : Int
    , field : InputField
    , value : String
    }


type alias Inputs =
    { name : String
    , calories : String
    , protein : String
    , fat : String
    , carbs : String
    , weight : String
    , portions : String
    , cookedWeight : String
    }
