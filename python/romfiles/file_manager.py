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
import glob


rom_path = sys.argv[1]
file_path = sys.argv[2]
if sys.argv[3]:
	subfile_name = sys.argv[3]


rom = ndspy.rom.NintendoDSRom.fromFile(rom_path)

code.interact(local=dict(globals(), **locals()))


