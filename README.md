# Elm Transit

Animated transitions between pages or components for your Elm apps. The purpose of this package is to make it trivial to add transition to you app, so it's a bit opiniated.

Uses elm-animations and Effects.tick for animation logic.

## Usage

Extend `WithTransition` record type with your own model. 

```elm
import Transit

-- let's say your model is holding a Route to store current page
type Route = ...
type alias Model = Transit.WithTransition { route: Maybe Route }
```

(Note: you're not bound to root model, you can also use it for sub-pages or components transitions)

Then wrap `Action` in one of your action types and call `init` and
`update` in your update function.

```elm
type Action = UpdateRoute Route | TransitAction Transit.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    UpdateRoute route ->
      let
        newModel = { model | route = Just route }
      in
        Transit.init 100 newModel TransitAction 

    TransitAction a ->
      Transit.update a model TransitAction
```

You can then use the provided `slideLeftStyle` function to add the visual effect in your view:

```elm
  div [ class "content", style (Transit.slideLeftStyle model.transition) ] [ text "Some content" ]
```
