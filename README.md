# Elm Transit

Delayed model updates, typically for page transitions in single page apps.

## Usage

Extend `WithTransition` record type with your own model. 

```elm
import Transit

type Route = ...
type alias Model = Transit.WithTransition { route: Maybe Route }
```

Note: you can also use it for sub-pages or components transitions.

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
