module Main exposing (..)

import Html.App as Html
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Transit


type alias Model =
  Transit.WithTransition { page : Page }


type Page =
  Page1 | Page2


type Msg
  = Click Page
  | SetPage Page
  | TransitMsg (Transit.Msg Msg)


init : ( Model, Cmd Msg )
init =
  ({ page = Page1, transition = Transit.empty }, Cmd.none)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Click page ->
      Transit.start TransitMsg (SetPage page) ( 500, 500 ) model

    SetPage page ->
      ({ model | page = page }, Cmd.none)

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
        [ ]
        [ p
            [ style [ ("opacity", toString (Transit.getValue model.transition)) ] ]
            [ text (toString model.page) ]
        , p [] [ text (toString (Transit.getStep model.transition)) ]
        , p [] [ text (toString (Transit.getValue model.transition)) ]
        ]
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Transit.subscriptions TransitMsg model


main : Program Never
main =
  Html.program
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
