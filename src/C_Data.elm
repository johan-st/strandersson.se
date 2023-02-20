module C_Data exposing (..)

import Json.Decode as D exposing (Decoder)



-----------------------------------------------------------------
-- 'C_Data' is designed for records that are filled in via a Cmd,
-- 'arrive' in the form of a JSON message, are decode via a
-- decoder, and are added to the model in some fashion.
-----------------------------------------------------------------
-- LIVSMEDEL DATA


type alias Livsmedel =
    { namn : String
    , id : Int
    , energi : Float
    , kolhydrater : Float
    , protein : Float
    , fett : Float
    }


decoderListLivsmedel : Decoder (List Livsmedel)
decoderListLivsmedel =
    D.field "livsmedel" (D.list decoderLivsmedel)


decoderLivsmedel : Decoder Livsmedel
decoderLivsmedel =
    D.map6
        Livsmedel
        (D.field "namn" D.string)
        (D.field "id" (D.string |> D.andThen stringToIntDecoder))
        (D.field "energi" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "carbohydrate" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "protein" (D.string |> D.andThen stringToFloatDecoder))
        (D.field "fat" (D.string |> D.andThen stringToFloatDecoder))



-- HELPERS


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
