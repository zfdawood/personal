module Main exposing (main)

{-| zdawood.dev.

Elm owns the whole page and its routing (Browser.application). Cloudflare Pages serves
index.html for any path it has no file for, because the site has no top-level 404.html,
so a deep link still lands here and the router decides what to show.

For now the front page is a showcase of the personal brand (public/brand.css): the desk,
the palette, the type and the pieces, laid out like a specimen sheet.

-}

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, article, details, div, figcaption, figure, footer, h1, h2, li, node, p, section, span, summary, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, href, rel, style, type_)
import Svg exposing (polygon, rect, svg)
import Svg.Attributes as SA
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


swatches : List Swatch
swatches =
    [ Swatch "desk" "#B39C78" "#120E0B" "oak by day, ebony by night"
    , Swatch "sheet" "#F3E9D8" "#2B2420" "parchment, umber"
    , Swatch "ink" "#2B2420" "#F3E9D8" "text"
    , Swatch "muted" "#5C4A2E" "#C9B896" "labels, ledes"
    , Swatch "rule" "#C9B896" "#4A3F35" "hairlines"
    , Swatch "gel" "#5A3D94" "#BBA5E8" "numbers, dates, asks"
    , Swatch "pink" "#AD3A6C" "#E58BB0" "marks, links, focus"
    , Swatch "moss" "#59634F" "#93A087" "done"
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
        , div [ class "glyphrow" ] [ leaf, span [ class "from" ] [ text "a low-poly leaf on the 4px grid, shaded by the same light" ] ]
        ]


ledgerRow : String -> String -> String -> String -> Html Msg
ledgerRow entry measure status kind =
    tr [] [ td [] [ Html.b [] [ text entry ] ], td [] [ text measure ], td [] [ span [ class ("tag " ++ kind) ] [ text ("[ " ++ status ++ " ]") ] ] ]


{-| A low-poly leaf (the brand skill's glyphs/leaf.svg): eight flat faces either side of a
curved midrib, lit from the top left, some dithered between two ramp steps like the desk,
and a pixel staircase for a stem. One viewBox unit is one 4px brand unit.
-}
leaf : Html Msg
leaf =
    svg [ SA.class "glyph", SA.viewBox "0 0 32 20", SA.shapeRendering "crispEdges", attribute "role" "img", attribute "aria-label" "A low-poly leaf" ]
        [ Svg.defs []
            [ dither "leaf-d1" "#AEBAA5" "#93A087"
            , dither "leaf-d2" "#93A087" "#7C8B6F"
            , dither "leaf-d3" "#7C8B6F" "#5E6D52"
            , dither "leaf-d4" "#5E6D52" "#59634F"
            ]
        , Svg.g [] (List.map pixel stemPixels)
        , facet "2,10 8,5 8,10.5" "#AEBAA5"
        , facet "8,5 15,3 15,10 8,10.5" "url(#leaf-d1)"
        , facet "15,3 22,6 22,9.5 15,10" "#93A087"
        , facet "22,6 26,10 22,9.5" "url(#leaf-d2)"
        , facet "2,10 8,10.5 8,14" "#7C8B6F"
        , facet "8,10.5 15,10 15,16 8,14" "url(#leaf-d3)"
        , facet "15,10 22,9.5 22,14 15,16" "#5E6D52"
        , facet "22,9.5 26,10 22,14" "url(#leaf-d4)"
        ]


facet : String -> String -> Html Msg
facet points fill =
    polygon [ SA.points points, SA.fill fill ] []


{-| A 2×2 checker of two colors: the halfway shade between two ramp steps.
-}
dither : String -> String -> String -> Html Msg
dither id base other =
    Svg.pattern [ SA.id id, SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]
        [ rect [ SA.width "2", SA.height "2", SA.fill base ] []
        , rect [ SA.width "1", SA.height "1", SA.fill other ] []
        , rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill other ] []
        ]


{-| The stem, stepping down to the right: a lit pixel above a shaded one. (x, y, width, color)
-}
stemPixels : List ( ( Int, Int ), Int, String )
stemPixels =
    [ ( ( 25, 9 ), 2, "#7C8B6F" ), ( ( 25, 10 ), 2, "#59634F" )
    , ( ( 27, 10 ), 2, "#7C8B6F" ), ( ( 27, 11 ), 2, "#59634F" )
    , ( ( 29, 11 ), 1, "#7C8B6F" ), ( ( 29, 12 ), 1, "#59634F" )
    , ( ( 30, 12 ), 1, "#5E6D52" ), ( ( 30, 13 ), 1, "#59634F" )
    , ( ( 31, 13 ), 1, "#5E6D52" ), ( ( 31, 14 ), 1, "#59634F" )
    ]


pixel : ( ( Int, Int ), Int, String ) -> Html Msg
pixel ( ( x, y ), w, color ) =
    rect [ SA.x (String.fromInt x), SA.y (String.fromInt y), SA.width (String.fromInt w), SA.height "1", SA.fill color ] []



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
