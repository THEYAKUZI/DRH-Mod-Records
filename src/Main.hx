package mods.ultimate_records;

import brain.stateMachine.State;
import brain.stateMachine.StateMachine;
import brain.uI.UIButton;
import dBGlobals.DBGlobal;
import facade.DBFacade;
import mods.api.Context;
import mods.api.Mod;
import mods.api.dungeon.Floor;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import town.HomeState;

/**
 * Ultimate Records: a board in town with each hero's floor on each Ultimate Rampage map, this week
 * (the game's own weekly scores) and ever (kept by this mod from its runs), and the last runs. It
 * opens from a round button under the options button of the town's home screen.
 */
class Main extends Mod {
	/** The Ultimate Rampage maps' constants all start so. */
	static inline final ULTIMATE = "INFINITE_";

	/** Under the home screen's options button, at its scale, in that screen's units. */
	static inline final BUTTON_X = 1861.0;

	static inline final BUTTON_Y = 236.0;

	static inline final BUTTON_SCALE = 1.19;

	static inline final CHEST_SIZE = 40.0;

	/** The town screens' layer. */
	static inline final TOWN_LAYER = 50;

	static inline final KEY_ESCAPE:UInt = 27;

	var ctx:Context;

	var facade:Null<DBFacade>;

	var art:Null<RecArt>;

	var store:RecStore;

	var board:Null<RecPopup>;

	var button:Null<UIButton>;

	var buttonClip:Null<MovieClip>;

	var atHome:Bool = false;

	override public function init(ctx:Context):Void {
		this.ctx = ctx;
		store = new RecStore(ctx.data, ctx.log);
		ctx.onFloorEnter(floorEntered);
		ctx.onTownEnter(store.finish);
		ctx.core.onStateEnter(stateEntered);
		ctx.core.onStateExit(stateExited);
		ctx.onKeyDown(keyDown);
	}

	/** Escape closes the board, and the town does not see it. */
	function keyDown(key:UInt):Bool {
		if (key != KEY_ESCAPE || board == null)
			return false;
		closeBoard();
		return true;
	}

	override public function ready(ctx:Context):Void {
		facade = ctx.core.facade;
		art = new RecArt(facade, function() {
			if (atHome)
				showButton();
		});
	}

	override public function dispose():Void {
		closeBoard();
		hideButton();
		if (art != null)
			art.destroy();
	}

	/** Each floor of an Ultimate Rampage run, with the hero played. */
	function floorEntered(floor:Floor):Void {
		var account = ctx.state.account;
		if (account == null || !StringTools.startsWith(floor.map, ULTIMATE))
			return;
		for (hero in account.inventory.heroes)
			if (hero.id == account.activeAvatarId) {
				var id:Int = hero.classId;
				store.floorEntered(floor.map, id, floor.number, Date.now().getTime());
			}
	}

	function stateEntered(machine:StateMachine, state:State):Void {
		if (Std.isOfType(state, HomeState)) {
			atHome = true;
			showButton();
		}
	}

	function stateExited(machine:StateMachine, state:State):Void {
		if (Std.isOfType(state, HomeState)) {
			atHome = false;
			closeBoard();
			hideButton();
		}
	}

	/** The options button's round frame, its gear swapped for the legendary chest. */
	function showButton():Void {
		if (buttonClip != null || art == null || !art.ready || facade == null)
			return;
		var clip = art.roundButton();
		var up:MovieClip = cast clip.getChildByName("up");
		if (up != null) {
			// The gear is drawn last, over the frame and its gold ring.
			if (up.numChildren > 2)
				up.getChildAt(up.numChildren - 1).visible = false;
			var chest = new Sprite();
			art.chest(CHEST_SIZE, chest, true, true);
			up.addChild(chest);
		}
		clip.x = BUTTON_X;
		clip.y = BUTTON_Y;
		clip.scaleX = clip.scaleY = BUTTON_SCALE;
		facade.sceneGraphManager.addChild(clip, TOWN_LAYER);
		buttonClip = clip;
		button = new UIButton(facade, clip);
		button.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
		button.releaseCallback = openBoard;
	}

	function hideButton():Void {
		if (button != null)
			button.destroy();
		if (buttonClip != null && facade != null)
			facade.sceneGraphManager.removeChild(buttonClip);
		button = null;
		buttonClip = null;
	}

	function openBoard():Void {
		var account = ctx.state.account;
		if (board != null || art == null || facade == null || account == null)
			return;
		board = new RecPopup(facade, art, store, account.inventory.heroes, function() board = null);
	}

	function closeBoard():Void {
		if (board != null)
			board.close();
	}
}
