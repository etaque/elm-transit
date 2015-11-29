# Elm Transit

Delayed model updates, typically for page transitions in single page apps.

## Usage

Extend `WithTransition` record type with your own model.

```elm
import Transit

type Page = Page1 | Page2
type alias Model = Transit.WithTransition { page: Page }
```

Wrap `Action` in one of your action types and call `init` and
`update` in your update function.

```elm
type Action = NextPage | TransitAction Transit.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    NextPage ->
      let
        effect = Effects.map TransitAction (Transit.init nextPage 150)
      in
        (model, effect)

    TransitAction ta ->
      let
        (newModel, transitEffect) = Transit.update ta model
        effect = Effects.map TransitAction transitEffect
      in
        (newModel, effect)

nextPage : Model -> Model
nextPage model =
  case model.page of
    Page1 -> Page2
    Page2 -> Page1
```

You can use the `status` method to get a class name for you views and apply
transition visual effects:

```elm
  div [ class (Transit.status model) ] [ text "Some content" ]
```
