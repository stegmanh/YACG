package main

import io.javalin.Javalin
import io.javalin.staticfiles.Location
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.concurrent.thread

val Games: ConcurrentHashMap<String, Game> = ConcurrentHashMap()

fun main(args: Array<String>) {

    // Spin up thread to clean up outstanding games
    thread(true, true, null, null, -1) {
        while (true) {
            val toRemove = ArrayList<String>()
            Games.forEach {id, game ->
                val fiveAgo = Date(System.currentTimeMillis() - (5 * 60 * 1000))
                if (game.createdTime.before(fiveAgo) && game.players.size == 0) {
                    toRemove.add(id)
                }
            }

            toRemove.forEach {Games.remove(it)}
            Thread.sleep(60 * 1000)
        }
    }

    // Load super basic dynamic routes
    // If you're reading this. Don't ask. It's for a very very specific use case
    var specials = Specials.loadSpecials()

    Javalin.create().apply {
        // TODO: Only server the static files needed
        enableStaticFiles("./client", Location.EXTERNAL)

        post("/create/:till") { ctx ->
            val roomId = UUID.randomUUID().toString()
            val tillParam= ctx.pathParam("till").trim()
            val till = tillParam.toIntOrNull() ?: 27
            Games.putIfAbsent(roomId, Game(till))
            ctx.json(object { var room = roomId })
        }

        get(specials.routeOne.name) { ctx ->
            ctx.html(specials.routeOne.response)
        }

        get(specials.routeTwo.name) { ctx ->
            val pathParam = ctx.pathParam("answer").trim()
            if (pathParam.contentEquals("20")) {
                ctx.result(specials.routeTwo.response )
            } else {
                ctx.result("Hmm not quite right..")
            }
        }

        ws("/join/:room") { ws ->
            ws.onConnect { session ->
                val pathParam = session.pathParam("room").trim()
                val game = Games.getOrPut(pathParam, { Game(27) })

                if (game == null) {
                    session.send("ERROR: Session not found")
                    session.disconnect()
                } else if (game.players.size > 1) {
                    session.send("ERROR: Session is full")
                    session.disconnect()
                } else {
                    var name = if (game.players.size > 0) "player2" else "player1"
                    if (session.queryString() != null) {
                        var potentialName = session.queryParam("name")
                        if (potentialName != null && potentialName.isNotEmpty() && !game.players.any { it.component2().name.contentEquals(potentialName) }) {
                            name = potentialName
                        }
                    }
                    println(name)

                    game.players.put(session, Player(name))
                }
            }

            // TODO: Broadcast disconnect message
            ws.onClose { session, status, message ->
                val pathParam = session.pathParam("room")?.trim()
                val game = Games.get(pathParam)

                println("Here")
                if (game != null) {
                    game.players.remove(session)
                    if (game.players.size == 0) {
                        println("Destroying game session")
                        Games.remove(pathParam)
                    }
                }
            }

            ws.onMessage { session, message ->
                val pathParam = session.pathParam("room")?.trim()
                val game = Games.get(pathParam)

                if (game == null) {
                    session.send("ERROR: Cannot find room")
                    session.disconnect()
                } else {
                    synchronized(game) {
                        game.handleMessage(session, message)
                    }
                }
            }
        }
    }.start(8000)
}