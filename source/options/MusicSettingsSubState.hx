package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;

class MusicSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Music Settings';
		rpcTitle = 'Music Settings Menu'; //for Discord Rich Presence
		
		var option:Option = new Option('Pause:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Tea Time', 'Picnic']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		var option:Option = new Option('Menu:',
			"Select the song for the Main Menu.",
			'menuTheme',
			STRING,
			['None', 'Walk In The Park', 'ShitPosted', 'Kick It To The Curb']);
		addOption(option);
		option.onChange = onChangeMenuTheme;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeMenuTheme()
	{	

		FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuTheme)));
		
		switch(ClientPrefs.data.menuTheme)
		{
			case 'Walk In The Park':
				ClientPrefs.data.mainBPM = 101.970;
			case 'ShitPosted':
				ClientPrefs.data.mainBPM = 116;
			case 'None':
				FlxG.sound.music.volume = 0;
				ClientPrefs.data.mainBPM = 102;
			case 'Kick It To The Curb':
				ClientPrefs.data.mainBPM = 108;
			default:
				ClientPrefs.data.mainBPM = 101.970;
		}

		Achievements.unlock('another-beat');
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState)
		{
			if (ClientPrefs.data.menuTheme == 'None')
				FlxG.sound.music.volume = 0;
			else
				FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuTheme)), 1, true);		
		}
		super.destroy();
	}
}
