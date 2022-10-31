module Page exposing (Details, Page(..))


type alias Details =
    { title : String
    , description : String
    , path : String
    }


type
    Page
    -- = Home Details
    -- | Baptism Details
    = NotFound Details
