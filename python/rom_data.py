import code 
import io
import os
import os.path
from os import path
import json
import copy
import re


def set_global_vars():
	global LOCATIONS, ROM_NAME, NARC_FORMATS, POKEDEX, METHODS, ITEMS, MOVES, GROTTO_NAMES, HEADER_LENGTH, MART_LOCATIONS, TYPES, CATEGORIES, EFFECT_CATEGORIES, EFFECTS, STATUSES, TARGETS, STATS, PROPERTIES, RESULT_EFFECTS, EGG_GROUPS, GROWTHS, ABILITIES, TRAINER_CLASSES, BATTLE_TYPES, TRAINER_NAMES, AIS, TEMPLATE_FLAGS, ANIMATION_ID, B_ANIMATION_ID

	with open(f'session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings['rom_name']
		BASE_ROM = settings['base_rom']
		ANIMATION_ID = settings["move_animations"]
		B_ANIMATION_ID = settings["battle_animations"]


	LOCATIONS = open(f'{ROM_NAME}/texts/locations.txt', mode="r" ,encoding='utf-8').read().splitlines()
	POKEDEX = open(f'{ROM_NAME}/texts/pokedex.txt', "r").read().splitlines()
	ITEMS = open(f'{ROM_NAME}/texts/items.txt', mode="r").read().splitlines()
	MOVES = open(f'{ROM_NAME}/texts/moves.txt', mode="r").read().splitlines()
	MART_LOCATIONS = open(f'Reference_Files/mart_locations.txt', mode="r").read().splitlines()
	
	for i,move in enumerate(MOVES):
		MOVES[i] = re.sub(r'[^A-Za-z0-9 \-]+', '', move)
	
	METHODS = open(f'Reference_Files/evo_methods.txt', mode="r").read().splitlines()
	GROTTO_NAMES = open('Reference_Files/grotto_locations.txt', mode="r").read().splitlines()

	TYPES = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark","Fairy"]

	CATEGORIES = ["Status","Physical","Special"]

	EFFECT_CATEGORIES = ["No Special Effect", "Status Inflicting","Target Stat Changing","Healing","Chance to Inflict Status","Raising Target's Stat along Attack", "Lowering Target's Stat along Attack","Raise user stats","Lifesteal","OHKO","Weather","Safeguard", "Force Switch Out", "Unique Effect"]

	EFFECTS = open(f'Reference_Files/effects.txt', "r").read().splitlines() 

	STATUSES = ["None","Visible","Temporary","Infatuation", "Trapped"]

	TARGETS = ["Any adjacent","Random (User/ Adjacent ally)","Random adjacent ally","Any adjacent opponent","All excluding user","All adjacent opponents","User's party","User","Entire Field","Random adjacent opponent","Field Itself","Opponent's side of field","User's side of field","User (Selects target automatically)"]

	STATS = ["None", "Attack", "Defense", "Special Attack", "Special Defense", "Speed", "Accuracy", "Evasion", "All" ]

	PROPERTIES = ["contact","requires_charge","recharge_turn","blocked_by_protect","reflected_by_magic_coat","stolen_by_snatch","copied_by_mirror_move","punch_move","sound_move","grounded_by_gravity","defrosts_targets","hits_non-adjacent_opponents","healing_move","hits_through_substitute"]

	RESULT_EFFECTS = open(f'Reference_Files/result_effects.txt', "r").read().splitlines()

	EGG_GROUPS = ["~","Monster","Water 1","Bug","Flying","Field","Fairy","Grass","Human-Like","Water 3","Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"];
	GROWTHS = ["Medium Fast","Erratic","Fluctuating","Medium Slow","Fast","Slow","Medium Fast","Medium Fast"]
	ABILITIES = open(f'{ROM_NAME}/texts/abilities.txt', "r").read().splitlines() 

	TEMPLATE_FLAGS =["has_moves", "has_items"]

	TRAINER_CLASSES = open(f'{ROM_NAME}/texts/tr_classes.txt', "r").read().splitlines()
	TRAINER_NAMES = open(f'{ROM_NAME}/texts/tr_names.txt', "r").read().splitlines()
	BATTLE_TYPES = ["Singles", "Doubles", "Triples", "Rotation"]

	AIS = ["Prioritize Effectiveness",
	"Evaluate Attacks",
	"Expert",
	"Prioritize Status",
	"Risky Attacks",
	"Prioritize Damage",
	"Partner",
	"Double Battle",
	"Prioritize Healing",
	"Utilize Weather",
	"Harassment",
	"Roaming Pokemon",
	"Safari Zone",
	"Catching Demo"]



	NARC_FORMATS = {}



################## ENCOUNTERS ################################

	ENCOUNTER_NARC_FORMAT = []
	seasons = ["spring", "summer", "fall", "winter"]

	for season in seasons:
		s_encounters = [[1,f'{season}_grass_rate'],
		[1, f'{season}_grass_doubles_rate'],
		[1, f'{season}_grass_special_rate'],
		[1, f'{season}_surf_rate'],
		[1, f'{season}_surf_special_rate'],
		[1, f'{season}_super_rod_rate'],
		[1, f'{season}_super_rod_special_rate'],
		[1, f'{season}_blank']]

		for enc_type in ["grass", "grass_doubles", "grass_special"]:
			for n in range(0,12):
				s_encounters.append([2, f'{season}_{enc_type}_slot_{n}'])
				s_encounters.append([1, f'{season}_{enc_type}_slot_{n}_min_level'])
				s_encounters.append([1, f'{season}_{enc_type}_slot_{n}_max_level'])

		for wat_enc_type in ["surf", "surf_special", "super_rod" , "super_rod_special"]:
			for n in range(0,5):
				s_encounters.append([2, f'{season}_{wat_enc_type}_slot_{n}'])
				s_encounters.append([1, f'{season}_{wat_enc_type}_slot_{n}_min_level'])
				s_encounters.append([1, f'{season}_{wat_enc_type}_slot_{n}_max_level'])

		for entry in s_encounters:
			ENCOUNTER_NARC_FORMAT.append(entry)

	NARC_FORMATS["encounters"] = ENCOUNTER_NARC_FORMAT


################## EVOLUTIONS ################################


	EVO_NARC_FORMAT = []

	for n in range(0, 7):
		EVO_NARC_FORMAT.append([2, f'method_{n}'])
		EVO_NARC_FORMAT.append([2, f'param_{n}'])
		EVO_NARC_FORMAT.append([2, f'target_{n}'])

	NARC_FORMATS["evolutions"] = EVO_NARC_FORMAT


################## GROTTOS ################################

	GROTTO_NARC_FORMAT = []

	for version in ["white", "black"]:
		for rarity in ["rare", "uncommon", "common"]:
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([2, f'{version}_{rarity}_pok_{n}'])
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([1, f'{version}_{rarity}_max_lvl_{n}'])
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([1, f'{version}_{rarity}_min_lvl_{n}'])
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([1, f'{version}_{rarity}_gender_{n}'])
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([1, f'{version}_{rarity}_form_{n}'])

			GROTTO_NARC_FORMAT.append([2, f'{version}_{rarity}_padding'])

	for item_type in ["normal", "hidden"]:
		for rarity in ["superrare", "rare", "uncommon", "common"]:
			for n in range(0,4):
				GROTTO_NARC_FORMAT.append([2, f'{item_type}_{rarity}_item_{n}'])

	NARC_FORMATS["grottos"] = GROTTO_NARC_FORMAT


################## HEADERS ################################

	HEADER_LENGTH = 48

	HEADER_NARC_FORMAT = [[1, "map_type"],
	[1, "unknown_1"],
	[2, "texture_id"],
	[2, "matrix_id"],
	[2, "script_id"],
	[2, "level_script_id"],
	[2, "text_bank_id"],
	[2, "music_spring_id"],
	[2, "music_summer_id"],
	[2, "music_fall_id"],
	[2, "music_winter_id"],
	[2, "encounter_id"],
	[2, "map_id"],
	[2, "parent_map_id"],
	[1, "location_name_id"],
	[1, "name_style_id" ],
	[1, "weather_id"],
	[1, "camera_id"],
	[1, "unknown_2"],
	[1, "flags"],
	[2, "unknown_3"],
	[2, "name_icon"],
	[4, "fly_x"],
	[4, "fly_y"],
	[4, "fly_z"]]

	if BASE_ROM == 'BW2':
		HEADER_NARC_FORMAT = [[1, "map_type"],
		[1, "unknown_1"],
		[2, "texture_id"],
		[2, "matrix_id"],
		[2, "script_id"],
		[2, "level_script_id"],
		[2, "text_bank_id"],
		[2, "music_spring_id"],
		[2, "music_summer_id"],
		[2, "music_fall_id"],
		[2, "music_winter_id"],
		[1, "encounter_id"],
		[1, 'unknown_4'],
		[2, "map_id"],
		[2, "parent_map_id"],
		[1, "location_name_id"],
		[1, "name_style_id" ],
		[1, "weather_id"],
		[1, "camera_id"],
		[1, "unknown_2"],
		[1, "flags"],
		[2, "unknown_3"],
		[2, "name_icon"],
		[4, "fly_x"],
		[4, "fly_y"],
		[4, "fly_z"]]

	NARC_FORMATS["headers"] = HEADER_NARC_FORMAT

################## ITEMS ################################

	ITEM_NARC_FORMAT = [[2, "market_value"],
				[1, "battle_flags"],
				[1, "gain_values"],
				[1, "berry_flags"],
				[1, "held_flags"],
				[1, "unknown_flag_1"],
				[1, "nature_gift_power"],
				[2, "type_attribute"],
				[1, "item_group"],
				[1, "battle_item_group"],
				[1, "usability_flag"],
				[1, "item_type"],
				[1, "consumable_flag"],
				[1, "name_order_id"],
				[1, "status_removal_flag"], #also used ball_id
				[1, "hp_atk_boost"],
				[1, "def_spatk_boost"],
				[1, "spd_spdef_boost"],
				[1, "acc_crit_pp_boost"],
				[2, "pp_flags"],
				[1, "hp_ev_gain"],
				[1, "atk_ev_gain"],
				[1, "def_ev_gain"],
				[1, "spd_ev_gain"],
				[1, "spatk_ev_gain"],
				[1, "spdef_ev_gain"],
				[1, "hp_gain"],
				[1, "pp_gain"],
				[1, "battle_happiness"],
				[1, "ow_happiness"],
				[1, "hold_happiness"],
				[2, "padding"]]

	NARC_FORMATS["items"] = ITEM_NARC_FORMAT

################## LEARNSETS ################################

	LEARNSET_NARC_FORMAT = []

	for n in range(25):
		LEARNSET_NARC_FORMAT.append([2, f'move_id_{n}'])
		LEARNSET_NARC_FORMAT.append([2, f'lvl_learned_{n}'])

	NARC_FORMATS["learnsets"] = LEARNSET_NARC_FORMAT


################## MARTS ################################


	MART_NARC_FORMAT = []

	for n in range(0,20):
		MART_NARC_FORMAT.append([2, f'item_{n}'])

	NARC_FORMATS["marts"] = MART_NARC_FORMAT


################## MOVES ################################

	MOVE_NARC_FORMAT = [[1, "type"],
	[1,	"effect_category"],
	[1,	"category"],
	[1,	"power"],
	[1,	"accuracy"],
	[1,	"pp"],
	[1,	"priority"],
	[1,	"hits"],
	[2,	"result_effect"],
	[1,	"effect_chance"],
	[1,	"status"],
	[1,	"min_turns"],
	[1,	"max_turns"],
	[1,	"crit"],
	[1,	"flinch"],
	[2,	"effect"],
	[1,	"recoil"],
	[1,	"healing"],
	[1,	"target"],
	[1,	"stat_1"],
	[1,	"stat_2"],
	[1,	"stat_3"],
	[1,	"magnitude_1"],
	[1,	"magnitude_2"],
	[1,	"magnitude_3"],
	[1,	"stat_chance_1"],
	[1,	"stat_chance_2"],
	[1,	"stat_chance_3"],
	[2,	"flag"], ## Flag is always 53 53
	[2,	"properties"]]

	NARC_FORMATS["moves"] = MOVE_NARC_FORMAT

################## PERSONAL ################################

	PERSONAL_NARC_FORMAT = [[1, "base_hp"],
	[1,	"base_atk"],
	[1,	"base_def"],
	[1,	"base_speed"],
	[1,	"base_spatk"],
	[1,	"base_spdef"],
	[1,	"type_1"],
	[1,	"type_2"],
	[1,	"catchrate"],
	[1,	"stage"],
	[2,	"evs"],
	[2,	"item_1"],
	[2,	"item_2"],
	[2,	"item_3"],
	[1,	"gender"],
	[1,	"hatch_cycle"],
	[1,	"base_happy"],
	[1,	"exp_rate"],
	[1,	"egg_group_1"],
	[1,	"egg_group_2"],
	[1,	"ability_1"],
	[1,	"ability_2"],
	[1,	"ability_3"],
	[1,	"flee"],
	[2,	"form_id"],
	[2,	"form"],
	[1,	"num_forms"],
	[1,	"color"],
	[2,	"base_exp"],
	[2,	"height"],
	[2,	"weight"],
	[4, "tm_1-32"],
	[4, "tm_33-64"],
	[4, "tm_65-95+hm_1"],
	[4, "hm_2-6"],
	[1, "tutors"]]

	NARC_FORMATS["personal"] = PERSONAL_NARC_FORMAT


################## TRAINERS ################################

	TRDATA_NARC_FORMAT = [[1, "template"],
	[1, "class"],
	[1, "battle_type_1"],
	[1, "num_pokemon"],
	[2, "item_1"],
	[2, "item_2"],
	[2, "item_3"],
	[2, "item_4"],
	[4, "ai"],
	[1, "heal"],
	[1, "money"],
	[2, "reward_item"]]

	NARC_FORMATS["trdata"] = TRDATA_NARC_FORMAT








