module Transit (Transition, WithTransition, Action, initAction, step, init, update, value, empty, slideLeftStyle) where

{-| Animated transitions between pages or components for your Elm apps.
The purpose of this package is to make it trivial to add transition to you app, so it's a bit opiniated.

Uses elm-animations and Effects.tick for animation logic.

# Model
@docs Transition, WithTransition, empty, Action

# Update
@docs init, update, initAction, step

# View
@docs slideLeftStyle, value
-}

import Time exposing (Time)
import Effects exposing (Effects)
import Animation exposing (..)


{-| Transition action, to be wrapped in your own action type
 -}
type Action = Init Time | Start Time Time | Tick Animation Time

{-| An opaque type for internal value storage
 -}
type Transition = T (Maybe Float)

{-| Helper for adding transition on your model
 -}
type alias WithTransition model = { model | transition : Transition }

{-| Empty transition state, as initial value in the model.
 -}
empty : Transition
empty =
  T Nothing


start : Transition
start =
  T (Just 0)

set : Float -> Transition
set =
  T << Just

{-| Helper that generates a new transition with the following params:

 * Animation duration (ms)
 * Model holding the transition
 * Action wrapper for the incoming effect (saves one `Effects.map`)

Returns:

 * Updated model with new transition state
 * Effects for next steps
 -}
init : Time -> WithTransition model -> (Action -> action) -> (WithTransition model, Effects action)
init dur model actionWrapper =
  update (initAction dur) model actionWrapper

{-| Helper for walking transition steps, same spec as `init but processing actions. Use `step` internally.
 -}
update : Action -> WithTransition model -> (Action -> action) -> (WithTransition model, Effects action)
update action model actionWrapper =
  let
    (t, fx) = step action
  in
    ({ model | transition = t }, Effects.map actionWrapper fx)

{-| Init action, if you need to produce it manually. See `init` otherwise.
 -}
initAction : Time -> Action
initAction =
  Init

{-| Walks transition's next step. See `update` helper.
 -}
step : Action -> (Transition, Effects Action)
step action =
  case action of

    Init dur ->
      (start, Effects.tick (Start dur))

    Start dur time ->
      let
        anim = animation time |> duration dur
        fx = Effects.tick (Tick anim)
      in
        (set (animate time anim), fx)

    Tick anim time ->
      if isDone time anim then
        (empty, Effects.none)
      else
        (set (animate time anim), Effects.tick (Tick anim))


{-| A simple left-sliding style value for elm-html.

    div [ class "content", style (Transit.slideLeftStyle model.transition) ] someContent

You can create your own with `value` extract function.
-}
slideLeftStyle : Transition -> List (String, String)
slideLeftStyle (T value) =
  case value of
    Just v ->
      [ ("opacity", toString v)
      , ("transform", "translateX(" ++ toString (40 - v * 40) ++ "px)")
      ]
    Nothing ->
      []

{-| Extract current animation value (a float between 0 and 1).
 -}
value : Transition -> Maybe Float
value (T v) =
  v
