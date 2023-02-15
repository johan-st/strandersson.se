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


filter : String -> List Livsmedel -> List Livsmedel
filter query list =
    plainFilter query list


{-| TODO: replace with fuzzy search. candidate dependency added
-}
plainFilter : String -> List Livsmedel -> List Livsmedel
plainFilter query list =
    List.filter (\item -> String.contains (String.toLower query) (String.toLower item.namn)) list


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