port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, for, href, id, name, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D
import Json.Encode
import Livsmedel exposing (Livsmedel)
import MealCalculator as MC


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
    , currentMealCalculator : MC.MealCalculator
    , savedMealCalculators : List MCSave
    , edit : Maybe Edit
    , inputs : Inputs
    , foodData : List Livsmedel
    , search : String
    , searchResults : List Livsmedel
    }


type alias MCSave =
    { id : Int
    , name : String
    , foodCalculator : MC.MealCalculator
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


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        fcNull =
            D.decodeValue (D.null True) flags.foodCalculator

        cmd =
            Http.get
                { url = "/livsmedelsDB.json"
                , expect = Http.expectJson GotFoodData Livsmedel.decoder
                }
    in
    if fcNull == Ok True then
        ( { build = flags.build
          , currentMealCalculator = MC.init
          , savedMealCalculators = []
          , edit = Nothing
          , inputs = inputsInit MC.init
          , foodData = []
          , search = ""
          , searchResults = []
          }
        , cmd
        )

    else
        let
            fcRes =
                D.decodeValue MC.decoder flags.foodCalculator
        in
        case fcRes of
            Err _ ->
                ( { build = flags.build
                  , currentMealCalculator = MC.init
                  , savedMealCalculators = []
                  , edit = Nothing
                  , inputs = inputsInit MC.init
                  , foodData = []
                  , search = ""
                  , searchResults = []
                  }
                , cmd
                )

            Ok fc ->
                ( { build = flags.build
                  , currentMealCalculator = fc
                  , savedMealCalculators = []
                  , edit = Nothing
                  , inputs = inputsInit fc
                  , foodData = []
                  , search = ""
                  , searchResults = []
                  }
                , cmd
                )


inputsInit : MC.MealCalculator -> Inputs
inputsInit fc =
    let
        cookedWeight =
            case MC.cookedWeight fc of
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
    , portions = String.fromInt <| MC.portions fc
    , cookedWeight = cookedWeight
    }



-- UPDATE


