path = 'normal'
characters = {{'thorne', -550, 257, 0}, {'mickle', -425, 511, 3}, {'doddle', -660, 758, 4}, {'paul', 1560, 562, 0}, {'mike', 1730, 420, 0}, {'drak3', 1950, 400, 0}};
donCharacters = {{'cain', -750, 300, 1}, {'oible', -200, 660, 2}, {'neek', 1525, 450, 1}, {'fightmarker', 2050, 340, 3}};

function onCreate()	
		if difficulty ~= null then
		if difficulty == 0 then
			path = 'normal';
		elseif difficulty == 1 then
			path = 'don';
			for i in pairs(donCharacters) do table.insert(characters, donCharacters[i]); end
			characters[4] = {'paul', 1380, 539, 0};
			characters[5] = {'mike', 1700, 400, 1};
			characters[6] = {'drak3', 1890, 380, 1};
		end
	end

	makeLuaSprite('sky', 'stages/park/'.. path ..'/day/sky', -2244.25, -965.85);
	setScrollFactor('sky', 0, 0);

	makeLuaSprite('buildings', 'stages/park/'.. path ..'/day/buildings', -1093.45, -558.8);
	setScrollFactor('buildings', 0.75, 0.75);

	makeLuaSprite('wall', 'stages/park/'.. path ..'/day/wall', -1505.45, 339.95);
	setScrollFactor('wall', 0.925, 0.925);

	makeLuaSprite('middleGround', 'stages/park/'.. path ..'/day/middleGround', -1747.9, -529.85);
	setScrollFactor('middleGround', 1, 1);

	if getProperty('gf.curCharacter') ~= 'gf' then
		makeFlxAnimateSprite('gff', 400, 135, 'characters/gf')
		addAnimationBySymbolIndices('gff', 'l', 'GF Dance', {30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14})
		addAnimationBySymbolIndices('gff', 'r', 'GF Dance', {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29})
		playAnim('gff', 'l', true)
		setScrollFactor('gff', 1, 1);
	end

	setScrollFactor('gf', 1, 1);

	for i in pairs(characters) do makeCharacter(characters[i][1], characters[i][2], characters[i][3], characters[i][4]) end

	if not lowQuality then
		makeLuaSprite('mountains', 'stages/park/'.. path ..'/day/mountains', -2192.4, -255.45);
		setScrollFactor('mountains', 0.25, 0.25);

		makeLuaSprite('backBuildings', 'stages/park/'.. path ..'/day/backBuildings', -667.6, -253.75);
		setScrollFactor('backBuildings', 0.5, 0.5);

		makeLuaSprite('clouds', 'stages/park/'.. path ..'/day/clouds', -1476.5, -394.75);
		setProperty('clouds.velocity.x', 25); -- clouds move
		setScrollFactor('clouds', 1, 1);

		makeLuaSprite('foreGround', 'stages/park/'.. path ..'/day/foreGround', -1776.25, 1125.9);
		setScrollFactor('foreGround', 1.2, 1.2);
	end

	addLuaSprite('sky', false);
	addLuaSprite('mountains', false);
	addLuaSprite('backBuildings', false);
	addLuaSprite('clouds', false);
	addLuaSprite('buildings', false);
	addLuaSprite('wall', false);
	addLuaSprite('middleGround', false);
	addLuaSprite('gff', false)
	addLuaSprite('foreGround', true);
end

function onCreatePost()
	if shadersEnabled == true and path == 'don' then addShader() end
end

function onUpdate(elapsed)
	if not lowQuality then
		if getProperty('clouds.x') > 2117 then -- clouds come back
			setProperty('clouds.x', -4505) -- thank you mr clouds
		end
	end
end

function onStepHit()
	if curStep % 4 == 0 then
		playAnim('gff', 'l', true)
	end
	if curStep % 8 == 0 then
		playAnim('gff', 'r', true)
		for i in pairs(characters) do playAnim(characters[i][1], 'idle', true) end
	end
end

function onCountdownTick(counter)
	if counter % 2 == 0 then
		playAnim('gff', 'r', true)
		for i in pairs(characters) do playAnim(characters[i][1], 'idle', true) end
	else
		playAnim('gff', 'l', true)
	end
end

function addShader()
	initLuaShader('adjustColor')
	shade = {'boyfriend', 'dad', 'gf', 'gff'};
	for i in ipairs(characters) do table.insert(shade, characters[i][1]) end
	for i, object in ipairs(shade) do
    	setSpriteShader(object, 'adjustColor')
    	setShaderFloat(object, 'hue', -30)
    	setShaderFloat(object, 'saturation', 11)
    	setShaderFloat(object, 'contrast', -11)
    	setShaderFloat(object, 'brightness', 12)
	end
end

function makeCharacter(name, x, y, layer)
	makeAnimatedLuaSprite(name, 'stages/park/characters/'.. name, x, y);
	addAnimationByPrefix(name, 'idle', 'idle', 24, false);
	setScrollFactor(name, 1, 1);
	lol = layer + 2;
	if lol > 3 then	lol = 3; end
	setObjectOrder(name, lol);
	addLuaSprite(name, false);
end