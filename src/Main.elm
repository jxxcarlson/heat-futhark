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
import HeatMap exposing (HeatMap)
import Time exposing (Posix)
import Configuration
import Http


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


type alias Model =
    { input : String
    , output : String
    , counter : Int
    , appState : AppState
    , beta : Float
    , betaString : String
    , heatMap : HeatMap
    , data : String
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
    | Step
    | Tick Posix
    | AdvanceAppState
    | Reset
    | GetData
    | GotData (Result Http.Error String)


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
      , heatMap = HeatMap.randomHeatMap ( 50, 50 )
      , data = ""
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

        Step ->
            ( { model | counter = model.counter + 1, heatMap = HeatMap.updateCells model.beta model.heatMap }, Cmd.none )

        Tick t ->
            case model.appState == Running of
                True ->
                    ( { model | counter = model.counter + 1, heatMap = HeatMap.updateCells model.beta model.heatMap }, Cmd.none )

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
            ( { model | counter = 0, appState = Ready, heatMap = HeatMap.randomHeatMap ( 50, 50 ) }, Cmd.none )

        GetData ->
            ( { model | message = "Getting data" }, getData )

        GotData (Ok str) ->
            ( { model | data = Debug.log "data" str }, Cmd.none )

        GotData (Err err) ->
            ( { model | message = "Error getting data" }, Cmd.none )



--
-- BACKEND
--


getData : Cmd Msg
getData =
    Http.get
        { url = Configuration.host
        , expect = Http.expectString GotData
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
            , el [] (HeatMap.renderAsHtml model.heatMap |> Element.html)
            , row [ spacing 18 ]
                [ resetButton
                , runButton model
                , row [ spacing 8 ] [ getDataButton, stepButton, counterDisplay model ]
                , inputBeta model
                ]
            , el [ Font.size 14, centerX ] (text "Run with 0 < beta < 1.0")
            , el [ Font.size 14 ] (text model.message)
            ]
        ]


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


stepButton : Element Msg
stepButton =
    row [ centerX ]
        [ Input.button buttonStyle
            { onPress = Just Step
            , label = el [ centerX, centerY ] (text "Step")
            }
        ]


getDataButton : Element Msg
getDataButton =
    row [ centerX ]
        [ Input.button buttonStyle
            { onPress = Just GetData
            , label = el [ centerX, centerY ] (text "Get data")
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
