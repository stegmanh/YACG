module Main exposing (..)

import Ports
import Game
import JsonTypes
import Http
import Browser exposing (Document)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Json.Encode as E
import Json.Decode as Decode


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type View
    = Main
    | Game



-- MODEL


type alias GameOptions =
    { maxDecks : Int
    }


defaultGameOptions : GameOptions
defaultGameOptions =
    GameOptions 27


type alias Model =
    { roomToJoin : String
    , gameOptions : GameOptions
    , playerName : String
    , view : View
    , gameModel : Game.Model
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model "" defaultGameOptions "" Main Game.initialModel
    , Cmd.none
    )



-- UPDATE


type Msg
    = GetNewRoomId
    | GotNewRoomId (Result Http.Error String)
    | UpdateGameOptions String
    | UpdateRoomToJoin String
    | UpdatePlayerName String
    | JoinRoom String
    | StartGame E.Value
    | GameMsg Game.Msg
    | None


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetNewRoomId ->
            ( model
            , getNewRoomId model.gameOptions
            )

        GotNewRoomId result ->
            case result of
                Ok roomId ->
                    ( { model | roomToJoin = roomId }, Cmd.none )

                Err err ->
                    ( { model | roomToJoin = "" }, Ports.sendErrorMessage "Error creating room" "Http error. Check network log" )

        UpdateGameOptions newMaxDecksString ->
            let
                newMaxDecks =
                    case String.toInt newMaxDecksString of
                        Just val ->
                            val

                        Nothing ->
                            27

                gO =
                    model.gameOptions

                gO_ =
                    { gO | maxDecks = newMaxDecks }
            in
                ( { model | gameOptions = gO_ }, Cmd.none )

        UpdateRoomToJoin roomId ->
            ( { model | roomToJoin = roomId }, Cmd.none )

        UpdatePlayerName playerName ->
            ( { model | playerName = playerName }, Cmd.none )

        JoinRoom roomId ->
            ( model, Ports.sendJsJoinMessage roomId model.playerName )

        StartGame value ->
            update (GameMsg (Game.PortMessage value)) { model | view = Game }

        GameMsg gameMsg ->
            case gameMsg of
                Game.LeaveRoom ->
                    let
                        ( model_, _ ) =
                            init ()
                    in
                        ( model_, Ports.sendJsDisconnectMessage )

                _ ->
                    let
                        ( gameModel, cmd ) =
                            Game.update gameMsg model.gameModel

                        gameCmd =
                            Cmd.map (\m -> GameMsg m) cmd
                    in
                        ( { model | gameModel = gameModel }, gameCmd )

        None ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.recieveFromJs handlePortMessage


handlePortMessage : E.Value -> Msg
handlePortMessage value =
    let
        messageType =
            JsonTypes.decodeServerMessageType value
    in
        case messageType of
            Ok (JsonTypes.Connected) ->
                StartGame value

            _ ->
                GameMsg (Game.PortMessage value)



-- VIEW


view : Model -> Html Msg
view model =
    let
        allowJoin =
            (String.length model.roomToJoin) > 0

        documentBody =
            case model.view of
                Main ->
                    [ div [ class "main-menu-container " ]
                        [ div []
                            [ h3 [] [ text "" ]
                            , div []
                                [ input [ type_ "text", placeholder "Enter a name", onInput (\s -> UpdatePlayerName s), value model.playerName, class "two-seventy-five" ] [] ]
                            , div [] [ input [ type_ "text", placeholder "RoomID", onInput (\s -> UpdateRoomToJoin s), value model.roomToJoin, class "two-seventy-five" ] [] ]
                            , div [] [ button [ disabled (not allowJoin), onClick <| JoinRoom model.roomToJoin, class "two-seventy-five" ] [ text "Join" ] ]
                            , div []
                                [ div [ class "create-game-container" ]
                                    [ div []
                                        [ div [ class "create-game-text" ] [ text "No Game? Create One:" ]
                                        , button [ onClick GetNewRoomId, classList [ ( "two-seventy-five", True ), ( "create-btn", True ) ] ] [ text "Create" ]
                                        ]
                                    , div []
                                        [ div [ class "create-game-text" ] [ text "Play until:" ]
                                        , input [ type_ "number", Html.Attributes.min "1", Html.Attributes.max "27", value (String.fromInt model.gameOptions.maxDecks), onInput (\s -> UpdateGameOptions s) ] []
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]

                Game ->
                    [ Html.map (\m -> GameMsg m) (Game.view model.gameModel) ]
    in
        div [ class "main-container" ]
            [ h1 []
                [ text "Generic Card Game" ]
            , div
                [ class "main-sub-container" ]
                documentBody
            ]



-- Helper functions


getNewRoomId : GameOptions -> Cmd Msg
getNewRoomId options =
    let
        createUrl =
            "/create/" ++ String.fromInt options.maxDecks
    in
        Http.send GotNewRoomId (Http.post createUrl Http.emptyBody gotNewRoomIdDecoder)


gotNewRoomIdDecoder : Decode.Decoder String
gotNewRoomIdDecoder =
    Decode.field "room" Decode.string
