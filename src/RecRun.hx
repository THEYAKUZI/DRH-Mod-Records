package mods.ultimate_records;

/** An Ultimate Rampage run: its map, the hero, the deepest floor reached, and when. */
class RecRun {
	public var map:String;

	/** GameMaster hero id. */
	public var hero:Int;

	public var floor:Int;

	/** When that floor was reached, in milliseconds since 1970. */
	public var time:Float;

	public function new(map:String, hero:Int, floor:Int, time:Float) {
		this.map = map;
		this.hero = hero;
		this.floor = floor;
		this.time = time;
	}

	public static function read(data:Dynamic):RecRun {
		var time:Float = data.time;
		return new RecRun(Std.string(data.map), Std.int(data.hero), Std.int(data.floor), time);
	}

	public function write():Dynamic {
		return {
			map: map,
			hero: hero,
			floor: floor,
			time: time
		};
	}
}
