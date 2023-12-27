import code 
import copy
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))

def output_personal_json(narc, rom_name):
	tools.output_json(narc, "personal", to_readable, rom_name)

def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)

	readable["index"] = file_name


	
	gen = "6"
	if file_name <= 151:
		gen = "1"
	elif file_name <= 251:
		gen = "2"
	elif file_name <= 386:
		gen = "3"
	elif file_name <= 493:
		gen = "4"
	elif file_name <= 649:
		gen = "5"
	else:
		gen = "6"
	readable["gen"] = gen

	try:
		readable["name"] = rom_data.POKEDEX[file_name].upper()
	except IndexError:
		readable["name"] = "Alt Form"

	try:
		readable["type_1"] = rom_data.TYPES[raw["type_1"]]
	except IndexError:
		return

	readable["type_2"] = rom_data.TYPES[raw["type_2"]]


	readable["item_1"] = rom_data.ITEMS[raw["item_1"]]
	readable["item_2"] = rom_data.ITEMS[raw["item_2"]]
	


	readable["exp_rate"] = rom_data.GROWTHS[raw["exp_rate"]]

	readable["egg_group_1"] = rom_data.EGG_GROUPS[raw["egg_group_1"]]
	readable["egg_group_2"] = rom_data.EGG_GROUPS[raw["egg_group_2"]]

	readable["ability_1"] = rom_data.ABILITIES[raw["ability_1"]]
	readable["ability_2"] = rom_data.ABILITIES[raw["ability_2"]]

	binary_ev = bin(raw["evs"])[2:].zfill(16) 
	index = 16
	ev_yields = ["hp_yield", "atk_yield", "def_yield", "speed_yield", "spatk_yield", "spdef_yield"]

	for ev in ev_yields:
		amount = int(binary_ev[index-2:index],2)
		readable[ev] = amount
		index -= 2

	# convert gen5 specific fields
	if base == 5:
		readable["item_3"] = rom_data.ITEMS[raw["item_3"]]
		readable["ability_3"] = rom_data.ABILITIES[raw["ability_3"]]
		readable["form_sprites"] = "Default"

	return readable


	
