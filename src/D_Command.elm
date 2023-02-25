port module D_Command exposing (..)

-- import Date exposing (Date)
-- import WebData exposing (WebData(..))
-- import WebData.Http

import B_Message exposing (..)
import C_Data exposing (..)
import Http
import Json.Encode



-------------------------------------------------------------
-- Side effects go here, e.g. getting data from a database,
-- an API, etc.
--
-- Also, we want all Commands to return a Msg so we can process
-- it within the top level 'Update' function.
--
-- We can map or 'wrap' commnads that return sub messages
-- to a message if we want to break out processing of sub messages
-- to an update helper.
-------------------------------------------------------------


getLivsmedel : Cmd Msg
getLivsmedel =
    Http.get
        { url = "/LivsmedelsDB.json"
        , expect = Http.expectJson (Meal << GotFoodData) decoderListLivsmedel
        }


port localStorageSet : Json.Encode.Value -> Cmd msg
