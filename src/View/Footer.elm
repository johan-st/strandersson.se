module View.Footer exposing (..)

import A_Model exposing (Model)
import B_Message exposing (Msg)
import Html exposing (..)
import Html.Attributes exposing (..)


view : Model -> Html Msg
view model =
    div [ class "footer" ]
        [ p []
            [ text "Made with "
            , a [ href "https://elm-lang.org/" ] [ text "Elm" ]
            , text " by "
            , a [ href "https://jst.dev/" ] [ text "johan-st" ]
            ]
        , p [class "footer__build-tag"] [ text model.build ]
        , p
            []
            [ text "Source code on "
            , a [ href "https://github.com/johan-st/strandesson.se" ] [ text "GitHub" ]
            ]
        ]
