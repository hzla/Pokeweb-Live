import code 
import copy
import sys
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))

def output_narc(narc_name="items"):
	tools.output_narc("items")

def write_readable_to_raw(file_name, narc_name="items"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

def to_raw(readable):
	raw = copy.deepcopy(readable)
	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars()
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	