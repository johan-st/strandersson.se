module View.Page.NotFound404 exposing (..)

import B_Message exposing (Msg)
import Html exposing (..)
import Html.Attributes exposing (..)


view : Html Msg
view =
    div
        [ class "page page--not-found-404" ]
        [ h1 [] [ text "404" ]
        , p [] [ text "Page not found" ]
        ]