type Msg
    = GotFoodData (Result Http.Error (List Livsmedel))
    | InputChanged InputField String
    | AddFood
    | RemoveFood Int
    | EditFood InputField MC.Food
    | EditFoodInput InputField MC.Food String
    | EditFoodDone Bool
    | SearchInput String
    | AddFoodFromSearch Livsmedel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFoodData (Ok livsmedel) ->
            ( { model
                | foodData = livsmedel
              }
            , Cmd.none
            )

        GotFoodData (Err _) ->
            -- TODO: handle error
            ( model, Cmd.none )

        InputChanged field value ->
            updateModelWithInputs model field value

        AddFood ->
            case inputsToFood model.inputs of
                Just new ->
                    let
                        newModel =
                            { model
                                | currentMealCalculator = MC.add new model.currentMealCalculator
                                , inputs = inputsInit model.currentMealCalculator
                            }
                    in
                    ( newModel
                    , localStorageSet <| MC.encoder newModel.currentMealCalculator
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

                newMC =
                    if validInput field str then
                        updateFood model.currentMealCalculator food field str

                    else
                        model.currentMealCalculator
            in
            ( { model
                | currentMealCalculator = newMC
                , edit = Just newEdit
              }
            , localStorageSet <| MC.encoder newMC
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
                    { model | currentMealCalculator = MC.remove index model.currentMealCalculator }
            in
            ( newModel, localStorageSet <| MC.encoder newModel.currentMealCalculator )

        SearchInput str ->
            ( { model | search = str, searchResults = Livsmedel.filter str model.foodData }, Cmd.none )

        AddFoodFromSearch livsmedel ->
            let
                newFood =
                    { name = livsmedel.namn
                    , calories = round <| livsmedel.energi
                    , protein = livsmedel.protein
                    , fat = livsmedel.fett
                    , carbs = livsmedel.kolhydrater
                    , weight = 100
                    }

                newModel =
                    { model
                        | currentMealCalculator = MC.add newFood model.currentMealCalculator
                    }
            in
            ( newModel, Cmd.none )


updateFood : MC.MealCalculator -> MC.Food -> InputField -> String -> MC.MealCalculator
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

        newMC =
            MC.updateFood newFood fc
    in
    newMC


updateModelWithInputs : Model -> InputField -> String -> ( Model, Cmd Msg )
updateModelWithInputs model field value =
    let
        maybeInt =
            String.toInt value

        newMC =
            case ( field, maybeInt ) of
                ( Portions, Just int ) ->
                    if int > 0 then
                        MC.portionsSet int model.currentMealCalculator

                    else
                        model.currentMealCalculator

                ( CookedWeight, Just int ) ->
                    if int > 0 then
                        MC.cookedWeightSet maybeInt model.currentMealCalculator

                    else if int <= 0 then
                        MC.cookedWeightSet Nothing model.currentMealCalculator

                    else
                        model.currentMealCalculator

                ( CookedWeight, Nothing ) ->
                    MC.cookedWeightSet Nothing model.currentMealCalculator

                _ ->
                    model.currentMealCalculator
    in
    ( { model
        | inputs = updateInputs field value model.inputs
        , currentMealCalculator = newMC
      }
    , if field == Portions || field == CookedWeight then
        localStorageSet <| MC.encoder newMC

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



-- HELPER FUNCTIONS


roundToString : Float -> String
roundToString value =
    value
        |> (*) 10
        |> round
        |> toFloat
        |> (\f -> f / 10)
        |> String.fromFloat


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


inputsToFood : Inputs -> Maybe MC.NewFood
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
        , viewSearch model.searchResults model.search
        , viewFooter model.build
        ]


viewSearch : List Livsmedel -> String -> Html Msg
viewSearch searchResults searchTerm =
    div [ id "search" ]
        [ h2 [] [ text "Search (prototype)" ]
        , p [ class "warning" ]
            [ text "- Search is still under development -" ]
        , viewInput
            { id = "search-input"
            , label = "Search"
            , placeholder = "enter at least 2 characters"
            , value = searchTerm
            , onInput = SearchInput
            , valid = String.length searchTerm >= 2
            , type_ = "text"
            , subtext = Just <| "Search results: " ++ String.fromInt (List.length searchResults)
            }
        , viewSearchResults searchResults
        ]


viewSearchResults : List Livsmedel -> Html Msg
viewSearchResults searchResults =
    div [ id "search-results" ]
        [ ul []
            (List.map viewSearchResult (List.take 10 searchResults))
        ]


viewSearchResult : Livsmedel -> Html Msg
viewSearchResult food =
    li []
        [ text food.namn
        , button [ onClick <| AddFoodFromSearch food ] [ text "Add" ]
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
            , viewInputs model.inputs <| MC.result model.currentMealCalculator
            ]
        , section [ id "food-list" ]
            [ h2 [] [ text "Food" ]
            , viewFoods (MC.foods model.currentMealCalculator) model.edit
            ]
        , section [ id "results" ]
            [ h2 [] [ text "Result" ]
            , viewResult <| MC.result model.currentMealCalculator
            ]
        ]


viewFooter : String -> Html Msg
viewFooter buildTag =
    div [ id "footer" ]
        [ a [ href "https://github.com/johan-st/strandersson.se" ] [ text "johan-st@github" ]
        , div [] [ text buildTag ]
        , a [ href "https://www.livsmedelsverket.se/" ] [ text "data från livsmedelsverket" ]
        ]


viewInputs : Inputs -> MC.MCResult -> Html Msg
viewInputs i res =
    let
        inputsAdd =
            [ { id = "name"
              , label = "Namn"
              , placeholder = "\"potatis\""
              , value = i.name
              , onInput = InputChanged Name
              , valid = validInput Name i.name
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "calories"
              , label = "Kalorier"
              , placeholder = "kcal/100g"
              , value = i.calories
              , onInput = InputChanged Calories
              , valid = validInput Calories i.calories
              , type_ = "text"
              , subtext = Just <| sanityCheckString i
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
              , label = "Fett"
              , placeholder = "g/100g"
              , value = i.fat
              , onInput = InputChanged Fat
              , valid = validInput Fat i.fat
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "carbs"
              , label = "Kolhydrater"
              , placeholder = "g/100g"
              , value = i.carbs
              , onInput = InputChanged Carbs
              , valid = validInput Carbs i.carbs
              , type_ = "text"
              , subtext = Nothing
              }
            , { id = "weight"
              , label = "Vikt"
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


sanityCheckString : Inputs -> String
sanityCheckString i =
    let
        prot =
            Maybe.withDefault 0 <| commaFloat i.protein

        fat =
            Maybe.withDefault 0 <| commaFloat i.fat

        carbs =
            Maybe.withDefault 0 <| commaFloat i.carbs

        estimatedKcal =
            MC.estimatedKcal prot fat carbs
    in
    "~ " ++ String.fromInt estimatedKcal ++ " kcals/100g"


viewFoods : List MC.Food -> Maybe Edit -> Html Msg
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


viewFood : Maybe Edit -> MC.Food -> Html Msg
viewFood mEdit food =
    case mEdit of
        Just edit ->
            if food.id == edit.id then
                viewFoodEdit food edit

            else
                viewFoodNormal food

        _ ->
            viewFoodNormal food


viewFoodNormal : MC.Food -> Html Msg
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


viewFoodEdit : MC.Food -> Edit -> Html Msg
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


viewResult : MC.MCResult -> Html Msg
viewResult result =
    let
        estimate =
            "~ " ++ String.fromInt result.portion.estimatedKcal ++ " kcal (from macros)"

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
                , td [] [ text <| roundToString result.portion.protein ++ " g" ]
                , td [] [ text <| roundToString result.portion.fat ++ " g" ]
                , td [] [ text <| roundToString result.portion.carbs ++ " g" ]
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
