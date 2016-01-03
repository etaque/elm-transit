# Elm Transit

    elm package install etaque/elm-transit

Delayed actions with transition progress for enter/exit animations in [Elm](http://elm-lang.org/).

See also:

* [elm-transit-router](http://package.elm-lang.org/packages/etaque/elm-transit-router/latest): a drop-in router with animated route transitions
* [elm-transit-style](http://package.elm-lang.org/packages/etaque/elm-transit-router/latest): animations for elm-html `style` attribute


## Usage

(Full working example [here](./example/src))

Use `WithTransition` record extension to extend your own model:

```elm
import Transit

type Page = Page1 | Page2

type alias Model = Transit.WithTransition { page: Page }
```

You're not bound to root model, you can also use it for sub-pages or components transitions.

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
        -- 100ms from 0 to 1, then action, then 200ms from 0 to 1
      in
        Transit.init TransitAction timeline model

    TransitAction a ->
      Transit.update TransitAction a model
        
    SetPage page ->
      ({ model | page = page }, Effects.none)
```

In your views, you can then either:

* Use `getValue` to get the 0 to 1 varying Float, and `getStatus` to know the current phase of transition.

* Or use one of the provided functions in [elm-transit-style](http://package.elm-lang.org/packages/etaque/elm-transit-router/latest) (or create one of your own)
to add the visual effect in your view:

```elm
  div [ style (TransitStyle.fadeSlideLeft 50 model.transition) ] [ text "Some content" ]
```

## Credits

* Thanks [Alex Galays](https://twitter.com/boubiyeah) for the challenge
* Built with [elm-animations](http://package.elm-lang.org/packages/mgold/elm-animation/latest), check it out!
