import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import json
import sys


from multiprocessing import Pool
import subprocess
from arm9_reader import output_tms_json
import hgss_header_reader

from pathlib import Path
import shutil



# code.interact(local=dict(globals(), **locals()))


#################### CREATE FOLDERS #############################
print("creating project folders")

narc_info = {} ##store narc names and file id pairs

rom_name = "projects/" + sys.argv[1].split(".")[0]

with open(f'{rom_name}/session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 



# code.interact(local=dict(globals(), **locals()))

dirpath = Path(f'{rom_name}/json/moves')
print(dirpath) 
if dirpath.exists() and dirpath.is_dir():
	shutil.rmtree(dirpath)

if not os.path.exists(f'{rom_name}'):
	os.makedirs(f'{rom_name}')

for folder in ["narcs", "texts", "json"]:
	if not os.path.exists(f'{rom_name}/{folder}'):
		os.makedirs(f'{rom_name}/{folder}')

with open(f'expansion_settings.json', "r") as outfile:  
	expansion_settings = json.load(outfile) 
	expand_moves = expansion_settings["moves"]
	expand_sprites = expansion_settings["alt_form_sprites"]



################# HARDCODED ROM INFO ##############################

BW_NARCS = [["a/0/1/6", "personal"],
["a/0/0/8", "maps"],
["a/0/0/9", "matrix"], 
["a/1/2/5", "overworlds"],
["a/0/1/8", "learnsets"],
["a/0/1/9", "evolutions"], 
["a/0/2/1","moves"],
["a/0/6/6", "move_animations"],
["a/0/6/7", "battle_animations"],
["a/0/2/4", "items"],
["a/0/9/0", "trtext_table"],
["a/0/9/1", "trtext_offsets"],
["a/0/9/2", "trdata"],
["a/0/9/3", "trpok"],
["a/1/2/6", "encounters"]]

BW_MSG_BANKS = [[286, "moves"],
[285, "abilities"],
[284, "pokedex"],
[191, "tr_classes"],
[190, "tr_names"],
[54, "items"]]

BW2_NARCS = [["a/0/1/6", "personal"],
["a/0/0/8", "maps"],
["a/0/0/9", "matrix"], 
["a/1/2/6", "overworlds"],
["a/0/1/8", "learnsets"],
["a/0/1/9", "evolutions"], 
["a/0/2/1","moves"],
["a/0/2/4", "items"],
["a/0/8/9", "trtext_table"],
["a/0/9/0", "trtext_offsets"],
["a/0/9/1", "trdata"],
["a/0/9/2", "trpok"],
["a/1/2/7", "encounters"],
["a/2/8/2", "marts"],
["a/2/8/3", "mart_counts"],
["a/2/7/3", "grottos"],
["a/0/6/5", "move_animations"],
["a/0/6/6", "battle_animations"]]


BW2_MSG_BANKS = [[488, "moves"],
[487, "abilities"],
[486, "pokedex"],
[383, "tr_classes"],
[382, "tr_names"],
[64, "items"]]

HGSS_NARCS = [['a/0/3/7', "encounters"],
['a/0/0/2', 'personal'],
['a/0/3/3', 'learnsets'],
['a/0/1/1', 'moves'],
['a/0/3/4', 'evolutions'],
['a/0/5/5', 'trdata'],
['a/0/5/6', 'trpok'],
['a/0/2/8', 'hidden_abilities']] 
# ha in file index 7

PL_NARCS = [
['poketool/waza/pl_waza_tbl.narc', 'moves'],
['poketool/personal/pl_personal.narc', 'personal'],
['poketool/personal/evo.narc', 'evolutions'],
['fielddata/encountdata/pl_enc_data.narc', 'encounters'],
['poketool/trainer/trdata.narc', 'trdata'],
['poketool/personal/wotbl.narc', 'learnsets'],
['poketool/trainer/trpoke.narc', 'trpok']
]


NARCS = []
MSG_BANKS = []

################### EXTRACT RELEVANT NARCS AND ARM9 #######################

if narc_info["base_rom"] == "BW":
	MSG_BANKS = BW_MSG_BANKS
	NARCS = BW_NARCS
elif narc_info["base_rom"] == "HGSS":
	NARCS = HGSS_NARCS
elif narc_info["base_rom"] == "PLAT":
	NARCS = PL_NARCS
else:
	MSG_BANKS = BW2_MSG_BANKS
	NARCS = BW2_NARCS

print("extracting narcs")

with open(f'{rom_name.split("/")[-1]}.nds', 'rb') as f:
	data = f.read()

rom = ndspy.rom.NintendoDSRom(data)

for narc in NARCS:
	file_id = rom.filenames[narc[0]]
	file = rom.files[file_id]
	parsed_file = ndspy.narc.NARC(file)
	
	narc_info[narc[1]] = file_id # store file ID for later
		
	# handle trainer text narcs
	if narc[1] == "trtext_table":
		data = parsed_file.files[0]
		offset = 0
		json_data = []

		while offset < len(data):
			entry = data[offset:(offset + 4)]
			tr_id = int.from_bytes(entry[:2], 'little')
			text_type = int.from_bytes(entry[2:], 'little')
			json_data.append([tr_id, text_type])
			offset += 4

		with open(f'{rom_name}/texts/trtexts.json', 'w') as f:
			json.dump(json_data, f)

	if narc[1] == "trtext_offsets":
		data = parsed_file.files[0]
		offset = 0
		json_data = []

		while offset < len(data):
			entry = data[offset:(offset + 2)]
			ofs = int.from_bytes(entry, 'little')
			json_data.append(ofs)
			offset += 2

		with open(f'{rom_name}/texts/trtexts_offsets.json', 'w') as f:
			json.dump(json_data, f)

	with open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'wb') as f:
		f.write(file)

