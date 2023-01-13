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


tr_path = f'{rom_name}/json/trdata'
trpok_path = f'{rom_name}/json/trpok'



trainers = os.listdir(tr_path)
tr_count = len(trainers)

print(tr_count)

offsets = json.load(open(f'{rom_name}/texts/trtexts_offsets.json', "r"))
text_table = json.load(open(f'{rom_name}/texts/trtexts.json', "r"))
texts = json.load(open(f'{rom_name}/message_texts/texts.json', "r"))

last_offset = max(offsets)

last_trainer_text_count = 0
offset_idx = -1
last_trainer = text_table[-1][0]

while offset_idx > -20:
	offset_idx -= 1
	curr_trainer = text_table[offset_idx][0]
	if curr_trainer != last_trainer:
		break
	else:
		last_trainer_text_count += 1

print(last_trainer_text_count)

last_offset += (last_trainer_text_count * 4)




for n in range(0, expand_trainers):
	tr_id = n + tr_count
	
	subprocess.run(["cp",f'{tr_path}/0.json', f'{tr_path}/{tr_id}.json'], check=True)
	subprocess.run(["cp",f'{trpok_path}/0.json', f'{trpok_path}/{tr_id}.json'], check=True)
	offsets.append((n + 1) * 4 + last_offset)
	
	text_table.append([n + tr_count, 0])
	texts[381].append(["", f"Trainer {n + tr_count}\\r", 0])


with open(f'{rom_name}/texts/trtexts_offsets.json', "w") as f:
	json.dump(offsets, f)

with open(f'{rom_name}/texts/trtexts.json', "w") as f:
	json.dump(text_table, f)

with open(f'{rom_name}/message_texts/texts.json', "w") as f:
	json.dump(texts, f)





	