port module Main exposing (main)

import Browser
import FoodCalculator as FC
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, name, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode as D
import Json.Encode


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { buildTime : String
    , foodCalculator : FC.FoodCalculator
    , inputs : Inputs
    }


{-| TODO: add versioning to flags
-}
type alias Flags =
    { foodCalculator : Json.Encode.Value
    , buildTime : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        fcNull =
            D.decodeValue (D.null True) flags.foodCalculator
    in
    if fcNull == Ok True then
        ( { buildTime = flags.buildTime
          , foodCalculator = FC.init
          , inputs = inputsInit FC.init
          }
        , Cmd.none
        )

    else
        let
            fcRes =
                D.decodeValue FC.decoder flags.foodCalculator
        in
        case fcRes of
            Err _ ->
                ( { buildTime = flags.buildTime
                  , foodCalculator = FC.init
                  , inputs = inputsInit FC.init
                  }
                , Cmd.none
                )

            Ok fc ->
                ( { buildTime = flags.buildTime
                  , foodCalculator = fc
                  , inputs = inputsInit fc
                  }
                , Cmd.none
                )


type alias Inputs =
    { name : String
    , calories : String
    , protein : String
    , fat : String
    , carbs : String
    , weight : String
    , portions : String
    }


type InputField
    = Name
    | Calories
    | Protein
    | Fat
    | Carbs
    | Weight
    | Portions


inputsInit : FC.FoodCalculator -> Inputs
inputsInit fc =
    Inputs "" "" "" "" "" "" (String.fromInt <| FC.portions fc)



-- UPDATE


type Msg
    = InputChanged InputField String
    | AddFood
    | RemoveFood Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged field value ->
            updateModelWithInputs model field value

        AddFood ->
            case inputsToNewFood model.inputs of
                Just new ->
                    let
                        newModel =
                            { model
                                | foodCalculator = FC.add new model.foodCalculator
                                , inputs = inputsInit model.foodCalculator
                            }
                    in
                    ( newModel
                    , localStorageSet <| FC.encoder newModel.foodCalculator
                    )

                Nothing ->
                    ( model, Cmd.none )

        RemoveFood index ->
            let
                newModel =
                    { model | foodCalculator = FC.remove index model.foodCalculator }
            in
            ( newModel, localStorageSet <| FC.encoder newModel.foodCalculator )


updateModelWithInputs : Model -> InputField -> String -> ( Model, Cmd Msg )
updateModelWithInputs model field value =
    let
        maybeNewPortions =
            case field of
                Portions ->
                    String.toInt value

                _ ->
                    Nothing

        newFC =
            case maybeNewPortions of
                Just newPortions ->
                    FC.setPortions newPortions model.foodCalculator

                Nothing ->
                    model.foodCalculator
    in
    ( { model
        | inputs = updateInputs field value model.inputs
        , foodCalculator = newFC
      }
    , if field == Portions then
        localStorageSet <| FC.encoder newFC

      else
        Cmd.none
    )


updateInputs : InputField -> String -> Inputs -> Inputs
updateInputs field value inputs =
    let
        new =
            case field of
                Name ->
                    { inputs | name = value }

                Calories ->
                    { inputs | calories = value }

                Protein ->
                    { inputs | protein = value }

                Fat ->
                    { inputs | fat = value }

                Carbs ->
                    { inputs | carbs = value }

                Weight ->
                    { inputs | weight = value }

                Portions ->
                    { inputs | portions = value }
    in
    case field of
        Name ->
            new

        _ ->
            if inputValid field new then
                new

            else
                inputs



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Meal Calculator" ]
        , viewAdd model.inputs
        , viewFoods <| FC.foods model.foodCalculator
        , viewResult <| FC.result model.foodCalculator
        , viewFooter model.buildTime
        ]


viewFooter : String -> Html Msg
viewFooter buildTime =
    div [ class "footer" ]
        [ text "Build: "
        , text buildTime
        ]


viewAdd : Inputs -> Html Msg
viewAdd i =
    div []
        [ form [ onSubmit AddFood ]
            [ input
                [ type_ "text"
                , placeholder "Name"
                , onInput <| InputChanged Name
                , classList [ ( "valid", inputValid Name i ) ]
                , value i.name
                ]
                []
            , input
                [ type_ "number"
                , placeholder "Calories"
                , onInput <| InputChanged Calories
                , classList [ ( "valid", inputValid Calories i ) ]
                , value i.calories
                ]
                []
            , input
                [ type_ "number"
                , placeholder "Protein"
                , onInput <| InputChanged Protein
                , classList [ ( "valid", inputValid Protein i ) ]
                , value i.protein
                ]
                []
            , input
                [ type_ "number"
                , placeholder "Fat"
                , onInput <| InputChanged Fat
                , classList [ ( "valid", inputValid Fat i ) ]
                , value i.fat
                ]
                []
            , input
                [ type_ "number"
                , placeholder "Carbs"
                , onInput <| InputChanged Carbs
                , classList [ ( "valid", inputValid Carbs i ) ]
                , value i.carbs
                ]
                []
            , input
                [ type_ "number"
                , placeholder "Weight"
                , onInput <| InputChanged Weight
                , classList [ ( "valid", inputValid Weight i ) ]
                , value i.weight
                ]
                []
            , input
                [ type_ "submit"
                , value "Add"
                , disabled <| not <| allValid i
                ]
                []
            ]
        , div []
            [ text "Portions: "
            , input
                [ type_ "number"
                , placeholder "Portions"
                , onInput <| InputChanged Portions
                , classList [ ( "valid", inputValid Portions i ) ]
                , value i.portions
                ]
                []
            ]
        ]


