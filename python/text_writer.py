import ndspy
import ndspy.rom
import ndspy.narc
import code 
import codecs
import io
import math
import struct, re
import json
from binary16 import binaryreader, binarywriter
import sys



def gen5put(texts):
    textofs = {}
    sizes = {}
    comments = {}
    textflags = {}
    blockwriters = {}
    for entry in texts:
        match = re.match("([^_]+)_([0-9]+)(.*)", entry[0])
        if not match:
            continue
        blockid = match.group(1)
        textid = int(match.group(2))
        flags = match.group(3)
        text = entry[1]
        if blockid.lower() == "comment":
            comments[textid] = text
            continue
        blockid = int(blockid)
        if blockid not in blockwriters:
            blockwriters[blockid] = binarywriter()
            textofs[blockid] = {}
            sizes[blockid] = {}
            textflags[blockid] = {}
        textofs[blockid][textid] = blockwriters[blockid].pos()
        dec = []
        while text:
            c = text[0]
            text = text[1:]
            if c == '\\':
                c = text[0]
                text = text[1:]
                if c == 'x':
                    n = int(text[:4], 16)
                    text = text[4:]
                elif c == 'n':
                    n = 0xFFFE
                elif c == 'r':
                    dec.append(0xF000)
                    dec.append(0xbe01)
                    dec.append(0)
                    continue
                elif c == 'f':
                    dec.append(0xF000)
                    dec.append(0xbe00)
                    dec.append(0)
                    continue
                else:
                    n = 1
                dec.append(n)
            elif c == 'V':
                if text[:2] == "AR":
                    text = text[3:]
                    eov = text.find(")")
                    args = list(map(int, text[:eov].split(",")))
                    text = text[eov+1:]
                    dec.append(0xF000)
                    dec.append(args.pop(0))
                    dec.append(len(args))
                    for a in args:
                        dec.append(a)
                else:
                    dec.append(ord('V'))
            else:
                dec.append(ord(c))
        flag = 0
        for i in range(16):
            if chr(65+i) in flags:
                flag |= 1<<i
        textflags[blockid][textid] = flag
        if "c" in flags:
            comp = [0xF100]
            container = 0
            bit = 0
            while dec:
                c = dec.pop(0)
                if c>>9:
                    print("Illegal compressed character: %i"%c)
                container |= c<<bit
                bit += 9
                while bit >= 16:
                    bit -= 16
                    comp.append(container&0xFFFF)
                    container >>= 16
            container |= 0xFFFF<<bit
            comp.append(container&0xFFFF)
            dec = comp[:]
        key = 0
        enc = []
        while dec:
            char = dec.pop() ^ key
            key = ((key>>3)|(key<<13))&0xFFFF
            enc.insert(0, char)
        enc.append(key^0xFFFF)
        sizes[blockid][textid] = len(enc)
        for e in enc:
            blockwriters[blockid].write16(e)
    numblocks = max(blockwriters)+1
    if numblocks != len(blockwriters):
        raise KeyError
    numentries = 0
    for block in blockwriters:
        numentries = max(numentries, max(textofs[block])+1)
    offsets = []
    baseofs = 12+4*numblocks
    textblock = binarywriter()
    for i in range(numblocks):
        data = blockwriters[i].toarray()
        offsets.append(baseofs+textblock.pos())
        relofs = numentries*8+4
        textblock.write32(len(data)+relofs)
        for j in range(numentries):
            textblock.write32(textofs[i][j]+relofs)
            textblock.write16(sizes[i][j])
            textblock.write16(textflags[i][j])
        textblock.writear(data)
    writer = binarywriter()
    writer.write16(numblocks)
    writer.write16(numentries)
    writer.write32(textblock.pos())
    writer.write32(0)
    for i in range(numblocks):
        writer.write32(offsets[i])
    writer.writear(textblock.toarray())
    return writer.tostring()


def set_global_vars():
    global ROM_NAME, NARC_FILE_IDS
    
    NARC_FILE_IDS = {}
    with open(f'session_settings.json', "r") as outfile:  
        settings = json.load(outfile) 
        ROM_NAME = settings['rom_name']
        NARC_FILE_IDS["story_texts"] = settings["story_texts"]
        NARC_FILE_IDS["message_texts"] = settings["message_texts"]
        NARC_FILE_IDS["trtext_table"] = settings["trtext_table"]
        NARC_FILE_IDS["trtext_offsets"] = settings["trtext_offsets"]
 


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
    