arm9 = bytearray(open(f'{rom_name}/arm9.bin', "rb").read())

if narc_info["base_rom"] != "HGSS" and narc_info["base_rom"] != "PLAT":
	overlay36 = rom.loadArm9Overlays([36])[36]
	overlay16 = rom.loadArm9Overlays([16])[16]

	with open(f'{rom_name}/overlay36.bin', 'wb') as f:
		f.write(overlay36.data)

	with open(f'{rom_name}/overlay16.bin', 'wb') as f:
		f.write(overlay16.data)

	B2_SWARM_OFFSET = 0x00050bfc
	B2_GROTTO_ODDS_OFFSET = 0x00055218
	W2_GROTTO_ODDS_OFFSET = 0x00055218 - 12

	if narc_info["base_version"] == "B2":
		GROTTO_ODDS_OFFSET = B2_GROTTO_ODDS_OFFSET
	else:
		GROTTO_ODDS_OFFSET = W2_GROTTO_ODDS_OFFSET

	################### EXTRACT RELEVANT TEXTS ##################
	print("parsing texts")

	msg_file_id = narc_info['message_texts']


	with open(f'{rom_name}/message_texts/texts.json', 'r') as f:
		messages = json.load(f)
		
		for msg_bank in MSG_BANKS:
			text = messages[msg_bank[0]]

			with open(f'{rom_name}/texts/{msg_bank[1]}.txt', 'w+') as outfile:
				for idx, line in enumerate(text):
					try:
						line[1] = line[1].replace("―", "").replace("⑮", " F").replace("⑭", " M").replace("⒆⒇", "PkMn").replace("é", "e").encode("ascii", "ignore").decode()
						outfile.write(line[1] + "\n")
					except:
						print(line[1])
						# code.interact(local=dict(globals(), **locals()))
						outfile.write(f"Entry {idx}" + "\n")

	

##############################################################
################### WRITE SESSION SETTINGS ###################