viewFoods : List FC.Food -> Html Msg
viewFoods fs =
    div []
        [ h2 [] [ text "Foods" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "Name" ]
                    , th [] [ text "Calories" ]
                    , th [] [ text "Protein" ]
                    , th [] [ text "Fat" ]
                    , th [] [ text "Carbs" ]
                    , th [] [ text "Weight" ]
                    , th [] [ text "Remove" ]
                    ]
                ]
            , tbody []
                (List.map viewFood fs)
            ]
        ]


viewFood : FC.Food -> Html Msg
viewFood food =
    tr []
        [ td [] [ text food.name ]
        , td [] [ text (String.fromInt food.calories) ]
        , td [] [ text (String.fromFloat food.protein) ]
        , td [] [ text (String.fromFloat food.fat) ]
        , td [] [ text (String.fromFloat food.carbs) ]
        , td [] [ text (String.fromInt food.weight) ]
        , td [ class "interactable", onClick <| RemoveFood food.id ] [ text "remove" ]
        ]


viewResult : FC.FCResult -> Html Msg
viewResult result =
    div []
        [ h2 [] [ text "Result" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "Calories" ]
                    , th [] [ text "Protein" ]
                    , th [] [ text "Fat" ]
                    , th [] [ text "Carbs" ]
                    , th [] [ text "Weight" ]
                    , th [] [ text "Total Weight" ]
                    ]
                ]
            , tbody []
                [ tr []
                    [ td [] [ text (String.fromInt result.calories) ]
                    , td [] [ text (String.fromFloat result.protein) ]
                    , td [] [ text (String.fromFloat result.fat) ]
                    , td [] [ text (String.fromFloat result.carbs) ]
                    , td [] [ text (String.fromInt result.portionWeight) ]
                    , td [] [ text (String.fromInt result.totalWeight) ]
                    ]
                ]
            ]
        ]



-- HELPER FUNCTIONS


inputValid : InputField -> Inputs -> Bool
inputValid f i =
    case f of
        Name ->
            if String.length i.name < 3 then
                False

            else
                True

        Calories ->
            String.toInt i.calories
                |> Maybe.map (\int -> int >= 0)
                |> Maybe.withDefault False

        Protein ->
            String.toFloat i.protein
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Fat ->
            String.toFloat i.fat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Carbs ->
            String.toFloat i.carbs
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Weight ->
            String.toInt i.weight
                |> Maybe.map (\int -> int >= 0)
                |> Maybe.withDefault False

        Portions ->
            String.toInt i.portions
                |> Maybe.map (\int -> int > 0)
                |> Maybe.withDefault False


allValid : Inputs -> Bool
allValid i =
    case inputsToNewFood i of
        Just _ ->
            True

        Nothing ->
            False


inputsToNewFood : Inputs -> Maybe FC.NewFood
inputsToNewFood i =
    let
        mName =
            if inputValid Name i then
                Just i.name

            else
                Nothing

        mCalories =
            String.toInt i.calories
                |> maybePositiveInt

        mProtein =
            String.toFloat i.protein
                |> maybePositiveFloat

        mFat =
            String.toFloat i.fat
                |> maybePositiveFloat

        mCarbs =
            String.toFloat i.carbs
                |> maybePositiveFloat

        mWeight =
            String.toInt i.weight
                |> maybePositiveInt
    in
    case ( mName, mCalories, mProtein ) of
        ( Just name, Just calories, Just protein ) ->
            case ( mFat, mCarbs, mWeight ) of
                ( Just fat, Just carbs, Just weight ) ->
                    Just
                        { name = name
                        , calories = calories
                        , protein = protein
                        , fat = fat
                        , carbs = carbs
                        , weight = weight
                        }

                _ ->
                    Nothing

        _ ->
            Nothing


maybePositiveInt : Maybe Int -> Maybe Int
maybePositiveInt maybeInt =
    Maybe.andThen
        (\int ->
            if int >= 0 then
                Just int

            else
                Nothing
        )
        maybeInt


maybePositiveFloat : Maybe Float -> Maybe Float
maybePositiveFloat maybeFloat =
    Maybe.andThen
        (\float ->
            if float >= 0 then
                Just float

            else
                Nothing
        )
        maybeFloat



-- PORTS


port localStorageSet : Json.Encode.Value -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
