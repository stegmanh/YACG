module Game exposing (..)

import Ports
import Utils exposing (partition)
import JsonTypes exposing (..)
import Array
import Constants exposing (randomMessages, specialPlayersOne, specialPlayersTwo, superSpecialPlayer)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as E
import Random


-- MODEL


type GameState
    = Waiting
    | Playing
    | Finished


type alias Model =
    { gameState : GameState
    , roomId : String
    , cards : List Card
    , players : List Player
    , selected : List Card
    , name : String
    , randomMessage : String
    }


initialModel : Model
initialModel =
    Model Waiting "" [] [] [] "" ""



-- UPDATE


type Msg
    = PortMessage E.Value
    | LeaveRoom
    | GameUpdate JsonMessage
    | SelectCard Card
    | GetRandomMessageIndex
    | GotRandomMessageIndex Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PortMessage value ->
            -- TODO: Handle Error case of decode here
            case decodeServerMessage value of
                Ok serverMessage ->
                    update (GameUpdate serverMessage) model

                Err e ->
                    ( model, Ports.sendErrorMessage "Error decoding server message" e )

        LeaveRoom ->
            ( model, Cmd.none )

        GameUpdate jsonMessage ->
            case jsonMessage of
                ConnectedState roomId_ ->
                    update GetRandomMessageIndex { model | roomId = roomId_ }

                StartState startState ->
                    ( { model | gameState = Playing, cards = startState.cards, players = startState.players, name = startState.name }, Cmd.none )

                UpdateState updatedState ->
                    let
                        updatedModel =
                            { model | selected = [], cards = updatedState.cards, players = updatedState.players }
                    in
                        ( updatedModel, Cmd.none )

                EndGameState ->
                    ( { model | gameState = Finished }, Cmd.none )

        SelectCard card ->
            let
                updatedSelectedCards =
                    updateSelectedCards model.selected card

                isAttempt =
                    List.length updatedSelectedCards == 3

                isSet =
                    isAttempt && Utils.isSetList updatedSelectedCards
            in
                if isSet then
                    ( model, Cmd.batch [ Ports.sendJsUpdateMessage updatedSelectedCards, Ports.sendJsSetMessage True ] )
                else if isAttempt then
                    ( { model | selected = [] }, Ports.sendJsSetMessage False )
                else
                    ( { model | selected = updatedSelectedCards }, Cmd.none )

        GetRandomMessageIndex ->
            ( model, Random.generate GotRandomMessageIndex (Random.int 0 (Array.length randomMessages)) )

        GotRandomMessageIndex idx ->
            let
                randomMessage_ =
                    case Array.get idx randomMessages of
                        Just randomMessage__ ->
                            randomMessage__

                        Nothing ->
                            ""
            in
                ( { model | randomMessage = randomMessage_ }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.gameState of
        Waiting ->
            div [ class "game-connecting" ]
                [ p [] [ text "Waiting for all players to connect" ]
                , p [] [ text ("Invite them to connect @ " ++ model.roomId) ]
                , button [ onClick LeaveRoom ] [ text "Leave Room" ]
                ]

        Playing ->
            div [ classList [ ( "game-container", True ) ] ] (renderMainGame model)

        Finished ->
            renderFinished model


renderMainGame : Model -> List (Html Msg)
renderMainGame model =
    [ (renderPlayerContainer model), (renderBoard model), (renderFooter model) ]


renderBoard : Model -> Html Msg
renderBoard model =
    let
        cardGroups =
            List.map (renderCard model) model.cards
                |> partition 3
                |> List.map (\group -> div [ classList [ ( "s-card-group", True ) ] ] group)
    in
        div [ classList [ ( "game-board", True ) ] ] cardGroups


renderCard : Model -> Card -> Html Msg
renderCard model card =
    let
        isSelectedCard =
            List.member card model.selected

        imgSrc =
            makeCardUrl card
    in
        div [ classList [ ( "s-card", True ), ( "s-card-selected", isSelectedCard ) ], onClick (SelectCard card) ]
            [ img [ classList [ ( "s-card-img", True ) ], src imgSrc ] [] ]


renderFooter : Model -> Html Msg
renderFooter model =
    let
        isSp1Playing =
            List.any (\player -> List.member (String.toUpper player.name) specialPlayersOne) model.players

        isSp2Playing =
            List.any (\player -> List.member (String.toUpper player.name) specialPlayersTwo) model.players

        sp1Footer =
            if isSp1Playing then
                div [ class "footer-special" ] [ text "Look! A special player! It's... A Mano!!! (Or Mana!)" ]
            else
                div [] []

        sp2Footer =
            if isSp2Playing then
                div [ class "footer-special" ] [ text model.randomMessage ]
            else
                div [] []
    in
        div [] [ sp1Footer, sp2Footer ]


renderPlayerContainer : Model -> Html Msg
renderPlayerContainer model =
    div [ class "s-player-container" ] (List.map renderPlayerPortion model.players)


renderPlayerPortion : Player -> Html Msg
renderPlayerPortion player =
    let
        playerName =
            player.name ++ ":"

        scoreString =
            String.join " " [ playerName, String.fromInt player.score ]
    in
        div [ class "s-player" ] [ p [] [ text scoreString ] ]


renderFinished : Model -> Html Msg
renderFinished model =
    case findWinningPlayer model.players of
        Just winningPlayer ->
            let
                additionalText =
                    if String.toUpper (winningPlayer.name) == superSpecialPlayer then
                        p [] [ text (superSpecialPlayer ++ " and winning set. Name a more iconic duo") ]
                    else if String.toUpper (winningPlayer.name) == "HOLDEN" then
                        p [] [ text "Well well well.. look who finally won one" ]
                    else
                        p [] []
            in
                div [ class "game-winners" ]
                    [ p [] [ text "Congratulations!" ]
                    , p [] [ text (winningPlayer.name ++ " won!") ]
                    , button [ onClick LeaveRoom ] [ text "Play Again?" ]
                    , additionalText
                    ]

        Nothing ->
            div [] [ text "Game Over! (How did you see this screen?)" ]



-- Helper functions


updateSelectedCards : List Card -> Card -> List Card
updateSelectedCards selectedCards newCard =
    -- Toggles card selected
    if List.member newCard selectedCards then
        List.filter (\c -> c /= newCard) selectedCards
    else
        newCard :: selectedCards


makeCardUrl : Card -> String
makeCardUrl card =
    "static/images/" ++ String.join "_" [ card.color, card.shape, card.fill, card.num ] ++ ".png"


findWinningPlayer : List Player -> Maybe Player
findWinningPlayer players =
    case List.head players of
        Just firstPlayer ->
            Just (List.foldl findWinningPlayerReducer firstPlayer players)

        Nothing ->
            Nothing


findWinningPlayerReducer : Player -> Player -> Player
findWinningPlayerReducer currHighest potential =
    if potential.score > currHighest.score then
        potential
    else
        currHighest
