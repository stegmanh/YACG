module Constants exposing (..)

import Array


randomMessages : Array.Array String
randomMessages =
    Array.fromList
        [ "TEXT_1"
        , "TEXT_2"
        , "TEXT_3"
        , "TEXT_4"
        , "TEXT_5"
        ]


superSpecialPlayer : String
superSpecialPlayer =
    "SPECIAL_PLAYER_ONE"


specialPlayersOne : List String
specialPlayersOne =
    [ "SP11", "SP12" ]


specialPlayersTwo : List String
specialPlayersTwo =
    [ "SP21", "SP22" ]
