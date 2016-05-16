module Transit exposing
  ( Transition, WithTransition, initial
  , Timeline, timeline, defaultTimeline, withEnterDuration, withExitDuration
  , Msg, start, tick, subscriptions
  , Step(..), getStep, getValue
  )

{-| Styled transitions with minimal boilerplate, typically for page transitions in single page apps.

See README or [example](https://github.com/etaque/elm-transit/blob/master/example/src/Main.elm) for usage.

Uses elm-animations and Cmd.tick for animation logic.

# State
@docs Transition, WithTransition, initial

# Timeline
@docs Timeline, timeline, defaultTimeline, withExitDuration, withEnterDuration

# Update
@docs Msg, start, tick, subscriptions

# View
@docs getValue, getStep, Step
-}

import Time exposing (Time)
import Task exposing (Task)
import AnimationFrame


{-| Extended type for the parent model holding the transition. -}
type alias WithTransition model msg =
  { model | transition : Transition msg }


{-| Opaque type for transition state storage. -}
type Transition msg =
  T (State msg)


{-| Private. -}
getState : Transition msg -> State msg
getState transition =
  case transition of T s -> s


{-| Private: internal state of the transition, stored in parent model. -}
type alias State msg =
  { step : Step
  , start : Time
  , value : Float
  , timeline : Maybe (Timeline msg)
  }

{-| Transition step: Exit -> *send message* -> Enter -> Done. -}
type Step =
  Exit | Enter | Done


{-| Transition msg, to be wrapped in your own msg type. -}
type Msg
  = Start Time
  | ExitTick Time
  | EnterTick Time


{-| Empty transition state, as initial value in the model. -}
initial : Transition msg
initial =
  T initialState

{-| Private. -}
initialState : State msg
initialState =
  { step = Done, start = 0, value = 1, timeline = Nothing }


{-| Timeline of the transition -}
type alias Timeline msg =
  { exitDuration : Float
  , msg : msg
  , enterDuration : Float
  }


{-| Build the timeline:
> exitDuration => message => enterDuration
-}
timeline : Float -> msg -> Float -> Timeline msg
timeline =
  Timeline


{-| Default timeline for this transition: exit of 50ms then enter of 200ms. -}
defaultTimeline : msg -> Timeline msg
defaultTimeline msg =
  Timeline 50 msg 200


{-| Update exit duration of timeline. -}
withExitDuration : Float -> Timeline msg -> Timeline msg
withExitDuration d timeline =
  { timeline | exitDuration = d }


{-| Update enter duration of timeline. -}
withEnterDuration : Float -> Timeline msg -> Timeline msg
withEnterDuration d timeline =
  { timeline | enterDuration = d }


{-| Start the transition with the following parameters:

* `tagger` to wrap Transit's Msg into your app's Msg type (consistent with `tick` signature, saves you one `Cmd.map`)
* `timeline` to setup transition
* `parent` is the model storing the Transition, to update with new transition state

Returns a tuple that you can directly emit from your `update`.
 -}
start : (Msg -> msg) -> Timeline msg -> WithTransition parent msg -> (WithTransition parent msg, Cmd msg)
start tagger timeline parent =
  let
    newParent =
      { parent | transition = T { initialState | timeline = Just timeline} }

    cmd =
      Cmd.map tagger (performSucceed Start Time.now)
  in
    ( newParent, cmd )


{-| Where all the logic happens. Run transition steps, and triggers timeline's parent message when needed.

* `tagger` to wrap Transit's msg into app's Msg type, has to be same type of timeline.msg,
* `msg` is the Transit message to process,
* `parent` is the model storing the Transition, for transition state update.
 -}
tick : (Msg -> msg) -> Msg -> WithTransition parent msg -> (WithTransition parent msg, Cmd msg)
tick tagger msg parent =
  let
    -- extract state from shadow type
    state =
      getState parent.transition

    -- wrap result for parent's types
    tag (state, fx) =
      ({ parent | transition = T state }, Cmd.map tagger fx)
  in
    case msg of

      Start time ->
        tag ( { state | step = Exit, start = time }, Cmd.none )

      ExitTick time ->
        case state.timeline of
          Just tl ->
            if time < state.start + tl.exitDuration then
              -- update value
              tag ( { state | step = Exit, value = 1 - (time - state.start) / tl.exitDuration }, Cmd.none )
            else
              -- emit msg, move to entering
              tag ( { state | step = Enter, start = time, value = 0 }, Cmd.none )
                |> triggerTimelineMsg tl.msg

          Nothing ->
            -- should not happen
            (parent, Cmd.none)

      EnterTick time ->
        case state.timeline of
          Just tl ->
            if time < state.start + tl.enterDuration then
              -- update value
              tag ( { state | value = (time - state.start) / tl.enterDuration }, Cmd.none )
            else
              -- finished
              tag ( { state | step = Done, value = 1 }, Cmd.none )

          Nothing ->
            -- should not happen
            (parent, Cmd.none)


{-| Animation frame subscription. Must be called by your component's subscription function. -}
subscriptions : (Msg -> msg) -> WithTransition parent msg -> Sub msg
subscriptions tagger parent =
  case .step (getState parent.transition) of
    Exit ->
      AnimationFrame.times (ExitTick >> tagger)

    Enter ->
      AnimationFrame.times (EnterTick >> tagger)

    Done ->
      Sub.none


{-| Private: join parent msg within a batch. -}
triggerTimelineMsg : msg -> (WithTransition parent msg, Cmd msg) -> (WithTransition parent msg, Cmd msg)
triggerTimelineMsg parentMsg (state, cmd) =
  (state, Cmd.batch [ cmd, performSucceed identity (Task.succeed parentMsg) ])


{-| Extract current animation value (a float between 0 and 1). -}
getValue : (Transition msg) -> Float
getValue (T state) =
  state.value


{-| Extract current animation step. -}
getStep : (Transition msg) -> Step
getStep (T state) =
  state.step


{-| Private. -}
performSucceed : (a -> msg) -> Task Never a -> Cmd msg
performSucceed =
  Task.perform never


{-| Private. -}
never : Never -> a
never n =
  never n
