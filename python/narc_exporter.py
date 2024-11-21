import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc
import code 
import io
import codecs
import os
import os.path
from os import path
from pathlib import Path
import json
import sys
import traceback
import gc

print(sys.argv)

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
import overworld_writer
import text_writer


if len(sys.argv) > 2:
	narc = sys.argv[1] 
	rom_name = sys.argv[3]

	narcs = ["personal","text", "learnset","move","encounter","trdata","trpok","item","evolution"]
	rom = "none"

	if narc in narcs:
		eval(f'{narc}_writer.output_narc(rom, rom_name)')


