require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'csv'
require 'pry'
require_relative 'helpers'

Dir["models/*.rb"].each {|file| require_relative file}

############# ROM EDITOR ROUTES ###########################

get '/' do
	$rom_name = SessionSettings.rom_name

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
	system "python python/rom_loader.py #{params['rom_name']}"
	content_type :json
  	{ url: "/headers" }.to_json
end

post '/rom/save' do
	$rom_name = SessionSettings.rom_name

	system "python python/rom_saver.py #{$rom_name}"
	return "200"
end



########################################## PERSONAL EDITOR ROUTES ####################

get '/personal' do
	@title = "- Personals"
	@active_header = 1
	$rom_name = SessionSettings.rom_name
	@poke_data = Personal.poke_data
	@moves = Move.get_all
	@move_names = Move.get_names_from @moves
	@tm_names = Tm.get_names
	@tutor_moves = Personal.tutor_moves


	@poke_data.each do |pok|
		if pok
			pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
		end
	end
	
	@pokemons = @poke_data[1..10]

	erb :personal
end

# loading rest of personal files
get '/personal/collection' do
	$rom_name = SessionSettings.rom_name

	@poke_data = Personal.poke_data
	@moves = Move.get_all

	@tm_names = Tm.get_names
	@tutor_moves = Personal.tutor_moves

	@poke_data.each do |pok|
		if pok
			pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
		end
	end

	@pokemons = @poke_data[11..-1]
	erb :personal_partial, layout: false
end

# called by ajax when user makes an edit
post '/personal' do 
	$rom_name = SessionSettings.rom_name

	narc_name = params['data']['narc']
	
	Object.const_get(narc_name.capitalize).write_data params["data"]
	system "python python/#{narc_name}_writer.py update #{params['data']['file_name']}"
	
	return 200
end


########################################## MOVE EDITOR ROUTES ####################

get '/moves' do 
	@title = "- Moves"
	@active_header = 4
	$rom_name = SessionSettings.rom_name
	
	@moves = Move.get_all
	@moves = @moves.to_a.sort_by {|mov| mov[0] }
	# @moves = @moves[0..10]
	
	@poke_data = Personal.poke_data
	@move_names = Move.get_names_from @moves

	erb :moves
end

get '/tms' do 
	@title = "- TMs"
	@active_header = 5
	$rom_name = SessionSettings.rom_name
	
	@moves = Move.get_all
	@tm_moves = Tm.get_tms_from @moves
	@move_names = Move.get_names_from @moves

	erb :tms
end

##################################################

get '/headers' do 
	@title = "- Headers"
	@active_header = 0
	$rom_name = SessionSettings.rom_name

	@header_data = Header.get_all


	@location_names = Header.location_names

	erb :headers
end