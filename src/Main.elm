module Main exposing (main)

{-| zdawood.dev.

Elm owns the whole page and its routing (Browser.application). Cloudflare Pages serves
index.html for any path it has no file for, because the site has no top-level 404.html,
so a deep link still lands here and the router decides what to show.

For now the front page is a showcase of the personal brand (public/brand.css): the desk,
the palette, the type and the pieces, laid out like a specimen sheet.

-}

import Brand exposing (Mode(..))
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, article, details, div, figcaption, figure, footer, h1, h2, li, node, p, section, span, summary, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, href, rel, style, type_)
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)



-- ROUTES


type Route
    = Home
    | Cv
    | NotFound


routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Cv (Parser.s "cv")
        ]


toRoute : Url -> Route
toRoute url =
    Parser.parse routeParser url |> Maybe.withDefault NotFound



-- MODEL


type alias Model =
    { key : Nav.Key
    , route : Route
    }


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key, route = toRoute url }, Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            ( { model | route = toRoute url }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.route of
        Home ->
            { title = "Z. Dawood", body = page [ "index", "specimen sheet" ] homeSheet }

        Cv ->
            { title = "CV · Z. Dawood", body = page [ "cv" ] cvSheet }

        NotFound ->
            { title = "Not found · Z. Dawood", body = page [ "404" ] notFoundSheet }


{-| A sheet on the desk: the bevel's eight faces, the file header strip (with the day/night
switch at its end), then the page. The footer sits on the desk under it. The switch only
carries data-theme-toggle: public/theme.js flips the mode and brand.css draws the label, so
nothing outside Elm edits Elm's DOM.
-}
page : List String -> List (Html Msg) -> List (Html Msg)
page path sheet =
    [ div [ class "paper" ]
        [ article [ class "sheet" ]
            (bevel :: readout path :: sheet)
        ]
    , footer [] [ span [] [ text "zdawood.dev · built in Elm · lit from the top left" ] ]
    ]


bevel : Html Msg
bevel =
    span [ class "bevel", attribute "aria-hidden" "true" ] (List.repeat 8 (node "i" [] []))


readout : List String -> Html Msg
readout path =
    div [ class "readout" ]
        (List.intersperse (span [] [ text "/" ]) (List.map (\part -> span [] [ text part ]) ("zdawood.dev" :: path))
            ++ [ Html.button [ class "chip", type_ "button", attribute "data-theme-toggle" "", attribute "aria-label" "Switch between day and night" ] [] ]
        )


homeSheet : List (Html Msg)
homeSheet =
    [ p [ class "kicker" ] [ text "zdawood.dev" ]
    , h1 [] [ text "z. dawood" ]
    , ul [ class "links" ]
        [ li [] [ a [ class "chip", href "/cv" ] [ text "cv" ] ]
        , li [] [ outbound "https://github.com/zfdawood" "github" ]
        , li [] [ outbound "https://www.linkedin.com/in/z-dawood/" "linkedin" ]
        ]
    , deskSection
    , paletteSection
    , typeSection
    , piecesSection
    , rulesSection
    ]


outbound : String -> String -> Html Msg
outbound url label =
    a [ class "chip", href url, rel "me noopener" ] [ text label ]



-- THE DESK


deskSection : Html Msg
deskSection =
    section []
        [ h2 [] [ text "the desk" ]
        , figure [ class "desk" ]
            [ div [ class "deskview", attribute "role" "img", attribute "aria-label" "Low-poly wooden planks with vines growing across them, in a dithered pixel style." ] []
            , figcaption []
                [ text "Everything sits on this. Low-poly planks and vines drawn by code at 320×200, each material dithered to its own four-color ramp, and shown at exactly 4× so one pixel is one spacing unit. Same seed, same picture. Night mode gets ebony boards." ]
            ]
        ]



-- PALETTE


type alias Swatch =
    { name : String, day : String, night : String, for : String }


