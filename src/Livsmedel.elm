module Livsmedel exposing (Livsmedel, decoder, filter)

import Fuzzy
import Json.Decode as D exposing (Decoder)


type alias Livsmedel =
    { namn : String
    , id : Int
    , energi : Float
    , kolhydrater : Float
    , protein : Float
    , fett : Float
    }


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



-- HEPLERS


{-| trim whitespace and convert to lower case
-}
root : String -> String
root str =
    str
        |> String.trim
        |> String.toLower



-- DECODER


decoder : Decoder (List Livsmedel)
decoder =
    D.field "livsmedel" (D.list decoderSingle)


decoderSingle : Decoder Livsmedel
decoderSingle =
    D.map6
        Livsmedel
        (D.field "namn" D.string)
        (D.field "id" (D.string |> D.andThen stringToIntDecoder))
        (D.field "energi" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "carbohydrate" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "protein" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "fat" (D.string |> D.andThen stringToFloatDecoder))


stringToIntDecoder : String -> Decoder Int
stringToIntDecoder intString =
    case String.toInt intString of
        Just value ->
            D.succeed value

        Nothing ->
            D.fail ("Invalid integer: " ++ intString)


stringToFloatDecoder : String -> Decoder Float
stringToFloatDecoder floatString =
    let
        floatStringDot =
            String.replace "," "." floatString
    in
    case String.toFloat floatStringDot of
        Just value ->
            D.succeed value

        Nothing ->
            D.fail ("Invalid float: " ++ floatStringDot)
