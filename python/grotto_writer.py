import code 
import copy
import sys
import rom_data
import tools


# code.interact(local=dict(globals(), **locals()))

def output_narc(rom,rom_name):
	return tools.output_narc("grottos", rom ,rom_name)

def write_readable_to_raw(file_name, narc_name="grottos"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)


def to_raw(readable):
	raw = copy.deepcopy(readable)

	for version in ["black", "white"]:
		for rarity in ["rare", "uncommon", "common"]:
			for n in range(0,4):
				raw[f'{version}_{rarity}_pok_{n}'] = rom_data.POKEDEX.index(readable[f'{version}_{rarity}_pok_{n}'])
		

	for item_type in ["normal", "hidden"]:
		for rarity in ["superrare", "rare", "uncommon", "common"]:
			for n in range(0,4):
				raw[f'{item_type}_{rarity}_item_{n}'] = rom_data.ITEMS.index(readable[f'{item_type}_{rarity}_item_{n}'].replace("Ã\x83Â©","é").replace('Ã©', 'é'))
	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
