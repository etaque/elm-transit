module Transit.Style
  ( fadeSlideLeft,slideLeft, slideLeftExit, slideLeftEnter
  , fade, fadeExit, fadeEnter
  ) where

{-| Default animations for transitions, to be used on elm-html `style` attribute.

# Slide left
@docs fadeSlideLeft, slideLeft, slideLeftExit, slideLeftEnter

# Fade
@docs fade, fadeExit, fadeEnter
-}

import Transit exposing (..)

type alias Style = List (String, String)


transition : (Float -> Style) -> (Float -> Style) -> WithTransition m -> Style
transition exit enter model =
  case (getStatus model.transition, getValue model.transition) of
    (Exit, v) ->
      exit v
    (Enter, v) ->
      enter v
    _ ->
      []

{-| TODO -}
fadeSlideLeft : Float -> WithTransition m -> Style
fadeSlideLeft offset m =
  (slideLeft offset m) ++ (fade m)

{-| TODO -}
slideLeft : Float -> WithTransition m -> Style
slideLeft offset m =
  transition (slideLeftExit offset) (slideLeftEnter offset) m

{-| TODO -}
slideLeftExit : Float -> Float -> Style
slideLeftExit offset v =
  [ ("transform", "translateX(" ++ toString (-v * offset) ++ "px)")
  ]

{-| TODO -}
slideLeftEnter : Float -> Float -> Style
slideLeftEnter offset v =
  [ ("transform", "translateX(" ++ toString (offset - v * offset) ++ "px)")
  ]


{-| TODO -}
fade : WithTransition m -> Style
fade m =
  transition fadeExit fadeEnter m

{-| Fade out exit -}
fadeExit : Float -> Style
fadeExit v =
  [ ("opacity", toString (1 - v)) ]


{-| Fade in enter -}
fadeEnter : Float -> Style
fadeEnter v =
  [ ("opacity", toString v) ]
