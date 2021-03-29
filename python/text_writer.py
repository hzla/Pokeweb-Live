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
        key = entry[2]
        enc = []
        print(key)
        while dec:
            char = dec.pop() ^ key
            key = ((key>>3)|(key<<13))&0xFFFF
            enc.insert(0, char)
        enc.append(entry[2])
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

    print(narc_data.files[bank_id])
    narc_data.files[bank_id] = gen5put(message_data)
    print("AFTER")
    print(narc_data.files[bank_id])

    
    with open(file_name, "wb") as outfile:
        outfile.write(narc_data.save())  



print(gen5put([['0_0', "Bianca: OK! I'll show you around\\nthe Pokémon Center!\\r", 28368], ['0_1', 'The Pokémon Center heals\\nPokémon for free!\\r\\nYou should bring your Pokémon here\\nanytime they are weak.\\r', 54908], ['0_2', "I'll heal your Pokémon.\\nHand me your Poké Ball for a sec!\\r", 1795], ['0_3', "Next, I'll explain the PC!\\r", 30339], ['0_4', 'This square thing is a PC!\\nAny Trainer is free to use it!\\r\\nYou can deposit Pokémon in it.\\r\\nAlso, you can withdraw\\nPokémon from it!\\r', 22251], ['0_5', 'The next thing is over here!\\r', 63100], ['0_6', 'This is the Poké Mart!\\r\\nHere you can buy and\\nsell many different items!\\r\\nThe Poké Balls you use\\nto catch Pokémon can also\\f\\nbe bought at the Poké Mart!\\r', 37196], ['0_7', "Here, VAR(256, 0),\\nI'll give you some Poké Balls!\\r", 28848], ['0_8', "Here, VAR(256, 0),\\nI'll give you some Poké Balls!\\r", 44827], ['0_9', "Bianca: Next up!\\r\\nI'll show you how\\nto use those Poké Balls!\\f\\nFollow me!\\r", 25019], ['0_10', 'Oh?\\nYour VAR(257, 1)...\\r', 45512], ['0_11', "Its Nature is VAR(264, 2)!\\r\\nWith a Pokémon like that by your side,\\nI'm sure you'll have a fun journey!", 54957], ['0_12', "All right! Here's some advice from a\\nguy who spends all of his time\\f\\nin Pokémon Centers!\\r\\nWhen your Pokémon's HP goes down,\\nmake sure to restore it!", 21137]]))


if len(sys.argv) > 2 and sys.argv[1] == "update":
    file_name = sys.argv[2]
    update_narc(file_name, sys.argv[3])
    


# message = b'\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x80\x00\x00\x00\x0c\x00\x00\x009\x00\x00\x00\xc5|$\xe40"\x92\x12\xe9\x97\xbaA|\xf2@\x91\t\x89\xc3KT_w\xf9\xb7\xc8\xd8D\x9d%\xe4/\xe7|/\xe4\x7f"\x98\x12\xe8\x97*\xbeD\xf2]\x91\x0e\x89\x8bKU_2\xf9\xe7\xc8\xdfD\x86%\xf9/\xa8|K\x14^\x9c\xf9\x126h\x13\xbeL\xf2C\x91\x10\x89\xc4K[_}\xf9\xe2\xc8\x9eD\x94%\xfe/\xe5|\'\xe40"\x8e\x12\xe8\x97-\xbeQ\xf2\x10\x91\x83v\x0c\x0c'


