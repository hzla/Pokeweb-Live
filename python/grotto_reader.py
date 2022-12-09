import code 
import tools
import copy
import rom_data

def output_grottos_json(narc):
	tools.output_json(narc, "grottos", to_readable)

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	readable["name"] = rom_data.GROTTO_NAMES[file_name]

	for version in ["black", "white"]:
		for rarity in ["rare", "uncommon", "common"]:
			for n in range(0,4):
				readable[f'{version}_{rarity}_pok_{n}'] = rom_data.POKEDEX[raw[f'{version}_{rarity}_pok_{n}']]
		
	for item_type in ["normal", "hidden"]:
		for rarity in ["superrare", "rare", "uncommon", "common"]:
			for n in range(0,4):
				readable[f'{item_type}_{rarity}_item_{n}'] = rom_data.ITEMS[raw[f'{item_type}_{rarity}_item_{n}']]

	return readable



	

