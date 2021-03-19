import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import math


def read16(stream):
    return int.from_bytes(stream.read(2), 'little')

def read32(stream):
    return int.from_bytes(stream.read(4), 'little')

def char_check(v):
    return v & 0xFF == 0xFF

def to_char(v):
    try:
        return chr(v)
    except ValueError:
        return hex(v)

def parse_msg_bank(filepath, msg_bank):
    messages = ndspy.narc.NARC.fromFile(filepath)

    message = messages.files[msg_bank]

    # code.interact(local=dict(globals(), **locals()))
    stream = io.BytesIO(message)

    numblocks = read16(stream)
    numentries = read16(stream)
    filesize = read32(stream)
    zero = read32(stream)

    blockoffsets = [] # uint32 blockoffsets[numblocks]
    tableoffsets = [] # uint32 tableoffsets[numblocks][numentries]
    charcounts = [] # uint16 charcounts[numblocks][numentries]
    textflags = [] # uint16 textflags[numblocks][numentries]

    texts = [] # string texts[numblocks][numentries]

    for i in range(0, numblocks):
        blockoffsets.append(read32(stream))

    for i in range(0, numblocks):
        stream.seek(blockoffsets[i])
        blocksize = read32(stream)
        texts.append([])
        for j in range(0, numentries):
            tableoffsets.append([])
            charcounts.append([])
            textflags.append([])
            texts[i].append([])

            tableoffsets[i].append(read32(stream))
            charcounts[i].append(read16(stream))
            textflags[i].append(read16(stream))
        
        for j in range(0, numentries):
            encchars = [0]
            decchars = [0]
            string = ""
            specialCharON = False
            compressed = False
            stream.seek(blockoffsets[i] + tableoffsets[i][j])

            for k in range(0, charcounts[i][j]):
                encchars.append(read16(stream))
            key = encchars[-1] ^ 0xFFFF
            
            while encchars:
                enc = encchars.pop()
                decchars.append(enc ^ key)
                # print(f'enc: {enc}, key: {key}, result: {enc ^ key}')
                key = ((key>>3)|(key<<13))& 0xFFFF

            while decchars:
                char = decchars.pop()

                if (char == 0xE000 or char == 0x25BC or char == 0x25BD or char == 0xF100 or char == 0xFFFE or char == 0xFFFF):
                    if (char == 0xE000):
                        string += "\n"
                    if (char == 0x25BC):
                        string += "\r"
                    if (char == 0x25BD):
                        string += "\f"
                    if (char == 0xF100):
                        compressed = True
                    if (char == 0xFFFE):
                        string += "\v"
                        specialCharON = True

                else:        
                    if specialCharON:
                        string += "{0:#0{1}x}".format(char,6)[2:]
                    elif compressed:
                        continue
                    elif char == 0xFFFF:
                        break
                    elif char == 0xF000:
                        string += chr(char)
                    # CODE FOR DECOMPRESSION GOES HERE
                    # elif char > 300: 
                    #     # print(decompress.decomp(char))
                    #     string += chr(char)
                    #     continue
                    else:
                        string += chr(char)

            texts[i][j] = str(string)
    return texts





# readText = new System.IO.BinaryReader(File.OpenRead(textNamePath));
# readText.BaseStream.Position = 0x0;
# int stringNameCount = (int)readText.ReadUInt16();
# initialKey = (int)readText.ReadUInt16();
# key1 = (initialKey * 0x2FD) & 0xFFFF;
# key2 = 0;
# realKey = 0;
# specialCharON = false;
# currentOffset = new int[stringNameCount];
# currentSize = new int[stringNameCount];
# car = 0;
# bool compressed = false;
# for (int i = 0; i < stringNameCount; i++) // Reads and stores string offsets and sizes
# {
#     key2 = (key1 * (i + 1) & 0xFFFF);
#     realKey = key2 | (key2 << 16);
#     currentOffset[i] = ((int)readText.ReadUInt32()) ^ realKey;
#     currentSize[i] = ((int)readText.ReadUInt32()) ^ realKey;
# }
# for (int i = 0; i < stringNameCount; i++) // Adds new string
# {
#     key1 = (0x91BD3 * (i + 1)) & 0xFFFF;
#     readText.BaseStream.Position = currentOffset[i];
#     string pokemonText = "";
#     for (int j = 0; j < currentSize[i]; j++) // Adds new characters to string
#     {
#         car = readText.ReadUInt16() ^ key1;
#         #region Special Characters
#         if (car == 0xE000 || car == 0x25BC || car == 0x25BD || car == 0xF100 || car == 0xFFFE || car == 0xFFFF)
#         {
#             if (car == 0xE000)
#             {
#                 pokemonText += @"\n";
#             }
#             if (car == 0x25BC)
#             {
#                 pokemonText += @"\r";
#             }
#             if (car == 0x25BD)
#             {
#                 pokemonText += @"\f";
#             }
#             if (car == 0xF100)
#             {
#                 compressed = true;
#             }
#             if (car == 0xFFFE)
#             {
#                 pokemonText += @"\v";
#                 specialCharON = true;
#             }
#         }
#         #endregion
#         else
#         {
#             if (specialCharON == true)
#             {
#                 pokemonText += car.ToString("X4");
#                 specialCharON = false;
#             }
#             else if (compressed)
#             {
#                 #region Compressed String
#                 int shift = 0;
#                 int trans = 0;
#                 string uncomp = "";
#                 while (true)
#                 {
#                     int tmp = car >> shift;
#                     int tmp1 = tmp;
#                     if (shift >= 0xF)
#                     {
#                         shift -= 0xF;
#                         if (shift > 0)
#                         {
#                             tmp1 = (trans | ((car << (9 - shift)) & 0x1FF));
#                             if ((tmp1 & 0xFF) == 0xFF)
#                             {
#                                 break;
#                             }
#                             if (tmp1 != 0x0 && tmp1 != 0x1)
#                             {
#                                 string character = getChar.GetString(tmp1.ToString("X4"));
#                                 pokemonText += character;
#                                 if (character == null)
#                                 {
#                                     pokemonText += @"\x" + tmp1.ToString("X4");
#                                 }
#                             }
#                         }
#                     }
#                     else
#                     {
#                         tmp1 = ((car >> shift) & 0x1FF);
#                         if ((tmp1 & 0xFF) == 0xFF)
#                         {
#                             break;
#                         }
#                         if (tmp1 != 0x0 && tmp1 != 0x1)
#                         {
#                             string character = getChar.GetString(tmp1.ToString("X4"));
#                             pokemonText += character;
#                             if (character == null)
#                             {
#                                 pokemonText += @"\x" + tmp1.ToString("X4");
#                             }
#                         }
#                         shift += 9;
#                         if (shift < 0xF)
#                         {
#                             trans = ((car >> shift) & 0x1FF);
#                             shift += 9;
#                         }
#                         key1 += 0x493D;
#                         key1 &= 0xFFFF;
#                         car = Convert.ToUInt16(readText.ReadUInt16() ^ key1);
#                         j++;
#                     }
#                 }
#                 #endregion
#                 pokemonText += uncomp;
#             }
#             else
#             {
#                 string character = getChar.GetString(car.ToString("X4"));
#                 pokemonText += character;
#                 if (character == null)
#                 {
#                     pokemonText += @"\x" + car.ToString("X4");
#                 }
#             }
#         }
#         key1 += 0x493D;
#         key1 &= 0xFFFF;
#     }
#     names.Add(pokemonText);
#     compressed = false;
# }
# readText.Close();