settings = {}
settings.update(narc_info)
settings["output_arm9"] = False
settings["fairy"] = False
settings["text_editor"] = False
settings["output_overworlds"] = True
settings["enable_single_npc_dbl_battles"] = False



with open(f'{rom_name}/session_settings.json', "w+") as outfile:  
	json.dump(settings, outfile, indent=4) 


if narc_info["base_rom"] != "HGSS" and narc_info["base_rom"] != "PLAT":
	with open(f'{rom_name}/grotto_odds.bin', 'wb') as f:
		f.write(overlay36.data[GROTTO_ODDS_OFFSET:(GROTTO_ODDS_OFFSET + 200)])

# code.interact(local=dict(globals(), **locals()))

#############################################################
################### Provision Placeholders for alt form sprites ###########


if narc_info["base_rom"] == "BW2":

	if expand_moves > 0:
		moves_file_path = f'{rom_name}/narcs/moves-{settings["moves"]}.narc'
		animations_file_path = f'{rom_name}/narcs/move_animations-{settings["move_animations"]}.narc'
		b_animations_file_path = f'{rom_name}/narcs/battle_animations-{settings["battle_animations"]}.narc'

		moves = ndspy.narc.NARC.fromFile(moves_file_path)
		animations = ndspy.narc.NARC.fromFile(animations_file_path)
		b_animations = ndspy.narc.NARC.fromFile(b_animations_file_path)

		## Expand moves

		# when using move id N > 673, b_animation_id (n - 561) is used
		# N must be greater than b_animations.files + moves.files = 559 + 114 = 673

		settings["original_move_count"] = len(moves.files)
		settings["battle_animation_count"] = len(b_animations.files)
		
		with open(f'{rom_name}/session_settings.json', "w+") as outfile:  
			json.dump(settings, outfile) 

		# add filler moves

		print(len(b_animations.files))

		for n in range(0, len(b_animations.files)):
			moves.files.append(moves.files[1])

		print(expand_moves)
		# expand animations and move files
		for n in range(0,expand_moves):
			n %= 559
			b_animations.files.append(animations.files[1])
			moves.files.append(moves.files[1])


		with open(moves_file_path, 'wb') as f:
			f.write(moves.save())

		with open(b_animations_file_path, 'wb') as f:
			f.write(b_animations.save())


	# code.interact(local=dict(globals(), **locals()))
	
	# sprites
	if expand_sprites:
		sprite_file_path = f'{rom_name}/narcs/sprites-{settings["sprites"]}.narc'
		narc = ndspy.narc.NARC.fromFile(sprite_file_path)

		while len(narc.files) < 15080:
			narc.files.append(narc.files[-1])

		placeholder_sprites = narc.files[15000:15020]

		
		for n in range(100):
			narc.files += placeholder_sprites

		with open(f'{rom_name}/narcs/sprites-{settings["sprites"]}.narc', 'wb') as f:
			f.write(narc.save())

		# party icons 
		sprite_file_path = f'{rom_name}/narcs/icons-{settings["icons"]}.narc'
		narc = ndspy.narc.NARC.fromFile(sprite_file_path)

		while len(narc.files) < 1516:
			narc.files.append(narc.files[-1])

		placeholder_sprites = narc.files[1502:1504]

		
		for n in range(100):
			narc.files += placeholder_sprites

		with open(f'{rom_name}/narcs/icons-{settings["icons"]}.narc', 'wb') as f:
			f.write(narc.save())

#############################################################
####################CONVERT TO JSON #########################

try:
	subprocess.run(['python3', 'python/parallel.py', rom_name], check = True)
except:
	subprocess.run(['python', 'python/parallel.py', rom_name], check = True)


output_tms_json(arm9, rom_name)
subprocess.run(['rm', '-rf', sys.argv[1]], check = True)

if narc_info["base_rom"] == "PLAT":
	subprocess.run(['cp', '-r', './texts', rom_name], check = True)




