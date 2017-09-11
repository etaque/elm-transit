# Elm Transit

    elm package install etaque/elm-transit

Delayed actions with transition progress for enter/exit animations in [Elm](http://elm-lang.org/).

See also:

* [elm-transit-style](http://package.elm-lang.org/packages/etaque/elm-transit-style/latest): animations for elm-html `style` attribute


## Usage

(Full working example [here](https://github.com/etaque/elm-transit/tree/master/example/src))

Use `WithTransition` record extension to extend your own model:

```elm
import Transit

-- see recursive type param: Transit needs to know the type of message it will send delayed
type Msg
  = NavigateTo Page
  | SetPage Page
  | TransitMsg (Transit.Msg Msg)

type Page = Page1 | Page2

type alias Model =
  Transit.WithTransition { page: Page }
```

You're not bound to root model, you can also use it for sub-pages or components transitions.

Then wrap `Msg` in one of your action types and call `start` and
`tick` in your update function.

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update action model =
  case action of

    NavigateTo page ->
      -- exit phase of 100ms, then `(SetPage page)` will be sent, then enter phase of 200ms
      Transit.start TransitMsg (SetPage page) ( 100, 200 ) model

    TransitMsg a ->
      Transit.tick TransitMsg a model
        
    SetPage page ->
      ({ model | page = page }, Cmd.none)
```

A subscription is necessary to receive animation frame ticks when transition is running:

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
  Transit.subscriptions TransitMsg model
```

In your views, you can then either:

* Use `getValue` to get the 1 -> 0 -> 1 varying Float, and `getStep` to know the current phase of transition.

* Or use one of the provided functions in [elm-transit-style](http://package.elm-lang.org/packages/etaque/elm-transit-router/latest) (or create one of your own)
to add the visual effect in your view:

```elm
  div [ style (TransitStyle.fadeSlideLeft 50 model.transition) ] [ text "Some content" ]
```

## Credits

* Thanks [Alex Galays](https://twitter.com/boubiyeah) for the challenge
