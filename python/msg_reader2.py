import ndspy
import ndspy.rom
import ndspy.narc
import code 
import codecs
import io
import math
import struct, re
import json
import io as StringIO
import os
import subprocess
# import unicodeparser
from binary16 import binaryreader, binarywriter


def set_global_vars():
    global ROM_NAME, NARC_FORMAT, STORY_NARC_FILE_ID,MESSAGE_NARC_FILE_ID
    
    with open(f'session_settings.json', "r") as outfile:  
        settings = json.load(outfile) 
        ROM_NAME = settings['rom_name']
        STORY_NARC_FILE_ID = settings["story_texts"]
        MESSAGE_NARC_FILE_ID = settings["message_texts"]


def gen5get(f):
    texts = []
    reader = binaryreader(f)
    
    numblocks = reader.read16()
    numentries = reader.read16()
    filesize = reader.read32()
    zero = reader.read32()
    blockoffsets = []
    for i in range(numblocks):
        blockoffsets.append(reader.read32())
    # filesize == len(f)-reader.pos()
    for i in range(numblocks):
        reader.seek(blockoffsets[i])
        size = reader.read32()
        tableoffsets = []
        charcounts = []
        textflags = []
        initial_key = 0
        for j in range(numentries):
            tableoffsets.append(reader.read32())
            charcounts.append(reader.read16())
            textflags.append(reader.read16())
        for j in range(numentries):
            compressed = False
            encchars = []
            text = ""
            reader.seek(blockoffsets[i]+tableoffsets[j])
            for k in range(charcounts[j]):
                encchars.append(reader.read16())
            key = encchars[len(encchars)-1]^0xFFFF
            initial_key = encchars[len(encchars)-1]
            decchars = []
            # print(initial_key)
            while encchars:
                encoded = encchars.pop()
                char = encoded ^ key
                key = ((key>>3)|(key<<13))&0xFFFF
                decchars.insert(0, char)
            # print(f'end: {key}')
            if decchars[0] == 0xF100:
                compressed = True
                decchars.pop(0)
                newstring = []
                container = 0
                bit = 0
                while decchars:
                    container |= decchars.pop(0)<<bit
                    bit += 16
                    while bit >= 9:
                        bit -= 9
                        c = container&0x1FF
                        if c == 0x1FF:
                            newstring.append(0xFFFF)
                        else:
                            newstring.append(c)
                        container >>= 9
                decchars = newstring
            while decchars:
                c = decchars.pop(0)
                if c == 0xFFFF:
                    break
                elif c == 0xFFFE:
                    text += "\\n"
                elif c < 20 or c > 0xF000:
                    text += "\\x%04X"%c
                elif c == 0xF000:
                    try:
                        kind = decchars.pop(0)
                        count = decchars.pop(0)
                        if kind == 0xbe00 and count == 0:
                            text += "\\f"
                            continue
                        if kind == 0xbe01 and count == 0:
                            text += "\\r"
                            continue
                        text += "VAR("
                        args = [kind]
                        for k in range(count):
                            args.append(decchars.pop(0))
                    except IndexError:
                        break
                    text += ", ".join(map(str, args))
                    text += ")"
                else:
                    text += chr(c)
            e = "%i_%i"%(i, j)
            flag = ""
            val = textflags[j]
            c = 65
            while val:
                if val&1:
                    # print(c)
                    # print(chr(c))
                    flag += chr(c)
                c += 1
                val >>= 1
            if compressed:
                flag += "c"
            e += flag
            texts.append([e, text, initial_key])
    return texts

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

def output_texts(folder, narc):
    n = 0
    texts = []
    print("outputting texts")
    for message in narc.files:   
        with open(f'{folder}/{n}.bin', "wb") as binary_file:
            binary_file.write(message)
        
        try: 
            block = gen5get(message)
        except:
            block = [[]]
        
        texts.append(block)

        n += 1

    with codecs.open(f'{folder}/texts.json', 'w', encoding='utf_8') as f:
        json.dump(texts, f)

def output_scripts(folder, narc):
    print("outputting scripts")
    
    for n, message in enumerate(narc.files):   
        with open(f'{folder}/{n}.bin', "wb") as binary_file:
            binary_file.write(message)

def output_move_scripts(folder, narc):
    print("outputting scripts")
    
    for n, message in enumerate(narc.files):   
        with open(f'{folder}/{n}.bin', "wb") as binary_file:
            binary_file.write(message)
        






def output_narc():
    set_global_vars()

    with codecs.open(f'{ROM_NAME}/message_texts/texts.json', 'r', encoding='utf_8') as f:
        texts = json.load(f)
        narcfile_path = f'{ROM_NAME}/narcs/message_texts-{MESSAGE_NARC_FILE_ID}.narc'
        narc = ndspy.narc.NARC.fromFile(narcfile_path)

        for idx, text in enumerate(texts):
            try:
                data = gen5put(text)
                narc.files[idx] = data
            except:
                # print(idx)
                continue

        old_narc = open(narcfile_path, "wb")
        old_narc.write(narc.save()) 

    with codecs.open(f'{ROM_NAME}/story_texts/texts.json', 'r', encoding='utf_8') as f:
        texts = json.load(f)
        narcfile_path = f'{ROM_NAME}/narcs/story_texts-{STORY_NARC_FILE_ID}.narc'
        narc = ndspy.narc.NARC.fromFile(narcfile_path)

        for idx, text in enumerate(texts):
            try:
                data = gen5put(text)
                narc.files[idx] = data
            except:
                # print(idx)
                continue

        old_narc = open(narcfile_path, "wb")
        old_narc.write(narc.save()) 

    print("texts narc saved")







