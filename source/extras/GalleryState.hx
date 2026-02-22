package extras;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import sys.FileSystem;
import backend.Mods;
#if (haxe_exif)
import exif.ExifData;
#end
import haxe.io.Bytes;
import sys.io.File;

import util.AnimOffsetHelper;

class GalleryState extends MusicBeatState
{
    private var images:Array<FlxSprite>;
    private var outlines:Array<FlxSprite>;
    private var currentIndex:Int = 0;
    private var lerpSelected:Float = 0;
    private var _drawDistance:Int = 2;
    private var _lastVisibles:Array<Int> = [];
    private var leftArrow:FlxSprite;
    private var rightArrow:FlxSprite;
    private var infoText:FlxText;
    private var imageScale:Int = 450;
    private var scrollSound:String = "scrollMenu";
    private var displayScales:Array<Float>;
	var leftArrowOffsets:AnimOffsetHelper;
	var rightArrowOffsets:AnimOffsetHelper;

    var holdTime:Float = 0;
    var bg:FlxSprite;

    var ui_tex = Paths.getSparrowAtlas('storyMenu/arrow');

    private var imageTexts:Array<FlxText>;
    private var imageAuthors:Array<String> = [];
    private var imagePrefixes:Array<String> = []; // Add this property

    override function create()
    {
        super.create();

        bg = new FlxSprite().loadGraphic(Paths.image('backGround'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, 0);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        images = [];
        outlines = [];
        displayScales = [];
        imageTexts = [];
        currentIndex = 0;

        loadImages();

        // Make sure lerpSelected matches currentIndex after images are loaded
        lerpSelected = currentIndex;

		leftArrow = new FlxSprite(FlxG.width * 0.1, FlxG.height/2);		
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "idle");
		leftArrow.animation.addByPrefix('press', "press", 24, false);
		leftArrow.animation.play('idle');
		leftArrow.scale.x *= -1;

		rightArrow = new FlxSprite(FlxG.width * 0.9, FlxG.height/2);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'idle');
		rightArrow.animation.addByPrefix('press', "press", 24, false);
		rightArrow.animation.play('idle');

		leftArrowOffsets = new AnimOffsetHelper();
		leftArrowOffsets.addOffset('idle', 0, 0);   
		leftArrowOffsets.addOffset('press', 0, -5);

		rightArrowOffsets = new AnimOffsetHelper();
		rightArrowOffsets.addOffset('idle', 0, 0); 
		rightArrowOffsets.addOffset('press', 0, -5);

        add(leftArrow);
        add(rightArrow);

        infoText = new FlxText(0, FlxG.height - 20, FlxG.width, "");
        infoText.setFormat(null, 16, 0xFFFFFFFF, "center");
        add(infoText);
        updateInfoText();

