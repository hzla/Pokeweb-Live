
# Pokeweb: GenV Rom Editor & Showdown Calc Generator
<p align="center">
    <img src="https://i.imgur.com/CP232tv.png" width="auto" height="400">
</p>

## Changelog

### 11/14/2022

Add trainer class and location info for showdown calc

### 11/13/2022

Showdown Calculator generator implemented

Placeholder data for data expansion removed

Fix bug where editor only reads 20 learnset moves, should now be 25

Fix bug where after using an editor that autocapitalizes data for formatting, it would continue to autocapitalize for every other editor without default capitilzation settings resulting in some editors breaking depending on what you edited beforehand. This caused messed up move data and basically screwed the whole rom preventing it from even exporting (affected editors: evolutions, items, marts, moves)

Fix bug where after deleting a pokemon, the slots above aren't moved down causing issues when adding/removing poks

Fix bug where incorrect evolution method ids were designated as requiring an item, causing certain evolution  methods to not save properly

## Features

Pokeweb is currently able to edit map headers, items, personals, level-up learnsets, tm/tutor learnsets, tms, moves, encounters, trainers, evolutions, marts, and grottos, alternate forms, and can search/view text banks.

To be implemented editors are texts, battle subway trainers, PWT trainers, tutor moves, and OW events. 

Not thoroughly bug tested, was originally made for personal use, use at your own risk.



### [Quick Feature Tour](https://streamable.com/cjk04j)
### [Calc Export Demo](https://streamable.com/0ym3uy)



