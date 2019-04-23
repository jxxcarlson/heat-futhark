module Main exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
   This version uses `mdgriffith/elm-ui` for the view functions.
-}

import Browser
import Html exposing (Html)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import HeatMap exposing (HeatMap(..))
import Time exposing (Posix)
import Configuration
import Http
import Array exposing(Array)
import Utility
import Bytes exposing(Bytes, Endianness(..))
import Bytes.Decode



tickInterval : Float
tickInterval =
    333


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

type alias Data = Array (Array Float)

type alias Model =
    { input : String
    , output : String
    , counter : Int
    , appState : AppState
    , beta : Float
    , betaString : String
    , heatMapSize : Int
    , heatMap : Maybe HeatMap
    , message : String
    }


type AppState
    = Ready
    | Running
    | Paused



-- MSG


type Msg
    = NoOp
    | InputBeta String
    | Tick Posix
    | AdvanceAppState
    | Reset
    | GetData
    | GotData (Result Http.Error Bytes)


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { input = "Test"
      , output = "Test"
      , counter = 0
      , appState = Ready
      , beta = 0.1
      , betaString = "0.1"
      , heatMapSize = 150
      , heatMap = Nothing
      , message = ""
      }
    , Cmd.none
    )


subscriptions model =
    Time.every tickInterval Tick


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        InputBeta str ->
            case String.toFloat str of
                Nothing ->
                    ( { model | betaString = str }, Cmd.none )

                Just beta_ ->
                    ( { model | betaString = str, beta = beta_ }, Cmd.none )

        Tick t ->
            case model.appState == Running of
                True ->
                    ( { model | counter = model.counter + 1 }, Cmd.none )

                False ->
                    ( model, Cmd.none )

        AdvanceAppState ->
            let
                nextAppState =
                    case model.appState of
                        Ready ->
                            Running

                        Running ->
                            Paused

                        Paused ->
                            Running
            in
                ( { model | appState = nextAppState }, Cmd.none )

        Reset ->
            ( { model | counter = 0, appState = Ready, heatMap = Nothing }, Cmd.none )

        GetData ->
            ( { model | message = "Getting data" }, (getData <| 4*model.heatMapSize*model.heatMapSize))
            --  4*model.heatMapSize*model.heatMapSize

        GotData (Ok bytes) ->
            let
                _ = Debug.log "Width" (Bytes.width bytes)
                n_ = model.heatMapSize * model.heatMapSize
            in
            case Bytes.Decode.decode (Utility.decodeArray n_ (Bytes.Decode.float32 LE)) bytes of
                 Nothing -> ( { model | message = "Could not decode data from server"} , Cmd.none)
                 Just array ->
                     let
                        n = model.heatMapSize
                      in
                        ( { model | message = "Got data",  heatMap = Just <| HeatMap (n,n) array}, Cmd.none )


        GotData (Err err) ->
            ( { model | message = "Error getting data", heatMap  = Nothing}, Cmd.none )


--
-- BACKEND
--


getData : Int -> Cmd Msg
getData nBytes =
    Http.get
        { url = Configuration.host
        , expect = Http.expectBytes GotData (Bytes.Decode.bytes nBytes)
        }



--
-- VIEW
--


view : Model -> Html Msg
view model =
    Element.layout [] (mainColumn model)


mainColumn : Model -> Element Msg
mainColumn model =
    column mainColumnStyle
        [ column [ centerX, spacing 20 ]
            [ title "Diffusion of Heat"
            , el [] (renderHeatMap model)
            , row [ spacing 18 ]
                [ resetButton
                , runButton model
                , row [ spacing 8 ] [ getDataButton, counterDisplay model ]
                , inputBeta model
                ]
            , el [ Font.size 14, centerX ] (text "Run with 0 < beta < 1.0")
            , el [ Font.size 14 ] (text model.message)
            ]
        ]


renderHeatMap : Model -> Element Msg
renderHeatMap model =
    case model.heatMap of
        Nothing -> Element.none
        Just heatMap -> el [] (HeatMap.renderAsHtml heatMap |> Element.html)


counterDisplay : Model -> Element Msg
counterDisplay model =
    el [ Font.size 18, width (px 30) ] (text <| String.fromInt model.counter)


title : String -> Element msg
title str =
    row [ centerX, Font.bold ] [ text str ]


outputDisplay : Model -> Element msg
outputDisplay model =
    row [ centerX ]
        [ text model.output ]


buttonFontSize =
    16


inputBeta : Model -> Element Msg
inputBeta model =
    Input.text [ width (px 60), Font.size buttonFontSize ]
        { onChange = InputBeta
        , text = model.betaString
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el [ Font.size buttonFontSize, moveDown 12 ] (text "beta ")
        }






getDataButton : Element Msg
getDataButton =
    row [ centerX ]
        [ Input.button buttonStyle
            { onPress = Just GetData
            , label = el [ centerX, centerY ] (text "Step")
            }
        ]


runButton : Model -> Element Msg
runButton model =
    row [ centerX, width (px 80) ]
        [ Input.button (buttonStyle ++ [ activeBackgroundColor model ])
            { onPress = Just AdvanceAppState
            , label = el [ centerX, centerY, width (px 60) ] (text <| appStateAsString model.appState)
            }
        ]


activeBackgroundColor model =
    case model.appState of
        Running ->
            Background.color (Element.rgb 0.65 0 0)

        _ ->
            Background.color (Element.rgb 0 0 0)


resetButton : Element Msg
resetButton =
    row [ centerX ]
        [ Input.button buttonStyle
            { onPress = Just Reset
            , label = el [ centerX, centerY ] (text <| "Reset")
            }
        ]


appStateAsString : AppState -> String
appStateAsString appState =
    case appState of
        Ready ->
            "Ready"

        Running ->
            "Running"

        Paused ->
            "Paused"



--
-- STYLE
--


mainColumnStyle =
    [ centerX
    , centerY
    , Background.color (rgb255 240 240 240)
    , paddingXY 20 20
    ]


buttonStyle =
    [ Background.color (rgb255 40 40 40)
    , Font.color (rgb255 255 255 255)
    , paddingXY 15 8
    , Font.size buttonFontSize
    ]



--
