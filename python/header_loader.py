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
from header_reader import output_headers_json


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

BW_NARCS = [["a/0/1/2", "headers"],["a/0/0/2", "messagetext"]]

BW_MSG_BANKS = [[89, "locations"]]

################### EXTRACT RELEVANT NARCS AND ARM9 #######################

narc_info = {} ##store narc names and file id pairs

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
settings["rom_name"] = rom_name
settings["base_rom"] = "Pokemon Black"
settings.update(narc_info)

with open(f'session_settings.json', "w") as outfile:  
	json.dump(settings, outfile) 
	print(settings)

#############################################################
################### CONVERT TO JSON #########################

headers_narc_data = ndspy.narc.NARC(rom.files[narc_info["headers"]])
output_headers_json(headers_narc_data)




