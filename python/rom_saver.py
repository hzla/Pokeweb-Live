import ndspy
import ndspy.rom, ndspy.bmg
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
# code.interact(local=dict(globals(), **locals()))


################# HARDCODED ROM INFO ##############################

BW_NARCS = [["a/0/1/6", "personal"], 
["a/0/1/7", "growth"],
["a/0/1/8", "lvlupmoves"],
["a/0/1/9", "evolution"], 
["a/0/2/0", "babyforms"],
["a/0/2/1","moves"],
["a/0/2/4", "items"],
["a/0/9/1", "trdata"],
["a/0/9/2", "trpok"],
["a/1/2/7", "encounters"],
["a/0/0/3", "storytext"],
["a/0/0/2", "messagetext"],
["a/0/5/6", "scripts"]]

BW_MSG_BANKS = [[286, "moves"],
[199, "types"],
[202, "move_descriptions"],
[285, "abilities"],
[183, "ability_descriptions"],
[284, "pokedex"],
[191, "tr_classes"],
[190, "tr_names"],
[54, "items"],
[89, "locations"]]

rom_name = sys.argv[1].split(".")[0] 


####################################################################
################### WRITE NARCS TO ROM ############################

personal_writer.output_narc()
learnset_writer.output_narc()



with open(f'{rom_name}.nds', 'rb') as f:
    data = f.read()
rom = ndspy.rom.NintendoDSRom(data)


with open(f'session_settings.json', "r") as outfile:  
	settings = json.load(outfile) 
	personal_narc_file_id = settings["personal"]
	learnset_narc_file_id = settings["learnsets"]

personal_narc_filepath = f'{rom_name}/narcs/personal-{personal_narc_file_id}.narc'
learnset_narc_filepath = f'{rom_name}/narcs/learnsets-{learnset_narc_file_id}.narc'


rom.files[personal_narc_file_id] = open(personal_narc_filepath, 'rb').read()
rom.files[learnset_narc_file_id] = open(learnset_narc_filepath, 'rb').read()


print("attempting save")


if path.exists(f'exports'):
	rom.saveToFile(f'exports/{rom_name}.nds')
else:
	os.makedirs('exports')
	rom.saveToFile(f'exports/{rom_name}.nds')


