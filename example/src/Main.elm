module Main where

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import Task
import Signal exposing (Address)
import Effects exposing (Effects, Never)
import StartApp
import Transit
import Transit.Style as TransitStyle


type alias Model = Transit.WithTransition { page : Page }

type Page = Page1 | Page2

type Action
  = Click Page
  | SetPage Page
  | TransitAction (Transit.Action Action)


init : (Model, Effects Action)
init =
  ({ page = Page1, transition = Transit.initial }, Effects.none)


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    Click page ->
      let
        timeline = Transit.timeline 100 (SetPage page) 200
      in
        Transit.init TransitAction timeline model

    SetPage page ->
      ({ model | page = page }, Effects.none)

    TransitAction transitAction ->
      Transit.update TransitAction transitAction model


view : Address Action -> Model -> Html
view addr model =
  div []
    [ nav []
      [ a [ onClick addr (Click Page1) ] [ text "To page 1" ]
      , a [ onClick addr (Click Page2) ] [ text "To page 2" ]
      ]
    , div
        [ style (TransitStyle.fadeSlideLeft 100 model) ]
        [ text (toString model.page) ]
    ]


app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }


main = app.html


port tasks : Signal (Task.Task Never ())
port tasks = app.tasks
