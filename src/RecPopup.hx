package mods.records;

import brain.clock.GameClock;
import brain.uI.UIButton;
import dBGlobals.DBGlobal;
import facade.DBFacade;
import mods.api.account.OwnedHero;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;

/**
 * The records board: the game's town popup stretched to a table of the nine Ultimate Rampage maps by
 * the six heroes. Three tabs: this week's floors, from the game's server, with the legendary chests
 * earned and still to earn; the best floors ever; the last runs.
 */
class RecPopup {
	/** The popup's size in its own units; the game shows its popups at `SCALE`. */
	static inline final W = 700.0;

	static inline final H = 470.0;

	static inline final SCALE = 1.8;

	/** The centre of the popup symbol's frame, which the board keeps. */
	static inline final CX = 380.0;

	static inline final CY = 253.0;

	static inline final POPUP_LAYER = 105;

	/** The menu layer that gives Escape to the board. */
	static inline final NAV_LAYER = "ULTIMATE_RECORDS";

	static inline final MARGIN = 36.0;

	static inline final MAP_COLUMN = 118.0;

	static inline final HEADER = 62.0;

	static inline final ROW = 26.0;

	static inline final ICON = 34.0;

	static inline final SMALL_CHEST = 19.0;

	static inline final GOLD = 0xFFCC00;

	static inline final WHITE = 0xFFFFFF;

	static inline final DIM = 0xB8A48C;

	static inline final DAY = 86400000.0;

	static var TABS:Array<String> = ["THIS WEEK", "BEST EVER", "RECENT RUNS"];

	var facade:DBFacade;

	var art:RecArt;

	var store:RecStore;

	var onClose:Void->Void;

	/** The account's heroes by board column, null where the account has not got that hero. */
	var owned:Array<Null<OwnedHero>> = [];

	var holder:Sprite;

	var frame:MovieClip;

	/** The tab being built. */
	var body:Sprite;

	/** Each tab's content, once built. */
	var bodies:Array<Null<Sprite>> = [null, null, null];

	/** The labels of the tab being built, over the rest of it. */
	var texts:Sprite;

	var closeButton:UIButton;

	var tabs:Array<UIButton> = [];

	var open:Bool = true;

	public function new(facade:DBFacade, art:RecArt, store:RecStore, heroes:Array<OwnedHero>, onClose:Void->Void) {
		this.facade = facade;
		this.art = art;
		this.store = store;
		this.onClose = onClose;
		for (i in 0...RecData.HERO_IDS.length)
			owned.push(null);
		for (hero in heroes) {
			var id:Int = hero.classId;
			var column = RecData.HERO_IDS.indexOf(id);
			if (column >= 0)
				owned[column] = hero;
		}

		frame = art.popup();
		layoutFrame();
		frame.scaleX = frame.scaleY = SCALE;
		holder = new Sprite();
		holder.addChild(frame);
		// As the game's popups: a curtain over the town, the board centred over it, Escape to close.
		facade.sceneGraphManager.showPopupCurtain();
		facade.sceneGraphManager.addChild(holder, POPUP_LAYER);
		frame.x = facade.stageRef.stageWidth / 2 - CX * SCALE;
		frame.y = facade.stageRef.stageHeight / 2 - CY * SCALE;
		facade.menuNavigationController.pushNewLayer(NAV_LAYER, close, closeButton);
		show(0);
	}

	public function close():Void {
		if (!open)
			return;
		open = false;
		facade.menuNavigationController.popLayer(NAV_LAYER);
		facade.sceneGraphManager.removeChild(holder);
		facade.sceneGraphManager.removePopupCurtain();
		closeButton.destroy();
		for (tab in tabs)
			tab.destroy();
		onClose();
	}

	/** The town popup, stretched to the board as the game stretches it for its larger popups. */
	function layoutFrame():Void {
		for (name in ["message_label", "left_button", "center_button", "right_button", "content"]) {
			var child = frame.getChildByName(name);
			if (child != null)
				child.visible = false;
		}
		var top = CY - H / 2;
		fit(frame.getChildByName("popup_base"), W, H);
		var base = frame.getChildByName("popup_base");
		base.x = CX;
		base.y = CY;

		var banner = frame.getChildByName("banner_title_label");
		fit(banner, W * 0.7, banner.height * 1.3);
		banner.x = CX;
		banner.y = top - 4;
		var title = RecArt.field(frame, "title_label");
		var format = title.defaultTextFormat;
		format.size = 26;
		format.align = TextFormatAlign.CENTER;
		title.defaultTextFormat = format;
		title.width = W * 0.7;
		title.height = 42;
		title.x = CX - title.width / 2;
		title.y = banner.y - 17;
		title.text = "ULTIMATE RECORDS";

		var cross:MovieClip = cast frame.getChildByName("close");
		cross.x = CX + W / 2 - 6;
		cross.y = top + 8;
		closeButton = new UIButton(facade, cross);
		closeButton.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
		closeButton.releaseCallback = close;

		for (i in 0...TABS.length)
			addTab(i, top);
	}

