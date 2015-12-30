# Elm Transit

Styled transitions with minimal boilerplate, typically for page transitions in single page apps:

> exit (float from 0 to 1) -> your action -> enter (float from 0 to 1)

Uses elm-animations and Effects.tick for animation logic.


## Usage

(Full working example [here](./example/src))

Extend `WithTransition` record type with your own model. 

```elm
import Transit

type Page = Page1 | Page2

type alias Model = Transit.WithTransition { page: Page }
```

(Note: you're not bound to root model, you can also use it for sub-pages or components transitions)

Then wrap `Action` in one of your action types and call `init` and
`update` in your update function.

Note that here we have a kind of recursive type definition, as `Transit.Action` with eventually trigger one `Action`.

```elm
type Action = NavigateTo Page | SetPage Page | TransitAction (Transit.Action Action)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    NavigateTo page ->
      let
        timeline = Transit.timeline 100 (SetPage page) 200
        -- 100m from 0 to 1, then action, then 200ms from 0 to 1
      in
        Transit.init TransitAction timeline model

    TransitAction a ->
      Transit.update TransitAction a model
        
    SetPage page ->
      ({ model | page = page }, Effects.none)
```

You can then use one of the provided functions in `Transit.Style` (or create one of your own)
to add the visual effect in your view:

```elm
  div [ class "content", style (Transit.fadeSlideLeft 50 model) ] [ text "Some content" ]
```
