module View.Header exposing (..)

import A_Model exposing (..)
import B_Message exposing (Msg(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


view : Model -> Html Msg
view model =
    let
        menuText =
            if model.menuState == Open then
                "Close"

            else
                "Menu"
    in
    div [ id "header" ]
        [ div [ class "header__logo" ]
            [ a [ href "/" ] [ text "Strandesson" ]
            ]
        , div [ class "header__menu-toggle", onClick ToggleMenu ]
            [ text menuText ]
        , nav [ classList [ ( "header__nav", True ), ( "header__nav--open", model.menuState == Open ) ] ]
            [ navLink HomeRoute "/" "Home" model
            , navLink MealRoute "/meal" "Meal Calculator" model
            , navLink NotFoundRoute "/contact" "404" model
            ]
        ]


navLink : Route -> String -> String -> Model -> Html Msg
navLink route hrefStr name model =
    a [ classList [ ( "current", model.route == route ) ], href hrefStr ] [ text name ]
