module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, div, text)
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , curentPage : Page
    }


type Page
    = NotFound
    | Top
    | Second


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model key Top
    , Cmd.none
    )


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg preModel =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( preModel, Nav.pushUrl preModel.key (Url.toString url) )

                Browser.External href ->
                    ( preModel, Nav.load href )

        UrlChanged url ->
            ( preModel, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "This is a Top Page"
    , body =
        [ div
            []
            [ text "rust crud" ]
        ]
    }
