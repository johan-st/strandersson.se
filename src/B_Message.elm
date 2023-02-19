module B_Message exposing (..)

import Browser
import C_Data exposing (..)
import Http
import Misc.MealCalculator as MC
import Url



-- import Time exposing (Time)


type Route
    = HomeRoute
    | MealRoute
    | NotFoundRoute


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
      -- | TimeChange Time
      -- router
    | NavigateTo Route
      -- home
    | Home HomeMsg
      -- meal
    | Meal MealMsg


type HomeMsg
    = NoOp



-- MEAL CALCULATOR


type MealMsg
    = GotFoodData (Result Http.Error (List Livsmedel))
    | InputChanged InputField String
    | AddFood
    | RemoveFood Int
    | EditFood InputField MC.Food
    | EditFoodInput InputField MC.Food String
    | EditFoodDone Bool
    | SearchInput String
    | AddFoodFromSearch Livsmedel


mealMap : MealMsg -> Msg
mealMap msg =
    Meal msg


type InputField
    = Name
    | Calories
    | Protein
    | Fat
    | Carbs
    | Weight
    | Portions
    | CookedWeight
