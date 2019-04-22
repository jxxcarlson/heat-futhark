module HeatMap exposing (HeatMap(..), classifyCell, CellType(..), location, index, cellAtIndex, setValue, nextCellValue, updateCell, updateCells, averageAt, randomHeatMap, renderAsHtml)

{-| This library is just a test. I repeat: a test!

@docs location, index

-}

import Array exposing (Array)
import Random
import List.Extra
import Svg exposing (Svg, svg, rect, g)
import Svg.Attributes as SA
import Html exposing (Html)


type HeatMap
    = HeatMap ( Int, Int ) (Array Float)


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


setValue : HeatMap -> ( Int, Int ) -> Float -> HeatMap
setValue (HeatMap ( nRows, nCols ) values) ( i, j ) value =
    let
        k =
            location nRows ( i, j )
    in
        (HeatMap ( nRows, nCols ) (Array.set k value values))


type CellType
    = Corner
    | Edge
    | Interior


classifyCell : HeatMap -> ( Int, Int ) -> CellType
classifyCell heatMap ( i, j ) =
    let
        ( nRows, nCols ) =
            dimensions heatMap

        mri =
            nRows - 1

        mci =
            nCols - 1
    in
        case i == 0 || j == 0 || i == mri || j == mci of
            False ->
                Interior

            True ->
                if i == 0 && j == 0 then
                    Corner
                else if i == 0 && j == mci then
                    Corner
                else if i == mri && j == 0 then
                    Corner
                else if i == mri && j == mci then
                    Corner
                else
                    Edge


averageAt : HeatMap -> ( Int, Int ) -> Float
averageAt heatMap ( i, j ) =
    let
        east =
            cellAtIndex ( i - 1, j ) heatMap

        west =
            cellAtIndex ( i + 1, j ) heatMap

        north =
            cellAtIndex ( i, j + 1 ) heatMap

        south =
            cellAtIndex ( i, j - 1 ) heatMap

        denominator =
            case classifyCell heatMap ( i, j ) of
                Interior ->
                    4

                Edge ->
                    3

                Corner ->
                    2
    in
        (east + west + north + south) / denominator


randomHeatMap : ( Int, Int ) -> HeatMap
randomHeatMap ( r, c ) =
    HeatMap ( r, c ) (Array.fromList <| floatSequence (r * c) 0 ( 0, 1 ))


nextCellValue : Float -> ( Int, Int ) -> HeatMap -> Float
nextCellValue beta ( i, j ) heatMap =
    let
        currentCellValue =
            cellAtIndex ( i, j ) heatMap
    in
        case classifyCell heatMap ( i, j ) == Interior of
            False ->
                currentCellValue

            True ->
                (1 - beta) * currentCellValue + beta * (averageAt heatMap ( i, j ))


updateCell : Float -> ( Int, Int ) -> HeatMap -> HeatMap
updateCell beta ( i, j ) heatMap =
    setValue heatMap ( i, j ) (nextCellValue beta ( i, j ) heatMap)


indices : HeatMap -> List ( Int, Int )
indices (HeatMap ( nRows, nCols ) _) =
    let
        n =
            nRows * nCols
    in
        List.map (index ( nRows, nCols )) (List.range 0 (n - 1))


updateCells : Float -> HeatMap -> HeatMap
updateCells beta heatMap =
    List.foldl (\( i, j ) acc -> setValue acc ( i, j ) (nextCellValue beta ( i, j ) heatMap)) heatMap (indices heatMap)



---
--- RNG
---
{-

   Example:

   > RNG.floatSequence 3 23 (0,1)
   [0.07049563320325747,0.8633668118636881,0.6762363032990798]

-}


floatSequence : Int -> Int -> ( Float, Float ) -> List Float
floatSequence n k ( a, b ) =
    floatSequence_ n (makeSeed k) ( a, b )
        |> Tuple.first


gen : Int -> ( Float, Float ) -> Random.Generator (List Float)
gen n ( a, b ) =
    Random.list n (Random.float a b)


makeSeed : Int -> Random.Seed
makeSeed k =
    Random.initialSeed k


floatSequence_ : Int -> Random.Seed -> ( Float, Float ) -> ( List Float, Random.Seed )
floatSequence_ n seed ( a, b ) =
    Random.step (gen n ( a, b )) seed



--
-- RENDER GRID
--


renderAsHtml : HeatMap -> Html msg
renderAsHtml heatMap =
    let
        ( nr, nc ) =
            dimensions heatMap

        cellSize =
            400 / (toFloat nr)
    in
        svg
            [ SA.height <| String.fromFloat 400
            , SA.width <| String.fromFloat 400
            , SA.viewBox <| "0 0 400 400"
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
        gridRect cellSize color ( i, j )


gridRect : Float -> String -> ( Int, Int ) -> Svg msg
gridRect size color ( row, col ) =
    rect
        [ SA.width <| String.fromFloat size
        , SA.height <| String.fromFloat size
        , SA.x <| String.fromFloat <| size * (toFloat col)
        , SA.y <| String.fromFloat <| size * (toFloat row)
        , SA.fill color

        --, SA.strokeWidth "1"
        -- , SA.stroke "rgb(25, 55, 125)"
        ]
        []
