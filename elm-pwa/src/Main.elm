module Main exposing (..)

import A_Model exposing (Model)
import B_Message exposing (Msg(..))
import Browser
import E_Init exposing (Flags, init)
import F_Update exposing (update)
import G_View exposing (view)


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
