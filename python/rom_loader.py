import ndspy
import ndspy.rom, ndspy.bmg, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import json
import sys

import msg_reader
import msg_reader2
from personal_reader import output_personal_json
from learnset_reader import output_learnset_json
from move_reader import output_moves_json
from arm9_reader import output_tms_json
from encounter_reader import output_encounters_json
from trdata_reader import output_trdata_json
from trpok_reader import output_trpok_json
from item_reader import output_items_json
from evolution_reader import output_evolutions_json

# code.interact(local=dict(globals(), **locals()))


#################### CREATE FOLDERS #############################

rom_name = sys.argv[1].split(".")[0] 

# code.interact(local=dict(globals(), **locals()))

if not os.path.exists(f'{rom_name}'):
    os.makedirs(f'{rom_name}')

for folder in ["narcs", "texts", "json"]:
	if not os.path.exists(f'{rom_name}/{folder}'):
		os.makedirs(f'{rom_name}/{folder}')

################# HARDCODED ROM INFO ##############################

BW_NARCS = [["a/0/1/6", "personal"],
["a/0/0/9", "matrix"], 
["a/1/2/5", "overworlds"],
["a/0/1/7", "growth"],
["a/0/1/8", "learnsets"],
["a/0/1/9", "evolutions"], 
["a/0/2/0", "babyforms"],
["a/0/2/1","moves"],
["a/0/2/4", "items"],
["a/0/9/2", "trdata"],
["a/0/9/3", "trpok"],
["a/1/2/6", "encounters"],
["a/0/0/3", "storytext"],
["a/0/5/6", "scripts"]]

BW_MSG_BANKS = [[286, "moves"],
[199, "types"],
[202, "move_descriptions"],
[285, "abilities"],
[183, "ability_descriptions"],
[284, "pokedex"],
[191, "tr_classes"],
[190, "tr_names"],
[54, "items"]]

################### EXTRACT RELEVANT NARCS AND ARM9 #######################


narc_info = {} ##store narc names and file id pairs

with open(f'session_settings.json', "r") as outfile:  
	narc_info = json.load(outfile) 


with open(f'{rom_name}.nds', 'rb') as f:
    data = f.read()

rom = ndspy.rom.NintendoDSRom(data)

for narc in BW_NARCS:
	file_id = rom.filenames[narc[0]]
	file = rom.files[file_id]
	parsed_file = ndspy.narc.NARC(file)
	
	narc_info[narc[1]] = file_id # store file ID for later
	
	with open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'wb') as f:
	    f.write(file)


arm9 = ndspy.codeCompression.decompress(rom.arm9)

with open(f'{rom_name}/arm9.bin', 'wb') as f:
	f.write(arm9)


#############################################################

################### EXTRACT RELEVANT TEXTS ##################

msg_file_id = narc_info['messagetext']

for msg_bank in BW_MSG_BANKS:
	text = msg_reader.parse_msg_bank(f'{rom_name}/narcs/messagetext-{msg_file_id}.narc', msg_bank[0])

	with codecs.open(f'{rom_name}/texts/{msg_bank[1]}.txt', 'w', encoding='utf_8') as f:
	    for block in text:
	    	for entry in block:
	    		try:
	    			f.write(entry)
	    		except UnicodeEncodeError:
	    			print("error")
	    			# f.write(str(entry.encode("UTF-8")))
	    		f.write("\n")


##############################################################
################### WRITE SESSION SETTINGS ###################

settings = {}
settings.update(narc_info)

print(settings)

with open(f'session_settings.json', "w+") as outfile:  
	json.dump(settings, outfile) 

#############################################################
################### CONVERT TO JSON #########################

personal_narc_data = ndspy.narc.NARC(rom.files[narc_info["personal"]])
output_personal_json(personal_narc_data)

learnset_narc_data = ndspy.narc.NARC(rom.files[narc_info["learnsets"]])
output_learnset_json(learnset_narc_data)

moves_narc_data = ndspy.narc.NARC(rom.files[narc_info["moves"]])
output_moves_json(moves_narc_data)

encounters_narc_data = ndspy.narc.NARC(rom.files[narc_info["encounters"]])
output_encounters_json(encounters_narc_data)

trdata_narc_data = ndspy.narc.NARC(rom.files[narc_info["trdata"]])
output_trdata_json(trdata_narc_data)

trpok_narc_data = ndspy.narc.NARC(rom.files[narc_info["trpok"]])
output_trpok_json(trpok_narc_data)

item_narc_data = ndspy.narc.NARC(rom.files[narc_info["items"]])
output_items_json(item_narc_data)

evolution_narc_data = ndspy.narc.NARC(rom.files[narc_info["evolutions"]])
output_evolutions_json(evolution_narc_data)



output_tms_json(arm9)


### TODO IMPLEMENT READERS FOR OTHER NARCS


