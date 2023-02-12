port module Main exposing (main)

import Browser
import FoodCalculator as FC
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, for, href, id, name, placeholder, type_, value)
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
    , edit : Maybe Edit
    , inputs : Inputs
    }


type alias Edit =
    { id : Int
    , field : InputField
    , value : String
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
          , edit = Nothing
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
                  , edit = Nothing
                  , inputs = inputsInit FC.init
                  }
                , Cmd.none
                )

            Ok fc ->
                ( { build = flags.build
                  , foodCalculator = fc
                  , edit = Nothing
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
    let
        cookedWeight =
            case FC.cookedWeight fc of
                Nothing ->
                    ""

                Just int ->
                    String.fromInt int
    in
    { name = ""
    , calories = ""
    , protein = ""
    , fat = ""
    , carbs = ""
    , weight = ""
    , portions = String.fromInt <| FC.portions fc
    , cookedWeight = cookedWeight
    }



-- UPDATE


type Msg
    = InputChanged InputField String
    | AddFood
    | RemoveFood Int
    | EditFood InputField FC.Food
    | EditFoodInput InputField FC.Food String
    | EditFoodDone Bool


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

        EditFood field food ->
            let
                str =
                    case field of
                        Name ->
                            food.name

                        Calories ->
                            String.fromInt food.calories

                        Protein ->
                            String.fromFloat food.protein

                        Fat ->
                            String.fromFloat food.fat

                        Carbs ->
                            String.fromFloat food.carbs

                        Weight ->
                            String.fromInt food.weight

                        _ ->
                            "not implemented"
            in
            ( { model
                | edit = Just <| Edit food.id field str
              }
            , Cmd.none
            )

        EditFoodInput field food str ->
            let
                newEdit =
                    Edit food.id field str

                newFC =
                    if validInput field str then
                        updateFood model.foodCalculator food field str

                    else
                        model.foodCalculator
            in
            ( { model
                | foodCalculator = newFC
                , edit = Just newEdit
              }
            , localStorageSet <| FC.encoder newFC
            )

        EditFoodDone valid ->
            if valid then
                ( { model
                    | edit = Nothing
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        RemoveFood index ->
            let
                newModel =
                    { model | foodCalculator = FC.remove index model.foodCalculator }
            in
            ( newModel, localStorageSet <| FC.encoder newModel.foodCalculator )


updateFood : FC.FoodCalculator -> FC.Food -> InputField -> String -> FC.FoodCalculator
updateFood fc food field str =
    let
        maybeInt =
            String.toInt str

        maybeFloat =
            commaFloat str

        newFood =
            case ( field, maybeInt, maybeFloat ) of
                ( Name, _, _ ) ->
                    { food | name = str }

                ( Calories, Just int, _ ) ->
                    { food | calories = int }

                ( Protein, _, Just float ) ->
                    { food | protein = float }

                ( Fat, _, Just float ) ->
                    { food | fat = float }

                ( Carbs, _, Just float ) ->
                    { food | carbs = float }

                ( Weight, Just int, _ ) ->
                    { food | weight = int }

                _ ->
                    food

        newFC =
            FC.updateFood newFood fc
    in
    newFC


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
        | inputs = updateInputs field value model.inputs
        , foodCalculator = newFC
      }
    , if field == Portions || field == CookedWeight then
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
    , subtext : Maybe String
    }


view : Model -> Html Msg
view model =
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
        [ section [ id "add-food-form" ]
            [ h2 [] [ text "Add Food" ]
            , viewInputs model.inputs <| FC.result model.foodCalculator
            ]
        , section [ id "food-list" ]
            [ h2 [] [ text "Food" ]
            , viewFoods (FC.foods model.foodCalculator) model.edit
            ]
        , section [ id "results" ]
            [ h2 [] [ text "Result" ]
            , viewResult <| FC.result model.foodCalculator
            ]
        ]


viewFooter : String -> Html Msg
viewFooter build =
    div [ id "footer" ]
        [ div [] [ text build ]
        , a [ href "https://github.com/johan-st/strandersson.se" ] [ text "github" ]
        ]


viewInputs : Inputs -> FC.FCResult -> Html Msg
viewInputs i res =
    let
        inputsAdd =
            [ { id = "name"
              , label = "Name"
              , placeholder = "\"potatoes\""
              , value = i.name
              , onInput = InputChanged Name
              , valid = validInput Name i.name
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "calories"
              , label = "Calories"
              , placeholder = "kcal/100g"
              , value = i.calories
              , onInput = InputChanged Calories
              , valid = validInput Calories i.calories
              , type_ = "text"
              , subtext = Just <| viewSanityCheckString i
              }
            , { id = "protein"
              , label = "Protein"
              , placeholder = "g/100g"
              , value = i.protein
              , onInput = InputChanged Protein
              , valid = validInput Protein i.protein
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "fat"
              , label = "Fat"
              , placeholder = "g/100g"
              , value = i.fat
              , onInput = InputChanged Fat
              , valid = validInput Fat i.fat
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "carbs"
              , label = "Carbs"
              , placeholder = "g/100g"
              , value = i.carbs
              , onInput = InputChanged Carbs
              , valid = validInput Carbs i.carbs
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "weight"
              , label = "Weight"
              , placeholder = "g"
              , value = i.weight
              , onInput = InputChanged Weight
              , valid = validInput Weight i.weight
              , type_ = "text"
              , subtext = Nothing
              }
            ]

        inputsOthers =
            [ { id = "portions"
              , label = "Portions"
              , placeholder = "number of portions"
              , value = i.portions
              , onInput = InputChanged Portions
              , valid = validInput Portions i.portions
              , type_ = "number"
              , subtext = Nothing
              }
            , { id = "cookedWeight"
              , label = "Cooked Weight"
              , placeholder = String.fromInt res.total.weight ++ "g"
              , value = i.cookedWeight
              , onInput = InputChanged CookedWeight
              , valid = validInput CookedWeight i.cookedWeight
              , type_ = "text"
              , subtext = Nothing
              }
            ]
    in
    div []
        [ form [ onSubmit AddFood, class "inputs-wrapper" ] <|
            List.map viewInput inputsAdd
                ++ viewSubmit (not <| validAddInputs i)
        , div [ class "inputs-wrapper" ] <|
            List.map viewInput inputsOthers
        ]


{-| Bool to disable submit button
-}
viewSubmit : Bool -> List (Html Msg)
viewSubmit dis =
    [ input
        [ class "submit"
        , type_ "submit"
        , value "Add"
        , disabled dis
        ]
        []
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
        , case i.subtext of
            Just s ->
                p [ class "subtext" ] [ text s ]

            Nothing ->
                text ""
        ]


viewSanityCheckString : Inputs -> String
viewSanityCheckString i =
    let
        prot =
            Maybe.withDefault 0 <| commaFloat i.protein

        fat =
            Maybe.withDefault 0 <| commaFloat i.fat

        carbs =
            Maybe.withDefault 0 <| commaFloat i.carbs

        estimatedKcal =
            FC.estimatedKcalPer100g 100 prot fat carbs
    in
    "~ " ++ String.fromInt estimatedKcal ++ " kcals/100g"


viewFoods : List FC.Food -> Maybe Edit -> Html Msg
viewFoods fs edit =
    table []
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
            (List.map (viewFood edit) fs)
        ]


viewFood : Maybe Edit -> FC.Food -> Html Msg
viewFood mEdit food =
    case mEdit of
        Just edit ->
            if food.id == edit.id then
                viewFoodEdit food edit

            else
                viewFoodNormal food

        _ ->
            viewFoodNormal food


viewFoodNormal : FC.Food -> Html Msg
viewFoodNormal food =
    tr []
        [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
        , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
        , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
        , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
        , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
        , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
        , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
        ]


viewFoodEdit : FC.Food -> Edit -> Html Msg
viewFoodEdit food edit =
    case edit.field of
        Name ->
            let
                valid =
                    validInput Name edit.value
            in
            tr []
                [ td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Name food ] []
                    , div [ classList [ ( "interactable", valid ), ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
                , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
                , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
                , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
                , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        Calories ->
            let
                valid =
                    validInput Calories edit.value
            in
            tr []
                [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
                , td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Calories food ] []
                    , div [ classList [ ( "interactable", valid ), ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
                , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
                , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
                , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        Protein ->
            let
                valid =
                    validInput Protein edit.value
            in
            tr []
                [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
                , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
                , td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Protein food ] []
                    , div [ classList [ ( "interactable", valid ), ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
                , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
                , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        Fat ->
            let
                valid =
                    validInput Fat edit.value
            in
            tr []
                [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
                , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
                , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
                , td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Fat food ] []
                    , div [ classList [ ( "interactable", valid ), ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
                , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        Carbs ->
            let
                valid =
                    validInput Carbs edit.value
            in
            tr []
                [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
                , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
                , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
                , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
                , td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Carbs food ] []
                    , div [ classList [ ( "interactable", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        Weight ->
            let
                valid =
                    validInput Weight edit.value
            in
            tr []
                [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
                , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
                , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
                , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
                , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
                , td []
                    [ input [ classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Weight food ] []
                    , div [ classList [ ( "interactable", valid ) ], onClick <| EditFoodDone valid ] [ text "done" ]
                    ]
                , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
                ]

        _ ->
            viewFoodNormal food


viewResult : FC.FCResult -> Html Msg
viewResult result =
    let
        estimate =
            "~ " ++ String.fromInt result.estimatedKcal ++ " kcal (from macros)"

        protPercent =
            case result.percentByWeight of
                Just percentByWeight ->
                    toPercent percentByWeight.protein ++ " %"

                Nothing ->
                    "N/A"

        fatPercent =
            case result.percentByWeight of
                Just percentByWeight ->
                    toPercent percentByWeight.fat ++ " %"

                Nothing ->
                    "N/A"

        carbsPercent =
            case result.percentByWeight of
                Just percentByWeight ->
                    toPercent percentByWeight.carbs ++ " %"

                Nothing ->
                    "N/A"
    in
    table []
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
                [ td [] [ text <| String.fromInt result.portion.calories ++ " kcal" ]
                , td [] [ text <| String.fromFloat result.portion.protein ++ " g" ]
                , td [] [ text <| String.fromFloat result.portion.fat ++ " g" ]
                , td [] [ text <| String.fromFloat result.portion.carbs ++ " g" ]
                , td [] [ text <| String.fromInt result.portion.weight ++ " g" ]
                ]
            , tr []
                [ td [] [ text estimate ]
                , td [] [ text protPercent ]
                , td [] [ text fatPercent ]
                , td [] [ text carbsPercent ]
                , td [] [ text "-" ]
                ]
            ]
        ]



-- HELPER FUNCTIONS


toPercent : Float -> String
toPercent value =
    value
        |> (*) 1000
        |> round
        |> toFloat
        |> (\f -> f / 10)
        |> String.fromFloat


{-| Validate string as input for given InputFIeld
-}
validInput : InputField -> String -> Bool
validInput f str =
    case f of
        Name ->
            if String.length str < 3 then
                False

            else
                True

        Calories ->
            str
                |> String.toInt
                |> Maybe.map (\int -> int >= 0)
                |> Maybe.withDefault False

        Protein ->
            str
                |> commaFloat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Fat ->
            str
                |> commaFloat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Carbs ->
            str
                |> commaFloat
                |> Maybe.map (\float -> float >= 0)
                |> Maybe.withDefault False

        Weight ->
            str
                |> String.toInt
                |> Maybe.map (\int -> int >= 0)
                |> Maybe.withDefault False

        Portions ->
            str
                |> String.toInt
                |> Maybe.map (\int -> int > 0)
                |> Maybe.withDefault False

        CookedWeight ->
            str
                |> String.toInt
                |> Maybe.map (\int -> int > 0)
                |> Maybe.withDefault False


validAddInputs : Inputs -> Bool
validAddInputs i =
    validInput Name i.name
        && validInput Calories i.calories
        && validInput Protein i.protein
        && validInput Fat i.fat
        && validInput Carbs i.carbs
        && validInput Weight i.weight


commaFloat : String -> Maybe Float
commaFloat s =
    s
        |> String.replace "," "."
        |> String.toFloat


inputsToFood : Inputs -> Maybe FC.NewFood
inputsToFood i =
    let
        mName =
            if validInput Name i.name then
                Just i.name

            else
                Nothing

        mCalories =
            if validInput Calories i.calories then
                String.toInt i.calories

            else
                Nothing

        mProtein =
            if validInput Protein i.protein then
                commaFloat i.protein

            else
                Nothing

        mFat =
            if validInput Fat i.fat then
                commaFloat i.fat

            else
                Nothing

        mCarbs =
            if validInput Carbs i.carbs then
                commaFloat i.carbs

            else
                Nothing

        mWeight =
            if validInput Weight i.weight then
                String.toInt i.weight

            else
                Nothing
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



-- PORTS


port localStorageSet : Json.Encode.Value -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
