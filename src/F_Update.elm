module F_Update exposing (..)

import A_Model exposing (..)
import B_Message exposing (..)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import C_Data exposing (..)
import D_Command exposing (..)
import Fuzzy
import Misc.MealCalculator as MC
import Url exposing (Url)



-- import E_Init exposing (parseLocation, reverseRoute)
----------------------------------------------------------------
-- Top level Message processing. Note that we handle each message
-- case explicitly in this function and in all helper update
-- functions. E.g., there are no '_' case matches.
--
-- Super clean.
--
----------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Internal url ->
                    ( { model
                        | route = routeParser url
                        , topNav = Closed
                      }
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model, Nav.load url )

        UrlChanged url ->
            ( { model
                | route = routeParser url
                , topNav = Closed
              }
            , Cmd.none
            )

        ToggleMenu ->
            case model.topNav of
                Open ->
                    ( { model | topNav = Closed }, Cmd.none )

                Closed ->
                    ( { model | topNav = Open }, Cmd.none )

        Meal mealMsg ->
            let
                ( newMealModel, cmd ) =
                    updateMeal mealMsg model.mealCalcModel
            in
            ( { model | mealCalcModel = newMealModel }, Cmd.map Meal cmd )

        NoOp ->
            ( model, Cmd.none )

        NotFound _ ->
            ( model, Cmd.none )



-- ------
-- ROUTES
-- ------


routeParser : Url -> Route
routeParser url =
    let
        pathList =
            url.path
                |> String.split "/"
                |> List.filter (\s -> s /= "")
                |> List.map String.toLower
    in
    case pathList of
        [] ->
            HomeRoute

        "meal" :: _ ->
            MealRoute

        _ ->
            NotFoundRoute


pathFromRoute : Route -> String
pathFromRoute route =
    case route of
        HomeRoute ->
            "/"

        MealRoute ->
            "/meal"

        NotFoundRoute ->
            "/404"



-- ---------------
-- MEAL CALCULATOR
-- ---------------


updateMeal : MealMsg -> ModelMealCalculator -> ( ModelMealCalculator, Cmd MealMsg )
updateMeal msg model =
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
                                , inputs = clearInputs model.currentMealCalculator
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
                | edit = Just <| MealEdit food.id field str
              }
            , Cmd.none
            )

        EditFoodInput field food str ->
            let
                newEdit =
                    MealEdit food.id field str

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

        EditFoodDone _ ->
            ( { model
                | edit = Nothing
              }
            , Cmd.none
            )

        RemoveFood food ->
            let
                newModel =
                    { model | currentMealCalculator = MC.remove food.id model.currentMealCalculator }
            in
            ( newModel, localStorageSet <| MC.encoder newModel.currentMealCalculator )

        SearchInput str ->
            ( { model | searchTerm = str, searchResults = filter str model.foodData }, Cmd.none )

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
                        , searchTerm = ""
                        , searchResults = []
                    }
            in
            ( newModel, localStorageSet <| MC.encoder newModel.currentMealCalculator )

        ToggleAddManual ->
            case model.addManual of
                Open ->
                    ( { model | addManual = Closed }, Cmd.none )

                Closed ->
                    ( { model | addManual = Open }, Cmd.none )


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


updateModelWithInputs : ModelMealCalculator -> InputField -> String -> ( ModelMealCalculator, Cmd MealMsg )
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


updateInputs : InputField -> String -> MealInputs -> MealInputs
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


clearInputs : MC.MealCalculator -> MealInputs
clearInputs fc =
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


inputsToFood : MealInputs -> Maybe MC.NewFood
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



-- filter livsmedeö


{-| lower limit is the minimum numver of chaacters needed to attempt search
-}
filter : String -> List Livsmedel -> List Livsmedel
filter query list =
    let
        rootquery =
            root query
    in
    if String.length rootquery < 2 then
        []

    else
        list
            |> filterOnFirst 3 rootquery
            |> filterFuzz rootquery


filterOnFirst : Int -> String -> List Livsmedel -> List Livsmedel
filterOnFirst numberOfChars query list =
    -- first two chars must match
    let
        short =
            String.left numberOfChars query

        res =
            list
                |> List.filter (\item -> String.contains (root short) (root item.namn))
    in
    res


filterFuzz : String -> List Livsmedel -> List Livsmedel
filterFuzz query list =
    let
        simpleMatch config separators needle hay =
            Fuzzy.match config separators needle hay
    in
    list
        |> List.sortBy
            (\item ->
                simpleMatch [] [] query (item.namn |> root)
                    |> .score
            )



-- -------
-- HEPLERS
-- -------


{-| trim whitespace and convert to lower case
-}
root : String -> String
root str =
    str
        |> String.trim
        |> String.toLower


commaFloat : String -> Maybe Float
commaFloat s =
    s
        |> String.replace "," "."
        |> String.toFloat