	/** Scales art to a size, from its own size at scale 1. */
	static function fit(art:DisplayObject, width:Float, height:Float):Void {
		art.scaleX = art.scaleY = 1;
		art.scaleX = width / art.width;
		art.scaleY = height / art.height;
	}

	function addTab(index:Int, top:Float):Void {
		var clip = art.tab();
		clip.x = CX + (index - 1) * 150.0;
		clip.y = top + 56;
		var label = RecArt.field(clip, "label");
		if (label != null)
			label.text = TABS[index];
		frame.addChild(clip);
		var button = new UIButton(facade, clip);
		button.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
		button.selectedFilter = DBGlobal.UI_SELECTED_FILTER;
		button.releaseCallback = function() show(index);
		tabs.push(button);
	}

	/** Shows a tab, built the first time only: the board does not change while it is open. */
	function show(tab:Int):Void {
		for (i in 0...tabs.length) {
			tabs[i].selected = i == tab;
			if (bodies[i] != null)
				bodies[i].visible = i == tab;
		}
		if (bodies[tab] != null)
			return;
		body = new Sprite();
		body.mouseEnabled = false;
		body.mouseChildren = false;
		bodies[tab] = body;
		frame.addChild(body);
		texts = art.labels();
		var top = CY - H / 2;
		if (tab == 0)
			week(top);
		else if (tab == 1)
			ever(top);
		else
			recent(top);
		body.addChild(texts);
	}

	/** This week's floors, as the game's server keeps them for each hero, with the legendary chests. */
	function week(top:Float):Void {
		var floors = weekly();
		var bottom = grid(top, floors, true);
		var counts:Array<String> = [];
		var played = false;
		for (h in 0...floors.length) {
			var earned = 0;
			for (floor in floors[h]) {
				if (floor > RecData.LEGENDARY_FLOOR)
					earned++;
				if (floor > 0)
					played = true;
			}
			counts.push(owned[h] == null ? "-" : earned + "/" + RecData.MAPS.length);
		}
		footer(bottom, "LEGENDARY", counts, true);
		note(bottom + ROW + 6,
			played ? "LEGENDARY CHEST ON FLOOR " + RecData.LEGENDARY_FLOOR + ", ONCE A WEEK PER HERO AND MAP" : "NO ULTIMATE RAMPAGE FLOOR THIS WEEK YET",
			weekLeft());
	}

	/** The deepest floor ever: this mod's records, and this week's from the server. */
	function ever(top:Float):Void {
		var floors = weekly();
		var deepest:Array<String> = [];
		for (h in 0...floors.length) {
			var most = 0;
			for (m in 0...RecData.MAPS.length) {
				var mine = store.bestFloor(RecData.HERO_IDS[h], RecData.MAPS[m]);
				if (mine > floors[h][m])
					floors[h][m] = mine;
				if (floors[h][m] > most)
					most = floors[h][m];
			}
			deepest.push(most > 0 ? "" + most : "-");
		}
		var bottom = grid(top, floors, false);
		footer(bottom, "DEEPEST", deepest, false);
		note(bottom + ROW + 6, "COUNTS THIS WEEK AND EVERY RUN SINCE THIS MOD WAS INSTALLED", "");
	}

	/** The week's score of each hero on each map, by column then row: -1 for a hero the account has not got. */
	function weekly():Array<Array<Int>> {
		var info = facade.dbAccountInfo == null ? null : facade.dbAccountInfo.localFriendInfo;
		var floors:Array<Array<Int>> = [];
		for (h in 0...RecData.HERO_IDS.length) {
			var column:Array<Int> = [];
			for (m in 0...RecData.MAPS.length) {
				var hero = owned[h];
				if (hero == null)
					column.push(-1);
				else if (info == null)
					column.push(0);
				else {
					var id:Int = hero.id;
					column.push(info.getIIAvatarScoreForNode(id, RecData.MAP_IDS[m]));
				}
			}
			floors.push(column);
		}
		return floors;
	}

