package main

import java.io.File
import java.io.IOException;
import java.util.Scanner

fun isSet(cards: Array<Card>): Boolean {
    if (cards.size != 3) {
        throw IllegalArgumentException("Must provide 3 cards to determine a set")
    }

    val c1 = cards[0];
    val c2 = cards[1];
    val c3 = cards[2];

    // Nice
    return (c1.color == c2.color && c1.color == c3.color
            || c1.color != c2.color && c1.color != c3.color && c2.color != c3.color)
            && (c1.shape == c2.shape && c1.shape == c3.shape
            || c1.shape != c2.shape && c1.shape != c3.shape && c2.shape != c3.shape)
            && (c1.fill == c2.fill && c1.fill == c3.fill
            || c1.fill != c2.fill && c1.fill != c3.fill && c2.fill != c3.fill)
            && (c1.num == c2.num && c1.num == c3.num
            || c1.num != c2.num && c1.num != c3.num && c2.num != c3.num)
}


// See note in app.ket
// This is potentially useful for specific dynamic routing though. Maybe worth exploring
class Specials (val routeOne: SpecialsMember, val routeTwo: SpecialsMember) {
    companion object {
        fun loadSpecials (): Specials {
            val result = StringBuilder("")

            //Get file from resources folder
            val classLoader = Specials::class.java.getClassLoader()
            val file = File(classLoader.getResource("specials.json").getFile())

            try {
                val scanner = Scanner(file)

                while (scanner.hasNextLine()) {
                    val line = scanner.nextLine()
                    result.append(line).append("\n")
                }

                scanner.close()

            } catch (e: IOException) {
                e.printStackTrace()
            }

            try {
                return mapper.readValue(result.toString(), Specials::class.java)
            } catch (e: Exception) {
                println("Got an error marshalling specials class from specials text: ")
                println(e.localizedMessage)
                return Specials(SpecialsMember("foo", "bar"), SpecialsMember("Bar", "Baz"))
            }

        }
    }
}

class SpecialsMember (val name: String, val response: String)

