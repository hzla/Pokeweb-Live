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

	

	#repair renplat
	
	if file_name == 0:
		return readable 
	learnsets = rom_data.RP_LS
	if file_name < 494:
		learnset = learnsets[file_name].split(",")
		moves = open('texts/rp_moves.txt').read().split("\n")

		for n in range(len(learnset)):
			move_name = learnset[n].split(" - ")[1].strip()
			lvl_learned = int(learnset[n].split(" - ")[0])
			
			readable[f'move_id_{n}'] = move_name
			readable[f'lvl_learned_{n}'] = lvl_learned
			readable[f'move_id_{n}_index'] = moves.index(move_name)
	else:
		for n in range(max_moves):
			if f'move_id_{n}' in readable:
				try:
					readable[f'move_id_{n}'] = rom_data.MOVES[raw[f'move_id_{n}']]
				except:
					print(raw[f'move_id_{n}'])
					# code.interact(local=dict(globals(), **locals()))
				readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']

	# end ren plat repait



	# for n in range(max_moves):
	# 	if f'move_id_{n}' in readable:
	# 		try:
	# 			readable[f'move_id_{n}'] = rom_data.MOVES[raw[f'move_id_{n}']]
	# 		except:
	# 			print(raw[f'move_id_{n}'])
	# 			# code.interact(local=dict(globals(), **locals()))
	# 		readable[f'move_id_{n}_index'] = raw[f'move_id_{n}']
	return readable



