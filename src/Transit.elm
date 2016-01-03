module Transit
  ( Transition, WithTransition, initial
  , Timeline, timeline, defaultTimeline, withEnterDuration, withExitDuration
  , Action, init, update
  , Status(..), getStatus, getValue
  ) where

{-| Styled transitions with minimal boilerplate, typically for page transitions in single page apps.

See README or [example](https://github.com/etaque/elm-transit/blob/master/example/src/Main.elm) for usage.

Uses elm-animations and Effects.tick for animation logic.

# Model
@docs Transition, WithTransition, initial

# Timeline
@docs Timeline, timeline, defaultTimeline, withExitDuration, withEnterDuration

# Update
@docs Action, init, update

# View
@docs getValue, getStatus, Status
-}

import Time exposing (Time)
import Task exposing (Task)
import Effects exposing (Effects)
import Animation exposing (Animation)


{-| Extended type for the target model holding the transition. -}
type alias WithTransition model = { model | transition : Transition }

{-| Opaque type for transition state storage. -}
type Transition = T State

{-| Private: internal state of the transition, stored in target model. -}
type alias State =
  { value : Float
  , status : Status
  , startTime : Time
  }

{-| Transition status. -}
type Status = Exit | Enter | Done

{-| Private: animation state, stored in ticks. -}
type alias AnimationState =
  { startTime : Time
  , animation : Animation
  }


{-| Transition action, to be wrapped in your own action type. -}
type Action a
  = Init (Timeline a)
  | Start (Timeline a) Time
  | ExitTick (Timeline a) AnimationState Time
  | EnterTick AnimationState Time


{-| Empty transition state, as initial value in the model. -}
initial : Transition
initial =
  T initialState


{-| Private -}
initialState : State
initialState =
  State 0 Done 0


{-| Timeline of the transition -}
type alias Timeline a =
  { exitDuration : Float
  , action : a
  , enterDuration : Float
  }

{-| Build the timeline:
> exitDuration => action => enterDuration
-}
timeline : Float -> a -> Float -> Timeline a
timeline =
  Timeline

{-| Default timeline for this action: exit of 100ms then enter of 200ms. -}
defaultTimeline : a -> Timeline a
defaultTimeline action =
  Timeline 100 action 200


{-| Update exit duration of timeline. -}
withExitDuration : Float -> Timeline a -> Timeline a
withExitDuration d timeline =
  { timeline | exitDuration = d }


{-| Update enter duration of timeline. -}
withEnterDuration : Float -> Timeline a -> Timeline a
withEnterDuration d timeline =
  { timeline | enterDuration = d }


{-| A shortcut to `update` that initialize the transition with the following parameters:
* `actionWrapper` to wrap Transit's action into your app's Action type (saves you one `Effects.map`)
* `timeline` to setup transition
* `target` is the model storing the Transition, that will be updated with new transition state
Returns a tuple that you can directly return from your `update`.
 -}
init : ((Action a) -> a) -> Timeline a -> WithTransition target -> (WithTransition target, Effects a)
init actionWrapper timeline =
  update actionWrapper (Init timeline)


{-| Where all the logic happens. Run transition steps, and triggers timeline's action when needed.
* `actionWrapper` to wrap Transit's action into app's Action type (saves one `Effects.map`),
* `action` is the Transit action to process,
* `target` is the model storing the Transition, that will be updated with new transition state.
 -}
update : ((Action a) -> a) -> Action a -> WithTransition target -> (WithTransition target, Effects a)
update actionWrapper action target =
  let
    -- extract state from shadow type
    state = case target.transition of T s -> s

    -- stop everything if an other (newer) transition has been stored in target
    watchRetarget animState (newState, fx) =
      if state.startTime == animState.startTime then
        (newState, fx)
      else
        (state, Effects.none)

    -- wrap result for target's types
    wrapForTarget (state, fx) =
      ({ target | transition = T state }, Effects.map actionWrapper fx)

  in
    case action of

      Init timeline ->
        -- start transition with a tick (time is required for animation start)
        (State 0 Exit 0, Effects.tick (Start timeline))
          |> wrapForTarget

      Start timeline time ->
        -- emit initial ExitTick carrying animation state
        let
          newAnim = Animation.animation time
            |> Animation.duration timeline.exitDuration
            |> Animation.ease identity
          -- store transition start time to be able to deal with retargeting
          newState = { state | startTime = time }
        in
          exitStep 0 timeline (AnimationState time newAnim) newState
            |> wrapForTarget

      ExitTick timeline animState time ->
        if Animation.isRunning time animState.animation then
          -- emit next ExitTick while animation is running
          exitStep (Animation.animate time animState.animation) timeline animState state
            |> watchRetarget animState
            |> wrapForTarget
        else
          -- otherwise trigger action and emit initial EnterTick with new animation state
          let
            newAnim = Animation.animation time
              |> Animation.duration timeline.enterDuration
              |> Animation.ease identity
          in
            enterStep 0 { animState | animation = newAnim } state
              |> watchRetarget animState
              |> wrapForTarget
              |> triggerTimelineAction timeline.action

      EnterTick animState time ->
        if Animation.isRunning time animState.animation then
          -- emit next EnterTick while animation is running
          enterStep (Animation.animate time animState.animation) animState state
            |> watchRetarget animState
            |> wrapForTarget
        else
          -- otherwise stop here
          (initialState, Effects.none)
            |> wrapForTarget


{-| Private: add target action within a batch. -}
triggerTimelineAction : a -> (WithTransition target, Effects a) -> (WithTransition target, Effects a)
triggerTimelineAction targetAction (state, fx) =
  (state, Effects.batch [ fx, Effects.task <| Task.succeed targetAction ])


{-| Private: update state and emit tick for Exit step. -}
exitStep : Float -> Timeline target -> AnimationState -> State -> (State, Effects (Action target))
exitStep value timeline animState state =
  ({ state | value = value, status = Exit }, Effects.tick (ExitTick timeline animState))


{-| Private: update state and emit tick for Enter step. -}
enterStep : Float -> AnimationState -> State -> (State, Effects (Action target))
enterStep value animState state =
  ({ state | value = value, status = Enter }, Effects.tick (EnterTick animState))


{-| Extract current animation value (a float between 0 and 1). -}
getValue : Transition -> Float
getValue (T state) =
  state.value


{-| Extract current animation status. -}
getStatus : Transition -> Status
getStatus (T state) =
  state.status

