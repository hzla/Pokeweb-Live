import code 
import copy
import sys
import rom_data
import tools


# code.interact(local=dict(globals(), **locals()))

def output_narc(rom, rom_name):
	return tools.output_narc("trdata", rom, rom_name)

def write_readable_to_raw(file_name, narc_name="trdata"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	raw["class"] = int(readable["class_id"]) 


	raw["reward_item"] = rom_data.ITEMS.index(raw["reward_item"])
	raw["battle_type_1"] = rom_data.BATTLE_TYPES.index(raw["battle_type_1"])

	for n in range(1, 5):
		raw[f'item_{n}'] = rom_data.ITEMS.index(raw[f'item_{n}'])


	binary_props = ""
	rom_data.TEMPLATE_FLAGS.reverse()
	
	for prop in rom_data.TEMPLATE_FLAGS:
		binary_props += bin(readable[prop])[2:].zfill(1)
	raw["template"] = int(binary_props, 2)

	binary_props = ""
	rom_data.AIS.reverse()
	
	for prop in rom_data.AIS:
		binary_props += bin(readable[prop])[2:].zfill(1)
	raw["ais"] = int(binary_props, 2)

	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