	/** The table of maps by heroes; returns where it ends. */
	function grid(top:Float, floors:Array<Array<Int>>, chests:Bool):Float {
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var column = (right - left - MAP_COLUMN) / RecData.HERO_IDS.length;
		var headerTop = top + 82;
		var rowsTop = headerTop + HEADER;

		for (h in 0...RecData.HERO_IDS.length) {
			var x = left + MAP_COLUMN + column * h + column / 2;
			heroIcon(h, x, headerTop + ICON / 2, ICON);
			var name = art.text(true, 10, owned[h] == null ? DIM : WHITE, column, TextFormatAlign.CENTER);
			name.multiline = true;
			name.wordWrap = true;
			name.height = 30;
			name.text = RecData.HERO_NAMES[h];
			name.x = x - column / 2;
			name.y = headerTop + ICON + 2;
			texts.addChild(name);
		}

		for (m in 0...RecData.MAPS.length) {
			var y = rowsTop + ROW * m;
			if (m % 2 == 0)
				stripe(left, y, right - left);
			var name = art.text(true, 13, GOLD, MAP_COLUMN, TextFormatAlign.LEFT);
			name.text = RecData.MAP_NAMES[m];
			name.x = left + 8;
			centre(name, y);
			texts.addChild(name);
			var most = 0;
			for (h in 0...floors.length)
				if (floors[h][m] > most)
					most = floors[h][m];
			for (h in 0...floors.length)
				cell(left + MAP_COLUMN + column * h + column / 2, y, floors[h][m], most, chests);
		}
		return rowsTop + ROW * RecData.MAPS.length + 4;
	}

	/** A floor: gold when the row's deepest, with the legendary chest (greyed until earned) this week. */
	function cell(x:Float, y:Float, floor:Int, most:Int, chests:Bool):Void {
		var withChest = chests && floor >= 0;
		var number = art.text(false, 15, floor > 0 && floor == most ? GOLD : floor > 0 ? WHITE : DIM, 44,
			withChest ? TextFormatAlign.RIGHT : TextFormatAlign.CENTER);
		number.text = floor > 0 ? "" + floor : "-";
		number.x = withChest ? x - 40 : x - 22;
		centre(number, y);
		texts.addChild(number);
		if (withChest) {
			var chest = new Sprite();
			chest.x = x + 14;
			chest.y = y + ROW / 2;
			art.chest(SMALL_CHEST, chest, floor > RecData.LEGENDARY_FLOOR, false);
			body.addChild(chest);
		}
	}

	function footer(y:Float, title:String, values:Array<String>, chests:Bool):Void {
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var column = (right - left - MAP_COLUMN) / RecData.HERO_IDS.length;
		var line = new Sprite();
		line.graphics.lineStyle(1.5, GOLD, 0.6);
		line.graphics.moveTo(left, y);
		line.graphics.lineTo(right, y);
		body.addChild(line);
		var label = art.text(true, 11, GOLD, MAP_COLUMN, TextFormatAlign.LEFT);
		label.text = title;
		label.x = left + 8;
		centre(label, y + 2);
		texts.addChild(label);
		for (h in 0...values.length) {
			var x = left + MAP_COLUMN + column * h + column / 2;
			var value = art.text(false, 14, values[h] == "-" ? DIM : WHITE, 50, chests ? TextFormatAlign.RIGHT : TextFormatAlign.CENTER);
			value.text = values[h];
			value.x = chests ? x - 46 : x - 25;
			centre(value, y + 2);
			texts.addChild(value);
			if (chests && values[h] != "-") {
				var chest = new Sprite();
				chest.x = x + 14;
				chest.y = y + 2 + ROW / 2;
				art.chest(SMALL_CHEST, chest, true, false);
				body.addChild(chest);
			}
		}
	}

	/** A line under the table: an explanation on the left, something to watch on the right. */
	function note(y:Float, left:String, right:String):Void {
		var width = W - 2 * MARGIN;
		var text = art.text(false, 10, DIM, width, TextFormatAlign.LEFT);
		text.text = left;
		text.x = CX - W / 2 + MARGIN + 8;
		text.y = y;
		texts.addChild(text);
		if (right == "")
			return;
		var watch = art.text(true, 11, GOLD, width, TextFormatAlign.RIGHT);
		watch.text = right;
		watch.x = CX - W / 2 + MARGIN - 8;
		watch.y = y - 1;
		texts.addChild(watch);
	}

	/** Until the week's rollover, as the game's world map counts it. */
	function weekLeft():String {
		var seconds = GameClock.getTimeToEpoch();
		if (seconds <= 0)
			return "";
		var days = Std.int(seconds / 86400);
		var hours = Std.int((seconds - days * 86400) / 3600);
		var minutes = Std.int((seconds - days * 86400 - hours * 3600) / 60);
		return "NEW WEEK IN " + (days > 0 ? days + "D " + hours + "H" : hours + "H " + minutes + "M");
	}

