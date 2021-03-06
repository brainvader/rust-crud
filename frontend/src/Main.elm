port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Flip exposing (flip)
import Html exposing (Html, a, button, div, embed, h1, h2, h3, li, text, ul)
import Html.Attributes exposing (class, classList, height, href, id, src, type_, width)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, bool, int, list, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Url exposing (Url)
import Url.Parser as Router exposing (Parser, s, top)


port log : Encode.Value -> Cmd msg


port ref : Encode.Value -> Cmd msg


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


type alias Counter =
    { count : Int
    , min : Int
    , max : Int
    }


type alias Cell =
    { kind : String
    , hidden : Bool
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


type QuizReady
    = Ready
    | Yet


type Command
    = Show
    | Animation
    | NoOps


type alias Model =
    { key : Nav.Key
    , currentPage : Page
    , quizReady : QuizReady
    , counter : Counter
    , quiz : Quiz
    , redo : List Command
    , undo : List Command
    , errorMessage : Maybe String
    }


type Page
    = NotFound
    | Top
    | Second
    | Minq


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        counter =
            { count = 0
            , min = 0
            , max = 0
            }

        quiz =
            { id = 0
            , question = []
            , answer = []
            }

        initialModel =
            { key = key
            , currentPage = Top
            , quizReady = Yet
            , counter = counter
            , quiz = quiz
            , redo = []
            , undo = []
            , errorMessage = Nothing
            }
    in
    url
        |> stepUrl initialModel


type Order
    = Forward
    | Backward


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SendHttpRequest
    | DataReceived (Result Http.Error Quiz)
    | Execute Order Command


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
        |> optional "hidden" bool True
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
                    let
                        max =
                            quiz.answer
                                |> List.length

                        counter =
                            { count = 0
                            , min = 0
                            , max = max
                            }

                        redo =
                            quiz.answer
                                |> List.map
                                    (\cell ->
                                        case cell.kind of
                                            "text" ->
                                                Show

                                            "svg" ->
                                                Show

                                            "animation" ->
                                                Animation

                                            _ ->
                                                Show
                                    )
                    in
                    ( { preModel | quizReady = Ready, quiz = quiz, redo = redo, counter = counter }
                    , Cmd.batch
                        [ Encode.string "#forth-btn" |> ref
                        , Encode.string "#back-btn" |> ref
                        ]
                    )

                Err httpError ->
                    ( { preModel | errorMessage = Just (buildErrorMessage httpError) }, Cmd.none )

        Execute order command ->
            let
                ( counter, redo, undo ) =
                    case order of
                        Forward ->
                            ( preModel.counter
                                |> countUp
                            , preModel.redo
                                |> List.drop 1
                                |> Debug.log "redo"
                            , preModel.undo
                                |> List.append [ command ]
                                |> Debug.log "undo"
                            )

                        Backward ->
                            ( preModel.counter
                                |> countDown
                            , preModel.redo
                                |> List.append [ command ]
                                |> Debug.log "redo"
                            , preModel.undo
                                |> List.drop 1
                                |> Debug.log "undo"
                            )

                answer =
                    preModel.quiz.answer
                        |> List.indexedMap Tuple.pair
                        |> List.map
                            (\( i, cell ) ->
                                if i < counter.count then
                                    { cell | hidden = False }

                                else
                                    { cell | hidden = True }
                            )

                newQuiz =
                    { id = preModel.quiz.id
                    , question = preModel.quiz.question
                    , answer = answer
                    }
            in
            ( { preModel | counter = counter, redo = redo, undo = undo, quiz = newQuiz }
            , Encode.string "AnswerShowed"
                |> log
            )


countUp : Counter -> Counter
countUp counter =
    if counter.max < counter.count then
        { counter | count = counter.max }

    else
        { counter | count = counter.count + 1 }


countDown : Counter -> Counter
countDown counter =
    if counter.count < counter.min then
        { counter | count = counter.min }

    else
        { counter | count = counter.count - 1 }


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
    case model.quizReady of
        Yet ->
            div []
                [ div [] [ text "No Quiz" ]
                , button [ onClick SendHttpRequest ] [ text "Get Quiz!!" ]
                ]

        Ready ->
            div []
                [ model.counter
                    |> viewCounter
                , model.quiz.id
                    |> toTitle
                    |> viewTitle
                , model.quiz.question
                    |> List.map
                        (\cell ->
                            li [] [ viewCell cell ]
                        )
                    |> ul [ class "list-question", class "no-bullet" ]
                , h2 [] [ text "答え" ]
                , model.quiz.answer
                    |> List.map
                        (\cell ->
                            li
                                [ classList [ ( "hidden", cell.hidden ) ] ]
                                [ viewCell cell ]
                        )
                    |> ul [ class "list-answer", class "no-bullet" ]
                , model
                    |> viewAnswerButton
                ]


viewCounter : Counter -> Html Msg
viewCounter counter =
    div []
        [ counter.count
            |> String.fromInt
            |> String.append "Counter: "
            |> text
        ]


toLabel : Order -> Command -> String
toLabel order command =
    case command of
        Show ->
            case order of
                Forward ->
                    "Show"

                Backward ->
                    "Back"

        Animation ->
            case order of
                Forward ->
                    "Play"

                Backward ->
                    "Reverse"

        NoOps ->
            "Oops!"


viewAnswerButton : Model -> Html Msg
viewAnswerButton model =
    model
        |> viewBackAndForthButton
        |> div []


viewBackAndForthButton : Model -> List (Html Msg)
viewBackAndForthButton model =
    let
        nextCommand =
            case model.redo of
                x :: _ ->
                    x

                _ ->
                    NoOps

        prevCommand =
            case model.undo of
                x :: _ ->
                    x

                _ ->
                    NoOps
    in
    [ button
        [ id "forth-btn"
        , classList
            [ ( "hidden", model.counter.count == model.counter.max ) ]
        , onClick <|
            Execute Forward nextCommand
        ]
        [ nextCommand |> toLabel Forward |> text ]
    , button
        [ id "back-btn"
        , classList
            [ ( "hidden", model.counter.count == 0 ) ]
        , onClick <|
            Execute Backward prevCommand
        ]
        [ prevCommand |> toLabel Backward |> text ]
    ]


toTitle : Int -> String
toTitle id =
    id
        |> String.fromInt
        |> String.append "Q"
        |> flip String.append ". "
        |> flip String.append "ここはタイトルです"


viewTitle : String -> Html msg
viewTitle title =
    h1 [] [ text title ]


viewCell : Cell -> Html msg
viewCell cell =
    case cell.kind of
        "text" ->
            text cell.content

        "svg" ->
            viewSVG cell.content

        "animation" ->
            text ""

        _ ->
            text "Empty Cell"


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
