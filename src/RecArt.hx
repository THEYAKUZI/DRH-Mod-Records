package mods.ultimate_records;

import brain.assetRepository.AssetLoadingComponent;
import brain.assetRepository.SwfAsset;
import brain.uI.UIObject;
import facade.DBFacade;
import gameMasterDictionary.GMSkin;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * The game's art the board is made of: the town popup, tab and round button, the hero and chest icons,
 * and the popup's two fonts (its title's comic one, its message's bold one).
 */
class RecArt {
	static inline final TOWN_SWF = "Resources/Art2D/UI/db_UI_town.swf";

	static inline final ITEMS_SWF = "Resources/Art2D/Icons/Items/db_icons_items.swf";

	static inline final CHEST = "db_items_chests_legendary";

	/** The chest's own size in its symbol, around the symbol's origin. */
	static inline final CHEST_BOX = 104.0;

	static inline final GREYED_ALPHA = 0.45;

	/** The outline of the game's popup text. */
	static inline final OUTLINE = 0x330000;

	public var ready(get, never):Bool;

	var facade:DBFacade;

	var loader:AssetLoadingComponent;

	var town:Null<SwfAsset>;

	var titleFont:String = "_sans";

	var bodyFont:String = "_sans";

	var embedded:Bool = false;

	var items:Null<SwfAsset>;

	/** Runs `loaded` once the town art and the chest are in. */
	public function new(facade:DBFacade, loaded:Void->Void) {
		this.facade = facade;
		loader = new AssetLoadingComponent(facade);
		loader.getSwfAsset(DBFacade.buildFullDownloadPath(TOWN_SWF), function(asset:SwfAsset) {
			var sample = create(asset, "popup");
			var title = sample == null ? null : field(sample, "title_label");
			var body = sample == null ? null : field(sample, "message_label");
			if (title == null || body == null)
				return;
			titleFont = title.defaultTextFormat.font;
			bodyFont = body.defaultTextFormat.font;
			embedded = title.embedFonts;
			town = asset;
			if (ready)
				loaded();
		});
		loader.getSwfAsset(DBFacade.buildFullDownloadPath(ITEMS_SWF), function(asset:SwfAsset) {
			items = asset;
			if (ready)
				loaded();
		});
	}

	function get_ready():Bool {
		return town != null && items != null;
	}

	/** The game's town popup: a frame (`popup_base`), a banner and its title, a close button. */
	public function popup():MovieClip {
		return create(town, "popup");
	}

	/** The round button of the town's options. */
	public function roundButton():MovieClip {
		return create(town, "options_panel_button");
	}

	/** The game's prompt button, used for the tabs. */
	public function tab():MovieClip {
		return create(town, "UI_prompt_button_extended");
	}

	public static function field(clip:MovieClip, name:String):Null<TextField> {
		var child = clip.getChildByName(name);
		return Std.isOfType(child, TextField) ? cast child : null;
	}

	/**
	 * A layer for labels, outlined as the game's popups are: one outline for all of them, as one for
	 * each would cost a render pass per label.
	 */
	public function labels():Sprite {
		var layer = new Sprite();
		layer.mouseEnabled = false;
		layer.mouseChildren = false;
		layer.filters = [new GlowFilter(OUTLINE, 1, 4, 4, 4)];
		return layer;
	}

	/** A label in the popup's title font, or else its message font, to go in `labels()`. */
	public function text(title:Bool, size:Int, color:Int, width:Float, align:TextFormatAlign):TextField {
		var label = new TextField();
		label.selectable = false;
		label.mouseEnabled = false;
		label.embedFonts = embedded;
		label.width = width;
		label.height = size * 1.7;
		var format = new TextFormat(title ? titleFont : bodyFont, size, color);
		format.align = align;
		label.defaultTextFormat = format;
		return label;
	}

	/**
	 * The legendary chest, in a `size` square centred on `into`'s origin, greyed when not `earned`. Its
	 * symbol is a shine looping over the chest through masks, and holds more art beside it, so it is
	 * scaled on the chest's own box and clipped to it. Unless `animated`, it stays on its first frame
	 * and is drawn once into a cached image: the board shows dozens, which would all redraw every frame.
	 */
	public function chest(size:Float, into:Sprite, earned:Bool, animated:Bool):Void {
		var clip = create(items, CHEST);
		if (clip == null)
			return;
		clip.scaleX = clip.scaleY = size / CHEST_BOX;
		var clipMask = new Sprite();
		clipMask.graphics.beginFill(0);
		clipMask.graphics.drawRect(-size / 2, -size / 2, size, size);
		clipMask.graphics.endFill();
		into.addChild(clip);
		into.addChild(clipMask);
		clip.mask = clipMask;
		if (!earned)
			grey(into);
		if (!animated) {
			still(clip);
			into.cacheAsBitmap = true;
		}
	}

	/** Stops a clip and every clip in it on their first frame. */
	static function still(target:DisplayObject):Void {
		if (Std.isOfType(target, MovieClip))
			(cast target : MovieClip).gotoAndStop(1);
		if (Std.isOfType(target, DisplayObjectContainer)) {
			var box:DisplayObjectContainer = cast target;
			for (i in 0...box.numChildren)
				still(box.getChildAt(i));
		}
	}

	/** A hero's round icon: its skin's, else its default skin's. */
	public function hero(constant:String, skinId:Int, size:Float, into:Sprite):Void {
		var gm = facade.gameMaster;
		var skin:GMSkin = skinId > 0 ? gm.getSkinByType(skinId) : null;
		if (skin == null) {
			var gmHero = gm.getHeroByConstant(constant);
			if (gmHero != null)
				skin = gm.getSkinByConstant(gmHero.DefaultSkin);
		}
		if (skin != null)
			icon(skin.UISwfFilepath, skin.IconName, size, into);
	}

	/** Greys out art, as for what is not there yet. */
	public static function grey(target:DisplayObject):Void {
		target.filters = [
			new ColorMatrixFilter([
				0.3, 0.59, 0.11, 0, 0,
				0.3, 0.59, 0.11, 0, 0,
				0.3, 0.59, 0.11, 0, 0,
				  0,    0,    0, 1, 0
			])
		];
		target.alpha = 0.45;
	}

	function icon(swf:String, name:String, size:Float, into:Sprite):Void {
		loader.getSwfAsset(DBFacade.buildFullDownloadPath(swf), function(asset:SwfAsset) {
			var clip = create(asset, name);
			if (clip == null)
				return;
			UIObject.scaleToFit(clip, size);
			into.addChild(clip);
		});
	}

	static function create(asset:SwfAsset, name:String):Null<MovieClip> {
		var type:Dynamic = asset.getClass(name);
		return type == null ? null : cast ASCompat.createInstance(type, []);
	}

	public function destroy():Void {
		loader.destroy();
	}
}
