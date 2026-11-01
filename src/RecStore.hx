package mods.ultimate_records;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/**
 * What the mod remembers between sessions, in its data folder: the deepest floor each hero reached on
 * each Ultimate Rampage map, and the last runs. Saved on every floor, so a crash loses nothing.
 */
class RecStore {
	static inline final FILE = "records.json";

	/** How many finished runs are kept. */
	static inline final KEEP = 10;

	/** The last finished runs, the latest first. */
	public var runs(default, null):Array<RecRun> = [];

	var path:String;

	var log:String->Void;

	/** The deepest floor reached, by `hero:map`. */
	var best:Map<String, Int> = new Map();

	/** The run in progress. */
	var current:Null<RecRun>;

	public function new(folder:String, log:String->Void) {
		path = folder + "/" + FILE;
		this.log = log;
		load();
	}

	public function bestFloor(hero:Int, map:String):Int {
		var floor = best.get(key(hero, map));
		return floor == null ? 0 : floor;
	}

	/** A floor of an Ultimate Rampage run starts. One no deeper than the last starts another run. */
	public function floorEntered(map:String, hero:Int, floor:Int, time:Float):Void {
		if (current != null && (current.map != map || current.hero != hero || floor <= current.floor))
			push();
		if (current == null)
			current = new RecRun(map, hero, floor, time);
		current.floor = floor;
		current.time = time;
		if (floor > bestFloor(hero, map))
			best.set(key(hero, map), floor);
		save();
	}

	/** The run left the dungeon. */
	public function finish():Void {
		if (current == null)
			return;
		push();
		save();
	}

	function push():Void {
		runs.unshift(current);
		if (runs.length > KEEP)
			runs = runs.slice(0, KEEP);
		current = null;
	}

	static function key(hero:Int, map:String):String {
		return hero + ":" + map;
	}

	function load():Void {
		if (!FileSystem.exists(path))
			return;
		try {
			var data:Dynamic = Json.parse(File.getContent(path));
			var saved:Dynamic = data.best;
			for (name in Reflect.fields(saved))
				best.set(name, Std.int(Reflect.field(saved, name)));
			var list:Array<Dynamic> = data.runs;
			for (run in list)
				runs.push(RecRun.read(run));
			if (data.current != null) {
				// The game stopped during that run.
				current = RecRun.read(data.current);
				finish();
			}
		} catch (error:Dynamic) {
			// Set aside, so the next save does not overwrite what it held.
			log("could not read " + FILE + ", set aside as " + FILE + ".bad: " + error);
			best = new Map();
			runs = [];
			current = null;
			FileSystem.rename(path, path + ".bad");
		}
	}

	function save():Void {
		var saved:Dynamic = {};
		for (name in best.keys())
			Reflect.setField(saved, name, best.get(name));
		var list:Array<Dynamic> = [];
		for (run in runs)
			list.push(run.write());
		var data = {
			version: 1,
			best: saved,
			runs: list,
			current: current == null ? null : current.write()
		};
		try {
			File.saveContent(path, Json.stringify(data, null, "\t"));
		} catch (error:Dynamic) {
			log("could not save " + FILE + ": " + error);
		}
	}
}
