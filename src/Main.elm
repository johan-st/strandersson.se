module Main exposing (main)

import Browser
import Html exposing (..)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


-- MODEL
type alias Model =
    { foods : List Food
    , portions : Int
    }


init : Model
init =
    Model [] 8


type Msg
    = FoodAdded Food
    | FoodRemoved Food
    | PortionChanged Int


-- UPDATE

update : Msg -> Model -> Model
update msg model =
    case msg of
        Debug.todo "Update the model based on the message"

-- VIEW
view : Model -> Html Msg
view model =
    div []
        [ text "New Sandbox" ]
