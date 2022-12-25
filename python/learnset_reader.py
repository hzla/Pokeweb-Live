import code 
import copy
import re
import rom_data
import tools

# code.interact(local=dict(globals(), **locals()))

def output_learnsets_json(narc, rom_name):
	tools.output_json(narc, "learnsets", to_readable, rom_name)

def to_readable(raw, file_name, base=5):
	readable = copy.deepcopy(raw)
	readable['index'] = file_name

	max_moves = 25

	if base == 4:
		max_moves = 20

	for n in range(max_moves):
		if f'move_id_{n}' in readable:
			readable[f'move_id_{n}'] = rom_data.MOVES[raw[f'move_id_{n}']]
			readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']
	return readable



