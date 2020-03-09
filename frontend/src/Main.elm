module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, div, h1, text)
import Url exposing (Url)
import Url.Parser as Router exposing (Parser, s, top)


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
    , currentPage : Page
    }


type Page
    = NotFound
    | Top
    | Second


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    url
        |> stepUrl
            { key = key
            , currentPage = Top
            }


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
            url
                |> stepUrl preModel


view : Model -> Browser.Document Msg
view model =
    case model.currentPage of
        NotFound ->
            viewNotFound model

        Top ->
            viewTop model

        Second ->
            viewSecond model


viewTop : Model -> Browser.Document Msg
viewTop model =
    { title = "This is a Top page"
    , body = [ h1 [] [ text "Welcome" ] ]
    }


viewSecond : Model -> Browser.Document Msg
viewSecond model =
    { title = "This is a Second page"
    , body = [ h1 [] [ text "Second Page" ] ]
    }


viewNotFound : Model -> Browser.Document Msg
viewNotFound model =
    { title = "Not Found"
    , body = [ h1 [] [ text "404 Page Not Found" ] ]
    }


stepUrl : Model -> Url.Url -> ( Model, Cmd Msg )
stepUrl model url =
    ( { model | currentPage = url |> toPage }
    , case model.currentPage of
        NotFound ->
            Cmd.none

        Top ->
            Cmd.none

        Second ->
            Cmd.none
    )


toPage : Url.Url -> Page
toPage url =
    url
        |> Router.parse urlParser
        |> Maybe.withDefault NotFound


urlParser : Parser (Page -> a) a
urlParser =
    Router.oneOf
        [ route top Top
        , route (s "about") Second
        ]


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
    Router.map handler parser
