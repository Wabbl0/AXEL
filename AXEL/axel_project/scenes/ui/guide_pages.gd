class_name GuidePages
extends RefCounted

const KIND_TEXT := "text"
const KIND_PAYTABLE := "paytable"
const KIND_FREE_SPINS := "free_spins"
const KIND_COMPENDIUM := "compendium"

const RTP_PERCENT := 73
const HIT_RATE_IN_TEN := 4

const FREE_SPINS_LOCKED_TITLE := "???"
const FREE_SPINS_LOCKED_BODY := "Something waits past the Vice Round.\n\nReach it once and this page will remember."

const PAGES: Array[Dictionary] = [
	{
		"title": "The Fight",
		"kind": KIND_TEXT,
		"body": "Every fight has a GOAL. Win that many chips on the board and the fight is over.\n\nEach paid spin costs your bet. Your BALANCE carries over from fight to fight. A new save starts with 1000 and there is no cap.\n\nIf you cannot pay for another spin, you lose. Losing ends the run and deletes that save.\n\nGOAL counts every win in full the moment it lands, Vice Round and Free Spins included.\n\nGoals grow: 100, then 150, then 225, then x1.5 for each fight after that. Every lore item on the true path makes goals a little higher.",
	},
	{
		"title": "Matching",
		"kind": KIND_TEXT,
		"body": "The board is 5 by 5.\n\nA win is 3, 4 or 5 of the same symbol side by side in one row or one column. Diagonals do not count unless an item says so. Loose groups never win.\n\nWinning symbols vanish and everything above them falls down. Nothing new drops in from the top. If the fall lines up a new match, that wins too. This chain is a cascade.\n\nA line of exactly 3 leaves a Wild in its middle square. A Wild counts as any symbol, so it can finish the next line.\n\nClearing the whole board pays nothing extra. The lines that cleared it already paid.",
	},
	{
		"title": "Payouts",
		"kind": KIND_PAYTABLE,
		"body": "What one line is worth for 3, 4 or 5 in a row. Every win also grows with your bet and the multiplier.",
		"footer": "The history box lists each win as bet x value x multiplier.",
	},
	{
		"title": "Bets & Multiplier",
		"kind": KIND_TEXT,
		"body": "BETS\nUse - and + between spins. The steps are 100, 200, 300, 400, 500 and 1000.\n\nA bigger bet costs more each spin, but every win grows with it. GOAL stays the same, so a big bet can end a fight in a few spins. It can also empty your balance just as fast.\n\nMULTIPLIER\nEvery paid spin starts at x1. Each win in a cascade adds +1 for the next win. Long cascades are where the big numbers come from.",
	},
	{
		"title": "Skull Meter & Powers",
		"kind": KIND_TEXT,
		"body": "Cigarette, Alcohol and Bloody Hand are power symbols. They pay more than the others, and their lines feed the skull.\n\nThe skull meter has 3 parts. A line of 3 fills 1 part, a line of 4 fills 2, a line of 5 fills all 3.\n\nBLOODY HAND turns every symbol of one kind into another kind.\nALCOHOL drops 1 or 2 Wilds where they help most.\nCIGARETTE burns away the two most common low symbols.\n\nNow and then a power wakes up on its own at the start of a spin.",
	},
	{
		"title": "Vice Round",
		"kind": KIND_TEXT,
		"body": "When the skull meter is full, the Vice Round starts after that spin.\n\nNo new symbols drop in. Each vice fires once, in order: Bloody Hand, then Alcohol, then Cigarette. Every line they make pays out, and the winnings bar holds the total until the round ends.\n\nThe Vice Round costs nothing and it is never a loss.\n\nWatch what is left on the board when it ends.",
	},
	{
		"title": "Free Spins",
		"kind": KIND_FREE_SPINS,
		"body": "If the Vice Round clears every symbol except the Wilds, Free Spins begin.\n\nChoose your vice: Bloody Hand gives 4 spins, Alcohol 5, Cigarette 8. Fewer spins, higher potential.\n\nFree Spins play by themselves. Each one starts on a fresh full board. A free spin that wins nothing always fires your vice. A winning one fires it only by chance.\n\nFilling the skull meter during Free Spins adds more spins: +4 for Bloody Hand, +3 for Alcohol, +2 for Cigarette.\n\nAll Free Spin wins stay on the bar until the last spin, and every one counts toward GOAL.",
	},
	{
		"title": "Odds",
		"kind": KIND_TEXT,
		"body": "On average, a spin pays back about {rtp}% of its bet. That number is the RTP (return to player).\n\nSo plain spins slowly eat your balance. About {hit} in 10 paid spins win something, but most wins are small.\n\nGOAL is reached in the big moments: long lines, cascades with a growing multiplier, power symbols, the Vice Round.\n\nItems are how you bend these odds in your favour.",
	},
	{
		"title": "Items",
		"kind": KIND_TEXT,
		"body": "Items lie on the floor of the school as white marks. Walk close to read one and take it with interact. Taking an item starts a fight, and it is equipped right away if a slot is free.\n\nOpen the item wheel (Tab, Q, R, I, or click Mike) to equip or unequip. You can equip 7 items. Some items add more slots.\n\nRarity: ◇ Common, ◈ Uncommon, ◆ Rare, ★ Epic, ✦ Legendary.\n\nThe first item you take in an area makes the items in every untouched area one rank rarer.\n\nIn a fight, hover an item name to read it. Its icon pulses each time it does something.",
	},
	{
		"title": "Compendium",
		"kind": KIND_COMPENDIUM,
		"body": "Every item you have ever picked up, in any save.",
	},
]
