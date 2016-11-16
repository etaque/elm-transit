module Transit
    exposing
        ( Transition
        , WithTransition
        , empty
        , Msg
        , start
        , tick
        , subscriptions
        , Step(..)
        , getStep
        , getValue
        )

{-| Styled transitions with minimal boilerplate, typically for page transitions in single page apps.

See README or [example](https://github.com/etaque/elm-transit/blob/master/example/src/Main.elm) for usage.

Uses elm-animations and Cmd.tick for animation logic.

# State
@docs Transition, WithTransition, empty

# Update
@docs Msg, start, tick, subscriptions

# View
@docs getValue, getStep, Step
-}

import Time exposing (Time)
import Task exposing (Task)
import Process
import AnimationFrame


{-| Extended type for the parent model holding the transition.
-}
type alias WithTransition model =
    { model | transition : Transition }


{-| Opaque type for transition state storage.
-}
type Transition
    = T State


{-| Private.
-}
getState : Transition -> State
getState transition =
    case transition of
        T s ->
            s


{-| Private: internal state of the transition, stored in parent model.
-}
type alias State =
    { step : Step
    , start : Time
    , value : Float
    , durations : ( Time, Time )
    }


{-| Transition step: Exit -> *send message* -> Enter -> Done.
-}
type Step
    = Exit
    | Enter
    | Done


{-| Transition msg, to be wrapped in your own msg type.
-}
type Msg msg
    = Start msg Time
    | Tick Time
    | EmitMsg msg Time


{-| Empty transition state, as initial value in the model.
-}
empty : Transition
empty =
    T initialState


{-| Private.
-}
initialState : State
initialState =
    { step = Done, start = 0, value = 1, durations = ( 0, 0 ) }


{-| Timeline of the transition
-}
type alias Durations =
    ( Float, Float )


{-| Start the transition with the following parameters:

* `tagger` to wrap Transit's Msg into your app's Msg type (consistent with `tick` signature, saves you one `Cmd.map`)
* `parentMsg` to send at end of exit
* `durations` of transition steps (exit phase then enter phase)
* `parent` is the model storing the Transition, to update with new transition state

Returns a tuple that you can directly emit from your `update`.
-}
start : (Msg msg -> msg) -> msg -> ( Time, Time ) -> WithTransition parent -> ( WithTransition parent, Cmd msg )
start tagger parentMsg durations parent =
    let
        state =
            getState parent.transition

        newState =
            { state | durations = durations }

        cmd =
            Cmd.map tagger (Task.perform (Start parentMsg) Time.now)
    in
        ( { parent | transition = T newState }, cmd )


{-| Where all the logic happens. Run transition steps, and triggers timeline's parent message when needed.

* `tagger` to wrap Transit's msg into app's Msg type, has to be same type of timeline.msg,
* `msg` is the Transit message to process,
* `parent` is the model storing the Transition, for transition state update.
-}
tick : (Msg msg -> msg) -> Msg msg -> WithTransition parent -> ( WithTransition parent, Cmd msg )
tick tagger msg parent =
    let
        -- extract state from shadow type
        state =
            getState parent.transition

        -- wrap result for parent's types
        tag ( state, fx ) =
            ( { parent | transition = T state }, Cmd.map tagger fx )
    in
        case msg of
            Start parentMsg time ->
                let
                    emitTask =
                        Task.succeed (EmitMsg parentMsg time)

                    emitCmd =
                        delay (Tuple.first state.durations) emitTask
                            |> Task.perform identity
                in
                    tag ( { state | step = Exit, start = time }, emitCmd )

            EmitMsg parentMsg time ->
                if time == state.start then
                    ( parent, Task.perform identity (Task.succeed parentMsg) )
                else
                    ( parent, Cmd.none )

            Tick time ->
                case state.step of
                    Exit ->
                        if time < state.start + (Tuple.first state.durations) then
                            -- update value
                            tag ( { state | step = Exit, value = 1 - (time - state.start) / (Tuple.first state.durations) }, Cmd.none )
                        else
                            -- move to entering
                            tag ( { state | step = Enter, value = 0 }, Cmd.none )

                    Enter ->
                        if time < state.start + (Tuple.first state.durations) + (Tuple.second state.durations) then
                            -- update value
                            tag ( { state | value = (time - state.start - (Tuple.first state.durations)) / (Tuple.second state.durations) }, Cmd.none )
                        else
                            -- finished
                            tag ( { state | step = Done, value = 1 }, Cmd.none )

                    Done ->
                        ( parent, Cmd.none )


{-| Animation frame subscription. Must be called by your component's subscription function.
-}
subscriptions : (Msg msg -> msg) -> WithTransition parent -> Sub msg
subscriptions tagger parent =
    case getStep parent.transition of
        Done ->
            Sub.none

        _ ->
            AnimationFrame.times (Tick >> tagger)


{-| Extract current animation value (a float between 0 and 1).
-}
getValue : Transition -> Float
getValue (T state) =
    state.value


{-| Extract current animation step.
-}
getStep : Transition -> Step
getStep (T state) =
    state.step


{-| Private.
-}
delay : Time -> Task x a -> Task x a
delay time task =
    Process.sleep time |> Task.andThen (\_ -> task)
