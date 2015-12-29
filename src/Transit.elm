module Transit
  ( Transition, WithTransition, initial, Action, Setup
  , init, update, value, status, Status(..)
  ) where

{-| Animated transitions between pages or components for your Elm apps.
The purpose of this package is to make it trivial to add transition to you app, so it's a bit opiniated.

Uses elm-animations and Effects.tick for animation logic.

# Model
@docs Transition, WithTransition, initial, Action, Setup

# Update
@docs init, update

# View
@docs value, status, Status
-}

import Time exposing (Time)
import Effects exposing (Effects)
import Animation exposing (Animation)


{-| Helper for adding transition on your model
 -}
type alias WithTransition model = { model | transition : Transition }

{-| An opaque type for internal value storage
 -}
type Transition = T State

{-| Internal (private) state of the transition -}
type alias State =
  { value : Float
  , status : Status
  }

{-| Transition status -}
type Status = Exit | Enter | Done


{-| Transition action, to be wrapped in your own action type
 -}
type Action a
  = Init (Setup a)
  | Start (Setup a) Time
  | ExitTick (Setup a) Animation Time
  | EnterTick Animation Time

{-| Setup of the transition to run -}
type alias Setup a =
  { exitDuration : Float
  , enterDuration : Float
  , targetEffects : Effects a
  }


{-| Empty transition state, as initial value in the model.
 -}
initial : Transition
initial =
  T initialState

initialState : State
initialState =
  State 0 Done


{-| Initial action to start transition -}
initAction : Setup a -> Action a
initAction =
  Init


{-| Initialize the transition
 -}
init : ((Action a) -> a) -> Setup a -> WithTransition target -> (WithTransition target, Effects a)
init actionWrapper setup =
  update actionWrapper (initAction setup)


{-| Where all the logic happens. Run transition next step,
and triggers target effects (transition host) when needed.
 -}
update : ((Action a) -> a) -> Action a -> WithTransition target -> (WithTransition target, Effects a)
update actionWrapper action target =
  let
    result (state, fx) =
      ({ target | transition = T state }, Effects.map actionWrapper fx)
  in
    case action of

      Init setup ->
        (State 0 Exit, Effects.tick (Start setup))
          |> result

      Start setup time ->
        Animation.animation time
          |> Animation.duration setup.exitDuration
          |> exitStep 0 setup
          |> result

      ExitTick setup exitAnim time ->
        if Animation.isRunning time exitAnim then
          exitStep (Animation.animate time exitAnim) setup exitAnim
            |> result
        else
          Animation.animation time
            |> Animation.duration setup.enterDuration
            |> enterStep 0
            |> result
            |> triggerTargetEffects setup.targetEffects

      EnterTick enterAnim time ->
        if Animation.isRunning time enterAnim then
          enterStep (Animation.animate time enterAnim) enterAnim
            |> result
        else
          (initialState, Effects.none)
            |> result


triggerTargetEffects : Effects a -> (WithTransition target, Effects a) -> (WithTransition target, Effects a)
triggerTargetEffects targetFx (state, fx) =
  (state, Effects.batch [ fx, targetFx ])


exitStep : Float -> Setup target -> Animation -> (State, Effects (Action target))
exitStep value setup anim =
  (State value Exit, Effects.tick (ExitTick setup anim))

enterStep : Float -> Animation -> (State, Effects (Action target))
enterStep value anim =
  (State value Enter, Effects.tick (EnterTick anim))


{-| Extract current animation value (a float between 0 and 1). -}
value : Transition -> Float
value (T state) =
  state.value

{-| Extract current animation status. -}
status : Transition -> Status
status (T state) =
  state.status

