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
import Html exposing (Html, a, article, details, div, figcaption, figure, footer, h1, h2, img, li, node, p, section, span, summary, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (alt, attribute, class, href, rel, src, style)
import Svg exposing (polygon, rect, svg)
import Svg.Attributes as SA
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)



-- ROUTES


type Route
    = Home
    | NotFound


routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Home Parser.top
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
            { title = "Z. Dawood", body = page homeSheet }

        NotFound ->
            { title = "Not found · Z. Dawood", body = page notFoundSheet }


{-| A sheet on the desk, with the footer under it.
-}
page : List (Html Msg) -> List (Html Msg)
page sheet =
    [ div [ class "paper" ] [ article [ class "sheet" ] sheet ]
    , footer [] [ text "zdawood.dev · built in Elm · lit from the top left" ]
    ]


homeSheet : List (Html Msg)
homeSheet =
    [ p [ class "kicker" ] [ text "zdawood.dev" ]
    , h1 [] [ text "z. dawood" ]
    , ul [ class "links" ]
        [ li [] [ outbound "https://github.com/zfdawood" "github" ]
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
    a [ class "chiplink", href url, rel "me noopener" ] [ text label ]



-- THE DESK


deskSection : Html Msg
deskSection =
    section []
        [ h2 [] [ text "the desk" ]
        , figure [ class "desk" ]
            [ node "picture"
                []
                [ node "source" [ attribute "srcset" "/desk-dark.png", attribute "media" "(prefers-color-scheme: dark)" ] []
                , img [ src "/desk-light.png", alt "Low-poly wooden planks with vines growing across them, in a dithered pixel style." ] []
                ]
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
                    , ledgerRow "Dithered shadow" "2 units, 4×4 Bayer" "proposed" "ask"
                    , ledgerRow "Scanlines" "6%, opt-in" "parked" "parked"
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
    tr [] [ td [] [ Html.b [] [ text entry ] ], td [] [ text measure ], td [ class ("status " ++ kind) ] [ text status ] ]


{-| Four flat faces lit from the top left: the face pointing up-left is brightest.
-}
leaf : Html Msg
leaf =
    svg [ SA.class "glyph", SA.viewBox "0 0 24 16", SA.shapeRendering "crispEdges", attribute "role" "img", attribute "aria-label" "A low-poly leaf" ]
        [ polygon [ SA.points "2,8 12,2 12,8", SA.fill "#AEBAA5" ] []
        , polygon [ SA.points "12,2 22,8 12,8", SA.fill "#93A087" ] []
        , polygon [ SA.points "2,8 12,8 12,14", SA.fill "#7C8B6F" ] []
        , polygon [ SA.points "12,8 22,8 12,14", SA.fill "#59634F" ] []
        , rect [ SA.x "21", SA.y "7", SA.width "3", SA.height "2", SA.fill "#5C4A2E" ] []
        ]



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
