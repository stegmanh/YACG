package main

enum class Color {
    Purple,
    Green,
    Red
}

enum class Shape {
    Oval,
    Diamond,
    Squiggle
}

enum class Fill {
    None,
    Stripped,
    Solid
}
enum class Num {
    One,
    Two,
    Three
}

data class Card(val color: Color, val shape: Shape, val fill: Fill, val num: Num)

class Deck {
    val cards: ArrayList<Card> = ArrayList()
    val playingCards: ArrayList<Card> = ArrayList()
    var isDeckOver: Boolean = false

    // TODO: Remove in prod
    var foundSet: ArrayList<Card> = ArrayList()

    init {
        // Lol
        Color.values().forEach { color ->
            Shape.values().forEach { shape ->
                Fill.values().forEach { fill ->
                    Num.values().forEach { num ->
                        this.cards.add(Card(color, shape, fill, num))
                    }
                }
            }
        }


        while (!playingCardsHasSet()) {
            cards.shuffle();
            cards.addAll(playingCards)
            playingCards.clear()

            for (i in 0..11) {
                val card = cards.elementAt(i)
                playingCards.add(card)
                cards.remove(card)
            }
        }
    }

    fun playCard(playedCards: Array<Card>): Boolean {
        if (playedCards.size != 3) {
            throw IllegalArgumentException("Need to play at least 3 cards")
        }

        //REMOVE:
        //for (i in 0..2) {
            //playedCards.set(i, foundSet.get(i))
        //}

        if (isSet(playedCards) && playingCards.containsAll(playedCards.asList())) {
            playedCards.forEachIndexed { idx, playedCard ->
                // Maintains the order of the cards..
                val playedCardIdx = playingCards.indexOf(playedCard)
                if (cards.size > 0 && playingCards.size <= 12) {
                    val newCard = cards.elementAt(0)
                    playingCards[playedCardIdx] = newCard
                    cards.remove(newCard)
                } else {
                    playingCards.removeAt(playedCardIdx)
                }
            }

            // Add 3 if there's ever not a set
            while (!playingCardsHasSet()) {
                if (cards.size == 0) {
                    isDeckOver = true
                    break
                } else {
                    for (i in 0..2) {
                        if (cards.size == 0) break
                        val card = cards.elementAt(0)
                        playingCards.add(card)
                        cards.remove(card)
                    }
                }
            }

            return true
        }

        return false
    }

    fun playingCardsHasSet(): Boolean {
        // Technically O(1) ;)
        playingCards.forEachIndexed { firstIdx, firstCard ->
            playingCards.forEachIndexed { secondIdx, secondCard ->
                playingCards.forEachIndexed inner@{ thirdIdx, thirdCard ->
                    if (firstIdx == secondIdx || firstIdx == thirdIdx || secondIdx == thirdIdx) {
                        return@inner
                    }

                    if (isSet(arrayOf(firstCard, secondCard, thirdCard))) {
                        // TODO: Remove here too
                        foundSet.clear()
                        foundSet.add(firstCard)
                        foundSet.add(secondCard)
                        foundSet.add(thirdCard)

                        println(firstCard)
                        println(secondCard)
                        println(thirdCard)
                        return true
                    }
                }
            }
        }

        return false
    }
}

