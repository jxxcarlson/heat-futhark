module Utility exposing (decodeArray)

{-| The decodeArray function decodes a Byte sequence
into an array of floats, assuming that that is possible.

-}

import Bytes exposing (Endianness(..))
import Bytes.Decode as Decode exposing (..)
import Bytes.Encode as Encode exposing (encode)
import Array exposing(Array)

{-|
    > import Utility exposing(..)
    > import Bytes.Encode as Encode exposing(encode)
    > testBytes = encode (test 1 2 3)
    <12 bytes> : Bytes.Bytes

    > import Bytes exposing(Endianness(..))
    > decode (decodeArray 3 (Decode.float32 BE)) testBytes
      Just (Array.fromList [1,2,3])
 -}
decodeArray : Int -> Decoder a -> Decoder (Array a)
decodeArray n decoder =
   loop (n, []) (decodeArrayStep decoder)
   |> map List.reverse
   |> map Array.fromList


decodeArrayStep : Decoder a -> (Int, List a) -> Decoder (Step (Int, List a) (List a))
decodeArrayStep decoder (n, xs) =
  if n <= 0 then
    succeed (Done xs)
  else
    map (\x -> Loop (n - 1, x :: xs)) decoder


test : Float -> Float -> Float -> Encode.Encoder
test x y z =
   Encode.sequence
     [ Encode.float32 BE x
     , Encode.float32 BE y
     , Encode.float32 BE z
     ]

