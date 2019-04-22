module ArrayParser exposing (..)

import Parser exposing (..)
import Array exposing (..)


{-|

    > run parseRow "[ 1.0 2.0 3]"
    Ok (Array.fromList [1,2,3])
-}
parseRow : Parser (Array Float)
parseRow =
    (Parser.sequence
        { start = "["
        , separator = ""
        , end = "]"
        , spaces = spaces
        , item = float
        , trailing = Optional -- trailing space
        }
    )
        |> Parser.map Array.fromList


{-|

> data = "[[ 0. 0.5 0.5 0. 0. 0. ][ 0. 0. 0. 0. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ][ 0. 0. 0. 1. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ]][[ 0. 0.5 0.5 0. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ] [ 0. 0. 0. 1. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ] [ 0. 0. 0. 0. 0. 0. ]]"
> run parseArray data
> Ok (Array.fromList [Array.fromList [0,0.5,0.5,0,0,0],Array.fromList [0,0,0,0,0,0],Array.fromList [0,0,0,0,0,0],Array.fromList [0,0,0,1,0,0],Array.fromList [0,0,0,0,0,0],Array.fromList [0,0,0,0,0,0]])
-}
parseArray : Parser (Array (Array Float))
parseArray =
    (Parser.sequence
        { start = "["
        , separator = ""
        , end = "]"
        , spaces = spaces
        , item = parseRow
        , trailing = Optional -- trailing space
        }
    )
        |> Parser.map Array.fromList
