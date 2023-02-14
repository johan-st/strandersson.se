module Livsmedel exposing (Livsmedel, decoderList, filter)

import Json.Decode as D exposing (Decoder)
import Simple.Fuzzy


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
    Simple.Fuzzy.filter
        (\lm -> lm.namn |> Simple.Fuzzy.root)
        (query |> Simple.Fuzzy.root)
        list


decoderList : Decoder (List Livsmedel)
decoderList =
    D.field "livsmedel" (D.list decoder)


decoder : Decoder Livsmedel
decoder =
    D.map6
        Livsmedel
        (D.field "namn" D.string)
        (D.field "id" D.int)
        (D.field "energi" D.float)
        (D.field "kolhydrater" D.float)
        (D.field "protein" D.float)
        (D.field "fett" D.float)
