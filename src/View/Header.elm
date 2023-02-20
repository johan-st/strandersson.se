module View.Header exposing (..)

import A_Model exposing (..)
import B_Message exposing (Msg)
import Html exposing (..)
import Html.Attributes exposing (..)


view : Model -> Html Msg
view model =
    div [ id "header" ]
        [ div [ class "header__logo" ]
            [ a [ href "/" ]
                [ img
                    [ src "https://via.placeholder.com/400x100/4787a8?text=placeholder+logo"
                    ]
                    []
                ]
            ]
        , nav [ class "header__nav" ]
            [ a [ classList [ ( "current", model.route == HomeRoute ) ], href "/" ] [ text "Home" ]
            , a [ classList [ ( "current", model.route == MealRoute ) ], href "/meal" ] [ text "Meal Calculator" ]
            , a [ classList [ ( "current", model.route == NotFoundRoute ) ], href "/contact" ] [ text "404" ]
            ]
        ]
