module Tests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Markdown.Block as Markdown
import Markdown.Html
import Markdown.Parser as Markdown
import Markdown.Renderer as Markdown
import Markdown.Scaffolded as Scaffolded
import Test exposing (..)



{-
   Unfortunately, there are basically no tests, yet. You're welcome to contribute tests!
   I personally test this project using the /examples and another semi-production app.

   If you want to contribute: There are good opportunities for creating property-based
   tests for this application. For that it would be neccessary to write a fuzzer:
   `Fuzzer children -> Fuzzer (Scaffolded.Block children)` and then identify the
   mathematical properties of functions like `map`, `foldFunction`, etc. and test them.
-}


suite : Test
suite =
    describe "Formatting Markdown"
        [ test "round-trip" <|
            \_ ->
                Result.map2
                    (\original prettyprinted ->
                        Expect.equalLists original prettyprinted
                    )
                    (exampleMarkdown
                        |> parseMarkdown
                        |> Result.mapError ((++) "Error in normal Markdown: ")
                    )
                    (exampleMarkdown
                        |> prettyprint
                        |> Result.andThen parseMarkdown
                        |> Result.mapError ((++) "Error in pretty-printed Markdown: ")
                    )
                    |> expectOk
        ]


expectOk : Result String Expectation -> Expectation
expectOk result =
    case result of
        Ok e ->
            e

        Err error ->
            Expect.fail error


parseMarkdown : String -> Result String (List Markdown.Block)
parseMarkdown markdown =
    markdown
        |> Markdown.parse
        |> Result.mapError (List.map Markdown.deadEndToString >> String.join "\n")


prettyprint : String -> Result String String
prettyprint markdown =
    markdown
        |> parseMarkdown
        |> Result.andThen
            (Markdown.render
                (Scaffolded.toRenderer
                    { renderHtml = Markdown.Html.oneOf []
                    , renderMarkdown = Scaffolded.reducePretty
                    }
                )
            )
        |> Result.map (String.join "\n\n")


exampleMarkdown : String
exampleMarkdown =
    """# Format _beautiful_ Markdown

> Markdown is only fine
> When *pretty printed*
> It has to be **BEAUTIFUL** I SAID.
## Links
Let's try [a `link`](https://example.com)

What about images? ![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "Logo Title Text 1")



## Lists

Markdown formatting is:
* [ ] Stupid
* [X] Okay-ish
* [ ] Works

- Let's not do checkboxes.

1. Don't use this project
1. What are you doing?
1. Ok. Please go now.

---------

0. Write library
1. Publish
2. ???
3. Profit!

## Code blocks

```elm
viewMarkdown : String -> List (Html Msg)
viewMarkdown markdown =
    [ Html.h2 [] [ Html.text "Prettyprinted:" ]
    , Html.hr [] []
    , Html.pre [ Attr.style "word-wrap" "pre-wrap" ] [ Html.text markdown ]
    ]
```

```
Please use more beautiful
Code blocks!
```
"""
