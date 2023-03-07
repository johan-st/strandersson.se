module G_View exposing (..)

import A_Model exposing (..)
import B_Message exposing (..)
import Browser exposing (Document)
import C_Data exposing (..)
import Html exposing (div)
import Html.Attributes exposing (id)
import View.Footer as Footer
import View.Header as Header
import View.Page.Home as PageHome
import View.Page.MealCalculator as PageMealCalculator
import View.Page.NotFound404 as NotFound404


view : Model -> Document Msg
view model =
    { title = "Strandersson.se"
    , body = [ Html.map Meal (MealCalculator.view model.mealCalcModel) ]
    }


docTitle : Route -> String
docTitle route =
    let
        base =
            "Strandesson.se | "
    in
    case route of
        HomeRoute ->
            base ++ "Home"

        MealRoute ->
            base ++ "Meal Calculator"

        NotFoundRoute ->
            base ++ "404"


pageViewer : Model -> Html.Html Msg
pageViewer model =
    let
        viewMain =
            case model.route of
                HomeRoute ->
                    PageHome.view

                MealRoute ->
                    Html.map Meal <| PageMealCalculator.view model.mealCalcModel

                NotFoundRoute ->
                    NotFound404.view
    in
    div [ id "main" ] [ viewMain ]
