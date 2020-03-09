module Main exposing (main)

import Browser.Navigation as Nav
import Html exposing (Html, div, text)


main : Html msg
main =
    view


type alias Model =
    { key : Nav.Key
    , curentPage : Page
    }


type Page
    = NotFound
    | Top
    | About


view : Html msg
view =
    div [] [ text "rust crud" ]
