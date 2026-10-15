# Fight and Dread inner-voice lines (2026-10-15)

Playtest note: combat fights and Dread had no story meaning.

## Lore (user confirmed)

- White dialogue is Mike's own self-conscience (left vague). Red is Axel, only in memory stills and the epilogue. Axel never speaks in the present.
- Fights: Mike faces the regret tied to each memory or item to win it back. The powers (cigarette, alcohol, bloody hand) are his vices.
- Dread: the guilt piling up as he digs. It only goes up.

## Lines (white, once per save)

Before the first fight:

1. Every memory here comes with regret.
2. You want it back? Then face it. Win, and it's yours.
3. And sure, lean on your vices. Smokes, booze, blood. You always do.

Before the first fight after Dread is above 0:

1. That's the guilt piling up.
2. The more you dig up, the harder it gets to face.
3. That's Dread. It only goes up.

"booze" is allowed here (user approved the wording); UI and item text still say "alcohol".

## Build

- `AxelWorld.play_fight_intro_lines()` picks the unseen sets, marks them seen, and plays them on the room's `TopDialogueOverlay` (or a temporary one).
- `AxelRun.enter_world_encounter` awaits it right before the combat wipe. Every floor pickup and memory starts a fight right after adding Dread, so the Dread lines always land on the fight that caused them. If both are unseen, the fight lines play first.
- Seen flags live in `GameManager` flags: `fightIntroSeen`, `dreadIntroSeen` (old saves default to false).
- Combat reads none of this.

## Also

- Epilogue: Axel's line "Yeah, don't want to end like me..." now uses `|other|` (red).
