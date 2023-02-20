module View.Page.Home exposing (..)

import B_Message exposing (Msg)
import Html exposing (..)
import Html.Attributes exposing (..)


view : Html Msg
view =
    div [ class "home" ]
        [ h2 [ class "home__title" ]
            [ text "Välkommen till familjen Strandersson" ]
        , p [] [ text "en liten samling verktyg och länkar vi tycker är användbara" ]
        ]
