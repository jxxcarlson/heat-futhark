module Main exposing (main)

{- This app is a demo of how computationally intensive tasks, in this case appliction
of the discrete heat kernel, can be offloaded to Futhark embedded in a Python server
that talks to the Elm app.

Still in a crude state/
-}

import Browser
import Html exposing (Html)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
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
    , nString : String
    , betaString : String
    , iterationsString : String
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
    | InputN String
    | InputIterations String
    | Tick Posix
    | AdvanceAppState
    | Reset
    | GetData
    | GotData (Result Http.Error Bytes)
    | CommandExecuted (Result Http.Error String)


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { input = "Test"
      , output = "Test"
      , counter = 0
      , appState = Ready
      , nString = "20"
      , betaString = "0.1"
      , iterationsString = "1"
      , heatMapSize = 20
      , heatMap = Nothing
      , message = ""
      }
    , dataCommand (20*20) "reset"
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
                    ( { model | betaString = str }, serverCommand <| "beta=" ++ str )

        InputN str ->
            case String.toInt str of
                Nothing ->
                    ( { model | nString = str }, Cmd.none )

                Just n_ ->
                    ( { model | nString = str, heatMapSize = n_ }, serverCommand <| "n=" ++ str )

        InputIterations str ->
                    case String.toInt str of
                        Nothing ->
                            ( { model | iterationsString = str }, Cmd.none )

                        Just n_ ->
                            ( { model | iterationsString = str }, serverCommand <| "iterations=" ++ str )

        Tick t ->
            case model.appState == Running of
                True ->
                    ( { model | counter = model.counter + 1 }, dataCommand  (nBytesInData model) <| "step=" ++ model.iterationsString)

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
            ( { model | counter = 0, appState = Ready, heatMap = Nothing }, dataCommand (nBytesInData model) "reset" )

        GetData ->
            ( { model | message = "Getting data" }, dataCommand (nBytesInData model) <| "step=" ++ model.iterationsString)

        GotData (Ok bytes) ->
            let
                n_ = model.heatMapSize * model.heatMapSize
            in
            case Bytes.Decode.decode (Utility.decodeArray n_ (Bytes.Decode.float32 LE)) bytes of
                 Nothing -> ( { model | message = "Could not decode data from server"} , Cmd.none)
                 Just array ->
                     let
                        n = model.heatMapSize
                      in
                        ( { model | counter = model.counter + 1, message = "Got data",  heatMap = Just <| HeatMap (n,n) array}, Cmd.none )


        GotData (Err err) ->
            ( { model | message = "Error getting data", heatMap  = Nothing}, Cmd.none )

        CommandExecuted (Ok str) ->
            ( {model | message = "Command executed: " ++ str}, Cmd.none)

        CommandExecuted (Err err) ->
                    ( {model | message = "Error executing command"}, Cmd.none)


--
-- BACKEND
--

serverCommand : String -> Cmd Msg
serverCommand cmd =
    Http.get
        { url = Configuration.host ++ "/" ++ cmd
        , expect = Http.expectString CommandExecuted
        }

dataCommand : Int -> String -> Cmd Msg
dataCommand dataSize cmd =
    Http.get
        { url = Configuration.host ++ "/" ++ cmd
        , expect = Http.expectBytes GotData (Bytes.Decode.bytes dataSize)
        }

nBytesInData: Model -> Int
nBytesInData model = 4*model.heatMapSize*model.heatMapSize

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
                [ resetButton model
                , runButton model
                , row [ spacing 8 ] [ getDataButton, counterDisplay model ]
                , inputBeta model
                , inputN model
                ]
            , inputIterations model, el [ Font.size 14, centerX ] (text "Run with 0 < beta < 1.0")
            , el [ Font.size 14 ] (text model.message)
            ]
        ]


renderHeatMap : Model -> Element Msg
renderHeatMap model =
    case model.heatMap of
        Nothing -> Keyed.el [] (String.fromInt model.counter, (HeatMap.renderAsHtml HeatMap.default |> Element.html))
        Just heatMap -> Keyed.el [] (String.fromInt model.counter, (HeatMap.renderAsHtml heatMap |> Element.html))


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
    Input.text inputTextStyle
        { onChange = InputBeta
        , text = model.betaString
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el inputTextLabelStyle (text "beta ")
        }

inputIterations : Model -> Element Msg
inputIterations model =
    Input.text inputTextStyle
        { onChange = InputIterations
        , text = model.iterationsString
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el inputTextLabelStyle (text "iterations/step ")
        }

inputN : Model -> Element Msg
inputN model =
    Input.text inputTextStyle
        { onChange = InputN
        , text = model.nString
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el inputTextLabelStyle (text "rows ")
        }

inputTextStyle = [ width (px 60), Font.size buttonFontSize, height (px 30) ]

inputTextLabelStyle = [ Font.size buttonFontSize, moveDown 6 ]



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


resetButton : Model -> Element Msg
resetButton model =
    row [ centerX ]
        [ Input.button buttonStyle
            { onPress = Just Reset
            , label = el [ centerX, centerY ] (text <| resetLabel model.appState)
            }
        ]

resetLabel : AppState -> String
resetLabel appState =
    case appState of
        Ready -> "Set up"
        _ -> "Reset"

appStateAsString : AppState -> String
appStateAsString appState =
    case appState of
        Ready ->
            "Run?"

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
