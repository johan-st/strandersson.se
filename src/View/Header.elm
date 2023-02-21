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
        [ div [ class "logo" ]
            [ a [ href "/", class "logo__link" ] [ text "Strandesson" ]
            ]
        , div [ class "nav__toggle", onClick ToggleMenu ]
            [ text menuText ]
        , nav
            [ classList
                [ ( "nav", True )
                , ( "nav--open", model.menuState == Open )
                ]
            ]
            [ navLink HomeRoute "/" "Home" model
            , navLink MealRoute "/meal" "Meal Calculator" model

            -- , navLink NotFoundRoute "/contact" "404" model
            ]
        ]


navLink : Route -> String -> String -> Model -> Html Msg
navLink route hrefStr name model =
    let
        textName =
            if model.route == route then
                "- " ++ name ++ " -"

            else
                name
    in
    a
        [ classList
            [ ( "nav__link", True )
            , ( "nav__link--current", model.route == route )
            ]
        , href hrefStr
        ]
        [ text textName ]
