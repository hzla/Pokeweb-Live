require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'csv'
require 'pry'
require_relative 'helpers'

Dir["models/*.rb"].each {|file| require_relative file}

before do
	$rom_name = SessionSettings.rom_name
	tabs = ['headers', 'personal', 'trainers', 'encounters', 'moves', 'tms', 'items']
	tab_name = request.path_info.split('/')[1]
	@active_header = tabs.find_index tab_name
	if tab_name
		@title = "- #{tab_name.capitalize}"
	end

end

############# ROM EDITOR ROUTES ###########################

get '/' do
	if $rom_name
		redirect "/headers"
	else
		@roms = Dir["*.nds"]
		erb :index
	end
end

get '/rom/new' do 
	SessionSettings.reset
	redirect '/'
end

# only ever called with ajax
post '/extract' do 
	# system "python python/rom_loader.py #{params['rom_name']}"

	system "python python/header_loader.py #{params['rom_name']}"

	command = "python python/rom_loader.py #{params['rom_name']}"
	pid = spawn command
	Process.detach(pid)

	content_type :json
  	{ url: "/headers" }.to_json
end

post '/rom/save' do
	system "python python/rom_saver.py #{$rom_name}"
	
	return "200"
end



########################################## PERSONAL EDITOR ROUTES ####################

get '/personal' do
	@poke_data = Personal.poke_data
	@moves = Move.get_all
	@move_names = Move.get_names_from @moves
	@tm_names = Tm.get_names
	@tutor_moves = Personal.tutor_moves

	@poke_data.each do |pok|
		if pok
			pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
		end # adds addtional move data to learnset data
	end	
	@pokemons = @poke_data[1..10]

	erb :personal
end

# loading rest of personal files
get '/personal/collection' do
	@poke_data = Personal.poke_data
	@moves = Move.get_all

	@tm_names = Tm.get_names
	@tutor_moves = Personal.tutor_moves

	@poke_data.each do |pok|
		if pok
			pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
		end # adds addtional move data to learnset data
	end

	@pokemons = @poke_data[11..-1]
	erb :personal_partial, layout: false
end

# called by ajax when user makes an edit
post '/personal' do 
	narc_name = params['data']['narc']
	
	Object.const_get(narc_name.capitalize).write_data params["data"]
	
	command = "python python/#{narc_name}_writer.py update #{params['data']['file_name']}"
	pid = spawn command
	Process.detach(pid)

	return 200
end


########################################## MOVE EDITOR ROUTES ####################

get '/moves' do 	
	@moves = Move.get_all
	@moves = @moves[0..10]
	
	@poke_data = Personal.poke_data
	@move_names = Move.get_names_from @moves

	erb :moves
end

get '/tms' do 	
	@moves = Move.get_all
	@tm_moves = Tm.get_tms_from @moves
	@move_names = Move.get_names_from @moves

	erb :tms
end

####################### HEADERS ###########################

get '/headers' do 
	@header_data = Header.get_all
	@location_names = Header.location_names

	erb :headers
end

####################### ENCOUNTERS ###########################

get '/encounters' do 
	@encounters = Encounter.get_all
	@location_names = Header.location_names

	erb :encounters
end

####################### TRAINERS ###########################

get '/trainers' do 
	@trainers = Trdata.get_all
	@trainer_poks = Trpok.get_all
	@move_names = Move.get_names_from Move.get_all

	@names = Trdata.names
	@class_names = Trdata.class_names
	
	
	erb :trainers
end

post '/create' do
	narc_name = params['data']['narc']
	
	created = Object.const_get(narc_name.capitalize).create params["data"]

	erb ("_" + narc_name).to_sym, :layout => false, :locals => { narc_name.to_sym => created, "#{narc_name}_index".to_sym => params['data']['sub_index'], :show => "show-flex" }
end

post '/delete' do 
	narc_name = params['data']['narc']
	created = Object.const_get(narc_name.capitalize).delete params["data"]
	return 200
end
