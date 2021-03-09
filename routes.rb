require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'csv'
require 'pry'
require 'httparty'
require_relative 'helpers'
require_relative 'models/models'


# set :server, %w[thin]


############# ROM SETUP ROUTES ###########################

get '/' do
	$rom_name = SessionSettings.rom_name

	if $rom_name
		redirect "/roms/#{$rom_name}/personal"
	else
		@roms = Dir["*.nds"]
		erb :index
	end
end

get '/roms/new' do 
	File.delete("session_settings.json") if File.exist?("session_settings.json")
	redirect '/'
end


# only ever called with ajax
post '/extract' do 
	system("python python/rom_loader.py #{params[:rom_name]}")
	content_type :json
  	{ url: "roms/#{params[:rom_name][0..-5]}/personal" }.to_json
end

get '/save_rom' do
	$rom_name = SessionSettings.rom_name
end



##########################################  EDITOR ROUTES ####################


get '/roms/:rom_name/personal' do

	$rom_name = SessionSettings.rom_name

	files = Dir["#{$rom_name}/json/personal/*.json"].sort_by{ |name| [name[/\d+/].to_i, name] }
	@poke_data = files.map do |pok|
		Personal.get_data(pok)
	end

	@pokemons = @poke_data[1..10]

	erb :personal
end

# loading rest of personal files
get '/roms/:rom_name/personal/collection' do
	$rom_name = SessionSettings.rom_name

	files = Dir["#{$rom_name}/json/personal/*.json"].sort_by{ |name| [name[/\d+/].to_i, name] }
	poke_data = files.map do |pok|
		Personal.get_data(pok)
	end

	@pokemons = poke_data[11..-1]
	erb :personal_partial, layout: false
end


# called by ajax when user makes an edit
post '/personal' do 
	Personal.write_data(params["data"])
	return 200
end




