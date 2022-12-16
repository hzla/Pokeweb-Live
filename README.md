
# Pokeweb: GenV Rom Editor & Showdown Calc Generator
<p align="center">
    <img src="https://i.imgur.com/CP232tv.png" width="auto" height="400">
</p>

## Features

Pokeweb is currently able to edit map headers, items, personals, level-up learnsets, tm/tutor learnsets, tms, moves, encounters, trainers, overworlds, evolutions, marts, and grottos, and alternate forms. Only supports America/English Roms.

Can export a custom showdown damage calculator, with trainer names,classes,locations, natures, movesets, and held items, taken from the loaded rom.

Can randomize a rom based on settings in pokeweb/randomizer. 

Not thoroughly bug tested, was originally made for personal use, use at your own risk.

[WIKI](https://github.com/hzla/Pokeweb/wiki)



### [Quick Feature Tour](https://streamable.com/cjk04j)
### [Calc Export Demo](https://streamable.com/0ym3uy)

You can join this Pokemon DS Rom Hacking discord server for updates as well as general support for your Pokemon gen IV/V rom hacking needs. [https://discord.gg/cTKQq5Y](https://discord.gg/cTKQq5Y)

## Windows Installation 

### [FRESH INSTALLATION DEMONSTRATION VIDEO](https://streamable.com/833yr6)

If you do not know what python and/or ruby is, please watch the installation demo video that shows an example windows install. 

Click the WINDOWS_INSTALL.bat file which will run the included ruby and python installers. 

If you already are using ruby >2.6 and python > 3.6, you can skip to the next step.

Open the Pokeweb folder in powershell or cmd and run 

	bundle install

followed by
	
   	 pip install ndspy

or if the above doesn't work.

	pip3 install ndspy


You can now start the server with 

	ruby routes.rb


The Pokeweb server can also be started by clicking and running Pokeweb_Windows.bat. You should be able to view Pokeweb on localhost:4567 in your browser.


### Manual Windows Install

If you are running into issues, try manually installing by downloading the latest windows ruby installer [here](https://rubyinstaller.org/downloads/) and python installer [here](https://www.python.org/downloads/).
You can check your version by typing 

 	ruby -v
and 
	python -V

Next, navigate to the Pokeweb root folder in cmd or powershell and run

	bundle install

followed by
	
    pip install ndspy

If the above steps succeed the server can now be run by running 

	ruby routes.rb

or by clicking and running Pokeweb_Windows.bat

## Mac OS Installation

Mac OS already comes with both ruby and python but you will need to update them to newer versions to run Pokeweb if you don't already have ruby >2.6 and python > 3.6. 

The easiest way to do this is to install [Homebrew](https://brew.sh/).
And then to follow these guides to update ruby and python.

[Installing Ruby on MacOS](https://stackify.com/install-ruby-on-your-mac-everything-you-need-to-get-going/)

[Installing Python on MacOS](https://opensource.com/article/19/5/python-3-default-mac)

Once they are installed, navigate to the project folder in Terminal.app 


	bundle install

followed by
	
    pip install ndspy

or if the above doesn't work.

	pip3 install ndspy


If the above steps succeed the server can now be run by running 

	ruby routes.rb


## Getting Started

Place any roms you wish to edit in root folder of Pokeweb and they should show up in the Load Rom dropdown on the homepage. 

**Make sure the rom name does not contain special characters or spaces.**

Loading a rom will take you to the a map headers list for the rom while the rest of the editors load in the background. Clicking on a tab before it is loaded will cause an error. This can take anywhere between 5-15 seconds. In the future you can select an already loaded rom in the Load Project dropdown.

![#1abc9c](https://placehold.co/15x15/1abc9c/1abc9c.png) Any thing this color can be clicked to be edited. 

If you make an invalid edit the border will turn <span style="color: #ff5555">red</span>, otherwise, your edits are saved automatically. 

To view a history of your edits, go to the Logs tab in the navbar on the rop right.

[Wiki](https://github.com/hzla/Pokeweb/wiki) - For More detailed information on the editors check the wiki.

Quick Tip: If you want to save time on exporting roms, you can open the session_settings.json file in the root folder after loading a rom. 

If you change "output_arm9": true to  "output_arm9": false, you can save about 5 seconds in rom export time. The arm9 is only used for editing TMs and if you want to enable TM editing again, you can change it back to "output_arm9": true.

If you would like to expand your move slots and are editing BW2, use expansion_settings.json to set how many extra move slots you would like to provision when loading the rom. Note: You will still need to expand necessary text banks16,402,403,and 488 starting at id 673 for text banks 402, 403, 488 and id 2019 for textbank 16.

If your rom has fairy typing implented change  "fairy": false to "fairy": true, to support fairy typing edits.

## Carrying Over Rom Data To Newer Releases

After downloading a newer release of Pokeweb, export your current project data using the export link in the navbar. Copy the ROM from the "exports" folder in the old release of Pokeweb into the root folder of the newer release of Pokeweb. You can load the rom as usual from there. 


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



Thanks to https://hack64.net/ for the browser patcher. 


## License

Pokeweb is released under the [MIT License](https://opensource.org/licenses/MIT).
