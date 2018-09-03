port module Ports exposing (..)

import Json.Encode as E
import JsonTypes exposing (..)


port sendToJs : E.Value -> Cmd msg


port recieveFromJs : (E.Value -> msg) -> Sub msg


type JsMessageType
    = Join
    | Update
    | Disconnect
    | Set
    | Error


encodeJsMessageType : JsMessageType -> E.Value
encodeJsMessageType jsMessageType =
    case jsMessageType of
        Join ->
            E.string "JOIN"

        Update ->
            E.string "UPDATE"

        Disconnect ->
            E.string "DISCONNECT"

        Set ->
            E.string "SET"

        Error ->
            E.string "ERROR"


type alias JsMessage =
    { messageType : JsMessageType
    , message : E.Value
    }


encodeJsMessage : JsMessage -> E.Value
encodeJsMessage jsMessage =
    E.object
        [ ( "messageType", (encodeJsMessageType jsMessage.messageType) )
        , ( "data", jsMessage.message )
        ]


sendJsDisconnectMessage : Cmd msg
sendJsDisconnectMessage =
    let
        disconnectMessage =
            JsMessage Disconnect (E.string "")
    in
        sendToJs <| encodeJsMessage disconnectMessage


sendJsJoinMessage : String -> String -> Cmd msg
sendJsJoinMessage roomId playerName =
    let
        joinMessage =
            JsMessage Join
                (E.object
                    [ ( "roomId"
                      , (E.string roomId)
                      )
                    , ( "name"
                      , (E.string playerName)
                      )
                    ]
                )
    in
        sendToJs <| encodeJsMessage joinMessage


sendJsUpdateMessage : List Card -> Cmd msg
sendJsUpdateMessage cards =
    let
        updateMessage =
            JsMessage Update (E.list encodeCard cards)
    in
        sendToJs <| encodeJsMessage updateMessage


sendJsSetMessage : Bool -> Cmd msg
sendJsSetMessage isFound =
    let
        setMessage =
            JsMessage Set (E.bool isFound)
    in
        sendToJs <| encodeJsMessage setMessage


sendErrorMessage : String -> String -> Cmd msg
sendErrorMessage humanString consoleString =
    let
        errorMessage =
            JsMessage Error
                (E.object
                    [ ( "humanString"
                      , (E.string humanString)
                      )
                    , ( "consoleString"
                      , (E.string consoleString)
                      )
                    ]
                )
    in
        sendToJs <| encodeJsMessage errorMessage
