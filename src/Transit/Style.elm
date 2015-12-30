module Transit.Style
  ( fadeSlideLeft
  , slideLeft, slideOutLeft, slideInLeft
  , fade, fadeOut, fadeIn
  , transition, Style
  ) where

{-| Default animations for transitions, to be used on elm-html `style` attribute.

    div
      [ style (fadeSlideLeft 100 model) ]
      [ text "content" ]

# Compositions
@docs fadeSlideLeft

# Slide left
@docs slideLeft, slideOutLeft, slideInLeft

# Fade
@docs fade, fadeOut, fadeIn

# Tooling to create animations
@docs transition, Style
-}

import Transit exposing (..)


{-| Alias for elm-html style value -}
type alias Style = List (String, String)


{-| Combine fade and slideLeft with the specified offset -}
fadeSlideLeft : Float -> WithTransition m -> Style
fadeSlideLeft offset m =
  (slideLeft offset m) ++ (fade m)


{-| Slide left transition, with the specified offset -}
slideLeft : Float -> WithTransition m -> Style
slideLeft offset m =
  transition (slideOutLeft offset) (slideInLeft offset) m


{-| Slide out to left (exit) -}
slideOutLeft : Float -> Float -> Style
slideOutLeft offset v =
  [ ("transform", "translateX(" ++ toString (-v * offset) ++ "px)")
  ]


{-| Slide in to left (enter) -}
slideInLeft : Float -> Float -> Style
slideInLeft offset v =
  [ ("transform", "translateX(" ++ toString (offset - v * offset) ++ "px)")
  ]


{-| Fade transition (out -> in) -}
fade : WithTransition m -> Style
fade m =
  transition fadeOut fadeIn m


{-| Fade out (exit) -}
fadeOut : Float -> Style
fadeOut v =
  [ ("opacity", toString (1 - v)) ]


{-| Fade in (enter) -}
fadeIn : Float -> Style
fadeIn v =
  [ ("opacity", toString v) ]


{-| Create an exit -> enter transition -}
transition : (Float -> Style) -> (Float -> Style) -> WithTransition m -> Style
transition exit enter model =
  case (getStatus model.transition, getValue model.transition) of
    (Exit, v) ->
      exit v
    (Enter, v) ->
      enter v
    _ ->
      []
