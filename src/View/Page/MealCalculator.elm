module View.Page.MealCalculator exposing (view)

import A_Model exposing (..)
import B_Message exposing (..)
import C_Data exposing (..)
import E_Init exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled, for, id, name, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Misc.MealCalculator as MC exposing (MealCalculator(..))



-- VIEW


type alias Input =
    { id : String
    , label : String
    , placeholder : String
    , value : String
    , onInput : String -> MealMsg
    , valid : Bool
    , type_ : String
    , subtext : Maybe String
    }


view : ModelMealCalculator -> Html MealMsg
view model =
    div [ id "mealCalculator" ]
        [ viewAddFood model
        , viewFoods (foods model.currentMealCalculator) model.edit
        , viewResult <| MC.result model.currentMealCalculator
        ]


viewAddFood : ModelMealCalculator -> Html MealMsg
viewAddFood model =
    div [ class "addFood" ]
        [ h2 [] [ text "Add Food" ]
        , viewSearch model.searchResults model.searchTerm
        , viewManualInputs model
        , viewInputsExtras model <| result model.currentMealCalculator
        ]


viewSearch : List Livsmedel -> String -> Html MealMsg
viewSearch searchResults searchTerm =
    div [ id "search" ]
        [ p [ class "warning" ]
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


viewSearchResults : List Livsmedel -> Html MealMsg
viewSearchResults searchResults =
    div [ id "search-results" ]
        [ ul []
            (List.map viewSearchResult (List.take 10 searchResults))
        ]


viewSearchResult : Livsmedel -> Html MealMsg
viewSearchResult food =
    li []
        [ text food.namn
        , button [ onClick <| AddFoodFromSearch food ] [ text "Add" ]
        ]


viewInputsExtras : ModelMealCalculator -> MC.MCResult -> Html MealMsg
viewInputsExtras model res =
    let
        i =
            model.inputs

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
    div [ class "inputs-wrapper" ] <|
        List.map viewInput inputsOthers


viewManualInputs : ModelMealCalculator -> Html MealMsg
viewManualInputs model =
    let
        i =
            model.inputs

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
    in
    div []
        [ button [ onClick ToggleAddManual ] [ text "add manualy" ]
        , div [ classList [ ( "addManual", True ), ( "addManual--open", model.addManual == Open ) ] ]
            [ form [ onSubmit AddFood, class "inputs-wrapper" ] <|
                List.map viewInput inputsAdd
                    ++ viewSubmit (not <| validAddInputs i)
            ]
        ]


{-| Bool to disable submit button
-}
viewSubmit : Bool -> List (Html MealMsg)
viewSubmit dis =
    [ input
        [ class "submit"
        , type_ "submit"
        , value "Add"
        , disabled dis
        ]
        []
    ]


viewInput : Input -> Html MealMsg
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


sanityCheckString : MealInputs -> String
sanityCheckString i =
    let
        prot =
            Maybe.withDefault 0 <| commaFloat i.protein

        fat =
            Maybe.withDefault 0 <| commaFloat i.fat

        carbs =
            Maybe.withDefault 0 <| commaFloat i.carbs

        estKcal =
            estimatedKcal prot fat carbs
    in
    "~ " ++ String.fromInt estKcal ++ " kcals/100g"


viewFoods : List MC.Food -> Maybe MealEdit -> Html MealMsg
viewFoods fs edit =
    ul [ class "foodList" ] <|
        viewFoodListHeader
            :: List.map (viewFood edit) fs


viewFoodListHeader : Html MealMsg
viewFoodListHeader =
    li [ class "foodList__header" ]
        [ div [ class "foodList__info" ] [ text "Kalorier i kcal/100g. Övriga i g/100g" ]
        , div [ class "food food--header" ]
            [ div [ class "food__name" ] [ text "Namn" ]
            , div [ class "food__weight" ] [ text "Mängd" ]
            , div [ class "food__protein" ] [ text "Protein" ]
            , div [ class "food__fat" ] [ text "Fett" ]
            , div [ class "food__carbs" ] [ text "Kolhydrater" ]
            , div [ class "food__calories" ] [ text "Kalorier" ]
            , div [ class "food__delete" ] [ text "ta bort" ]
            ]
        ]


viewFood : Maybe MealEdit -> MC.Food -> Html MealMsg
viewFood mEdit food =
    case mEdit of
        Just edit ->
            if food.id == edit.id then
                viewFoodEdit food edit

            else
                viewFoodNormal food

        _ ->
            viewFoodNormal food


viewFoodNormal : MC.Food -> Html MealMsg
viewFoodNormal food =
    li [ class "food" ]
        [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
        , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
        , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
        , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
        , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
        , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
        , div [ class "food__delete interactable", onClick <| RemoveFood food ] [ text "ta bort" ]
        ]


viewFoodEdit : MC.Food -> MealEdit -> Html MealMsg
viewFoodEdit food edit =
    case edit.field of
        Name ->
            let
                valid =
                    validInput Name edit.value
            in
            li [ class "food" ]
                [ input [ class "food__name", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Name food ] [ text <| food.name ]
                , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
                , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
                , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
                , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
                , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        Weight ->
            let
                valid =
                    validInput Weight edit.value
            in
            li [ class "food" ]
                [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
                , input [ class "food__weight", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Weight food ] [ text <| food.name ]
                , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
                , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
                , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
                , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        Protein ->
            let
                valid =
                    validInput Protein edit.value
            in
            li [ class "food" ]
                [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
                , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
                , input [ class "food__protein", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Protein food ] [ text <| food.name ]
                , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
                , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
                , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        Fat ->
            let
                valid =
                    validInput Fat edit.value
            in
            li [ class "food" ]
                [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
                , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
                , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
                , input [ class "food__fat", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Fat food ] [ text <| food.name ]
                , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
                , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        Carbs ->
            let
                valid =
                    validInput Carbs edit.value
            in
            li [ class "food" ]
                [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
                , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
                , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
                , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
                , input [ class "food__carbs", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Carbs food ] [ text <| food.name ]
                , div [ class "food__calories interactable", onClick <| EditFood Calories food ] [ text <| String.fromInt food.calories ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        Calories ->
            let
                valid =
                    validInput Calories edit.value
            in
            li [ class "food" ]
                [ div [ class "food__name interactable", onClick <| EditFood Name food ] [ text <| food.name ]
                , div [ class "food__weight interactable", onClick <| EditFood Weight food ] [ text <| String.fromInt food.weight ++ " g" ]
                , div [ class "food__protein interactable", onClick <| EditFood Protein food ] [ text <| String.fromFloat food.protein ]
                , div [ class "food__fat interactable", onClick <| EditFood Fat food ] [ text <| String.fromFloat food.fat ]
                , div [ class "food__carbs interactable", onClick <| EditFood Carbs food ] [ text <| String.fromFloat food.carbs ]
                , input [ class "food__calories", classList [ ( "valid", valid ) ], value edit.value, onInput <| EditFoodInput Calories food ] [ text <| food.name ]
                , div [ class "food__done interactable", classList [ ( "valid", valid ) ], onClick <| EditFoodDone valid ] [ text "Klar" ]
                ]

        _ ->
            viewFoodNormal food


viewResult : MC.MCResult -> Html MealMsg
viewResult res =
    section [ class "results" ]
        [ viewPercentages res
        , viewPartials "per portion" "resultsPartial resultsPartial--portion" res.portion
        , viewPartials "totalt" "resultsPartial resultsPartial--total" res.total
        ]


viewPercentages : MC.MCResult -> Html MealMsg
viewPercentages res =
    let
        header =
            h3 [ class "results__header" ] [ text "fördeling" ]
    in
    case res.percentByWeight of
        Just percentByWeight ->
            div [ class "results__percentages" ]
                [ header
                , viewLabelAndData "results__percentage" "protein" (toPercent percentByWeight.protein)
                , viewLabelAndData "results__percentage" "fett" (toPercent percentByWeight.fat)
                , viewLabelAndData "results__percentage" "kolhydrater" (toPercent percentByWeight.carbs)
                ]

        Nothing ->
            div [ class "results__percentages" ]
                [ header
                , viewLabelAndData "results__percentage" "protein" "N/A"
                , viewLabelAndData "results__percentage" "fett" "N/A"
                , viewLabelAndData "results__percentage" "kolhydrater" "N/A"
                ]


viewPartials : String -> String -> MC.MCResultPartial -> Html MealMsg
viewPartials titel additionalClass portion =
    div [ class additionalClass ]
        [ h3 [ class "results__header" ] [ text titel ]
        , viewLabelAndData "resultsPartial__kcal" "kalorier" (String.fromInt portion.calories ++ " kcal")

        -- , viewLabelAndData "resultsPartial__estimate" "kalorier (uppskattat)" (String.fromInt portion.estimatedKcal ++ " kcal")
        , viewLabelAndData "resultsPartial__protein" "protein" (roundToString portion.protein ++ " g")
        , viewLabelAndData "resultsPartial__fat" "fett" (roundToString portion.fat ++ " g")
        , viewLabelAndData "resultsPartial__carbs" "kolhydrater" (roundToString portion.carbs ++ " g")
        , viewLabelAndData "resultsPartial__weight" "vikt" (String.fromInt portion.weight ++ " g")
        ]


viewLabelAndData : String -> String -> String -> Html MealMsg
viewLabelAndData className label data =
    div [ class className ]
        [ div [ class "resultsPartial__label" ] [ text label ]
        , div [ class "resultsPartial__data" ] [ text data ]
        ]



-- LOGIC


foods : MealCalculator -> List MC.Food
foods (MealCalculator internals) =
    internals.foods |> List.sortBy .id


result : MealCalculator -> MC.MCResult
result (MealCalculator internals) =
    let
        totalWeight =
            case internals.doneWeight of
                Just weight ->
                    weight

                Nothing ->
                    internals.foods
                        |> List.map .weight
                        |> List.sum

        totalCalories =
            internals.foods
                |> List.map (\food -> toFloat food.calories * (toFloat food.weight / 100))
                |> List.sum

        totalProtein =
            internals.foods
                |> List.map (\food -> food.protein * (toFloat food.weight / 100))
                |> List.sum

        totalCarbs =
            internals.foods
                |> List.map (\food -> food.carbs * (toFloat food.weight / 100))
                |> List.sum

        totalFat =
            internals.foods
                |> List.map (\food -> food.fat * (toFloat food.weight / 100))
                |> List.sum

        weightMacros =
            totalProtein + totalCarbs + totalFat

        percentByWeight =
            if weightMacros == 0 then
                Nothing

            else
                Just
                    { protein = ratioOf weightMacros totalProtein
                    , fat = ratioOf weightMacros totalFat
                    , carbs = ratioOf weightMacros totalCarbs
                    }

        kcalEstTotal =
            estimatedKcal totalProtein totalFat totalCarbs

        kcalEstPortion =
            toFloat kcalEstTotal / toFloat internals.portions |> round
    in
    { total =
        { calories = totalCalories |> round
        , protein = totalProtein
        , carbs = totalCarbs
        , fat = totalFat
        , weight = totalWeight
        , estimatedKcal = kcalEstTotal
        }
    , portion =
        { calories = totalCalories / toFloat internals.portions |> round
        , protein = totalProtein / toFloat internals.portions
        , carbs = totalCarbs / toFloat internals.portions
        , fat = totalFat / toFloat internals.portions
        , weight = toFloat totalWeight / toFloat internals.portions |> round
        , estimatedKcal = kcalEstPortion
        }
    , percentByWeight = percentByWeight
    }


estimatedKcal : Float -> Float -> Float -> Int
estimatedKcal protein fat carbs =
    round <|
        proteinGramsToKcal protein
            + fatGramsToKcal fat
            + carbsGramsToKcal carbs


proteinGramsToKcal : Float -> Float
proteinGramsToKcal grams =
    grams * 4


fatGramsToKcal : Float -> Float
fatGramsToKcal grams =
    grams * 9


carbsGramsToKcal : Float -> Float
carbsGramsToKcal grams =
    grams * 4


validAddInputs : MealInputs -> Bool
validAddInputs i =
    validInput Name i.name
        && validInput Calories i.calories
        && validInput Protein i.protein
        && validInput Fat i.fat
        && validInput Carbs i.carbs
        && validInput Weight i.weight


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



-- HELPERS


{-| TODO: rename to appropriate name
-}
ratioOf : Float -> Float -> Float
ratioOf whole part =
    if part == 0 then
        0

    else if whole == 0 then
        1

    else
        part / whole


commaFloat : String -> Maybe Float
commaFloat s =
    s
        |> String.replace "," "."
        |> String.toFloat


toPercent : Float -> String
toPercent value =
    value
        |> (*) 1000
        |> round
        |> toFloat
        |> (\f -> f / 10)
        |> String.fromFloat
        |> (\s -> s ++ "%")


roundToString : Float -> String
roundToString value =
    value
        |> (*) 10
        |> round
        |> toFloat
        |> (\f -> f / 10)
        |> String.fromFloat
