package util;

import flixel.FlxSprite;
import haxe.ds.StringMap;

class AnimOffsetHelper {
    public var animOffsets:StringMap<Array<Float>> = new StringMap();

    public function new() {}

    public function addOffset(anim:String, x:Float, y:Float) {
        animOffsets.set(anim, [x, y]);
    }

    public function applyOffset(sprite:FlxSprite, anim:String) {
        var offset = animOffsets.get(anim);
        if (offset != null) {
            sprite.offset.set(offset[0], offset[1]);
        } else {
            sprite.offset.set(0, 0);
        }
    }
}