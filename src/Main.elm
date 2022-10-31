module Main exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (Html, a, div, h1, li, p, text, ul)
import Html.Attributes exposing (href)
import Page exposing (Page(..))
import Page.NotFound as NotFound
import String
import Url exposing (Protocol, Url)



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url
    }


init : {} -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model key url, Cmd.none )



-- UPDATE


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        page =
            urlToPage model.url
    in
    { title = "Strandersson.se " ++ pageToString page
    , body =
        [ viewHeader model
        , viewPage page
        ]
    }


viewHeader : Model -> Html Msg
viewHeader _ =
    div []
        [ h1 [] [ text "Strandersson.se" ]
        , ul []
            [ li [] [ viewLink "Home" "/" ]
            , li [] [ viewLink "About" "/about" ]
            , li [] [ viewLink "Contact" "/contact" ]
            ]
        ]


viewLink : String -> String -> Html Msg
viewLink label path =
    li [] [ a [ href path ] [ text label ] ]


viewUrlDetails : Url -> Html Msg
viewUrlDetails url =
    div []
        [ p [] [ text <| Url.toString url ]
        , ul []
            [ li [] [ text <| "protocol:" ++ protocolString url.protocol ]
            , li [] [ text <| "host:" ++ url.host ]
            , li [] [ text <| "port:" ++ Maybe.withDefault "" (Maybe.map String.fromInt url.port_) ]
            , li [] [ text <| "path:" ++ url.path ]
            , li [] [ text <| "query:" ++ Maybe.withDefault "" url.query ]
            , li [] [ text <| "fragment:" ++ Maybe.withDefault "" url.fragment ]
            ]
        ]



-- VIEW HELPERS


protocolString : Protocol -> String
protocolString protocol =
    case protocol of
        Url.Http ->
            "http"

        Url.Https ->
            "https"


urlToPage : Url -> Page
urlToPage url =
    case url.path of
        _ ->
            NotFound NotFound.details


pageToString : Page -> String
pageToString page =
    case page of
        NotFound _ ->
            "Not found"


viewPage : Page -> Html Msg
viewPage page =
    case page of
        NotFound _ ->
            div [] [ text "Not found" ]



-- MAIN


main : Program {} Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
