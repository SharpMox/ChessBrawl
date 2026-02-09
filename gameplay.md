# ChessBrawl — Gameplay Loop

## Game Flow Overview

```mermaid
flowchart TD
    %% ── Menu & King Select ──
    Menu["**MENU**<br/>Start · Quit"]
    KingSelect["**KING SELECT**<br/>Good 3pts · Bad 3pts · Ugly 9pts<br/>Back → Menu"]

    Menu -- Start --> KingSelect
    KingSelect -- Back --> Menu
    KingSelect -- Pick king --> RoundOverlay

    %% ── Placement Phase ──
    RoundOverlay["**ROUND OVERLAY — Placement**<br/>GameState = PLACEMENT<br/><br/>Shows: Round N, wave list preview<br/>Enemies pre-spawned in rows 0-1"]

    subgraph placement_actions [" "]
        direction LR
        PA1["Place King<br/>required, rows 6-7<br/>round 1 or if lost"]
        PA2["Buy & place pieces<br/>rows 6-7, costs points"]
        PA3["Tap placed piece<br/>→ remove & refund<br/>this round only"]
        PA4["Menu → Pause"]
        PA5["Start Round<br/>enabled once King<br/>is on board"]
    end

    RoundOverlay --- placement_actions
    PA5 -- Start Round --> PlayerTurn

    %% ── Wave Active: Player Turn ──
    PlayerTurn["**PLAYER TURN**<br/>1 play per turn · timer running"]

    subgraph player_actions [" "]
        direction LR
        P1["Tap piece → show valid moves<br/>Tap valid cell → move/capture<br/>Tap same piece → deselect<br/>Tap elsewhere → deselect"]
        P2["Drag piece<br/>→ drop on valid cell<br/>ghost preview shown"]
        P3["Skip Turn<br/>→ end turn, no move"]
        P4["Skip Wave<br/>→ auto-capture all enemies<br/>earn their points, end wave"]
        P5["Menu → Pause"]
    end

    PlayerTurn --- player_actions

    subgraph player_effects ["On capture"]
        direction LR
        E1["+points added to score"]
        E2["Floating +N pill"]
        E3["Shake animation"]
    end

    PlayerTurn --- player_effects
    PlayerTurn -- "Pawn reaches row 0" --> PlayerPromo["Auto-promote → Knight or Rook<br/>respawns in player zone rows 6-7"]
    PlayerPromo --> UsedPlay

    PlayerTurn -- "Play used or Skip Turn" --> UsedPlay{" "}
    P4 -- Skip Wave --> WaveEnd

    %% ── Wave Active: Enemy Turn ──
    UsedPlay --> EnemyTurn["**ENEMY TURN — AI**<br/>0.3s select + 0.3s move<br/><br/>Priority:<br/>1. Capture player piece — highest value<br/>2. Advance toward player pieces"]

    subgraph enemy_effects ["On capture of player piece"]
        direction LR
        EE1["Red flash + shake"]
        EE2["'Lost a X' pill"]
    end

    EnemyTurn --- enemy_effects
    EnemyTurn -- "Pawn reaches row 7" --> EnemyPromo["Auto-promote → Knight or Rook<br/>respawns in enemy zone rows 0-1"]
    EnemyPromo --> EnemiesCheck
    EnemyTurn -- "King captured" --> GameOver

    EnemyTurn --> EnemiesCheck{All enemies cleared?}
    EnemiesCheck -- No --> PlayerTurn
    EnemiesCheck -- Yes --> WaveEnd{" "}

    %% ── Wave / Round progression ──
    WaveEnd --> MoreWaves{More waves in round?}
    MoreWaves -- Yes --> WaveTransition["**WAVE TRANSITION**<br/>GameState = WAVE_TRANSITION<br/><br/>Shows: Wave N overlay<br/>New enemies spawn in rows 0-1<br/>Start Wave button"]
    WaveTransition -- Start Wave --> PlayerTurn

    MoreWaves -- No --> MoreRounds{Round < 10?}
    MoreRounds -- Yes --> RoundOverlay
    MoreRounds -- No --> Victory

    %% ── End screens ──
    Victory["**VICTORY!**<br/>Stats: Round, Wave, Moves, Time<br/>Captured & Lost pieces<br/><br/>Restart · Menu"]
    GameOver["**KING DEFEATED!**<br/>Stats: Round, Wave, Moves, Time<br/>Captured & Lost pieces<br/><br/>Restart · Menu"]

    Victory -- Restart --> RoundOverlay
    Victory -- Menu --> Menu
    GameOver -- Restart --> RoundOverlay
    GameOver -- Menu --> Menu

    %% ── Pause overlay ──
    Pause["**PAUSE OVERLAY**<br/>Resume · Finish Wave — only during wave · Abandon → King Select"]
    PA4 --> Pause
    P5 --> Pause
    Pause -- Resume --> PlayerTurn
    Pause -- Finish Wave --> WaveEnd
    Pause -- Abandon --> KingSelect

    %% ── Styles ──
    classDef state fill:#2d2d2d,stroke:#666,color:#fff,font-size:13px
    classDef action fill:#1a3a1a,stroke:#4a4,color:#cfc,font-size:11px
    classDef effect fill:#1a1a3a,stroke:#44a,color:#ccf,font-size:11px
    classDef decision fill:#3a3a1a,stroke:#aa4,color:#ffc,font-size:12px
    classDef endscreen fill:#3a1a1a,stroke:#a44,color:#fcc,font-size:13px
    classDef hidden fill:none,stroke:none,color:none

    class Menu,KingSelect,RoundOverlay,PlayerTurn,EnemyTurn,WaveTransition state
    class PA1,PA2,PA3,PA4,PA5,P1,P2,P3,P4,P5,PlayerPromo,EnemyPromo action
    class E1,E2,E3,EE1,EE2 effect
    class EnemiesCheck,MoreWaves,MoreRounds decision
    class Victory,GameOver,Pause endscreen
    class UsedPlay,WaveEnd hidden
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
