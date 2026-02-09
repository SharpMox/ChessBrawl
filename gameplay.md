# ChessBrawl — Gameplay Loop

## Game Flow Overview

```mermaid
---
config:
  flowchart:
    nodeSpacing: 20
    rankSpacing: 30
    padding: 8
  theme: dark
  themeVariables:
    fontSize: 16px
---
flowchart TD
    Menu(["**MENU** — Start · Quit"]) -- Start --> KS(["**KING SELECT** — Good 3pts · Bad 3pts · Ugly 9pts"])
    KS -- Back --> Menu
    KS -- Pick king --> PL

    subgraph round ["Game Loop — 10 Rounds"]
        PL["**PLACEMENT** — Place King, buy pieces rows 6-7, remove & refund"]
        PL -- Start Round --> PT

        subgraph wave ["Wave Active"]
            PT["**PLAYER TURN** — 1 play, timer running"]
            PT -- "Tap/drag piece → move or capture" --> Move["Execute move"]
            PT -- Skip Turn --> ET
            PT -- Skip Wave --> WE
            Move -- "Capture? +pts, +N pill, shake" --> Move
            Move -- "Pawn row 0 → promote" --> Move
            Move --> ET

            ET["**ENEMY TURN** — AI: 0.3s select + 0.3s move"]
            ET -- "Capture → flash, shake, loss pill" --> Check
            ET -- "King captured" --> GO
            ET -- "No capture / advance" --> Check
            ET -- "Enemy pawn row 7 → promote" --> Check

            Check{All enemies cleared?}
            Check -- No --> PT
            Check -- Yes --> WE{" "}
        end

        WE --> MW{More waves?}
        MW -- Yes --> WT["**WAVE TRANSITION** — spawn enemies, Start Wave"]
        WT --> PT
        MW -- No --> MR{Round < 10?}
        MR -- Yes --> PL
    end

    MR -- No --> V
    V(["**VICTORY!** — Stats, Restart · Menu"])
    GO(["**KING DEFEATED!** — Stats, Restart · Menu"])
    V -- Restart --> PL
    V -- Menu --> Menu
    GO -- Restart --> PL
    GO -- Menu --> Menu

    PL -. Menu .-> Pause
    PT -. Menu .-> Pause
    Pause["**PAUSE** — Resume · Finish Wave · Abandon"]
    Pause -- Resume --> PT
    Pause -- Finish Wave --> WE
    Pause -- Abandon --> KS

    classDef state fill:#2d2d2d,stroke:#666,color:#fff
    classDef decision fill:#3a3a1a,stroke:#aa4,color:#ffc
    classDef endscreen fill:#3a1a1a,stroke:#a44,color:#fcc
    classDef hidden fill:none,stroke:none,color:none
    class PL,PT,ET,WT,Move state
    class Menu,KS,V,GO endscreen
    class Check,MW,MR decision
    class WE hidden
    class Pause state
```

## Round & Wave Progression

| Round | Waves | New Piece | Peak Composition |
|-------|-------|-----------|------------------|
| 1 | 3 | ♟ Pawn | 4♟ |
| 2 | 3 | ♞ Knight | 4♟ 1♞ |
| 3 | 3 | ♝ Bishop | 4♟ 2♞ 1♝ |
| 4 | 5 | — | 4♟ 2♞ 2♝ |
| 5 | 5 | ♜ Rook | 5♟ 2♞ 2♝ 1♜ |
| 6 | 5 | — | 4♟ 3♞ 2♝ 2♜ |
| 7 | 7 | ♛ Queen | 4♟ 3♞ 2♝ 2♜ 1♛ |
| 8 | 7 | — | 4♟ 2♞ 2♝ 2♜ 2♛ |
| 9 | 7 | — | 3♟ 3♞ 2♝ 2♜ 2♛ |
| 10 | 9 | — | 2♟ 2♞ 2♝ 3♜ 3♛ |

## Piece Economy

| Piece | Symbol | Cost / Capture Reward |
|-------|--------|-----------------------|
| King | ♔ | 0 |
| Pawn | ♟ | 1 |
| Knight | ♞ | 3 |
| Bishop | ♝ | 3 |
| Rook | ♜ | 5 |
| Queen | ♛ | 9 |

- **Starting points:** 3 (or 9 with Ugly king)
- Points are spent to place pieces and earned by capturing enemies.
- Captured enemy piece cost is added back to the player's score.

## Grid Layout

- **6 columns × 8 rows**
- **Rows 0–1:** Enemy spawn zone
- **Rows 6–7:** Player placement zone
- Pieces move using standard chess rules (pawns move upward for player, downward for enemy).

## Key Mechanics

- **Pawn promotion:** When a pawn reaches the opposite end (row 0 for player, row 7 for enemy), it auto-promotes to a Knight or Rook (random) and respawns in its owner's starting zone.
- **Spawn capture:** If enemies spawn on a cell occupied by a player piece, that piece is lost.
- **Turn structure:** Player gets 1 move per turn, then the enemy AI gets 1 move. This alternates until the wave ends.
- **Wave end:** A wave ends when all enemies in that wave are captured (or the player uses Skip Wave).
- **Game over:** The game ends immediately if the King is captured (by enemy move or enemy spawn).
