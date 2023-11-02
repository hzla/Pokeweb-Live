from struct import unpack
from setuptools import Command
from yaml import dump, load, Loader
from sys import argv
import json

AddressesPerEntry = 0xE

move_file_location = argv[2]
print(move_file_location)

move_data = {}
with open(move_file_location) as move:
    move_data = json.load(move)
    move_data["readable"]["spas"] = [] 


CommandSet = None
with open('tools/movecommands/MOV_SCRCMD.yml', 'r') as DATA:
    CommandSet = load(DATA, Loader=Loader)
    DATA.close()

with open('B2W2_MOVSCRCMD.s', 'w') as MOVSCRCMD_INC:
    for Index, Command in CommandSet.items():

        if "Alias" in Command:
            MOVSCRCMD_INC.write(f'.macro {Command["Alias"]} ')
            SpaceCharacter = " " if Command['Parameters'] is not None else ""
            if Command['Parameters'] is not None:
                for Parameter in Command['Parameters']:
                    SpaceCharacter = " " if Command['Parameters'].index(Parameter) != len(Command['Parameters']) - 1 else ""
                    MOVSCRCMD_INC.write(f'{Parameter["Name"]}{SpaceCharacter}')
            MOVSCRCMD_INC.write('\n')
            MOVSCRCMD_INC.write(f'.hword {Index}\n')
            if Command['Parameters'] is not None:
                for Parameter in Command['Parameters']:
                    if Parameter['Type'] == "int":
                        MOVSCRCMD_INC.write(f'.word \{Parameter["Name"]}\n')
                    else:
                        break

     
            MOVSCRCMD_INC.write(f'.endm\n')
            MOVSCRCMD_INC.write(f'\n')

        MOVSCRCMD_INC.write(f'.macro {Command["Name"]} ')
        SpaceCharacter = " " if Command['Parameters'] is not None else ""
        if Command['Parameters'] is not None:
            for Parameter in Command['Parameters']:
                SpaceCharacter = " " if Command['Parameters'].index(Parameter) != len(Command['Parameters']) - 1 else ""
                MOVSCRCMD_INC.write(f'{Parameter["Name"]}{SpaceCharacter}')
        MOVSCRCMD_INC.write('\n')
        MOVSCRCMD_INC.write(f'.hword {Index}\n')
        if Command['Parameters'] is not None:
            for Parameter in Command['Parameters']:
                if Parameter['Type'] == "int":
                        MOVSCRCMD_INC.write(f'.word \{Parameter["Name"]}\n')
                else:
                    break
        
        MOVSCRCMD_INC.write(f'.endm\n')
        MOVSCRCMD_INC.write(f'\n')
    MOVSCRCMD_INC.close()


lines = []


with open(argv[1], 'rb') as SCRIPT:
    Addresses = []
    Count = unpack('<L', SCRIPT.read(0x4))[0]
    print(f'.include \"B2W2_MOVSCRCMD.s\"')
    print(f'.align 4')
    print()
    print(f'.word {Count} @ Count')
    for Index in range(Count):
        Addresses += set(unpack('<' + 'L' * AddressesPerEntry, SCRIPT.read(AddressesPerEntry * 0x4)))
        for Address in Addresses:
            for Pass in range(AddressesPerEntry):
                print(f'.word SCRIPT_{Address}')
    print()
    for Address in Addresses:
        SCRIPT.seek(Address)
        print(f'SCRIPT_{Address}:')
        while True:
            CommandIndex = unpack('<H', SCRIPT.read(0x2))[0]
            CommandData = CommandSet[CommandIndex]
            ParameterData = []
            if CommandData['Parameters'] is not None:
                for Parameter in CommandData['Parameters']:
                    if Parameter['Type'] == "int":
                        ParameterData.append(unpack('<l', SCRIPT.read(0x4))[0])
                    else:
                        break
            print(' ' * 4, CommandData["Name"], end=' ')
            print(*ParameterData, sep=', ')

            if "LoadSPA" in CommandData["Name"]:
                move_data["readable"]["spas"].append(ParameterData[0]) 
            if 'End' in CommandData.keys():
                break
        print()


with open(move_file_location, "w") as outfile:  
    json.dump(move_data, outfile)