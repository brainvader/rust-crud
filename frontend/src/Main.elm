port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Flip exposing (flip)
import Html exposing (Html, a, button, div, embed, h1, h2, h3, li, text, ul)
import Html.Attributes exposing (class, classList, height, href, id, src, type_, width)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)
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
    , counter : Counter
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
            Counter 0 0 0
    in
    url
        |> stepUrl (Model key Top Nothing counter Nothing)


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
                    let
                        max =
                            quiz.answer
                                |> List.length

                        counter =
                            Counter 0 0 max
                    in
                    ( { preModel | pageData = Just quiz, counter = counter }
                    , Cmd.batch
                        [ Encode.string "#forth-btn" |> ref
                        , Encode.string "#back-btn" |> ref
                        ]
                    )

                Err httpError ->
                    ( { preModel | errorMessage = Just (buildErrorMessage httpError) }, Cmd.none )

        Increment ->
            ( { preModel | counter = preModel.counter |> countUp }
            , Encode.string "Increment" |> log
            )

        Decrement ->
            ( { preModel | counter = preModel.counter |> countDown }
            , Encode.string "Decrement" |> log
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
    case model.pageData of
        Just quiz ->
            div []
                [ model.counter
                    |> viewCounter
                , quiz.id
                    |> toTitle
                    |> viewTitle
                , viewCells quiz.question
                , h2 [] [ text "答え" ]
                , quiz.answer
                    |> List.indexedMap Tuple.pair
                    |> List.map
                        (\( i, cell ) ->
                            li
                                [ classList [ ( "hidden", model.counter.count < i + 1 ) ] ]
                                [ viewCell cell ]
                        )
                    |> ul [ class "list-answer", class "no-bullet" ]
                , model
                    |> viewShowAnswer
                ]

        Nothing ->
            div []
                [ div [] [ text "No Quiz" ]
                , button [ onClick SendHttpRequest ] [ text "Get Quiz!!" ]
                ]


viewCounter : Counter -> Html Msg
viewCounter counter =
    div []
        [ counter.count
            |> String.fromInt
            |> String.append "Counter: "
            |> text
        ]


viewShowAnswer : Model -> Html Msg
viewShowAnswer model =
    model
        |> viewBackAndForthButton
        |> div []


viewBackAndForthButton : Model -> List (Html Msg)
viewBackAndForthButton model =
    if model.counter.count == 0 then
        [ button [ id "forth-btn", onClick Increment ] [ text "Show Answer" ]
        , button [ id "back-btn", class "hidden", onClick Decrement ] [ text "Back" ]
        ]

    else if model.counter.count == model.counter.max then
        [ button [ id "forth-btn", class "hidden", onClick Increment ] [ text "Next" ]
        , button [ id "back-btn", onClick Decrement ] [ text "Back" ]
        ]

    else
        [ button [ id "forth-btn", onClick Increment ] [ text "Next" ]
        , button [ id "back-btn", onClick Decrement ] [ text "Back" ]
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

        _ ->
            text "Empty Cell"


viewCells : List Cell -> Html msg
viewCells cells =
    cells
        |> List.map toLi
        |> ul [ class "no-bullet" ]


toLi : Cell -> Html msg
toLi cell =
    case cell.kind of
        "text" ->
            li [] [ text cell.content ]

        "svg" ->
            li [] [ viewSVG cell.content ]

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
