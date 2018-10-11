module Main exposing (Model, Msg(..), Page(..), init, main, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Transit exposing (Step(..))


type alias Model =
    Transit.WithTransition { page : Page }


type Page
    = Page1
    | Page2


type Msg
    = Click Page
    | SetPage Page
    | TransitMsg (Transit.Msg Msg)


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { page = Page1, transition = Transit.empty }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Click page ->
            Transit.start TransitMsg (SetPage page) ( 500, 500 ) model

        SetPage page ->
            ( { model | page = page }, Cmd.none )

        TransitMsg transitMsg ->
            Transit.tick TransitMsg transitMsg model


view : Model -> Html Msg
view model =
    div []
        [ nav []
            [ a [ onClick (Click Page1) ] [ text "To page 1" ]
            , a [ onClick (Click Page2) ] [ text "To page 2" ]
            ]
        , div
            []
            [ p
                [ style "opacity" (String.fromFloat (Transit.getValue model.transition)) ]
                [ text (pageToString model.page) ]
            , p [] [ text (stepToString (Transit.getStep model.transition)) ]
            , p [] [ text (String.fromFloat (Transit.getValue model.transition)) ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Transit.subscriptions TransitMsg model


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- helper


stepToString : Step -> String
stepToString step =
    case step of
        Exit ->
            "Exit"

        Enter ->
            "Enter"

        Done ->
            "Done"


pageToString : Page -> String
pageToString page =
    case page of
        Page1 ->
            "Page1"

        Page2 ->
            "Page2"
