require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'csv'
require 'pry'
require 'httparty'
require_relative 'helpers'

Dir["models/*.rb"].each {|file| require_relative file}

############# ROM EDITOR ROUTES ###########################

get '/' do
	$rom_name = SessionSettings.rom_name

	if $rom_name
		redirect "/roms/#{$rom_name}/personal"
	else
		@roms = Dir["*.nds"]
		erb :index
	end
end

get '/rom/new' do 
	File.delete("session_settings.json") if File.exist?("session_settings.json")
	redirect '/'
end


# only ever called with ajax
post '/extract' do 
	system "python python/rom_loader.py #{params['rom_name']}"
	content_type :json
  	{ url: "roms/#{params[:rom_name][0..-5]}/personal" }.to_json
end

post '/rom/save' do
	$rom_name = SessionSettings.rom_name

	system "python python/rom_saver.py #{$rom_name}"
	return "200"
end



########################################## PERSONAL EDITOR ROUTES ####################

get '/roms/:rom_name/personal' do

	$rom_name = SessionSettings.rom_name

	@poke_data = Personal.poke_data

	@moves = Move.get_all
	@move_names = Move.get_names_from @moves

	@poke_data.each do |pok|
		if pok
			pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
		end
	end
	
	@pokemons = @poke_data[1..10]

	erb :personal
end

# loading rest of personal files
get '/roms/:rom_name/personal/collection' do
	$rom_name = SessionSettings.rom_name

	@poke_data = Personal.poke_data
	@moves = Move.get_all

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

get '/roms/:rom_name/moves' do 
	$rom_name = SessionSettings.rom_name
	
	@moves = Move.get_all
	@moves = @moves.to_a.sort_by {|mov| mov[0] }
	
	@poke_data = Personal.poke_data
	@move_names = Move.get_names_from @moves

	erb :moves
end