module G_View exposing (..)

import A_Model exposing (..)
import B_Message exposing (..)
import Browser exposing (Document)
import C_Data exposing (..)
import E_Init exposing (Flags)
import Html
import View.Footer as Footer
import View.Header as Header
import View.Page.Home as PageHome
import View.Page.MealCalculator as PageMealCalculator
import View.Page.NotFound404 as NotFound404


view : Model -> Document Msg
view model =
    { title = docTitle model.route
    , body =
        [ Header.view model
        , pageViewer model
        , Footer.view model
        ]
    }


docTitle : Route -> String
docTitle route =
    let
        base =
            "Strandesson.se | "
    in
    case route of
        HomeRoute ->
            base ++ "Home"

        MealRoute ->
            base ++ "Meal Calculator"

        NotFoundRoute ->
            base ++ "404"


pageViewer : Model -> Html.Html Msg
pageViewer model =
    case model.route of
        HomeRoute ->
            PageHome.view

        MealRoute ->
            Html.map Meal <| PageMealCalculator.view model.mealCalcModel

        NotFoundRoute ->
            NotFound404.view



-- case model.appState of
--     Ready ->
--         routerView model
--     NotReady _ ->
--         text "Loading"
-- routerView : Model -> Html Msg
-- routerView model =
--     let
--         buttonStyles route =
--             if model.route == route then
--                 styles navigationButtonActive
--             else
--                 styles navigationButton
--     in
--         div [ styles [ bg ] ]
--             [ div [ styles (appStyles ++ wrapper) ]
--                 [ header [ styles headerSection ]
--                     [ h1 [] [ text (model.taco.translate "site-title") ]
--                     ]
--                 , nav [ styles navigationBar ]
--                     [ button
--                         [ onClick (NavigateTo HomeRoute)
--                         , buttonStyles HomeRoute
--                         ]
--                         [ text (model.taco.translate "page-title-home") ]
--                     , button
--                         [ onClick (NavigateTo SettingsRoute)
--                         , buttonStyles SettingsRoute
--                         ]
--                         [ text (model.taco.translate "page-title-settings") ]
--                     , button
--                         [ onClick (NavigateTo DonutsRoute)
--                         , buttonStyles DonutsRoute
--                         ]
--                         [ text (model.taco.translate "page-title-donuts") ]
--                     ]
--                 , pageView model
--                 , footer [ styles footerSection ]
--                     [ text (model.taco.translate "footer-github-before" ++ " ")
--                     , a
--                         [ href "https://github.com/ohanhi/elm-taco/"
--                         , styles footerLink
--                         ]
--                         [ text "Github" ]
--                     , text (model.taco.translate "footer-github-after")
--                     ]
--                 ]
--             ]
-- pageView : Model -> Html Msg
-- pageView model =
--     div [ styles activeView ]
--         [ (case model.route of
--             HomeRoute ->
--                 viewHome model
--             SettingsRoute ->
--                 viewSettings model
--             DonutsRoute ->
--                 viewDonuts model
--             NotFoundRoute ->
--                 h1 [] [ text "404 :(" ]
--           )
--         ]
