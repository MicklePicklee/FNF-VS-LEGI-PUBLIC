@echo off
color 0a
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib remove lime
haxelib remove openfl
haxelib remove flixel
haxelib remove flixel-addons
haxelib remove flixel-tools
haxelib remove hscript-iris
haxelib remove tjson
haxelib remove hxdiscord_rpc
haxelib remove hxvlc
haxelib remove flxanimate
haxelib remove linc_luajit
haxelib remove funkin.vis
haxelib remove grig.audio
echo Finished!
pause