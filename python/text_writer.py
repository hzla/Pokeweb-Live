import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import struct, re
import json
import sys
import os

def set_global_vars():
    global ROM_NAME, NARC_FILE_IDS, REPLACE_TR_SCRIPT, BASE_ROM
    
    NARC_FILE_IDS = {}
    with open(f'session_settings.json', "r") as outfile:  
        settings = json.load(outfile) 
        ROM_NAME = settings['rom_name']
        BASE_ROM = settings['base_rom']
        NARC_FILE_IDS["story_texts"] = settings["story_texts"]
        NARC_FILE_IDS["message_texts"] = settings["message_texts"]
        NARC_FILE_IDS["trtext_table"] = settings["trtext_table"]
        NARC_FILE_IDS["trtext_offsets"] = settings["trtext_offsets"]
        NARC_FILE_IDS["scripts"] = settings["scripts"]
        REPLACE_TR_SCRIPT = settings["enable_single_npc_dbl_battles"]


def output_narc(rom):
    set_global_vars()

    ######## TEXTS #########

    for narc_name in ["story_texts", "message_texts"]:
        narc = ndspy.narc.NARC(rom.files[NARC_FILE_IDS[narc_name]])

        texts = os.listdir(f'{ROM_NAME}/{narc_name}')

        for file in texts:
            if file.endswith("_edited.txt"):
                print(file)
                bank_id = int(file.split("_edited.txt")[0])
                bank_bin = open(f'{ROM_NAME}/{narc_name}/{bank_id}.bin', "rb").read()
                narc.files[bank_id] = bank_bin

    ######## SCRIPTS ###########

    narc = ndspy.narc.NARC(rom.files[NARC_FILE_IDS["scripts"]])

    scripts = os.listdir(f'{ROM_NAME}/scripts')

    for file in scripts:
        if file.endswith(".txt"):
            print(f'detected')
            bank_id = int(file.split(".txt")[0])
            bank_bin = open(f'{ROM_NAME}/scripts/{bank_id}.bin', "rb").read()
            narc.files[bank_id] = bank_bin


    if REPLACE_TR_SCRIPT and BASE_ROM == "BW2":
        bank_bin = open(f'Reference_Files/1239.bin', "rb").read()
        narc.files[1239] = bank_bin
        rom.files[NARC_FILE_IDS["scripts"]] = narc.save()

    return rom


def update_narc(file_name, narc_name):
    set_global_vars()
    
    # retrieve narc and message bank
    msg_info = file_name.split("_")
    bank_id = int(msg_info[1])
 
    file_name = f'{ROM_NAME}/narcs/{narc_name}-{NARC_FILE_IDS[narc_name]}.narc'
    narc_data = ndspy.narc.NARC.fromFile(file_name)

    # retrieve updated msg
    texts = []
    with open(f'{ROM_NAME}/{narc_name}/texts.json', encoding='utf_8') as outfile:
        texts = json.load(outfile)
    message_data = texts[bank_id]
    narc_data.files[bank_id] = gen5put(message_data)

    with open(file_name, "wb") as outfile:
        outfile.write(narc_data.save()) 


    if bank_id == 381:
        # update trainer text tables if editing trainer text bank
        file_id = NARC_FILE_IDS['trtext_table']
        trtext_table_path = f'{ROM_NAME}/narcs/trtext_table-{file_id}.narc'
        table_narc_data = ndspy.narc.NARC.fromFile(trtext_table_path) 

        file_id = NARC_FILE_IDS['trtext_offsets']
        trtext_offsets_path = f'{ROM_NAME}/narcs/trtext_offsets-{file_id}.narc'
        offset_narc_data = ndspy.narc.NARC.fromFile(trtext_offsets_path)

        trtext_table = []
        offset_table = []

        with open(f'{ROM_NAME}/texts/trtexts.json', "r") as outfile:  
            trtext_table = json.load(outfile)  

        with open(f'{ROM_NAME}/texts/trtexts_offsets.json', "r") as outfile:  
            offset_table = json.load(outfile)

        trtext = bytearray()
        offsets = bytearray()

        for entry in trtext_table:
            trtext += entry[0].to_bytes(2, 'little')
            trtext += entry[1].to_bytes(2, 'little')

        for entry in offset_table:
            offsets += entry.to_bytes(2, 'little')

        table_narc_data.files[0] = trtext
        offset_narc_data.files[0] = offsets

        with open(trtext_table_path, "wb") as outfile:
            outfile.write(table_narc_data.save()) 

        with open(trtext_offsets_path, "wb") as outfile:
            outfile.write(offset_narc_data.save()) 


if len(sys.argv) > 2 and sys.argv[1] == "update":
    file_name = sys.argv[2]
    update_narc(file_name, sys.argv[3])
    


