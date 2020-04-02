module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, button, div, embed, h1, h3, img, li, object, text, ul)
import Html.Attributes exposing (height, href, src, type_, width)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)
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


type alias Cell =
    { kind : String
    , content : String
    }


type alias Question =
    List Cell


type alias Answer =
    List Cell


type alias Quiz =
    { id : Int
    , question : Question
    , answer : Answer
    }


type alias Model =
    { key : Nav.Key
    , currentPage : Page
    , pageData : Maybe Quiz
    , counter : Int
    , errorMessage : Maybe String
    }


type Page
    = NotFound
    | Top
    | Second
    | Minq


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    url
        |> stepUrl (Model key Top Nothing 0 Nothing)


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SendHttpRequest
    | DataReceived (Result Http.Error Quiz)
    | Increment
    | Decrement


getQuiz : Cmd Msg
getQuiz =
    Http.get
        { url = "http://127.0.0.1:3000/example/what-is-minq"
        , expect = Http.expectJson DataReceived quizDecoder
        }


cellDecoder : Decoder Cell
cellDecoder =
    Decode.succeed Cell
        |> required "kind" string
        |> required "content" string


quizDecoder : Decoder Quiz
quizDecoder =
    Decode.succeed Quiz
        |> required "id" int
        |> required "question" (list cellDecoder)
        |> required "answer" (list cellDecoder)


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

        SendHttpRequest ->
            ( preModel, getQuiz )

        DataReceived result ->
            case result of
                Ok quiz ->
                    ( { preModel | pageData = Just quiz }, Cmd.none )

                Err httpError ->
                    ( { preModel | errorMessage = Just (buildErrorMessage httpError) }, Cmd.none )

        Increment ->
            let
                max =
                    case preModel.pageData of
                        Just quiz ->
                            quiz.answer
                                |> List.length

                        Nothing ->
                            0
            in
            ( { preModel | counter = preModel.counter |> countUp |> until max }, Cmd.none )

        Decrement ->
            ( { preModel | counter = preModel.counter |> countDown }, Cmd.none )


countUp : Int -> Int
countUp count =
    count + 1


until : Int -> Int -> Int
until max count =
    if max < count then
        max

    else
        count


countDown : Int -> Int
countDown count =
    case count of
        0 ->
            0

        _ ->
            count - 1


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message


view : Model -> Browser.Document Msg
view model =
    case model.currentPage of
        NotFound ->
            viewNotFound model

        Top ->
            viewTop model

        Second ->
            viewSecond model

        Minq ->
            viewMinq model


viewTop : Model -> Browser.Document Msg
viewTop model =
    { title = "This is a Top page"
    , body =
        [ h1 [] [ text "Welcome" ]
        , viewIndex
        ]
    }


viewSecond : Model -> Browser.Document Msg
viewSecond model =
    { title = "This is a Second page"
    , body = [ h1 [] [ text "Second Page" ] ]
    }


viewMinq : Model -> Browser.Document Msg
viewMinq model =
    { title = "MinQ Test Page"
    , body =
        [ h1 []
            [ text "Welcom Minq" ]
        , case model.errorMessage of
            Just message ->
                viewError message

            Nothing ->
                viewQuiz model
        ]
    }


viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch data at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]


viewQuiz : Model -> Html Msg
viewQuiz model =
    case model.pageData of
        Just quiz ->
            div []
                [ div []
                    [ quiz.id
                        |> String.fromInt
                        |> (++) "id: "
                        |> text
                    ]
                , renderCells quiz.question
                , quiz.answer
                    |> List.take model.counter
                    |> renderCells
                , if model.counter == List.length quiz.answer then
                    button [ onClick Decrement ] [ text "Back" ]

                  else if model.counter == 0 then
                    button [ onClick Increment ] [ text "Next" ]

                  else
                    div []
                        [ button [ onClick Increment ] [ text "Next" ]
                        , button [ onClick Decrement ] [ text "Back" ]
                        ]
                ]

        Nothing ->
            div []
                [ div [] [ text "No Quiz" ]
                , button [ onClick SendHttpRequest ] [ text "Get Quiz!!" ]
                ]


renderCells : List Cell -> Html msg
renderCells cells =
    cells
        |> viewListing
        |> ul []


viewListing : List Cell -> List (Html msg)
viewListing cells =
    cells
        |> List.map toLi


toLi : Cell -> Html msg
toLi cell =
    case cell.kind of
        "text" ->
            li [] [ text cell.content ]

        "svg" ->
            viewSVG cell.content

        _ ->
            li [] [ text "Empty Cell" ]


viewNotFound : Model -> Browser.Document Msg
viewNotFound model =
    { title = "Not Found"
    , body = [ h1 [] [ text "404 Page Not Found" ] ]
    }


viewSVG : String -> Html msg
viewSVG url =
    embed
        [ type_ "image/svg+xml"
        , src url
        , width 500
        , height 500
        ]
        []


viewIndex : Html msg
viewIndex =
    ul []
        [ viewLink "/"
        , viewLink "/second"
        , viewLink "/minq"
        ]


viewLink : String -> Html msg
viewLink path =
    li []
        [ a [ href path ] [ text path ]
        ]


stepUrl : Model -> Url.Url -> ( Model, Cmd Msg )
stepUrl model url =
    url
        |> toPage
        |> toUpdate model


toUpdate : Model -> Page -> ( Model, Cmd Msg )
toUpdate model newPage =
    -- TODO: get session data to share data between pages
    ( { model | currentPage = newPage }
    , case newPage of
        NotFound ->
            Cmd.none

        Top ->
            Cmd.none

        Second ->
            Cmd.none

        Minq ->
            Cmd.none
    )


toPage : Url.Url -> Page
toPage url =
    url
        |> Router.parse routes
        |> Maybe.withDefault NotFound


routes : Parser (Page -> a) a
routes =
    Router.oneOf
        [ route top Top
        , route (s "second") Second
        , route (s "minq") Minq
        ]


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
    Router.map handler parser
