import code 
import copy
import rom_data
import tools

def output_items_json(narc, rom_name):
	tools.output_json(narc, "items", to_readable, rom_name)


def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)

	readable["name"] = rom_data.ITEMS[file_name]

	# CONVERT FIELDS HERE
	return readable



