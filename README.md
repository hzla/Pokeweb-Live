
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

Offline Installation is same as default pokeweb except you must also install pyyaml after installing python. Additionaly, if you are on windows, make sure your ruby installation comes with the devkit. https://rubyinstaller.org/downloads/ 

`bundle install`

`python -m pip install ndspy`

`python -m pip install pyyaml`

afterwards, create a file in the root folder with the name `.env`

and add this to it

```
KEY=REPLACE_THIS_WITH_ANY_LONG_STRING_YOU_WANT
MODE=offline
```

the server can then be started with `bundle exec passenger start`

To use the move animation editor, binutils must be installed. https://developer.arm.com/downloads/-/gnu-rm

Pokeweb is released under the [MIT License](https://opensource.org/licenses/MIT).
