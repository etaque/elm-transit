module Transit (init, update, Action) where

import Effects exposing (Effects)
import Task exposing (Task, andThen, sleep, succeed)
import Time exposing (Time)


type alias WithTransition m =
  { m | transitStatus : Status }

type alias ModelUpdate m =
  WithTransition m -> WithTransition m

type Status
  = Exiting
  | Entering
  | Entered

type Action m
  = Exit (ModelUpdate m) Time
  | Enter (ModelUpdate m) Time
  | End


init : ModelUpdate m -> Time -> Effects (Action m)
init modelUpdate delay =
   succeed (Exit modelUpdate delay)
     |> Effects.task


update : Action m -> WithTransition m -> (WithTransition m, Effects (Action m))
update action model =
  case action of

    Exit modelUpdate delay ->
      let
        newModel = { model | transitStatus = Exiting }
        enteringEffect = Effects.task (scheduleEntering modelUpdate delay)
      in
        (newModel, enteringEffect)

    Enter modelUpdate delay ->
      let
        newModel = { model | transitStatus = Entering }
        enteredEffect = Effects.task (scheduleEntered delay)
      in
        (newModel, enteredEffect)

    End ->
      ({ model | transitStatus = Entered }, Effects.none)


scheduleEntering : ModelUpdate m -> Time -> Task.Task x (Action m)
scheduleEntering modelUpdate delay =
  delayed delay (succeed (Enter modelUpdate delay))


scheduleEntered : Time -> Task x (Action m)
scheduleEntered delay =
  delayed delay (succeed End)


delayed : Time -> (Task error value) -> Task error value
delayed delay task =
  sleep delay `andThen` \_ -> task


status : WithTransition m -> String
status model =
  case model.transitStatus of
    Entering ->
      "entering"
    Entered ->
      "entered"
    Exiting ->
      "exiting"
