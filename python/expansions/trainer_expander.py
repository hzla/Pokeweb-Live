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

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

import rom_data


expand_trainers = 10
rom_name = "projects/" + sys.argv[1].split(".")[0]

narc_info = {} ##store narc names and file id pairs
with open(f'{rom_name}/session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 

rom_data.set_global_vars(rom_name)


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




	