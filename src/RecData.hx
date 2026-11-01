package mods.records;

/** The six heroes and the nine Ultimate Rampage maps, in the order the board shows them. */
class RecData {
	/** GameMaster hero ids, their constants (for the default skin) and the names the game shows. */
	public static var HERO_IDS:Array<Int> = [101, 102, 103, 104, 105, 106];

	public static var HERO_CONSTANTS:Array<String> = ["BERSERKER", "RANGER", "SORCERER", "BATTLE_CHEF", "VAMPIRE_HUNTER", "GHOST_SAMURAI"];

	public static var HERO_NAMES:Array<String> = ["BERSERKER", "RANGER", "SORCERER", "BATTLE CHEF", "VAMPIRE HUNTER", "GHOST SAMURAI"];

	/** The maps' node constants (as `Floor.map`), node ids (as the weekly scores) and names. */
	public static var MAPS:Array<String> = [
		"INFINITE_ARENA", "INFINITE_CATACOMBS", "INFINITE_PRISON", "INFINITE_ICE_CAVES", "INFINITE_VILLAGE", "INFINITE_TEMPLE", "INFINITE_DINO",
		"INFINITE_AZTECH", "INFINITE_TRIBAL"
	];

	public static var MAP_IDS:Array<Int> = [50150, 50151, 50153, 50155, 50156, 50158, 50159, 50161, 50162];

	public static var MAP_NAMES:Array<String> = ["ARENA", "BARROWS", "PRISON", "CAVERNS", "BATTLEHEIM", "FROSTGAARD", "DINO PARK", "RUINS", "JUNGLE"];

	/**
	 * The floor whose clear gives the legendary chest, once a week per hero and map. The game counts it
	 * earned when the week's score is above it, as its world map does.
	 */
	public static inline final LEGENDARY_FLOOR = 15;
}