You can join this Pokemon DS Rom Hacking discord server for updates as well as general support for your Pokemon gen IV/V rom hacking needs. [https://discord.gg/cTKQq5Y](https://discord.gg/cTKQq5Y)
## Windows Installation 

### [FRESH INSTALLATION DEMONSTRATION VIDEO](https://streamable.com/833yr6)

If you do not know what python and/or ruby is, please watch the installation demo video that shows an example windows install. 

Click the WINDOWS_INSTALL.bat file which will run the included ruby and python installers. 

If you already are using ruby >2.6 and python > 3.6, you can skip to the next step.

Open the Pokeweb folder in powershell or cmd and run 

	$ bundle install

followed by
	
   	 $ pip install ndspy
	 
You can now start the server with 

	$ ruby routes.rb


The Pokeweb server can also be started by clicking and running Pokeweb_Windows.bat. You should be able to view Pokeweb on localhost:4567 in your browser.


### Manual Windows Install

If you are running into issues, try manually installing by clicking and running the ruby and python installers individually. Make sure both versions are in use. If the included installers fail, you can download download windows ruby installer [here](https://rubyinstaller.org/downloads/) and python installer [here](
).
You can check your version by typing 

 	$ ruby -v
and 
	$ python -V

Next, navigate to the Pokeweb root folder in cmd or powershell and run

	$ bundle install

followed by
	
    $ pip install ndspy

If the above steps succeed the server can now be run by running 

	$ ruby routes.rb

or by clicking and running Pokeweb_Windows.bat

## Mac OS Installation

Mac OS already comes with both ruby and python but you will need to update them to newer versions to run Pokeweb if you don't already have ruby >2.6 and python > 3.6. 

The easiest way to do this is to install [Homebrew](https://brew.sh/).
And then to follow these guides to update ruby and python.

[Installing Ruby on MacOS](https://stackify.com/install-ruby-on-your-mac-everything-you-need-to-get-going/)

[Installing Python on MacOS](https://opensource.com/article/19/5/python-3-default-mac)

Once they are installed, navigate to the project folder in Terminal.app 


	$ bundle install

followed by
	
    $ pip install ndspy

If the above steps succeed the server can now be run by running 

	$ ruby routes.rb



## Getting Started

Place any roms you wish to edit in root folder of Pokeweb and they should show up in the Load Rom dropdown on the homepage. Make sure the rom name does not contain special characters or spaces. Loading a rom will take you to the a map headers list for the rom while the rest of the editors load in the background. Clicking on a tab before it is loaded will cause an error. This can take anywhere between 5-15 seconds. In the future you can select an already loaded rom in the Load Project dropdown.

The rest is pretty simple.
![#1abc9c](https://via.placeholder.com/15/1abc9c/000000?text=+)Any thing this color can be clicked to be edited. 

If you make an invalid edit the border will turn <span style="color: #ff5555">red</span>, otherwise, your edits are saved automatically. 

To view a history of your edits, go to the Logs tab in the navbar on the rop right.

Quick Tip: If you want to save time on exporting roms, you can open the session_settings.json file in the root folder after loading a rom. 
If you change "output_arm9": true to  "output_arm9": false, you can save about 5 seconds in rom export time. The arm9 is only used for editing TMs and if you want to enable TM editing again, you can change it back to "output_arm9": true.

## Carrying Over Rom Data To Newer Releases

After downloading a newer release of Pokeweb, export your current project data using the export link in the navbar. Copy the ROM from the "exports" folder in the old release of Pokeweb into the root folder of the newer release of Pokeweb. You can load the rom as usual from there. 


## Showdown Calculator (experimental)

Clicking Battle Calculator will export data and take you to a custom fork of the showdown battle calculator. Pokemon changes (bst, typing, nature, abilities), and move changes (base power, typing, multihit) and trainer sets are auto imported. Changes sometimes require hard refreshing (cntrl + shift + r) the browser before they appear.

Sets will autopopulate with Level, Trainer Class, Trainer Name, and Location encountered in the game if the trainer uses a trainer script (script 3000 + trainer_id for singles, 5000 + trainer_id for doubles). This means trainers that utilize non global scripts to start battles will not have their location shown (ex. gym leaders).

If you have added trainer classes or trainer names, please add the files the "trainer_classes_{ROM_NAME}.txt" and "trainer_names_{ROM_NAME}.txt" to "Pokeweb/Reference_Files". For example, if your rom name is "white.nds", replace ROM_NAME with "white" These files should include a line separated list of trainer names and classes. This data can be found in file 382 and 383 in the game text banks using your gen 5 text editor of choice. Otherwise, the calculator will default to vanilla names/classes. Files will need to be added prior to loading a rom in Pokeweb.  
Additional settings can be found in pokeweb/calculator_settings.json.

```
// pokeweb will only export sets that match these conditions

{
	"min_ivs": 0, // 0 - 255
	"has_items": [0,1], // [0] for no, [1] for yes, [0,1] for both
	"has_moves": [0,1], // [0] for no, [1] for yes, [0,1] for both
	"battle_types": ["Singles", "Doubles", "Triples", "Rotation"], // "Singles", "Doubles", "Triples", "Rotation"
	"ai_values": [7,135]
}
```


If you would like to share the calculator after importing your set data, you can send the public/dist folder and anyone can run the calculator by runnning index.html in their browser. 

## Smart Randomizer Functions (made for dev use)


Assumes basic programming knowledge and fairy implementation on base rom. Navigate to root pokeweb folder in cmd/terminal/powershell. Run
```
 irb -r ./routes.rb
```
to start ruby console. 

### Team Creation

```
Randomizer.create_team [BST_LOW, BST_HIGH], NUM_POKS, [TYPE1, TYPE2], LEVEL
```
The above will generate a random pokemon team within the bst range, with the number of pokemon specified in NUM_POKS, and with movesets scaled to LEVEL. Types can be either an array of Capitalized types, or the string "all".

Example 
```
Randomizer.create_team [240,400], 2, ["Fire"], 16
```
```
[
  {
    "name": "CYNDAQUIL",
    "index": 155,
    "via_player": 1.0,
    "via_ai": 1.0,
    "via_player_gym_1": 1.0,
    "via_player_gym_2": 1.0,
    "via_player_gym_3": 1.0,
    "via_player_gym_4": 1.0,
    "via_player_gym_5": 1.0,
    "via_player_gym_6": 1.0,
    "via_player_gym_7": 1.0,
    "via_player_gym_8": 1.0,
    "types": [
      "Fire",
      "None"
    ],
    "modified_bst": 247.4,
    "modified_bst_physical": 243.4,
    "modified_bst_special": 251.4,
    "can_be_mixed": true,
    "physical_ok": true,
    "special_ok": true,
    "item": "lifeorb",
    "moves": [
      "FLAME BURST",
      "NATURE POWER",
      "LEAF TORNADO",
      "SCORCHING SANDS"
    ]
  },
  {
    "name": "Rotom-Heat",
    "index": 692,
    "via_player": 1.0,
    "via_ai": 1.0,
    "via_player_gym_1": 1.0,
    "via_player_gym_2": 1.0,
    "via_player_gym_3": 1.0,
    "via_player_gym_4": 1.0,
    "via_player_gym_5": 1.0,
    "via_player_gym_6": 1.0,
    "via_player_gym_7": 1.0,
    "via_player_gym_8": 1.0,
    "types": [
      "Electric",
      "Fire"
    ],
    "modified_bst": 429.40000000000003,
    "modified_bst_physical": 389.40000000000003,
    "modified_bst_special": 429.40000000000003,
    "can_be_mixed": false,
    "physical_ok": true,
    "special_ok": null,
    "item": "focussash",
    "moves": [
      "FIRE PUNCH",
      "SPARK",
      "PAIN SPLIT",
      "CHARGE"
    ]
  }
]
```
### Encounter Generation

```
Randomizer.create_encounter [BST_LOW, BST_HIGH], LEVEL, TYPES
```

The following creates a pool of 24 pokemon, 6 at the upper bst_range, 12 in the mid, and 6 in the low. BST for unevolved pokemon are scaled to their evolutions depending on LEVEL provided. 


### Other info

Randomizer settings are in json files Pokeweb/randomizer. The variable "via_player", adjusts how the randomizer adjusts a pokemon's bst before deciding whether or not to allow it as an encounter.


The variable "via_ai" adjusts how the randomizer adjusts a pokemon's bst before deciding if it fits a particular trainer. 1.0 is the default value. 0.0 will result in that option never being selected (default value for pokestudio mons, moves the ai doesn't know how to use properly, useless abilities).


These viabiility variables are for the randomizer user to customize. 


In theory, a 300bst pokemon with via score 1.1 should match a 330 bst pokemon with via score 1.0. Every ability, move, pokemon, and item has either a via_ai or via_player variable that can be customized by the randomizer user. 


BST in the randomizer is not the same as regular BST. The randomizer subtracts out the weaker offensive stat and slightly devalues deffensives stats, and slightly gives more value to speed stat. If you would like to implement your own methodology of calculating a mon's bst, code is in the modified_bst method in Pokeweb/models/randomizer.rb


The team generator will randomly choose pokemon1, then choose pokemon3 based on typing that is supereffective against mons that are supereffective against pokemon1 and so forth. 


The moveset generator will first determine how powerful moves generally should be by looking at the level and bst specified. It will then generally try to find stab moves, then sometimes status moves. Then fill the rest with coverage moves (moves that are supereffective against types that are supereffective against itself). Only status moves are limited to the pokemon's learnset.


All randomizer algorithms are in Pokeweb/models/randomizer.rb. This is where adjustments to the team/encounter/move generator algs can be made.


## Advanced Usage

Upon loading a rom, narc contents are parsed into a more readable format and stored in projects/ROM_NAME/json.
Every json file has a "raw" section and "readable" section.
The "raw" section is data taken straight from the narc and converted into an integer.
The "readable section is the "raw" data converted into a format more understandable to the user. (ex. 1 becomes "Bulbasaur")

You can write your own tools to manipulate the json data as long as you do not change the file locations and validate the inputs yourself.
Json files can have their "readable" data copied over to the "raw" section by running the respective *_writer.py file in the command line 

	$ python python/NARC_NAME_writer.py update FILE_NAME

Data from the "raw" sections can be output to the Narcs, and saved into a rom by running the rom_saver.py file from the command line.

	$ python python/rom_saver.py ROM_NAME


Similarly, showdown calculators created can be customized by modifying the moves.json, poks.json, and sets.json files in public/dist. Just follow the existing formatting. 
## Contributing

A rough overview of the app detailing what overall structure as well as planned todos can be found in misc/app_info.txt

## Credits

Thanks to kaphotics, andibad, bond697, and kazowar for their posts on the project pokemon forums that helped with much of the format info for the narcs, especially bond697's IDB files.

Thanks to Hello007 for his research into the PID algorithm.

Thanks to turtleisaac for pokeditor src code that let me look up what some of bitfields did what as well for his partial list of move effects. 

Thanks to platinummaster for helping with my text parser algorithm

Thanks to Drayano for his forum post on the hidden grotto narc format.

Thanks to Spike-Eared Pichu for SDSME which helped me obtain some text banks and which I used as reference for the encounter editor.

Thanks to Mero Mero for info on where to find the tm list in the arm9


## License

Pokeweb is released under the [MIT License](https://opensource.org/licenses/MIT).
