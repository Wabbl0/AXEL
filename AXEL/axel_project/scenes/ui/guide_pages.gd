class_name GuidePages
extends RefCounted

const KIND_TEXT := "text"
const KIND_PAYTABLE := "paytable"
const KIND_FREE_SPINS := "free_spins"
const KIND_COMPENDIUM := "compendium"

const RTP_PERCENT := 51
const HIT_RATE_IN_TEN := 4

const FIG_FIGHT_HUD := "fight_hud"
const FIG_GOAL_LADDER := "goal_ladder"
const FIG_MATCH_LINE := "match_line"
const FIG_CASCADE := "cascade"
const FIG_PAYTABLE := "paytable"
const FIG_BET_STEPS := "bet_steps"
const FIG_MULTIPLIER := "multiplier"
const FIG_SKULLS := "skulls"
const FIG_POWERS := "powers"
const FIG_VICE_ORDER := "vice_order"
const FIG_FREE_SPINS := "free_spins"
const FIG_LOCKED := "locked"
const FIG_ODDS := "odds"
const FIG_RARITY := "rarity"
const FIG_COMPENDIUM := "compendium"

const FREE_SPINS_LOCKED_TITLE := "???"
const FREE_SPINS_LOCKED_BLOCKS: Array[Dictionary] = [
	{"figure": FIG_LOCKED},
	{"text": "Something waits past the [b]Vice Round[/b].\n\nReach it once and this page will remember."},
]

