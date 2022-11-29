## Changelog

### 11/24/2022

Add move animation editor and move expansion option

### 11/21/2022

Add experimental kaizo randomizer code

### 11/14/2022

Add trainer class and location info for showdown calc

### 11/13/2022

Showdown Calculator generator implemented

Placeholder data for data expansion removed

Fix bug where editor only reads 20 learnset moves, should now be 25

Fix bug where after using an editor that autocapitalizes data for formatting, it would continue to autocapitalize for every other editor without default capitilzation settings resulting in some editors breaking depending on what you edited beforehand. This caused messed up move data and basically screwed the whole rom preventing it from even exporting (affected editors: evolutions, items, marts, moves)

Fix bug where after deleting a pokemon, the slots above aren't moved down causing issues when adding/removing poks

Fix bug where incorrect evolution method ids were designated as requiring an item, causing certain evolution  methods to not save properly