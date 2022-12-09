import code 
import io
import os
import os.path
from os import path
import json
import copy
import re
import rom_data

# code.interact(local=dict(globals(), **locals()))

def output_headers_json(headers):
	rom_data.set_global_vars()
	headers = headers.files[0]
	header_count = int(len(headers) / rom_data.HEADER_LENGTH)

	read_narc_data(headers, rom_data.NARC_FORMATS["headers"], header_count )

def read_narc_data(data, narc_format, file_count):
	stream = io.BytesIO(data)
	headers = { }
	headers["count"] = file_count

	#USE THE FORMAT LIST TO PARSE BYTES
	for n in range(1, file_count + 1):
		headers[n] = {}
		for entry in narc_format:
			byte = read_bytes(stream, entry[0])
			headers[n][entry[1]] = byte
	
		try:
			headers[n]["location_name"] = rom_data.LOCATIONS[headers[n]["location_name_id"]]
		except:
			headers[n]["location_name"] = "Unknown Location"
			print(n)

	#OUTPUT TO JSON
	if not os.path.exists(f'{rom_data.ROM_NAME}/json/headers'):
		os.makedirs(f'{rom_data.ROM_NAME}/json/headers')

	with open(f'{rom_data.ROM_NAME}/json/headers/headers.json', "w") as outfile:  
		json.dump(headers, outfile) 

def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

	