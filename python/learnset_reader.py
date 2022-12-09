import code 
import copy
import re
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))

def output_learnsets_json(narc):
	tools.output_json(narc, "learnsets", to_readable)

def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)
	readable['index'] = file_name

	for n in range(25):
		if f'move_id_{n}' in readable:
			readable[f'move_id_{n}'] = rom_data.MOVES[raw[f'move_id_{n}']]
			readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']
	return readable



