import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import os.path
from os import path
import json
import sys


import personal_writer
import learnset_writer
import move_writer
import tm_writer
import header_writer
import encounter_writer
import trdata_writer
import trpok_writer
import item_writer
import evolution_writer
# import msg_reader2

# code.interact(local=dict(globals(), **locals()))




rom_name = sys.argv[1].split(".")[0] 


####################################################################
################### WRITE NARCS/ARM9 TO ROM ############################
print("outputting narcs")
personal_writer.output_narc()
learnset_writer.output_narc()
move_writer.output_narc()
header_writer.output_narc()
encounter_writer.output_narc()
trpok_writer.output_narc()
trdata_writer.output_narc()
item_writer.output_narc()
evolution_writer.output_narc()
# msg_reader2.output_narc()

with open(f"{rom_name.split('/')[1]}.nds", 'rb') as f:
    data = f.read()
rom = ndspy.rom.NintendoDSRom(data)



settings = {}
with open(f'session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	personal_narc_file_id = settings["personal"]
	learnset_narc_file_id = settings["learnsets"]
	moves_narc_file_id = settings["moves"]
	headers_narc_file_id = settings["headers"]
	encounters_narc_file_id = settings["encounters"]
	trdata_narc_file_id = settings["trdata"]
	trpok_narc_file_id = settings["trpok"]
	item_narc_file_id = settings["items"]
	evolution_narc_file_id = settings["evolutions"]
	story_texts_narc_file_id = settings["story_texts"]
	message_texts_narc_file_id = settings["message_texts"]
	trtext_table_narc_file_id = settings["trtext_table"]
	trtext_offsets_narc_file_id = settings["trtext_offsets"]

	if settings["base_rom"] == "BW2":
		mart_narc_file_id = settings["marts"]
		mart_counts_narc_file_id = settings["mart_counts"]
		grotto_narc_file_id = settings["grottos"]
		sprites_narc_file_id = settings["sprites"]
		b_animations_narc_file_id = settings["battle_animations"]
		animations_narc_file_id = settings["move_animations"]
		icons_narc_file_id = settings["icons"]

if settings["output_arm9"] == True:

	tm_writer.output_arm9()
	mutable_rom = bytearray(data)
	arm9_offset = 16384 #0x4000

	#get edited arm9
	edited_arm9_file = bytearray(open(f'{rom_name}/arm9.bin', 'rb').read())

	# #compress it
	print ("compressing arm9")
	arm9 = bytearray(ndspy.codeCompression.compress(edited_arm9_file, isArm9=True))

	#reinsert arm9
	mutable_rom[arm9_offset:arm9_offset + len(arm9)] = arm9

	#update rom in memory
	rom = ndspy.rom.NintendoDSRom(mutable_rom)


if settings["base_rom"] == "BW2":
	import mart_writer
	import grotto_writer
	mart_writer.output_narc()
	grotto_writer.output_narc()


	grotto_odds = 0

	grotto_odds = open(f'{rom_name}/grotto_odds.bin','rb').read()

	#load decompressed overlay
	overlay36 = rom.loadArm9Overlays([36])[36]
	
	#set data
	overlay36_data = overlay36.data

	B2_GROTTO_ODDS_OFFSET = 0x00055218
	
	# overwrite data with edits

	overlay36_data[B2_GROTTO_ODDS_OFFSET:(B2_GROTTO_ODDS_OFFSET + 200)] = grotto_odds
	
	#set new data
	overlay36.data = overlay36_data

	# recompress and insert

	rom.files[36] = overlay36.save(compress=True)
	print("saved grotto odds")





personal_narc_filepath = f'{rom_name}/narcs/personal-{personal_narc_file_id}.narc'
learnset_narc_filepath = f'{rom_name}/narcs/learnsets-{learnset_narc_file_id}.narc'
moves_narc_filepath = f'{rom_name}/narcs/moves-{moves_narc_file_id}.narc'
headers_narc_filepath = f'{rom_name}/narcs/headers-{headers_narc_file_id}.narc'
encounters_narc_filepath = f'{rom_name}/narcs/encounters-{encounters_narc_file_id}.narc'
trdata_narc_filepath = f'{rom_name}/narcs/trdata-{trdata_narc_file_id}.narc'
trpok_narc_filepath = f'{rom_name}/narcs/trpok-{trpok_narc_file_id}.narc'
item_narc_filepath = f'{rom_name}/narcs/items-{item_narc_file_id}.narc'
evolution_narc_filepath = f'{rom_name}/narcs/evolutions-{evolution_narc_file_id}.narc'
message_texts_narc_filepath = f'{rom_name}/narcs/message_texts-{message_texts_narc_file_id}.narc'
story_texts_narc_filepath = f'{rom_name}/narcs/story_texts-{story_texts_narc_file_id}.narc'

trtext_table_narc_filepath = f'{rom_name}/narcs/trtext_table-{trtext_table_narc_file_id}.narc'
trtext_offsets_narc_filepath = f'{rom_name}/narcs/trtext_offsets-{trtext_offsets_narc_file_id}.narc'

if settings["base_rom"] == "BW2":
	mart_narc_filepath = f'{rom_name}/narcs/marts-{mart_narc_file_id}.narc'
	mart_counts_narc_filepath = f'{rom_name}/narcs/mart_counts-{mart_counts_narc_file_id}.narc'

	grotto_narc_filepath = f'{rom_name}/narcs/grottos-{grotto_narc_file_id}.narc'

print("writing narcs")

rom.files[personal_narc_file_id] = open(personal_narc_filepath, 'rb').read()
rom.files[learnset_narc_file_id] = open(learnset_narc_filepath, 'rb').read()
rom.files[moves_narc_file_id] = open(moves_narc_filepath, 'rb').read()
rom.files[headers_narc_file_id] = open(headers_narc_filepath, 'rb').read()
rom.files[encounters_narc_file_id] = open(encounters_narc_filepath, 'rb').read()
rom.files[trdata_narc_file_id] = open(trdata_narc_filepath, 'rb').read()
rom.files[trpok_narc_file_id] = open(trpok_narc_filepath, 'rb').read()
rom.files[item_narc_file_id] = open(item_narc_filepath, 'rb').read()
rom.files[evolution_narc_file_id] = open(evolution_narc_filepath, 'rb').read()

# code.interact(local=dict(globals(), **locals()))

# rom.files[message_texts_narc_file_id] = open(message_texts_narc_filepath, 'rb').read()
# rom.files[story_texts_narc_file_id] = open(story_texts_narc_filepath, 'rb').read()

# print(message_texts_narc_filepath)
# print(story_texts_narc_filepath)


# print(len(open(message_texts_narc_filepath, 'rb').read()))
# print(len(open(story_texts_narc_filepath, 'rb').read()))

# rom.files[trtext_table_narc_file_id] = open(trtext_table_narc_filepath, 'rb').read()
# rom.files[trtext_offsets_narc_file_id] = open(trtext_offsets_narc_filepath, 'rb').read()


if settings["base_rom"] == "BW2":
	rom.files[mart_narc_file_id] = open(mart_narc_filepath, 'rb').read()
	rom.files[mart_counts_narc_file_id] = open(mart_counts_narc_filepath, 'rb').read()
	print("saved mart")
	rom.files[grotto_narc_file_id] = open(grotto_narc_filepath, 'rb').read()
	print("saved grotto")
	rom.files[sprites_narc_file_id] = open(f'{rom_name}/narcs/sprites-{sprites_narc_file_id}.narc', 'rb').read()
	rom.files[b_animations_narc_file_id] = open(f'{rom_name}/narcs/battle_animations-{b_animations_narc_file_id}.narc', 'rb').read()
	rom.files[animations_narc_file_id] = open(f'{rom_name}/narcs/move_animations-{animations_narc_file_id}.narc', 'rb').read()
	rom.files[icons_narc_file_id] = open(f'{rom_name}/narcs/icons-{icons_narc_file_id}.narc', 'rb').read()


print("attempting save")


if path.exists(f'exports'):
	rom.saveToFile(f"exports/{rom_name.split('/')[1]}.nds")
else:
	os.makedirs('exports')
	rom.saveToFile(f"exports/{rom_name.split('/')[1]}.nds")


