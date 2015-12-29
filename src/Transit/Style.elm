module Transit.Style (slideLeftEnter, fadeOutExit) where

{-| Default animations for transitions, to be used on elm-html `style` attribute.

@docs slideLeftEnter, fadeOutExit
-}

import Transit exposing (Transition, Status(..), status, value)


{-| A simple left-sliding style value for elm-html.

    div [ class "content", style (Transit.slideLeftStyle model.transition) ] someContent

You can create your own with `value` extract function.
-}
slideLeftEnter : Float -> Transition -> List (String, String)
slideLeftEnter offset transition =
  case (status transition, value transition) of
    (Enter, v) ->
      [ ("opacity", toString v)
      , ("transform", "translateX(" ++ toString (offset - v * offset) ++ "px)")
      ]
    _ ->
      []

{-| Fade out exit -}
fadeOutExit : Transition -> List (String, String)
fadeOutExit transition =
  case (status transition, value transition) of
    (Exit, v) ->
      [ ("opacity", toString (1 - v)) ]
    _ ->
      []
