port module Main exposing (main)

import Browser
import FoodCalculator as FC
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, for, id, name, placeholder, type_, value)
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
    { build : String
    , foodCalculator : FC.FoodCalculator
    , inputs : Inputs
    }


type alias Flags =
    { foodCalculator : Json.Encode.Value
    , build : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        fcNull =
            D.decodeValue (D.null True) flags.foodCalculator
    in
    if fcNull == Ok True then
        ( { build = flags.build
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
                ( { build = flags.build
                  , foodCalculator = FC.init
                  , inputs = inputsInit FC.init
                  }
                , Cmd.none
                )

            Ok fc ->
                ( { build = flags.build
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
    , cookedWeight : String
    }


type InputField
    = Name
    | Calories
    | Protein
    | Fat
    | Carbs
    | Weight
    | Portions
    | CookedWeight


inputsInit : FC.FoodCalculator -> Inputs
inputsInit fc =
    Inputs "" "" "" "" "" "" (String.fromInt <| FC.portions fc) ""



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
            case inputsToFood model.inputs of
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
        maybeInt =
            String.toInt value

        newFC =
            case ( field, maybeInt ) of
                ( Portions, Just int ) ->
                    if int > 0 then
                        FC.portionsSet int model.foodCalculator

                    else
                        model.foodCalculator

                ( CookedWeight, Just int ) ->
                    if int > 0 then
                        FC.cookedWeightSet maybeInt model.foodCalculator

                    else if int <= 0 then
                        FC.cookedWeightSet Nothing model.foodCalculator

                    else
                        model.foodCalculator

                ( CookedWeight, Nothing ) ->
                    FC.cookedWeightSet Nothing model.foodCalculator

                _ ->
                    model.foodCalculator
    in
    ( { model
        | inputs = updateInputs field value (commaFloats model.inputs)
        , foodCalculator = newFC
      }
    , if field == Portions then
        localStorageSet <| FC.encoder newFC

      else
        Cmd.none
    )


updateInputs : InputField -> String -> Inputs -> Inputs
updateInputs field value inputs =
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

        CookedWeight ->
            { inputs | cookedWeight = value }



-- VIEW


type alias Input =
    { id : String
    , label : String
    , placeholder : String
    , value : String
    , onInput : String -> Msg
    , valid : Bool
    , type_ : String
    }


view : Model -> Html Msg
view model =
    let
        _ =
            Debug.log "cookedWeight" (FC.cookedWeight model.foodCalculator)
    in
    div [ class "wrapper" ]
        [ viewHeader
        , viewCalculator model
        , viewFooter model.build
        ]


viewHeader : Html Msg
viewHeader =
    div [ id "header" ]
        [ h1 [] [ text "Food Calculator" ]
        , p [] [ text "Calculate the calories, protein, fat and carbs of your food." ]
        ]


viewCalculator : Model -> Html Msg
viewCalculator model =
    div [ id "main" ]
        [ viewInputs model.inputs
        , viewFoods <| FC.foods model.foodCalculator
        , viewResult <| FC.result model.foodCalculator
        ]


viewFooter : String -> Html Msg
viewFooter build =
    div [ id "footer" ]
        [ text build ]


viewInputs : Inputs -> Html Msg
viewInputs i =
    let
        inputsAdd =
            [ { id = "name"
              , label = "Name"
              , placeholder = "\"potatoes\""
              , value = i.name
              , onInput = InputChanged Name
              , valid = inputValid Name i
              , type_ = "text"
              }
            , { id = "calories"
              , label = "Calories"
              , placeholder = "kcal/100g"
              , value = i.calories
              , onInput = InputChanged Calories
              , valid = inputValid Calories i
              , type_ = "text"
              }
            , { id = "protein"
              , label = "Protein"
              , placeholder = "g/100g"
              , value = i.protein
              , onInput = InputChanged Protein
              , valid = inputValid Protein i
              , type_ = "text"
              }
            , { id = "fat"
              , label = "Fat"
              , placeholder = "g/100g"
              , value = i.fat
              , onInput = InputChanged Fat
              , valid = inputValid Fat i
              , type_ = "text"
              }
            , { id = "carbs"
              , label = "Carbs"
              , placeholder = "g/100g"
              , value = i.carbs
              , onInput = InputChanged Carbs
              , valid = inputValid Carbs i
              , type_ = "text"
              }
            , { id = "weight"
              , label = "Weight"
              , placeholder = "g"
              , value = i.weight
              , onInput = InputChanged Weight
              , valid = inputValid Weight i
              , type_ = "text"
              }
            ]

        inputsOthers =
            [ { id = "portions"
              , label = "Portions"
              , placeholder = "number of portions"
              , value = i.portions
              , onInput = InputChanged Portions
              , valid = inputValid Portions i
              , type_ = "number"
              }
            , { id = "cookedWeight"
              , label = "Cooked Weight"
              , placeholder = "g"
              , value = i.cookedWeight
              , onInput = InputChanged CookedWeight
              , valid = inputValid CookedWeight i
              , type_ = "text"
              }
            ]
    in
    div []
        [ form [ onSubmit AddFood, class "inputs-wrapper" ] <|
            List.map viewInput inputsAdd
                ++ [ input
                        [ class "submit"
                        , type_ "submit"
                        , value "Add"
                        , disabled <| not <| allValid i
                        ]
                        []
                   ]
        , div [ class "inputs-wrapper" ] <|
            List.map viewInput inputsOthers
        ]


viewInput : Input -> Html Msg
viewInput i =
    div [ class "input-wrapper" ]
        [ label [ for i.id ] [ text i.label ]
        , input
            [ name i.id
            , id i.id
            , type_ i.type_
            , placeholder i.placeholder
            , onInput <| i.onInput
            , classList [ ( "valid", i.valid ) ]
            , value i.value
            ]
            []
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
                    , th [] [ text "Actions" ]
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
                    , th [] [ text "Portion Weight" ]
                    ]
                ]
            , tbody []
                [ tr []
                    [ td [] [ text (String.fromInt result.calories) ]
                    , td [] [ text (String.fromFloat result.protein) ]
                    , td [] [ text (String.fromFloat result.fat) ]
                    , td [] [ text (String.fromFloat result.carbs) ]
                    , td [] [ text (String.fromInt result.portionWeight) ]
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
            i.protein
                |> commaFloat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Fat ->
            i.fat
                |> commaFloat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Carbs ->
            i.carbs
                |> commaFloat
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

        CookedWeight ->
            String.toInt i.cookedWeight
                |> Maybe.map (\int -> int > 0)
                |> Maybe.withDefault False


allValid : Inputs -> Bool
allValid i =
    case inputsToFood (commaFloats i) of
        Just _ ->
            True

        Nothing ->
            False


commaFloats : Inputs -> Inputs
commaFloats i =
    { i
        | protein = String.replace "," "." i.protein
        , fat = String.replace "," "." i.fat
        , carbs = String.replace "," "." i.carbs
    }


commaFloat : String -> Maybe Float
commaFloat s =
    s
        |> String.replace "," "."
        |> String.toFloat


inputsToFood : Inputs -> Maybe FC.NewFood
inputsToFood i =
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