{-| Day and night come from Brand.elm, generated from cozy-archive's tokens.toml. -}
swatches : List Swatch
swatches =
    let
        day =
            Brand.palette Day

        night =
            Brand.palette Night

        swatch name pick for =
            Swatch name (pick day) (pick night) for
    in
    [ swatch "desk" .desk "oak by day, ebony by night"
    , swatch "sheet" .sheet "parchment, umber"
    , swatch "ink" .ink "text"
    , swatch "muted" .muted "labels, ledes"
    , swatch "rule" .rule "hairlines"
    , swatch "gel" .gel "numbers, dates, asks"
    , swatch "pink" .pink "marks, links, focus"
    , swatch "good" .good "done"
    ]


paletteSection : Html Msg
paletteSection =
    section []
        [ h2 [] [ text "palette" ]
        , p [] [ text "Warm neutrals from a desktop theme, two inks from a printed handout. Each chip is day on the left, night on the right." ]
        , ul [ class "swatches" ] (List.map swatchView swatches)
        ]


swatchView : Swatch -> Html Msg
swatchView s =
    li [ class "swatch" ]
        [ span [ class "chipcolor" ]
            [ span [ style "background" s.day ] []
            , span [ style "background" s.night ] []
            ]
        , span [ class "sname" ] [ text s.name ]
        , span [ class "shex" ] [ text (s.day ++ " / " ++ s.night) ]
        , span [ class "sfor" ] [ text s.for ]
        ]



-- TYPE


typeSection : Html Msg
typeSection =
    section []
        [ h2 [] [ text "type" ]
        , div [ class "faces" ]
            [ face "mono" "JetBrains Mono" "headings, labels" "record 0042 / filed"
            , face "text" "Newsreader" "running text" "Paper, ink, pencil and one highlighter."
            , face "hand" "Kalam" "dates and numbers, pencilled in" "Mon 11/16 · 1. 2. 3."
            , face "head" "Archivo" "names in a ledger" "Ledger entry"
            ]
        ]


face : String -> String -> String -> String -> Html Msg
face role family for sample =
    div [ class ("face " ++ role) ]
        [ span [ class "fmeta" ] [ text (family ++ " · " ++ for) ]
        , span [ class "fsample" ] [ text sample ]
        ]



-- PIECES


piecesSection : Html Msg
piecesSection =
    section []
        [ h2 [] [ text "pieces" ]
        , div [ class "tablewrap" ]
            [ table []
                [ thead [] [ tr [] [ th [] [ text "Entry" ], th [] [ text "Measure" ], th [] [ text "Status" ] ] ]
                , tbody []
                    [ ledgerRow "Cut corners" "45°" "kept" "good"
                    , ledgerRow "Hard shadow" "1 unit, no blur" "kept" "good"
                    , ledgerRow "Flat-shaded bevel" "8 faces, Lambert" "kept" "good"
                    , ledgerRow "Dithered shadow" "2 units, 4×4 Bayer" "parked" "parked"
                    ]
                ]
            ]
        , details [ class "fold" ]
            [ summary [] [ span [ class "mark" ] [], span [ class "ftopic" ] [ text "a fold-out" ] ]
            , p [] [ text "Detail lives under the line until someone asks for it. The page reads as a short list first." ]
            ]
        , p [ class "sample-hl" ] [ text "One thing per page gets ", span [ class "hl" ] [ text "the highlighter" ], text ", and a quote is set ", span [ class "said" ] [ text "in the purple ink" ], text "." ]
        , div [ class "glyphrow" ] [ Brand.leaf, span [ class "from" ] [ text "a low-poly leaf on the 4px grid, shaded by the same light" ] ]
        ]


ledgerRow : String -> String -> String -> String -> Html Msg
ledgerRow entry measure status kind =
    tr [] [ td [] [ Html.b [] [ text entry ] ], td [] [ text measure ], td [] [ span [ class ("tag " ++ kind) ] [ text ("[ " ++ status ++ " ]") ] ] ]


-- RULES


rulesSection : Html Msg
rulesSection =
    section []
        [ h2 [] [ text "rules" ]
        , ul [ class "rules" ]
            [ li [] [ text "Light comes from the top left, so every shadow falls down-right." ]
            , li [] [ text "One spacing unit, 4px. Every gap is a whole number of them." ]
            , li [] [ text "Corners are cut at 45°, never rounded. Shadows are hard, never blurred." ]
            , li [] [ text "Mono for structure, serif for reading, pencil for dates." ]
            , li [] [ text "Day and night, always." ]
            ]
        ]



-- CV


{-| A placeholder until the real CV is written (he's writing that copy himself).
-}
cvSheet : List (Html Msg)
cvSheet =
    [ p [ class "kicker" ] [ text "cv" ]
    , h1 [] [ text "z. dawood" ]
    , p [ class "lede" ]
        [ text "Being filed. Until then, "
        , a [ href "https://www.linkedin.com/in/z-dawood/" ] [ text "LinkedIn" ]
        , text " has it."
        ]
    , ul [ class "links" ] [ li [] [ a [ class "chip", href "/" ] [ text "front page" ] ] ]
    ]



-- NOT FOUND


notFoundSheet : List (Html Msg)
notFoundSheet =
    [ p [ class "kicker" ] [ text "404 / record not found" ]
    , h1 [] [ text "nothing filed here" ]
    , p [ class "lede" ] [ a [ href "/" ] [ text "back to the front page" ] ]
    ]



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
