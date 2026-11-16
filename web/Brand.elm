module Brand exposing (Mode(..), Palette, leaf, palette)

{-| GENERATED from tokens.toml by tools/gen.py. Edit tokens.toml (or templates/web/), then run `make`.

The web palette for both modes, and the low-poly leaf, so an Elm site never hardcodes a color.

-}

import Html.Attributes
import Svg exposing (Svg)
import Svg.Attributes as SA


type Mode
    = Day
    | Night


type alias Palette =
    { desk : String
    , shadow : String
    , sheet : String
    , recess : String
    , lit : String
    , rule : String
    , ruleShade : String
    , ink : String
    , muted : String
    , faint : String
    , gel : String
    , pink : String
    , good : String
    }


palette : Mode -> Palette
palette mode =
    case mode of
        Day ->
            { desk = "#B39C78"
            , shadow = "#7A6646"
            , sheet = "#F3E9D8"
            , recess = "#E3D5B8"
            , lit = "#FBF6EC"
            , rule = "#C9B896"
            , ruleShade = "#B9A684"
            , ink = "#2B2420"
            , muted = "#5C4A2E"
            , faint = "#776649"
            , gel = "#5A3D94"
            , pink = "#AD3A6C"
            , good = "#59634F"
            }

        Night ->
            { desk = "#120E0B"
            , shadow = "#000000"
            , sheet = "#2B2420"
            , recess = "#1C1713"
            , lit = "#3A3129"
            , rule = "#4A3F35"
            , ruleShade = "#1C1713"
            , ink = "#F3E9D8"
            , muted = "#C9B896"
            , faint = "#A18A64"
            , gel = "#BBA5E8"
            , pink = "#E58BB0"
            , good = "#93A087"
            }


{-| The low-poly leaf: one viewBox unit is one brand unit. Style it with `svg.glyph`.
-}
leaf : Svg msg
leaf =
    Svg.svg
        [ SA.class "glyph"
        , SA.viewBox "0 0 32 20"
        , SA.shapeRendering "crispEdges"
        , Html.Attributes.attribute "role" "img"
        , Html.Attributes.attribute "aria-label" "A low-poly leaf"
        ]
        [ Svg.defs []
            [ Svg.pattern [ SA.id "leaf-aebaa5-93a087", SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]
                [ Svg.rect [ SA.width "2", SA.height "2", SA.fill "#AEBAA5" ] []
                , Svg.rect [ SA.width "1", SA.height "1", SA.fill "#93A087" ] []
                , Svg.rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill "#93A087" ] []
                ]
            , Svg.pattern [ SA.id "leaf-93a087-7c8b6f", SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]
                [ Svg.rect [ SA.width "2", SA.height "2", SA.fill "#93A087" ] []
                , Svg.rect [ SA.width "1", SA.height "1", SA.fill "#7C8B6F" ] []
                , Svg.rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill "#7C8B6F" ] []
                ]
            , Svg.pattern [ SA.id "leaf-7c8b6f-5e6d52", SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]
                [ Svg.rect [ SA.width "2", SA.height "2", SA.fill "#7C8B6F" ] []
                , Svg.rect [ SA.width "1", SA.height "1", SA.fill "#5E6D52" ] []
                , Svg.rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill "#5E6D52" ] []
                ]
            , Svg.pattern [ SA.id "leaf-5e6d52-59634f", SA.width "2", SA.height "2", SA.patternUnits "userSpaceOnUse" ]
                [ Svg.rect [ SA.width "2", SA.height "2", SA.fill "#5E6D52" ] []
                , Svg.rect [ SA.width "1", SA.height "1", SA.fill "#59634F" ] []
                , Svg.rect [ SA.x "1", SA.y "1", SA.width "1", SA.height "1", SA.fill "#59634F" ] []
                ]
            ]
        , Svg.rect [ SA.x "25", SA.y "9", SA.width "2", SA.height "1", SA.fill "#7C8B6F" ] []
        , Svg.rect [ SA.x "25", SA.y "10", SA.width "2", SA.height "1", SA.fill "#59634F" ] []
        , Svg.rect [ SA.x "27", SA.y "10", SA.width "2", SA.height "1", SA.fill "#7C8B6F" ] []
        , Svg.rect [ SA.x "27", SA.y "11", SA.width "2", SA.height "1", SA.fill "#59634F" ] []
        , Svg.rect [ SA.x "29", SA.y "11", SA.width "1", SA.height "1", SA.fill "#7C8B6F" ] []
        , Svg.rect [ SA.x "29", SA.y "12", SA.width "1", SA.height "1", SA.fill "#59634F" ] []
        , Svg.rect [ SA.x "30", SA.y "12", SA.width "1", SA.height "1", SA.fill "#5E6D52" ] []
        , Svg.rect [ SA.x "30", SA.y "13", SA.width "1", SA.height "1", SA.fill "#59634F" ] []
        , Svg.rect [ SA.x "31", SA.y "13", SA.width "1", SA.height "1", SA.fill "#5E6D52" ] []
        , Svg.rect [ SA.x "31", SA.y "14", SA.width "1", SA.height "1", SA.fill "#59634F" ] []
        , Svg.polygon [ SA.points "2,10 8,5 8,10.5", SA.fill "#AEBAA5" ] []
        , Svg.polygon [ SA.points "8,5 15,3 15,10 8,10.5", SA.fill "url(#leaf-aebaa5-93a087)" ] []
        , Svg.polygon [ SA.points "15,3 22,6 22,9.5 15,10", SA.fill "#93A087" ] []
        , Svg.polygon [ SA.points "22,6 26,10 22,9.5", SA.fill "url(#leaf-93a087-7c8b6f)" ] []
        , Svg.polygon [ SA.points "2,10 8,10.5 8,14", SA.fill "#7C8B6F" ] []
        , Svg.polygon [ SA.points "8,10.5 15,10 15,16 8,14", SA.fill "url(#leaf-7c8b6f-5e6d52)" ] []
        , Svg.polygon [ SA.points "15,10 22,9.5 22,14 15,16", SA.fill "#5E6D52" ] []
        , Svg.polygon [ SA.points "22,9.5 26,10 22,14", SA.fill "url(#leaf-5e6d52-59634f)" ] []
        ]