        updateImagesDisplay();
    }

    private function loadImages():Void {
        var paths:Array<String> = ['assets/shared/images/gallery/'];
        #if MODS_ALLOWED
        if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
            paths.unshift(Paths.mods(Mods.currentModDirectory + '/images/gallery/'));
        paths.unshift(Paths.mods('images/gallery/'));
        #end
    
        for (path in paths) {
            if (!FileSystem.exists(path)) continue;
            try {
                var files = FileSystem.readDirectory(path);
                for (file in files) {
                    var lower = file.toLowerCase();
                    if (!(lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg'))) 
                        continue;
                    var img = new FlxSprite().loadGraphic(path + file);
                    var scale = Math.min(imageScale / img.width, imageScale / img.height);
                    img.setGraphicSize(Std.int(img.width * scale), Std.int(img.height * scale));
                    img.updateHitbox();
    
                    img.antialiasing = ClientPrefs.data.antialiasing;
                    images.push(img);
                    displayScales.push(1);
    
                    var outline = new FlxSprite();
                    outline.makeGraphic(Std.int(img.width) + 6, Std.int(img.height) + 6, FlxColor.WHITE);
                    outlines.push(outline);
    
                    img.visible = false;
                    outline.visible = false;
    
                    add(outline);
                    add(img);
    
                    var author:String = "Unknown Author";
                    try {
                        var filePath = path + file;
                        var bytes = File.getBytes(filePath);
                        #if debug
                        trace('First 16 bytes: ' + [for (k in 0...16) bytes.get(k)]);
                        #end
                        if (bytes.get(0) != 137 || bytes.get(1) != 80 || bytes.get(2) != 78 || bytes.get(3) != 71) {
                            #if debug
                            trace('Not a valid PNG file!');
                            #end
                            continue;
                        }
                    
                        if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
                            #if (haxe_exif)
                            var exif = new ExifData(bytes);
                            if (exif != null && exif.artist != null && exif.artist != "") {
                                author = exif.artist;
                            }
                            #end
                        } else if (lower.endsWith('.png')) {
                            var text = extractPngText(bytes, "Author");
                            if (text != null && text != "") {
                                author = text;
                            } else {
                                var xmpAuthor = extractXMPAuthor(bytes);
                                if (xmpAuthor != null && xmpAuthor != "") {
                                    author = xmpAuthor;
                                }
                            }
                        }
                    } catch (e) {
                        // Ignore errors, fallback to Unknown Author
                    }
                    imageAuthors.push(author);
                
                    var prefix = 'Art By: ';
                    switch(author).toLowerCase() 
                    {
                        case "mikeasked":
                            prefix = 'Meat Rider: ';
                        case "retroaddie":
                            prefix = 'Developer, not a fan: ';
                        case "tyler9":
                            prefix = '';
                        case "the legi discord":
                            prefix = 'Thank You: ';
                        default:
                            prefix = 'Art By: ';
                    }
                    imagePrefixes.push(prefix);
                
                    var txt = new FlxText(0, 0, imageScale, prefix + author);
                    txt.setFormat(null, 18, FlxColor.WHITE, "center");
                    txt.visible = false;
                    imageTexts.push(txt);
                    add(txt);
                
                    // Trace loaded image and author (only in debug)
                    #if debug
                    trace('Loaded image: ' + file + ', ' + prefix + author);
                    #end
                }
            } catch (e) {
                #if debug
                trace('Failed to read directory: ' + path + '\nError: ' + e);
                #end
            }
        }
    
        if (images.length == 0) {
            #if debug
            trace('No images found in any gallery folders!');
            #end
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        lerpSelected = FlxMath.lerp(currentIndex, lerpSelected, Math.exp(-elapsed * 9.6));


		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

        if (images.length > 1)
        {
            if (controls.UI_RIGHT_P) {
                changeSelection(1);
                holdTime = 0;
            }

            if (controls.UI_LEFT_P) {
                changeSelection(-1);
                holdTime = 0;
            }
			if (controls.UI_LEFT)
			{
				leftArrow.animation.play('press', false);
				leftArrowOffsets.applyOffset(leftArrow, 'press');
			}
			else
			{
				leftArrow.animation.play('idle');
				leftArrowOffsets.applyOffset(leftArrow, 'idle');
			}
			if (controls.UI_RIGHT)
			{
				rightArrow.animation.play('press', false);
				rightArrowOffsets.applyOffset(rightArrow, 'press');
			}
			else
			{
				rightArrow.animation.play('idle');
				rightArrowOffsets.applyOffset(rightArrow, 'idle');
            }

            if(controls.UI_LEFT || controls.UI_RIGHT)
                {
                    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                    holdTime += elapsed;
                    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
                    if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                        changeSelection((checkNewHold - checkLastHold) * (controls.UI_RIGHT ? shiftMult : -shiftMult));
                }
        }
        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new ExtraMenuState());
            holdTime = 0;

        }

        updateImagesDisplay();
    }
    

    private function changeSelection(change:Int)
    {
        if (images.length == 0) return;
        currentIndex = FlxMath.wrap(currentIndex + change, 0, images.length - 1);
        FlxG.sound.play(Paths.sound(scrollSound), 0.4);
        updateInfoText();
    }

    private function updateImagesDisplay():Void
    {
        for (i in _lastVisibles)
        {
            if (images[i] != null) images[i].visible = false;
            if (outlines[i] != null) outlines[i].visible = false;
            if (imageTexts[i] != null) imageTexts[i].visible = false;
        }
        _lastVisibles = [];

        var min:Int = Std.int(Math.max(0, Math.floor(lerpSelected - _drawDistance)));
        var max:Int = Std.int(Math.min(images.length, Math.ceil(lerpSelected + _drawDistance + 1)));
        var roundedLerp:Int = Math.round(lerpSelected);
        for (i in min...max)
        {
            var targetScale:Float = (i == roundedLerp) ? 1 : 0.6;

            displayScales[i] = FlxMath.lerp(targetScale, displayScales[i], Math.exp(-FlxG.elapsed * 16));

            var img = images[i];
            var outline = outlines[i];
            var txt = imageTexts[i];
            if (img == null || outline == null || txt == null) continue;

            var offset:Float = i - lerpSelected;

            img.visible = true;
            img.setGraphicSize(Std.int(imageScale * displayScales[i]), Std.int(imageScale * displayScales[i]));
            img.updateHitbox();
            img.x = FlxG.width/2 - img.width/2 + offset * (imageScale * 1.2);
            img.y = FlxG.height/2 - img.height/2;
            img.color = (i == roundedLerp) ? FlxColor.WHITE : FlxColor.fromRGB(126,126,126);

            outline.visible = true;
            var outlineW = Std.int(img.width) + 6;
            var outlineH = Std.int(img.height) + 6;
            if (outline.width != outlineW || outline.height != outlineH)
                outline.makeGraphic(outlineW, outlineH, FlxColor.WHITE);
            outline.x = img.x - 3;
            outline.y = img.y - 3;

            txt.visible = true;
            txt.x = img.x;
            txt.y = img.y + img.height + 8;
            txt.fieldWidth = img.width;
            txt.text = imagePrefixes[i] + imageAuthors[i];

            _lastVisibles.push(i);
        }
    }

    private function updateInfoText():Void
    {
        infoText.text = "Image " + (currentIndex + 1) + " of " + images.length;
    }

    private function extractPngText(bytes:Bytes, keyword:String):String {
        var i = 8;
        while (i < bytes.length) {
            if (i + 8 > bytes.length) break;
            // PNG chunk length
            var length = (bytes.get(i) << 24) | (bytes.get(i+1) << 16) | (bytes.get(i+2) << 8) | bytes.get(i+3);
            var type = bytes.getString(i + 4, 4);
            if (type == "tEXt") {
                var data = bytes.sub(i + 8, length);
                var nul = -1;
                for (j in 0...data.length) {
                    if (data.get(j) == 0) {
                        nul = j;
                        break;
                    }
                }
                if (nul > 0) {
                    var key = data.getString(0, nul);
                    if (key == keyword) {
                        return data.getString(nul + 1, Std.int(length - nul - 1));
                    }
                }
            }
            i += 8 + length + 4; // 8 for length+type, length for data, 4 for CRC
        }
        return null;
    }

    private function extractXMPAuthor(bytes:Bytes):String {
    var i = 8;
    while (i < bytes.length) {
        if (i + 8 > bytes.length) break;
        var length = (bytes.get(i) << 24) | (bytes.get(i+1) << 16) | (bytes.get(i+2) << 8) | bytes.get(i+3);        var type = bytes.getString(i + 4, 4);
        trace("PNG chunk type: " + type + " at offset " + i + " length " + length);
        if (type == "iTXt") {
            var data = bytes.sub(i + 8, length);
            var pos = 0;
            var keywordEnd = -1;
            for (j in pos...data.length) {
                if (data.get(j) == 0) {
                    keywordEnd = j;
                    break;
                }
            }
            if (keywordEnd > 0) {
                var keyword = data.getString(pos, keywordEnd - pos);
                trace("Found PNG iTXt chunk keyword: " + keyword);
                pos = keywordEnd + 1;
                var compressionFlag = data.get(pos);
                trace("Compression flag: " + compressionFlag);
                pos++;
                pos++;
                while (pos < data.length && data.get(pos) != 0) pos++;
                pos++;
                while (pos < data.length && data.get(pos) != 0) pos++;
                pos++;
                if (keyword.indexOf("XML:com.adobe.xmp") != -1 && pos < data.length) {
                    var xmlText:String;
                    if (compressionFlag == 1) {
                        #if (haxe_zip)
                        var compressed = data.sub(pos, data.length - pos);
                        var uncompress = new haxe.zip.Uncompress(-15);
                        xmlText = uncompress.run(compressed);
                        uncompress.close();
                        #else
                        trace("XMP iTXt is compressed, but haxe.zip.Uncompress is not available!");
                        xmlText = "";
                        #end
                    } else {
                        xmlText = data.getString(pos, data.length - pos);
                    }
                    trace("XMP XML found: " + xmlText);
                    var regex = new EReg("<rdf:li>([\\s\\S]*?)</rdf:li>", "");
                    if (regex.match(xmlText)) {
                        return StringTools.trim(regex.matched(1));
                    }
                }
            }
        } else if (type == "tEXt") {
            // Fallback: old tEXt chunk parsing (your existing code)
            var data = bytes.sub(i + 8, length);
            var nul = -1;
            for (j in 0...data.length) {
                if (data.get(j) == 0) {
                    nul = j;
                    break;
                }
            }
            if (nul > 0) {
                var key = data.getString(0, nul);
                if (key == "XML:com.adobe.xmp") {
                    var xmlText = data.getString(nul + 1, length - nul - 1);
                    trace("XMP XML found (tEXt): " + xmlText);
                    var regex = new EReg("<rdf:li>([\\s\\S]*?)</rdf:li>", "");
                    if (regex.match(xmlText)) {
                        return StringTools.trim(regex.matched(1));
                    }
                }
            }
        }
        i += 8 + length + 4; // 8 for length+type, length for data, 4 for CRC
    }
    return null;
}
}
