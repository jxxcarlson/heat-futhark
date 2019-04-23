module HeatMap exposing (HeatMap(..), default, renderAsHtml)

{-|  A HeatMap is in effect a 2D array of floats implemented
as a flat array.  The main purpose of this module is
to provide both SVG and HTML renditions of HeatMaps.


-}

import Array exposing (Array)
import Svg exposing (Svg, svg, rect, g)
import Svg.Attributes as SA
import Svg.Lazy
import Html exposing (Html)


type HeatMap
    = HeatMap ( Int, Int ) (Array Float)


default = HeatMap (10, 10) <| Array.fromList (List.repeat 100 0.0)
rows : HeatMap -> Int
rows (HeatMap ( rows_, _ ) _) =
    rows_


cols : HeatMap -> Int
cols (HeatMap ( r_, cols_ ) _) =
    cols_


dimensions : HeatMap -> ( Int, Int )
dimensions (HeatMap idx _) =
    idx


location : Int -> ( Int, Int ) -> Int
location nRows ( row, col ) =
    nRows * row + col


index : ( Int, Int ) -> Int -> ( Int, Int )
index ( nRows, nCols ) n =
    ( n // nCols, modBy nRows n )


cellAtIndex : ( Int, Int ) -> HeatMap -> Float
cellAtIndex ( i, j ) heatMap =
    let
        (HeatMap ( nRows, _ ) array) =
            heatMap
    in
        Array.get (location nRows ( i, j )) array
            |> Maybe.withDefault 0


indices : HeatMap -> List ( Int, Int )
indices (HeatMap ( nRows, nCols ) _) =
    let
        n =
            nRows * nCols
    in
        List.map (index ( nRows, nCols )) (List.range 0 (n - 1))




--
-- RENDER GRID
--


renderAsHtml : HeatMap -> Html msg
renderAsHtml heatMap =
    let

        nPixels = 500

        ( nr, nc ) =
            dimensions heatMap

        cellSize =
            nPixels / (toFloat nr)
    in
        svg
            [ SA.height <| String.fromFloat nPixels
            , SA.width <| String.fromFloat nPixels
            , SA.viewBox <| "0 0 " ++ (String.fromInt nPixels) ++ " " ++ (String.fromInt nPixels)
            ]
            [ renderAsSvg cellSize heatMap ]


renderAsSvg : Float -> HeatMap -> Svg msg
renderAsSvg cellSize heatMap =
    indices heatMap
        |> List.map (renderCell cellSize heatMap)
        |> g []

renderCell : Float -> HeatMap -> ( Int, Int ) -> Svg msg
renderCell cellSize heatMap ( i, j ) =
    let
        red =
            255.0 * (cellAtIndex ( i, j ) heatMap)

        color =
            "rgb(" ++ String.fromFloat red ++ ", 0, 0)"
    in
        Svg.Lazy.lazy3  gridRect cellSize color ( i, j )


gridRect : Float -> String -> ( Int, Int ) -> Svg msg
gridRect size color ( row, col ) =
    rect
        [ SA.width <| String.fromFloat size
        , SA.height <| String.fromFloat size
        , SA.x <| String.fromFloat <| size * (toFloat col)
        , SA.y <| String.fromFloat <| size * (toFloat row)
        , SA.fill color
        ]
        []
