module Views.Page.MealCalculator exposing (view)

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
    div [ class "wrapper" ]
        [ viewHeader
        , viewCalculator model
        , viewSearch model.searchResults model.search

        -- , viewFooter model.build
        ]


viewSearch : List Livsmedel -> String -> Html MealMsg
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


viewHeader : Html MealMsg
viewHeader =
    div [ id "header" ]
        [ h1 [] [ text "Food Calculator" ]
        , p [] [ text "Calculate the calories, protein, fat and carbs of your food." ]
        ]


viewCalculator : ModelMealCalculator -> Html MealMsg
viewCalculator model =
    div [ id "main" ]
        [ section [ id "add-food-form" ]
            [ h2 [] [ text "Add Food" ]
            , viewInputs model.inputs <| result model.currentMealCalculator
            ]
        , section [ id "food-list" ]
            [ h2 [] [ text "Food" ]
            , viewFoods (foods model.currentMealCalculator) model.edit
            ]
        , section [ id "results" ]
            [ h2 [] [ text "Result" ]
            , viewResult <| result model.currentMealCalculator
            ]
        ]



-- viewFooter : String -> Html MealMsg
-- viewFooter buildTag =
--     div [ id "footer" ]
--         [ a [ href "https://github.com/johan-st/strandersson.se" ] [ text "johan-st@github" ]
--         , div [] [ text buildTag ]
--         , a [ href "https://www.livsmedelsverket.se/" ] [ text "data från livsmedelsverket" ]
--         ]


viewInputs : Inputs -> MC.MCResult -> Html MealMsg
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


sanityCheckString : Inputs -> String
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


viewFoods : List MC.Food -> Maybe Edit -> Html MealMsg
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


viewFood : Maybe Edit -> MC.Food -> Html MealMsg
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
    tr []
        [ td [ class "interactable", onClick <| EditFood Name food ] [ text food.name ]
        , td [ class "interactable", onClick <| EditFood Calories food ] [ text (String.fromInt food.calories) ]
        , td [ class "interactable", onClick <| EditFood Protein food ] [ text (String.fromFloat food.protein) ]
        , td [ class "interactable", onClick <| EditFood Fat food ] [ text (String.fromFloat food.fat) ]
        , td [ class "interactable", onClick <| EditFood Carbs food ] [ text (String.fromFloat food.carbs) ]
        , td [ class "interactable", onClick <| EditFood Weight food ] [ text (String.fromInt food.weight) ]
        , td [ class "interactable", class "danger", onClick <| RemoveFood food.id ] [ text "remove" ]
        ]


viewFoodEdit : MC.Food -> Edit -> Html MealMsg
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


viewResult : MC.MCResult -> Html MealMsg
viewResult res =
    let
        estimate =
            "~ " ++ String.fromInt res.portion.estimatedKcal ++ " kcal (from macros)"

        protPercent =
            case res.percentByWeight of
                Just percentByWeight ->
                    toPercent percentByWeight.protein ++ " %"

                Nothing ->
                    "N/A"

        fatPercent =
            case res.percentByWeight of
                Just percentByWeight ->
                    toPercent percentByWeight.fat ++ " %"

                Nothing ->
                    "N/A"

        carbsPercent =
            case res.percentByWeight of
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
                [ td [] [ text <| String.fromInt res.portion.calories ++ " kcal" ]
                , td [] [ text <| roundToString res.portion.protein ++ " g" ]
                , td [] [ text <| roundToString res.portion.fat ++ " g" ]
                , td [] [ text <| roundToString res.portion.carbs ++ " g" ]
                , td [] [ text <| String.fromInt res.portion.weight ++ " g" ]
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


validAddInputs : Inputs -> Bool
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
