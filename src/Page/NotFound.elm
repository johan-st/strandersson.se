module Page.NotFound exposing (Model, Msg(..), details, update, view)

import Html exposing (Html, div, li, p, text, ul)
import Page
import Url exposing (Protocol(..), Url)



-- Page DetailsDetails


details : Page.Details
details =
    { title = "Page Not Found"
    , description = "The page you are looking for does not exist."
    , path = "404"
    }



-- Model


type alias Model =
    { urlRequested : Url }



-- Update


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    viewUrlDetails model.urlRequested


viewUrlDetails : Url -> Html Msg
viewUrlDetails url =
    let
        protocolString =
            case url.protocol of
                Http ->
                    "http"

                Https ->
                    "https"
    in
    div []
        [ p [] [ text <| Url.toString url ]
        , ul []
            [ li [] [ text <| "protocol:" ++ protocolString ]
            , li [] [ text <| "host:" ++ url.host ]
            , li [] [ text <| "port:" ++ Maybe.withDefault "" (Maybe.map String.fromInt url.port_) ]
            , li [] [ text <| "path:" ++ url.path ]
            , li [] [ text <| "query:" ++ Maybe.withDefault "" url.query ]
            , li [] [ text <| "fragment:" ++ Maybe.withDefault "" url.fragment ]
            ]
        ]
