#### To add a new editor to pokeweb

# add narc file path and name pair to rom_loader.py at line 58

# add narc name to parallel.py at line 39

# create file narc_name NARCNAME_reader.py in pokeweb/python, template as follows

import code 
import copy
import rom_data
import tools

def output_items_json(narc):
	tools.output_json(narc, YOUR_NARCNAME_HERE, to_readable)


def to_readable(raw, file_name):
	readable = copy.deepcopy(raw)

	# CONVERT FIELDS HERE
	return readable

# create narc_name.rb in pokeweb/models, template as follows (optional)

class YourNarcName < Pokenarc


	def self.get_all
		@@narc_name = "your_narcname"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "your_narcname"
		@@upcases = []
		super
	end
end

# create url for editor to route to in pokeweb/routes.rb, template as follows (optional)

get "/your_narc_name" do 
	@mynarcdata = YourNarcName.get_all

	erb :your_narc_name

end

# create html for editor in views your_narc_name.erb, use methods in helpers to define fields (optional)



# create NARCNAME_writer.py in pokeweb/python, template as follows

import code 
import copy
import sys
import rom_data
import tools


def output_narc(narc_name="your_narc_name"):
	tools.output_narc("your_narc_name")

def write_readable_to_raw(file_name, narc_name="your_narc_name"):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)

def to_raw(readable):
	raw = copy.deepcopy(readable)
	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2 and sys.argv[1] == "update":
	rom_data.set_global_vars()
	file_names = sys.argv[2].split(",")
	 
	for file_name in file_names:
		write_readable_to_raw(int(file_name))


# define narc file paths and in rom_saver.py 

import your_narc_name_writer

your_narc_name_writer.output_narc()
your_narc_name_narc_file_id = settings["your_narc_name"
your_narc_name_narc_filpath = f'{rom_name}/narcs/your_narcname-{your_narc_name_narc_file_id}.narc'
rom.files[your_narc_name_narc_file_id] = open(your_narc_name_narc_filepath, 'rb').read()








