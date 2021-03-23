import ndspy
import ndspy.rom, ndspy.bmg, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import os.path
from os import path
import json
import sys

import msg_reader
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
import mart_writer
# code.interact(local=dict(globals(), **locals()))


################# HARDCODED ROM INFO ##############################


rom_name = sys.argv[1].split(".")[0] 


####################################################################
################### WRITE NARCS/ARM9 TO ROM ############################
print("outputting narcs")
# personal_writer.output_narc()
# learnset_writer.output_narc()
# move_writer.output_narc()
# header_writer.output_narc()
# encounter_writer.output_narc()
# trdata_writer.output_narc()
# trpok_writer.output_narc()
# item_writer.output_narc()
# evolution_writer.output_narc()
mart_writer.output_narc()

tm_writer.output_arm9()

with open(f"{rom_name.split('/')[1]}.nds", 'rb') as f:
    data = f.read()
rom = ndspy.rom.NintendoDSRom(data)


# mutable_rom = bytearray(data)
# arm9_offset = 16384 #0x4000



# #get edited arm9
# edited_arm9_file = bytearray(open(f'{rom_name}/arm9.bin', 'rb').read())

# # #compress it
# print ("compressing arm9")
# arm9 = bytearray(ndspy.codeCompression.compress(edited_arm9_file, isArm9=True))

# #reinsert arm9
# mutable_rom[arm9_offset:arm9_offset + len(arm9)] = arm9

# #update rom in memory
# rom = ndspy.rom.NintendoDSRom(mutable_rom)

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
	if settings["base_rom"] == "BW2":
		mart_narc_file_id = settings["marts"]
		mart_counts_narc_file_id = settings["mart_counts"]

personal_narc_filepath = f'{rom_name}/narcs/personal-{personal_narc_file_id}.narc'
learnset_narc_filepath = f'{rom_name}/narcs/learnsets-{learnset_narc_file_id}.narc'
moves_narc_filepath = f'{rom_name}/narcs/moves-{moves_narc_file_id}.narc'
headers_narc_filepath = f'{rom_name}/narcs/headers-{headers_narc_file_id}.narc'
encounters_narc_filepath = f'{rom_name}/narcs/encounters-{encounters_narc_file_id}.narc'
trdata_narc_filepath = f'{rom_name}/narcs/trdata-{trdata_narc_file_id}.narc'
trpok_narc_filepath = f'{rom_name}/narcs/trpok-{trpok_narc_file_id}.narc'
item_narc_filepath = f'{rom_name}/narcs/items-{item_narc_file_id}.narc'
evolution_narc_filepath = f'{rom_name}/narcs/evolutions-{evolution_narc_file_id}.narc'

if settings["base_rom"] == "BW2":
	mart_narc_filepath = f'{rom_name}/narcs/marts-{mart_narc_file_id}.narc'
	mart_counts_narc_filepath = f'{rom_name}/narcs/mart_counts-{mart_counts_narc_file_id}.narc'

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

if settings["base_rom"] == "BW2":
	rom.files[mart_narc_file_id] = open(mart_narc_filepath, 'rb').read()
	rom.files[mart_counts_narc_file_id] = open(mart_counts_narc_filepath, 'rb').read()
	print("saved mart")


print("attempting save")


if path.exists(f'exports'):
	rom.saveToFile(f"exports/{rom_name.split('/')[1]}.nds")
else:
	os.makedirs('exports')
	rom.saveToFile(f"exports/{rom_name.split('/')[1]}.nds")


