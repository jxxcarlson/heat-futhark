module ArrayParser exposing (decodeArray, byteArrayDecoder, dummyDecodeArray)

import Parser exposing (..)
import Array exposing (..)
import Bytes exposing(Bytes)
import Bytes.Decode exposing(Decoder)


--
-- THIS MODULE IS NOT USED
--


byteArrayDecoder : Decoder (Array Float)
byteArrayDecoder  =
    Bytes.Decode.succeed Array.empty


dummyDecodeArray : Bytes -> Decoder (Array Float)
dummyDecodeArray bytes =
    Bytes.Decode.succeed  <| Array.fromList [0.0, 1.0, 2.0]

decodeArray : String -> Maybe (Array (Array Float))
decodeArray str =
    run parseArray str
      |> Result.toMaybe

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
