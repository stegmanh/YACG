module JsonTypes exposing (..)

import Json.Encode as E
import Json.Decode as D


type JsonMessageType
    = Connected
    | StartGame
    | UpdateGame
    | EndGame


type JsonMessage
    = ConnectedState String
    | StartState GameStartedUpdate
    | UpdateState GameUpdatedUpdate
    | EndGameState


type alias GameStartedUpdate =
    { cards : List Card
    , players : List Player
    , name : String
    }


type alias GameUpdatedUpdate =
    { cards : List Card
    , players : List Player
    }


type alias Card =
    { color : String
    , shape : String
    , fill : String
    , num : String
    }


type alias Player =
    { name : String
    , score : Int
    }


decodeServerMessageType : E.Value -> Result String JsonMessageType
decodeServerMessageType value =
    let
        messageTypeResult =
            D.decodeValue (D.field "messageType" D.string) value
    in
        case messageTypeResult of
            Ok messageType ->
                case messageType of
                    "CONNECTED" ->
                        Ok Connected

                    "START" ->
                        Ok StartGame

                    "UPDATE" ->
                        Ok UpdateGame

                    "FINISHED" ->
                        Ok EndGame

                    _ ->
                        Err ("Unkown message type: " ++ messageType)

            Err e ->
                Err (D.errorToString e)


decodeServerMessage : E.Value -> Result String JsonMessage
decodeServerMessage value =
    let
        messageType =
            decodeServerMessageType value
    in
        case messageType of
            Ok Connected ->
                case D.decodeValue (D.field "data" D.string) value of
                    Ok roomId ->
                        Ok (ConnectedState roomId)

                    Err e ->
                        Err (D.errorToString e)

            Ok StartGame ->
                case (D.decodeValue (D.field "data" decodeGameUpdateStarted) value) of
                    Ok startMessage ->
                        Ok (StartState startMessage)

                    Err e ->
                        Err (D.errorToString e)

            Ok UpdateGame ->
                case (D.decodeValue (D.field "data" decodeGameUpdateUpdated) value) of
                    Ok updateMessage ->
                        Ok (UpdateState updateMessage)

                    Err e ->
                        Err (D.errorToString e)

            Ok EndGame ->
                Ok EndGameState

            Err e ->
                Err e


decodeGameUpdateStarted : D.Decoder GameStartedUpdate
decodeGameUpdateStarted =
    D.map3 GameStartedUpdate
        (D.field "cards" (D.list decodeCard))
        (D.field "players" (D.list decodePlayer))
        (D.field "name" D.string)


decodeGameUpdateUpdated : D.Decoder GameUpdatedUpdate
decodeGameUpdateUpdated =
    D.map2 GameUpdatedUpdate
        (D.field "cards" (D.list decodeCard))
        (D.field "players" (D.list decodePlayer))


encodeCard : Card -> E.Value
encodeCard card =
    E.object
        [ ( "color", E.string card.color )
        , ( "shape", E.string card.shape )
        , ( "fill", E.string card.fill )
        , ( "num", E.string card.num )
        ]


decodeCard : D.Decoder Card
decodeCard =
    D.map4 Card
        (D.field "color" D.string)
        (D.field "shape" D.string)
        (D.field "fill" D.string)
        (D.field "num" D.string)


decodePlayer : D.Decoder Player
decodePlayer =
    D.map2 Player
        (D.field "name" D.string)
        (D.field "score" D.int)
