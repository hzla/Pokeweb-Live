import code 
import copy
import sys
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))

def output_narc(narc_name="learnsets"):
	tools.output_narc("learnsets")

def write_readable_to_raw(file_name, narc_name="learnsets"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	for n in range(25):
		if f'move_id_{n}' in readable:
			
			if readable[f'move_id_{n}'] == "-":
				continue

			if readable[f'move_id_{n}'].split(" ")[0].lower() == "expanded":
				raw[f'move_id_{n}'] = int(readable[f'move_id_{n}'].split(" ")[-1])
			else:
				raw[f'move_id_{n}'] = rom_data.MOVES.index(readable[f'move_id_{n}'])

			#update index info for readable since ruby side only updates the name, not id
			readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']

		if f'lvl_learned_{n}' in readable:
			raw[f'lvl_learned_{n}'] = readable[f'lvl_learned_{n}']
	
	return raw

################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars()
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
