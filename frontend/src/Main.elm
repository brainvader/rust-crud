module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, div, text)


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


view : Html msg
view =
    div [] [ text "rust crud" ]