	/** The last runs, the latest first. */
	function recent(top:Float):Void {
		var left = CX - W / 2 + MARGIN;
		var right = CX + W / 2 - MARGIN;
		var runs = store.runs;
		if (runs.length == 0) {
			var empty = art.text(true, 16, GOLD, W, TextFormatAlign.CENTER);
			empty.text = "NO RUNS YET";
			empty.x = CX - W / 2;
			empty.y = top + 170;
			texts.addChild(empty);
			var hint = art.text(false, 12, WHITE, W - 2 * MARGIN, TextFormatAlign.CENTER);
			hint.text = "Your Ultimate Rampage runs show up here as you play them.";
			hint.x = CX - W / 2 + MARGIN;
			hint.y = top + 205;
			texts.addChild(hint);
			return;
		}
		var columns = [left + 8, left + 230, left + 400, right - 8];
		var heads = ["HERO", "MAP", "FLOOR", "WHEN"];
		var headTop = top + 86;
		for (i in 0...heads.length) {
			var head = art.text(true, 11, GOLD, 150, i == 3 ? TextFormatAlign.RIGHT : TextFormatAlign.LEFT);
			head.text = heads[i];
			head.x = i == 3 ? columns[i] - 150 : columns[i];
			head.y = headTop;
			texts.addChild(head);
		}
		var now = Date.now().getTime();
		for (i in 0...runs.length) {
			var run = runs[i];
			var y = headTop + 24 + ROW * i;
			if (i % 2 == 0)
				stripe(left, y, right - left);
			var h = RecData.HERO_IDS.indexOf(run.hero);
			if (h >= 0)
				heroIcon(h, columns[0] + 11, y + ROW / 2, 22);
			add(art.text(true, 12, WHITE, 190, TextFormatAlign.LEFT), h >= 0 ? RecData.HERO_NAMES[h] : "?", columns[0] + 28, y);
			var m = RecData.MAPS.indexOf(run.map);
			add(art.text(true, 12, GOLD, 160, TextFormatAlign.LEFT), m >= 0 ? RecData.MAP_NAMES[m] : run.map, columns[1], y);
			add(art.text(false, 14, WHITE, 90, TextFormatAlign.LEFT), "FLOOR " + run.floor, columns[2], y);
			if (run.floor > RecData.LEGENDARY_FLOOR) {
				var chest = new Sprite();
				chest.x = columns[2] + 98;
				chest.y = y + ROW / 2;
				art.chest(SMALL_CHEST, chest, true, false);
				body.addChild(chest);
			}
			add(art.text(false, 12, DIM, 150, TextFormatAlign.RIGHT), ago(now - run.time), columns[3] - 150, y);
		}
	}

	function add(label:TextField, text:String, x:Float, rowY:Float):Void {
		label.text = text;
		label.x = x;
		centre(label, rowY);
		texts.addChild(label);
	}

	static function ago(ms:Float):String {
		var minutes = Std.int(ms / 60000);
		if (minutes < 1)
			return "JUST NOW";
		if (minutes < 60)
			return minutes + " MIN AGO";
		if (ms < DAY)
			return Std.int(minutes / 60) + " H AGO";
		var days = Std.int(ms / DAY);
		return days == 1 ? "YESTERDAY" : days + " DAYS AGO";
	}

	/** A hero's icon, its skin's when the account has it, greyed when not. */
	function heroIcon(column:Int, x:Float, y:Float, size:Float):Void {
		var icon = new Sprite();
		icon.x = x;
		icon.y = y;
		var hero = owned[column];
		var skin:Int = hero == null ? 0 : hero.skinId;
		art.hero(RecData.HERO_CONSTANTS[column], skin, size, icon);
		if (hero == null)
			RecArt.grey(icon);
		body.addChild(icon);
	}

	/** A dark band behind every other row, as the game's leaderboards. */
	function stripe(x:Float, y:Float, width:Float):Void {
		var band = new Sprite();
		band.graphics.beginFill(0x000000, 0.22);
		band.graphics.drawRoundRect(x, y, width, ROW, 8, 8);
		band.graphics.endFill();
		body.addChild(band);
	}

	/** Centres a label on a row's height. */
	static function centre(label:TextField, rowY:Float):Void {
		label.y = rowY + (ROW - label.textHeight) / 2 - 2;
	}
}
