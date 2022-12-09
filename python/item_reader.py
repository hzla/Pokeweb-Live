import code 
import copy
import rom_data
import tools

def output_items_json(narc):
	tools.output_json(narc, "items", to_readable)


def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	readable["name"] = rom_data.ITEMS[file_name]

	# CONVERT FIELDS HERE
	return readable



