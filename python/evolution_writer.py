import code 
import copy
import sys
import rom_data
import tools


# code.interact(local=dict(globals(), **locals()))

def output_narc(rom,rom_name):
	return tools.output_narc("evolutions",rom, rom_name)
	
def write_readable_to_raw(file_name, narc_name="evolutions"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

def to_raw(readable):
	raw = copy.deepcopy(readable)

	for n in range(0,7):
		
		raw[f'method_{n}'] = rom_data.METHODS.index(readable[f'method_{n}'])
		
		if readable[f'target_{n}'].upper() in rom_data.POKEDEX:
			raw[f'target_{n}'] = rom_data.POKEDEX.index(readable[f'target_{n}'].upper())
		else:
			raw[f'target_{n}'] = 0

		if raw[f'method_{n}'] in [6,8,17,18,19,20]:
			raw[f'param_{n}'] = rom_data.ITEMS.index(raw[f'param_{n}'].replace("Ã\x83Â©","é").replace('Ã©', 'é'))
		elif raw[f'method_{n}'] == 21:
			raw[f'param_{n}'] = rom_data.MOVES.index(readable[f'param_{n}'].upper())
		elif raw[f'method_{n}'] == 22:
			raw[f'param_{n}'] = rom_data.POKEDEX.index(readable[f'param_{n}'].upper())
		else:
			raw

	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))
	
