import code 
import os
import json
import sys
import subprocess
from pathlib import Path
import shutil





expand_encs = 5
rom_name = "projects/" + sys.argv[1].split(".")[0]
enc_path = f'{rom_name}/json/encounters'
encs = os.listdir(enc_path)
enc_count = len(encs)

print(enc_count)


for n in range(0, expand_encs):
	subprocess.run(["cp",f'{enc_path}/1.json', f'{enc_path}/{enc_count + n}.json'], check=True)






	