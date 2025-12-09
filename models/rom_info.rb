class RomInfo

	def self.pokemon_names
		file_path = "#{$rom_name}/texts/pokedex.txt"
		data = File.open(file_path, "r:ISO8859-1").read.split("\n").map do |p|
			p.name_titleize
		end
	end

    def self.pokemon_center_headers
        ids = [9,21,42,66,100,110,116,123,399,408,414,426,436,444,455,461,473]
        gyms = [436,455,42,66,100,110,123,473]
        [ids, gyms]

    end

    def self.original_move_count 
        contents = File.open("#{$rom_name}/session_settings.json", "r") do |f|
            f.read
        end
        return JSON.parse(contents)["original_move_count"] || 559
    end


	def self.types
		typing = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark"].map do |type|
			type.upcase
		end
        typing << "FAIRY" if $fairy
        typing
	end

	def self.abilities
		File.open("#{$rom_name}/texts/abilities.txt"){|f| f.read}.split("\n").map do |ab|
			ab.titleize
		end
	end

	def self.evo_methods
		File.open("Reference_Files/evo_methods.txt"){|f| f.read}.split("\n")
	end

	def self.items
		# encoding for latin text ISO8859-1
		File.open("#{$rom_name}/texts/items.txt"){|f| f.read}.split("\n")
	end

	def self.egg_groups
		["~","Monster","Water 1","Bug","Flying","Field","Fairy","Grass","Human-Like","Water 3","Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"]
	end

	def self.growth_rates
		["Medium Fast","Erratic","Fluctuating","Medium Slow","Fast","Slow"]
	end

	def self.status_types
		["None","Visible","Temporary","Infatuation", "Trapped"]
	end

	def self.natures
		 ["Hardy",
		"Lonely",
		"Brave",
		"Adamant",
		"Naughty",
		"Bold",
		"Docile",
		"Relaxed",
		"Impish",
		"Lax",
		"Timid",
		"Hasty",
		"Serious",
		"Jolly",
		"Naive",
		"Modest",
		"Mild",
		"Quiet",
		"Bashful",
		"Rash",
		"Calm",
		"Gentle",
		"Sassy",
		"Careful",
		"Quirky"]
	end

	def self.targets 
		["Any adjacent","Random (User/ Adjacent ally)","Random adjacent ally","Any adjacent opponent","All excluding user","All adjacent opponents","User's party","User","Entire Field","Random adjacent opponent","Field Itself","Opponent's side of field","User's side of field","User (Selects target automatically)"]
	end

	def self.stats
		["None", "Attack", "Defense", "Special Attack", "Special Defense", "Speed", "Accuracy", "Evasion", "All" ]
	end

	def self.effects
		File.open("Reference_Files/effects.txt"){|f| f.read}.split("\n")
	end

	def self.result_effects
		File.open("Reference_Files/result_effects.txt"){|f| f.read}.split("\n")
	end

	def self.class_names
		names =[]
		File.open("#{$rom_name}/texts/tr_classes.txt"){|f| f.read}.split("\n").each_with_index do |n, i|
			names << "#{n} (#{i})"
		end
		names
	end

	def self.effect_cats
		["No Special Effect", "Status Inflicting","Target Stat Changing","Healing","Chance to Inflict Status","Raising Target's Stat along Attack", "Lowering Target's Stat along Attack","Raise user stats","Lifesteal","OHKO","Weather","Safeguard", "Force Switch Out", "Unique Effect"]
	end

	def self.battle_types
		["Singles", "Doubles", "Triples", "Rotation"]
	end

	def self.genders
		["Default", "Female", "Male"]
	end


    def self.form_info
        forms = {}
        forms["Kyogre"] = ["Primal"]
        forms["Groudon"] = ["Primal"]
        forms["Deoxys"] = ['Attack', 'Defense', 'Speed']
        forms["Shaymin"] = ["Sky"]
        forms["Giratina"] = ["Origin"]
        forms["Palkia"] = ["Origin"]
        forms["Dialga"] = ["Origin"]
        forms["Rotom"] = ["Heat", "Wash", "Frost", "Fan", "Mow"]
        forms["Castorm"] = ["Sunny", "Rainy", "Snowy"]
        forms["Basculin"] = ["Blue-Striped", "White-Striped"]
        forms["Darmanitan"] = ["Zen"]
        forms["Meloetta"] = ["Pirouette"]
        forms["Kyurem"] = ["White", "Black"]
        forms["Keldeo"] = ["Resolute"]
        forms["Tornadus"] = ["Therian"]
        forms["Thundurus"] = ["Therian"]
        forms["Landorus"] = ["Therian"]
        forms["Burmy"] = ["Sandy", "Trash"]
        forms["Wormadam"] = ["Sandy", "Trash"]
        forms["Genesect"] = ["Douse", "Chill", "Burn", "Shock"]
        forms["Greninja"] = ["Ash", "Bond"]
        forms["Meowstic"] = ["F"]
        forms["Indeedee"] = ["F"]
        forms["Pumpkaboo"] = ["Small","Large","Jumbo"]
        forms["Gourgeist"] = ["Small","Large","Jumbo"]
        forms["Zygarde"] = ["10%", "Complete"]
        forms["Hoopa"] = ["Unbound"]
        forms["Oricorio"] = ["Baile", "Pom-Pom", "Pa'u", "Sensu"]
        forms["Lycanroc"] = ["Midnight", "Dusk"]
        forms["Necrozma"] = ["Dusk-Mane", "Dawn-Wings", "Ultra"]
        forms["Toxtricity"] = ["Low-Key"]
        forms["Sinistea"] = ["Phony", "Antique"]
        forms["Polteageist"] = ["Phony", "Antique"]
        forms["Urshifu"] = ["Rapid-Strike"]
        forms["Zarude"] = ["Dada"]
        forms["Calyrex"] = ["Ice", "Shadow"]
        forms["Ursaluna"] = ["Bloodmoon"]
        forms["Maushold"] = ["Four"]
        forms["Slowbro"] = ["Mega"]
        forms["Tauros"] = ["Paldea-Combat", "Paldea-Blaze", "Paldea-Aqua"]

        alolan_mons = ["Rattata, Raticate","Raichu","Sandshrew", "Sandlsash", "Vulpix","Ninetales","Diglett","Dugtrio","Geodude", "Graveler","Golem","Persian","Grimer", "Muk","Exeggutor","Marowak"]   
        galar_mons = ["Meowth", "Ponyta","Rapidash", "Slowpoke","Slowbro", "Farfetch'd","Weezing", "Mr. Mime","Articuno","Zapdos","Moltres","Slowking","Corsola","Zigzagoon","Linoone","Darmanitan","Yamask","Stunfisk"]
        hisui_mons = ["Growlithe","Arcanine","Voltorb", "Electrode","Typhlosion","Qwilfish","Sneasel","Lilligant","Zorua", "Zoroark","Braviary","Sligoo","Goodra","Avalugg","Decidueye"]
        paldea_mons = ["Wooper"]

        regional_mons = [alolan_mons, galar_mons, hisui_mons, paldea_mons]
        region_names = ["Alola", "Galar","Hisui","Paldea"]
        regional_mons.each_with_index do |region, i|
            region.each do |mon|
                forms[mon] ||= []
                forms[mon] << region_names[i]
            end
        end
        
        forms
    end

	def self.showdown_abilities 
		[
    "Adaptability",
    "Aftermath",
    "Air Lock",
    "Analytic",
    "Anger Point",
    "Anticipation",
    "Arena Trap",
    "Bad Dreams",
    "Battle Armor",
    "Big Pecks",
    "Blaze",
    "Chlorophyll",
    "Clear Body",
    "Cloud Nine",
    "Color Change",
    "Compound Eyes",
    "Contrary",
    "Cursed Body",
    "Cute Charm",
    "Damp",
    "Defeatist",
    "Defiant",
    "Download",
    "Drizzle",
    "Drought",
    "Dry Skin",
    "Early Bird",
    "Effect Spore",
    "Filter",
    "Flame Body",
    "Flare Boost",
    "Flash Fire",
    "Flower Gift",
    "Forecast",
    "Forewarn",
    "Friend Guard",
    "Frisk",
    "Gluttony",
    "Guts",
    "Harvest",
    "Healer",
    "Heatproof",
    "Heavy Metal",
    "Honey Gather",
    "Huge Power",
    "Hustle",
    "Hydration",
    "Hyper Cutter",
    "Ice Body",
    "Illuminate",
    "Illusion",
    "Immunity",
    "Imposter",
    "Infiltrator",
    "Inner Focus",
    "Insomnia",
    "Intimidate",
    "Iron Barbs",
    "Iron Fist",
    "Justified",
    "Keen Eye",
    "Klutz",
    "Leaf Guard",
    "Levitate",
    "Light Metal",
    "Lightning Rod",
    "Limber",
    "Liquid Ooze",
    "Magic Bounce",
    "Magic Guard",
    "Magma Armor",
    "Magnet Pull",
    "Marvel Scale",
    "Minus",
    "Mold Breaker",
    "Moody",
    "Motor Drive",
    "Mountaineer",
    "Moxie",
    "Multiscale",
    "Multitype",
    "Mummy",
    "Natural Cure",
    "No Guard",
    "Normalize",
    "Oblivious",
    "Overcoat",
    "Overgrow",
    "Own Tempo",
    "Persistent",
    "Pickpocket",
    "Pickup",
    "Plus",
    "Poison Heal",
    "Poison Point",
    "Poison Touch",
    "Prankster",
    "Pressure",
    "Pure Power",
    "Quick Feet",
    "Rain Dish",
    "Rattled",
    "Rebound",
    "Reckless",
    "Regenerator",
    "Rivalry",
    "Rock Head",
    "Rough Skin",
    "Run Away",
    "Sand Force",
    "Sand Rush",
    "Sand Stream",
    "Sand Veil",
    "Sap Sipper",
    "Scrappy",
    "Serene Grace",
    "Shadow Tag",
    "Shed Skin",
    "Sheer Force",
    "Shell Armor",
    "Shield Dust",
    "Simple",
    "Skill Link",
    "Slow Start",
    "Sniper",
    "Snow Cloak",
    "Snow Warning",
    "Solar Power",
    "Solid Rock",
    "Soundproof",
    "Speed Boost",
    "Stall",
    "Static",
    "Steadfast",
    "Stench",
    "Sticky Hold",
    "Storm Drain",
    "Sturdy",
    "Suction Cups",
    "Super Luck",
    "Swarm",
    "Swift Swim",
    "Synchronize",
    "Tangled Feet",
    "Technician",
    "Telepathy",
    "Teravolt",
    "Thick Fat",
    "Tinted Lens",
    "Torrent",
    "Toxic Boost",
    "Trace",
    "Truant",
    "Turboblaze",
    "Unaware",
    "Unburden",
    "Unnerve",
    "Victory Star",
    "Vital Spirit",
    "Volt Absorb",
    "Water Absorb",
    "Water Veil",
    "Weak Armor",
    "White Smoke",
    "Wonder Guard",
    "Wonder Skin",
    "Zen Mode"
	]
	end
end

