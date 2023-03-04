
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

## Installation 

If you are not comfortable debugging ruby/python, and working with a console, it is highly recommended you use the live hosted version instead at [fishbowlweb.cloud:3000](http://fishbowlweb.cloud:3000). If you encounter issues running pokeweb locally, be aware that only limited assistance can be provided. 


Offline Installation is same as default pokeweb except you must also install pyyaml after installing python and requires python >= 3.10. Additionaly, if you are on windows, make sure your ruby installation comes with the devkit. https://rubyinstaller.org/downloads/ 

`bundle install`

`python -m pip install ndspy`

`python -m pip install pyyaml`

afterwards, create a file in the root folder with the name `.env`

and add this to it

```
KEY=REPLACE_THIS_WITH_ANY_LONG_STRING_YOU_WANT
MODE=offline
```
## Starting Server on MACOS or LINUX  

the server can then be started with `bundle exec passenger start` and should be serving on localhost:3000

## Starting Server on Windows

Navigate to your python installation where python.exe is located. Should be in C:/. Make a copy of python.exe and rename it python3.exe.

Start the server with `rackup config.ru` and should be serving on localhost:9292



To use the move animation editor, binutils must be installed. https://developer.arm.com/downloads/-/gnu-rm

Pokeweb is released under the [MIT License](https://opensource.org/licenses/MIT).
