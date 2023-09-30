import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import json
import sys
import subprocess
from pathlib import Path
import shutil
import csv
import re
import copy
import platform


# getting the name of the directory
# where the this file is present.
current = os.path.dirname(os.path.realpath(__file__))
 
# Getting the parent directory name
# where the current directory is present.
parent = os.path.dirname(current)
 
# adding the parent directory to
# the sys.path.
sys.path.append(parent)

import move_writer
import rom_data

expand_moves = 339
rom_name = "projects/" + sys.argv[1].split(".")[0]

narc_info = {} ##store narc names and file id pairs
with open(f'{rom_name}/session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 

rom_data.set_global_vars(rom_name)


animations_file_path = f'{rom_name}/narcs/move_animations-{narc_info["move_animations"]}.narc'
b_animations_file_path = f'{rom_name}/narcs/battle_animations-{narc_info["battle_animations"]}.narc'

animations = ndspy.narc.NARC.fromFile(animations_file_path)
b_animations = ndspy.narc.NARC.fromFile(b_animations_file_path)




if True: #len(b_animations.files) < 300:
			
	def expand_move_desc(filename, filler_count, n=1, start=560):
		num_newlines = 0
		with open(filename, 'rb+') as f:
			lines = f.readlines()
			actions = [lines[10], lines[14], lines[18]]
			
			f.seek(0, os.SEEK_END)    
			while num_newlines < n:
				f.seek(-2, os.SEEK_CUR)
				if f.read(1) == b'\n':
					num_newlines += 1
			f.truncate()

			for n in range(0,filler_count):
				f.write(bytes(f"# STR_{start}\n", 'utf-8'))
				f.write(bytes("[\"\\n\"]\n", 'utf-8'))
				f.write(bytes("\"$$\"]\n", 'utf-8'))
				f.write(bytes("\n", 'utf-8'))
				start += 1

			with open('Reference_Files/move_desc.txt', 'r') as csvfile:
				moves = csvfile.readlines()
				for row in moves:
					f.write(bytes(f"# STR_{start}\n", 'utf-8'))

					row = row[0:-1]
					row = row.split("\\n")
					for idx, line in enumerate(row):				
						base = f"\"{line}\\n\","
						if idx == 0: 
							base = "[" + base

						if idx == len(row) - 1:
							base = base[0:-4] + "$\"]"

						f.write(bytes(f'{base}\n', 'utf-8'))
					f.write(bytes("\n", 'utf-8'))
					start += 1
			f.write(bytes("END_MSG", "utf-8"))

	def expand_move_actions(filename, filler_count, case="lower", n=1, start=1680):
		num_newlines = 0
		with open(filename, 'rb+') as f:
			lines = f.readlines()
			actions = [lines[10], lines[14], lines[18]]
			
			f.seek(0, os.SEEK_END)    
			while num_newlines < n:
				f.seek(-2, os.SEEK_CUR)
				if f.read(1) == b'\n':
					num_newlines += 1
			f.truncate()

			for n in range(0,filler_count):
				f.write(bytes(f"# STR_{start}\n", 'utf-8'))
				f.write(bytes("[\"!$\"]\n", 'utf-8'))
				f.write(bytes("\n", 'utf-8'))
				start += 1

			with open('Reference_Files/move_names.txt', 'r') as csvfile:
				moves = csvfile.readlines()
				for row in moves:
					row = row[0:-1]
					for i in range(0,3):
						f.write(bytes(f"# STR_{start}\n", 'utf-8'))
						f.write(actions[i])
						f.write(bytes(f"\"{row}!$\"]\n", 'utf-8'))
						f.write(bytes("\n", 'utf-8'))
						start += 1
			f.write(bytes("END_MSG", "utf-8"))

	def expand_move_names(filename, filler_count, case="lower", n=1, start=560):
		num_newlines = 0
		with open(filename, 'rb+') as f:
			f.seek(0, os.SEEK_END)    
			while num_newlines < n:
				f.seek(-2, os.SEEK_CUR)
				if f.read(1) == b'\n':
					num_newlines += 1
			f.truncate()
		
			for n in range(0,filler_count):
				f.write(bytes(f"# STR_{start}\n", 'utf-8'))
				f.write(bytes(f"[\"FILLER {n}$\"]\n", 'utf-8'))
				f.write(bytes("\n", 'utf-8'))
				start += 1

			with open('Reference_Files/move_names.txt', 'r') as csvfile:
				moves = csvfile.readlines()
				for row in moves:
					row = row[0:-1]
					if case == "upper": row = row.upper()
					f.write(bytes(f"# STR_{start}\n", 'utf-8'))
					f.write(bytes(f"[\"{row}$\"]\n", 'utf-8'))
					f.write(bytes("\n", 'utf-8'))
					start += 1

			f.write(bytes("END_MSG", "utf-8"))

	


	## Expand moves

	# when using move id N > 673, b_animation_id (n - 561) is used
	# N must be greater than b_animations.files + moves.files = 559 + 114 = 673

	narc_info["original_move_count"] = 560
	narc_info["battle_animation_count"] = 115 #len(b_animations.files)
	filler_count = narc_info["battle_animation_count"]

	with open(f'{rom_name}/session_settings.json', "w+") as outfile:  
		json.dump(narc_info, outfile) 


	#expand text banks

	if narc_info["base_rom"] == "BW2":
		banks = [16, 402, 403, 488]
	else:
		banks = [13, 202,203,286]
	

	for n in banks:
		bank = "message_texts"
		subprocess.run(['dotnet', 'tools/beatertext/BeaterText.dll', '-d', f'{rom_name}/{bank}/{n}.bin', f'{rom_name}/{bank}/{n}_edited.txt'], check = True)
	
	case = "lower"
		
	for n in banks[2:]:
		if n == 488 or n == 286:
			case = "upper"
		expand_move_names(f'{rom_name}/{bank}/{n}_edited.txt', narc_info["battle_animation_count"], case)

	expand_move_actions(f'{rom_name}/{bank}/{banks[0]}_edited.txt', narc_info["battle_animation_count"] * 3)
	expand_move_desc(f'{rom_name}/{bank}/{banks[1]}_edited.txt', narc_info["battle_animation_count"])

	# recompile text banks
	for n in banks:
		bank = "message_texts"
		subprocess.run(['dotnet', 'tools/beatertext/BeaterText.dll', '-m', f'{rom_name}/{bank}/{n}_edited.txt', f'{rom_name}/{bank}/{n}.bin'], check = True)




	# expand pokeweb text file
	with open(f'{rom_name}/texts/moves.txt', 'r+') as f:
		lines = f.readlines()
		lines = lines[0:560]
		
		for n in range(560, 560 + filler_count):
			lines.append(f'FILLER {n}\n')

		with open('Reference_Files/move_names.txt', 'r') as moves:
			names = moves.readlines()
			for move in names:
				lines.append(move.upper())

		f.seek(0)
		f.writelines(lines)



	# # add filler moves to json
	filler_move = open(f'{rom_name}/json/moves/0.json', 'r').read()
	for n in range(0, filler_count):
		idx = 560 + n

		with open(f"{rom_name}/json/moves/{idx}.json", "w") as f:
			f.write(filler_move)
		



		# if platform.system() == 'Windows': 
		# 	print(f'{rom_name}/json/moves/{idx}.json')
		# 	os.system(f"copy {rom_name}/json/moves/0.json {rom_name}/json/moves/{idx}.json")
		# 	print(f"copy {rom_name}/json/moves/0.json {rom_name}/json/moves/{idx}.json")
		# 	print(idx)
		# else:
		# 	subprocess.run(['cp', f'{rom_name}/json/moves/0.json', f'{rom_name}/json/moves/{idx}.json' ], check = True)
		# # os.system(f"cp {rom_name}/json/moves/0.json {rom_name}/json/moves/{idx}.json")


	# # expand animations and move files

	move_info = {}
	with open('Reference_Files/moves.csv', 'r') as f:
		for move in csv.reader(f):
			move_info[int(move[0])] = move

	backup_move_info = {}
	with open('Reference_Files/backup_moves.csv', 'r') as f:
		for move in csv.reader(f):
			backup_move_info[int(move[0])] = move

	# print(backup_move_info)



	empty_move = json.load(open(f'{rom_name}/json/moves/0.json'))



	# expand animations with dummy data
	b_animations.files = b_animations.files[:115]

	while len(b_animations.files) < 115:
		b_animations.files.append(animations.files[247])

	for n in range(0, expand_moves):
		b_animations.files.append(animations.files[247])

	with open(b_animations_file_path, 'wb') as f:	
		f.write(b_animations.save())




	for n in range(560,(560 + expand_moves)):
		with open(f'{rom_name}/json/moves/{n + filler_count}.json', 'w+') as f:
			move = copy.deepcopy(empty_move)

			readable = move["readable"]

			readable["index"] = n + filler_count
			readable["animation"] = 0
			if n in move_info:
				info = move_info[n]
				readable["name"] = info[1]
				readable["type"] = info[2]
				readable["category"] = info[3]
				
				if info[4] == "--":
					info[4] = 0
				readable["power"] = int(info[4])

				if info[5] == "--":
					info[5] = 101
				readable["accuracy"] = int(info[5])
				readable["pp"] = int(info[6].split(" ")[0])

				for i in range(11,14):
					
					if len(info) > i:
						stat = info[i]

						if stat != "":
							stat_idx = i - 10

							magnitude = int(stat.split(" ")[0])
							readable[f"magnitude_{stat_idx}"] = magnitude
							
							if "(" in stat:
								chance = int(re.findall(r'\(.*?\)', stat)[0][1:-2])
								readable[f"stat_chance_{stat_idx}"] = chance
								stat_name = re.findall(r'\d.*?\(', stat)[0][2:-2]				
							else:
								stat_name = " ".join(stat.split(" ")[1:])

							if stat_name != "Omniboost":
								readable[f"stat_{stat_idx}"] = stat_name

				flags = info[10]
				if "contact" in flags:
					readable["contact"] = 1

				if "recharge" in flags:
					readable["recharge_turn"] = 1

				if "[charge]" in flags:
					readable["requires_charge"] = 1

				if "[protect]" in flags:
					readable["blocked_by_protect"] = 1

				if "reflectable" in flags:
					readable["reflected_by_magic_coat"] = 1

				if "Snatch" in flags:
					readable["stolen_by_snatch"] = 1

				if "Mirror" in flags:
					readable["copied_by_mirror_move"] = 1

				if "[punch]" in flags:
					readable["punch_move"] = 1

				if "sound" in flags:
					readable["sound_move"] = 1

				if "Gravity" in flags:
					readable["grounded_by_gravity"] = 1

				if "defrost" in flags:
					readable["defrosts_targets"] = 1

				if "Gravity" in flags:
					readable["grounded_by_gravity"] = 1

				if "healing" in flags:
					readable["healing_move"] = 1

				if "Subs" in flags:
					readable["hits_through_substitute"] = 1

				if info[9] == "Normal target":
					readable["target"] = "Any adjacent"
				elif "All adjacent P" in info[9]:
					readable["target"] = "All excluding user"
				elif "All adjacent o" in info[9]:
					readable["target"] = "All adjacent opponents"
				elif info[9] == "self":
					readable["target"] == "User"

				# check for effect
				if info[8] != '':
					effects = re.findall(r'\[.*?\]', info[8])

					for effect in effects:
						effect = effect[1:-1]
						
						if "chance" in effect:
							chance = int(effect.split("%")[0])
							readable["effect_chance"] = chance
							readable["effect_category"] = "Chance to Inflict Status"

							if "poison" in effect:
								readable["effect"] = "Chance to Poison"
								readable["status"] = "Visible"

							if "burn" in effect:
								readable["effect"] = "Chance to Burn"
								readable["status"] = "Visible"

							if "paralysis" in effect:
								readable["effect"] = "Chance to Paralyze"
								readable["status"] = "Visible"

							if "freeze" in effect:
								readable["effect"] = "Chance to Freeze"
								readable["status"] = "Visible"

						if "priority" in effect:
							prio = int(effect.split(" prio")[0])
							if prio < 0:
								prio = 256 + prio
							readable["priority"] = prio

						if "flinch" in effect:
							readable["flinch"] = readable["effect_chance"]
							readable["effect_chance"] = 0
							readable["effect_category"] = "No Special Effect"

						if "crit rate" in effect:
							readable["crit"] = 1

						if "2 to 5" in effect:
							readable["min_hits"] = 2
							readable["max_hits"] = 5

						if "induce" in effect:
							readable["effect_category"] = "Status Inflicting"
			else:
				info = backup_move_info[n]
				readable["name"] = info[1]
				readable["type"] = info[2]

				if info[3] == "???":
					info[3] = "Physical"

				readable["category"] = info[3]


				readable["pp"] = int(info[4])

				if info[5] == "—":
					info[5] = 0

				try:
					readable["power"] = int(info[5])
				except:
					readable["power"] = 0

				if info[6] == "—":
					info[6] = 101
				
				try:
					readable["accuracy"] = int(info[6])
				except:
					info[6] = 101

			full_move = {}
			full_move["readable"] = readable
			full_move["raw"] = move["raw"]
			json.dump(full_move, f)
		move_writer.write_readable_to_raw(n + filler_count)


	



	