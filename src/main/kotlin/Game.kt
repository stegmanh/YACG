package main

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.*
import io.javalin.websocket.WsSession
import java.util.*

val mapper = ObjectMapper().registerKotlinModule()

class Player(name: String) {
    val name = name
    var score = 0
    var ready = false
}

enum class GameState {
    NotStarted,
    Playing,
    Finished
}

class Game (val playRounds: Int) {
    val deck = Deck()
    val players = HashMap<WsSession, Player>()
    val createdTime = Date()
    var state = GameState.NotStarted
    var roundsPlayed = 0

    fun handleMessage(session: WsSession, message: String) {
        val player = players.get(session)

        if (player == null) {
            println("Session doesn't exist in game...")
            return
        }

        val gameMessage = mapper.readValue(message, GameMessage::class.java)

        if (gameMessage.isReadyMessage()) {
            // For now - allow players to manually start
            // TODO: Auto start configure option
            player.ready = true
        } else if (gameMessage.isStartMessage()) {
            player.ready = true
            start()
        } else if (gameMessage.isUpdateMessage()) {
            val gameUpdateMessage = mapper.readValue(message, GameUpdateMessage::class.java)
            val moved = deck.playCard(gameUpdateMessage.data)
            if (moved) {
                player.score = player.score + 1
                roundsPlayed++
                update()
                if (deck.isDeckOver || roundsPlayed >= playRounds) {
                    endGame()
                }
            }
        }

    }

    private fun start() {
        this.state = GameState.Playing

        players.forEach { session, player ->
            session.send(getStartGameString(player))
        }
    }

    fun hasStarted(): Boolean {
        return this.state == GameState.Playing
    }

    private fun update() {
        players.forEach { session, player ->
            session.send(getUpdateGameString())
        }
    }

    private fun endGame() {
        players.forEach { session, player ->
            session.send(getFinishedGameString())
        }
    }

    private fun isAllPlayersReady(): Boolean {
        // TODO:  Debugging reasons
        return players.size == 2 && players.all { it.component2().ready }
        //return players.all { it.component2().ready }
    }

    private fun getStartGameString(currentPlayer: Player): String {
        val players = players.map {
            val player = it.component2();
            object { val name = player.name; val score = player.score; }
        }

        val startObject = object {
            val messageType = "START"
            val data = object {
                val name = currentPlayer.name
                val cards = deck.playingCards
                val players = players
            }
        }

        return mapper.writeValueAsString(startObject)
    }

    private fun getUpdateGameString(): String {
        val players = players.map {
            val player = it.component2()
            object { val name = player.name; val score = player.score; }
        }

        val startObject = object {
            val messageType = "UPDATE"
            val data = object {
                val cards = deck.playingCards;
                val players = players
            }
        }

        return mapper.writeValueAsString(startObject)
    }

    private fun getFinishedGameString(): String {
        val startObject = object {
            val messageType = "FINISHED"
        }

        return mapper.writeValueAsString(startObject)
    }

    fun isNameTaken(name: String): Boolean {
        return this.players.any{ it.component2().name.contentEquals(name) }
    }
}

class GameMessage(messageType: String, data: JsonNode) {
    val messageType: String = messageType
    val data: JsonNode = data

    fun isReadyMessage(): Boolean {
        return messageType.contentEquals("READY")
    }

    fun isUpdateMessage(): Boolean {
        return messageType.contentEquals("UPDATE")
    }

    fun isStartMessage(): Boolean {
        return messageType.contentEquals("START")
    }
}

class GameUpdateMessage(messageType: String, data: Array<Card>) {
    val messageType: String = messageType
    val data: Array<Card> = data
}
