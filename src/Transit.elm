module Transit (init, update, statusName, Status(..), Action, WithTransition) where

{-| Delayed model update for transition effects in Elm.

# Types
@docs Action, Status, WithTransition

# Updates
@docs init, update

# Helpers
@docs statusName
-}

import Effects exposing (Effects)
import Task exposing (Task, andThen, sleep, succeed)
import Time exposing (Time)


{-| An extensible record type containing the transition status -}
type alias WithTransition m =
  { m | transitStatus : Status }

type alias ModelUpdate m =
  WithTransition m -> WithTransition m

{-| A type for the transition status
* Exiting: model update scheduled
* Entering: model update applied
* Entered: transition finished
-}
type Status
  = Exiting
  | Entering
  | Entered

{-| A type for transition steps -}
type Action m
  = Exit (ModelUpdate m) Time
  | Enter (ModelUpdate m) Time
  | End


{-| Initialize the transition. The returned effect is carrying the exit action,
holding the desired model update to be done and the transition delay (before and
after the model update)
-}
init : ModelUpdate m -> Time -> Effects (Action m)
init modelUpdate delay =
   succeed (Exit modelUpdate delay)
     |> Effects.task

{-| Update the transition status, and apply the desired model update when it's time to.
Returns the updated model and the effect carrying the next transition action.
-}
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
        newModel = modelUpdate { model | transitStatus = Entering }
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


{-| Helper for the views: class name with CSS transition -}
statusName : WithTransition m -> String
statusName model =
  case model.transitStatus of
    Exiting ->
      "exiting"
    Entering ->
      "entering"
    Entered ->
      "entered"