const PAGES: Array[Dictionary] = [
	{
		"title": "The Fight",
		"kind": KIND_TEXT,
		"blocks": [
			{"figure": FIG_FIGHT_HUD},
			{"text": "Every fight has a [b]GOAL[/b]. Win that many chips on the grid and the fight is over."},
			{"text": "Each paid spin costs your [b]bet[/b]. Your [b]BALANCE[/b] carries over from fight to fight. A new save starts with 3000 and there is no cap."},
			{"divider": true},
			{"heading": "LOSING"},
			{"text": "If you cannot pay for another spin, [b]you lose[/b]. Losing ends the run and [b]deletes that save[/b]."},
			{"divider": true},
			{"heading": "GOALS GROW"},
			{"figure": FIG_GOAL_LADDER},
			{"text": "GOAL counts every win in full the moment it lands, [b]Vice Round[/b] and [b]Free Spins[/b] included.\n\nGoals grow every fight: 50, 60, 70, 80, 95, 115, 145, 190, 250, 330, then [b]x1.5[/b] for the next fight, and a little more for each fight after that. Every lore item on the true path makes goals a little higher.

[b]Dread[/b] raises every goal too. Each item you pick up adds some (rarer items add more), and each memory adds 10%."},
		],
	},
	{
		"title": "Matching",
		"kind": KIND_TEXT,
		"blocks": [
			{"text": "The grid is [b]5 by 5[/b].\n\nA win is [b]3, 4 or 5[/b] of the same symbol side by side in one [b]row[/b] or one [b]column[/b]. Diagonals do not count unless an item says so. Loose groups never win."},
			{"figure": FIG_MATCH_LINE},
			{"text": "A line of [b]exactly 3[/b] leaves a {wild} [b]Wild[/b] in its middle square. A Wild counts as any symbol, so it can finish the next line."},
			{"divider": true},
			{"heading": "CASCADES"},
			{"figure": FIG_CASCADE},
			{"text": "Winning symbols vanish and everything above them [b]falls down[/b]. Nothing new drops in from the top. If the fall lines up a new match, that wins too. This chain is a [b]cascade[/b].\n\nClearing the whole grid pays nothing extra. The lines that cleared it already paid."},
		],
	},
	{
		"title": "Payouts",
		"kind": KIND_PAYTABLE,
		"blocks": [
			{"text": "What one line is worth for [b]3, 4 or 5[/b] in a row. Every win also grows with your [b]bet[/b] and the [b]multiplier[/b]."},
			{"figure": FIG_PAYTABLE},
			{"text": "The history box lists each win as [b]bet x value x multiplier[/b]."},
		],
	},
	{
		"title": "Bets & Multiplier",
		"kind": KIND_TEXT,
		"blocks": [
			{"heading": "BETS"},
			{"figure": FIG_BET_STEPS},
			{"text": "Use [b]-[/b] and [b]+[/b] between spins, or the keys [b]Q[/b] and [b]R[/b]. The steps are 100, 200, 300, 400, 500 and 1000."},
			{"text": "A bigger bet costs more each spin, but [b]every win grows with it[/b]. GOAL stays the same, so a big bet can end a fight in a few spins. It can also [b]empty your balance[/b] just as fast."},
			{"divider": true},
			{"heading": "MULTIPLIER"},
			{"figure": FIG_MULTIPLIER},
			{"text": "Every paid spin starts at [b]x1[/b]. Each win in a cascade adds [b]+1[/b] for the next win. Long cascades are where the big numbers come from."},
		],
	},
	{
		"title": "Skull Meter & Powers",
		"kind": KIND_TEXT,
		"blocks": [
			{"figure": FIG_POWERS},
			{"text": "[b]Cigarette[/b], [b]Alcohol[/b] and [b]Bloody Hand[/b] are [b]Power symbols[/b]. They pay more than the [b]Normal symbols[/b], and only their wins fill the Skull Meter."},
			{"divider": true},
			{"heading": "SKULL METER"},
			{"figure": FIG_SKULLS},
			{"text": "The Skull Meter has [b]3 steps[/b]. A Power symbol line of 3 fills 1 step, a line of 4 fills 2, a line of 5 fills all 3. It empties after every spin, so it has to fill within one spin."},
			{"divider": true},
			{"heading": "POWERS"},
			{"text": "{hand} [b]BLOODY HAND[/b] turns every symbol of one kind into another kind.\n\n{alcohol} [b]ALCOHOL[/b] drops 1 or 2 Wilds where they help most.\n\n{cig} [b]CIGARETTE[/b] burns away the two most common low symbols."},
			{"text": "Now and then a power [b]wakes up on its own[/b] at the start of a spin."},
		],
	},
	{
		"title": "Vice Round",
		"kind": KIND_TEXT,
		"blocks": [
			{"text": "When the [b]Skull Meter is full[/b], the Vice Round starts after that spin."},
			{"figure": FIG_VICE_ORDER},
			{"text": "No new symbols drop in. Each vice fires [b]once[/b], in order: [b]Bloody Hand[/b], then [b]Alcohol[/b], then [b]Cigarette[/b]. Every line they make pays out, and the winnings bar holds the total until the round ends."},
			{"text": "The Vice Round [b]costs nothing[/b] and it is [b]never a loss[/b]."},
			{"divider": true},
			{"text": "Watch what is left on the grid when it ends."},
		],
	},
	{
		"title": "Free Spins",
		"kind": KIND_FREE_SPINS,
		"blocks": [
			{"text": "If the Vice Round clears every symbol [b]except the Wilds[/b], Free Spins begin."},
			{"heading": "CHOOSE YOUR VICE"},
			{"figure": FIG_FREE_SPINS},
			{"text": "[b]Bloody Hand[/b] gives 4 spins, [b]Alcohol[/b] 5, [b]Cigarette[/b] 8. Fewer spins, higher potential."},
			{"divider": true},
			{"text": "Free Spins play by themselves. Each one starts on a [b]fresh full grid[/b]. A free spin that wins nothing [b]always fires your vice[/b]. A winning one fires it only by chance."},
			{"text": "Filling the Skull Meter within one free spin [b]adds more spins[/b]: +4 for Bloody Hand, +3 for Alcohol, +2 for Cigarette. The meter empties after every free spin, but spins you already won stay."},
			{"text": "All Free Spin wins stay on the bar until the last spin, and every one [b]counts toward GOAL[/b]."},
		],
	},
	{
		"title": "Odds",
		"kind": KIND_TEXT,
		"blocks": [
			{"text": "On average, a spin pays back about [b]{rtp}%[/b] of its bet. That number is the [b]RTP[/b] (return to player)."},
			{"figure": FIG_ODDS},
			{"text": "So plain spins [b]slowly eat your balance[/b]. About [b]{hit} in 10[/b] paid spins win something, but most wins are small."},
			{"divider": true},
			{"text": "GOAL is reached in [b]the big moments[/b]: long lines, cascades with a growing multiplier, power symbols, the Vice Round."},
			{"text": "[b]Items[/b] are how you bend these odds in your favour."},
		],
	},
	{
		"title": "Items",
		"kind": KIND_TEXT,
		"blocks": [
			{"text": "Items lie on the floor of the school as [b]white marks[/b]. Walk close to read one and take it with interact. [b]Taking an item starts a fight[/b], and it is equipped right away if a slot is free."},
			{"divider": true},
			{"heading": "THE ITEM WHEEL"},
			{"text": "Open the item wheel ([b]Tab[/b], Q, R, I, or click Mike) to equip or unequip. You can equip [b]7 items[/b]. Some items add more slots."},
			{"divider": true},
			{"heading": "RARITY"},
			{"figure": FIG_RARITY},
			{"text": "The first item you take in an area makes the items in every [b]untouched area[/b] one rank rarer."},
			{"text": "In a fight, [b]hover an item name[/b] to read it. Its icon pulses each time it does something."},
		],
	},
	{
		"title": "Compendium",
		"kind": KIND_COMPENDIUM,
		"blocks": [
			{"text": "Every item you have ever picked up, [b]in any save[/b]."},
			{"figure": FIG_COMPENDIUM},
		],
	},
]
