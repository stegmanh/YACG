module Utils exposing (partition, isSetList)

import Array
import JsonTypes exposing (Card)


partition : Int -> List a -> List (List a)
partition i list =
    partitionHelper i list []


partitionHelper : Int -> List a -> List (List a) -> List (List a)
partitionHelper i list memo =
    let
        taken =
            List.take i list
    in
        if (List.length taken) == 0 then
            memo
        else if (List.length taken) < i then
            memo ++ [ taken ]
        else
            (memo ++ [ taken ]) ++ (partitionHelper i (List.drop i list) memo)


isSetList : List Card -> Bool
isSetList cards =
    let
        cardsArray =
            Array.fromList cards

        c1 =
            Array.get 0 cardsArray

        c2 =
            Array.get 1 cardsArray

        c3 =
            Array.get 2 cardsArray
    in
        case ( c1, c2, c3 ) of
            ( Just c1_, Just c2_, Just c3_ ) ->
                isSet c1_ c2_ c3_

            _ ->
                False


isSet : Card -> Card -> Card -> Bool
isSet c1 c2 c3 =
    (c1.color
        == c2.color
        && c1.color
        == c3.color
        || c1.color
        /= c2.color
        && c1.color
        /= c3.color
        && c2.color
        /= c3.color
    )
        && (c1.shape
                == c2.shape
                && c1.shape
                == c3.shape
                || c1.shape
                /= c2.shape
                && c1.shape
                /= c3.shape
                && c2.shape
                /= c3.shape
           )
        && (c1.fill
                == c2.fill
                && c1.fill
                == c3.fill
                || c1.fill
                /= c2.fill
                && c1.fill
                /= c3.fill
                && c2.fill
                /= c3.fill
           )
        && (c1.num
                == c2.num
                && c1.num
                == c3.num
                || c1.num
                /= c2.num
                && c1.num
                /= c3.num
                && c2.num
                /= c3.num
           )
