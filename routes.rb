require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'csv'
require 'net/http'
require 'dotenv'
require 'active_support'
require 'pry'
require 'date'
require_relative 'helpers'
require_relative 'models/pokenarc'




if ENV["DEVMODE"] == "TRUE"
	require 'pry'
	require "sinatra/reloader"
	require 'benchmark'
end

enable :sessions #unless ENV['RACK_ENV'] == 'test'
Dotenv.load


Dir["models/*.rb"].each {|file| require_relative file}
p "init"

$gen = 5





class MyApp < Sinatra::Base

	set :bind, '0.0.0.0'
	set :bind, '0.0.0.0:3000'

	configure do
	  enable :cross_origin
	end
	options "*" do
	    response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
	    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
	    response.headers["Access-Control-Allow-Origin"] = "*"
	    200
	end

  
	before do

		headers 'Access-Control-Allow-Origin' => '*'

		
		response.headers['Access-Control-Allow-Origin'] = '*'
		$mode = ENV["MODE"]
		$edit_mode = ENV["EDIT_MODE"]
		$offline = ($mode == "offline")

		if $rom_name 
			session[:rom_name] = $rom_name
		end
		if !$offline
			$rom_name = session[:rom_name]
		end
		@pb_proj = ""
		
		if params["project"] && params["project"].length > 0
			$rom_name = "projects/#{params["project"]}"
			$gen = SessionSettings.get("g4") ? 4 : 5
			if !SessionSettings.get("public")
				$rom_name = nil
			end
			@pb_proj = "?project=#{params["project"]}"
		end

		

		# if ENV['RACK_ENV'] == 'test'
		# 	$rom_name = ENV['ROM']
		# end

		$fairy = SessionSettings.fairy?

		return if !$rom_name or $rom_name == ""

		@rom_name = $rom_name.split("/")[1]
		# $gen = SessionSettings.get("g4") ? 4 : 5
		tabs = ['headers', 'personal', 'trainers', 'encounters', 'moves', 'items', 'tms','marts', 'grottos', 'story_texts', 'info_texts',"files"]
		
		begin
			if SessionSettings.base_rom == "BW"
				tabs.delete('marts')
				tabs.delete('grottos')
			end
		rescue
			session[:rom_name] = nil
			$rom_name = nil
			redirect '/?rom_load_failed=true'
		end


		tab_name = request.path_info.split('/')[1]
		@active_header = tabs.find_index tab_name
		if tab_name
			@title = "- #{tab_name.capitalize}"
		end

	end

	####### Mastersheet ##########

	 get '/mastersheet' do 
	 	
	 	if !File.exist?("#{$rom_name}/mastersheet.txt")
	 		File.write("#{$rom_name}/mastersheet.txt", "##{$rom_name.split("/")[-1]}")
	 	end


		 	@encounters = Encounter.get_all
			@trainers = Trdata.get_all
			@gender_table = Trdata.gender_table
			@trainer_poks = Trpok.get_all

		 	@master_data = Mastersheet.parse @encounters, @trainers, @trainer_poks
		 	
		 	@moves = Move.get_all
			@move_names = Move.get_names_from @moves
			@poke_data = Personal.poke_data
			
			@location_names = Header.location_names
			# @item_locations = Item.locations
			@evolutions = Evolution.get_all

			@pok_locations = Personal.get_all_locations @encounters




	 	erb :mastersheet
	 end

	 post '/mastersheet' do 
	 	content = params["content"]
	 	# binding.pry
	 	File.write("#{$rom_name}/mastersheet.txt", content)
	 	@encounters = Encounter.get_all
	 	@trainers = Trdata.get_all
		@gender_table = Trdata.gender_table
		@trainer_poks = Trpok.get_all
	 	@master_data = Mastersheet.parse @encounters, @trainers, @trainer_poks
		

		@poke_data = Personal.poke_data
		
		erb :_mastersheet, layout: false

	 end

	
	################# GENERAL SPA EDITOR ######################


	get '/extract_spas' do 
		`python3 python/spa_reader.py all projects/spa_rom -r`
		$rom_name = "projects/spa_rom"
		redirect '/spas/1'
	end



	############# ROM EDITOR ROUTES ###########################

	get '/' do
		if $rom_name
			p "redirecting..."
			redirect "/headers"
		else
			@roms = Dir["*.nds"]
			@projects = Dir['projects/*']

			erb :index
		end
	end

	get '/files' do 
		redirect '/' if !$rom_name
		p "right"
		erb :files
	end




	get '/files/:file_path/:file_index' do 
		redirect '/' if !$rom_name
		file_path = params["file_path"].split("").join("/")
		file_index = params["file_index"]
		rom_name = $rom_name.split("/")[1]

		p "python3 python/romfiles/file_manager.py -extract #{rom_name}.nds #{file_path} #{file_index}"
		`python3 python/romfiles/file_manager.py -extract #{rom_name}.nds #{file_path} #{file_index}`
		
		file_path = file_path.gsub("/","")
		send_file "./exports/#{rom_name}_#{file_path}_#{file_index}.bin", :filename => "#{rom_name}_#{file_path}_#{file_index}.bin" , :type => 'Application/octet-stream'
	end

	get '/files/:file_path' do 
		redirect '/' if !$rom_name
		file_path = params["file_path"].split("").join("/")
		rom_name = $rom_name.split("/")[1]

		p "python3 python/romfiles/file_manager.py -extract #{rom_name}.nds #{file_path}"
		`python3 python/romfiles/file_manager.py -extract #{rom_name}.nds #{file_path}`
		
		file_path = file_path.gsub("/","")
		send_file "./exports/#{rom_name}_#{file_path}.bin", :filename => "#{rom_name}_#{file_path}.bin" , :type => 'Application/octet-stream'
	end

	get '/rom/new' do 
		session[:rom_name] = nil
		$rom_name =  nil
		return (redirect '/') 
	end

	get '/load_project' do 
		
		pw = params["password"]
		p params
		project = params["rom"]

		if !$offline

			if  !Cipher.auth?(project, pw)
				redirect '/?wrong_password=true'
			end
		end

		session[:rom_name] = project
		$rom_name = project

		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}: Loaded Project : #{project}"
		end

		redirect '/headers'
	end

	post '/extract_rom' do 
		py = "python3"

		p "offline"
		if Dir.exist?("projects/#{params['rom_name'].split(".")[0]}")
			begin
				`rm -rf projects/#{params['rom_name'].split(".")[0]}`
			rescue
			end
		end
		
		p params
		fairy = params['fairy'] 
		

		begin
			retries ||= 0
			system "#{py} python/header_loader.py #{params['rom_name']} offline"
			session[:rom_name] = "projects/#{params['rom_name'].split(".")[0]}"
			$rom_name = "projects/#{params['rom_name'].split(".")[0]}"
			command = "#{py} python/rom_loader.py #{params['rom_name']} offline #{fairy}"
			pid = spawn command
			Process.detach(pid)
		rescue
			py = "python"
			retry if (retries += 1) < 2 
		end
		

		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}: Loaded Rom : #{params['rom_name']}"
		end

		content_type :json
	  	return { url: "/headers" }.to_json
	end


	post '/extract' do 
		p "vanilla"
		# params['rom_name'] = params['rom_name']
		# p params['rom_name']

		p params
		py = "python3"
		
		base = params["rom_base"]
		rom_name = params['rom_name'].split(".")[0]
		fairy = params['fairy']



		pw = Cipher.encrypt params['password']
		# load from xdelta
		if params["filename"]
			file = params["filename"]["tempfile"]
			File.open("./xdeltas/#{rom_name}.xdelta", 'wb') do |f|
		    	f.write(file.read)
		  	end
		  	
			# create base rom
			p "xdelta3 -d -s ./base/blank.nds ./base/#{base}.xdelta ./base/#{base}.nds"
			system "xdelta3 -d -s ./base/blank.nds ./base/#{base}.xdelta ./base/#{base}.nds"

			# create uploaded rom
			p "xdelta3 -d -s ./base/#{base}.nds ./xdeltas/#{rom_name}.xdelta #{rom_name}.nds"
			system "xdelta3 -d -s ./base/#{base}.nds ./xdeltas/#{rom_name}.xdelta #{rom_name}.nds"

			# delete base rom
			system "rm -rf ./base/#{base}.nds"

			begin
				retries ||= 0
				system "#{py} python/header_loader.py #{params['rom_name']} #{pw}"
				session[:rom_name] = "projects/#{params['rom_name'].split(".")[0]}"
				command = "#{py} python/rom_loader.py #{params['rom_name']} online #{fairy}"
				pid = spawn command
				Process.detach(pid)
			rescue
				py = "python"
				retry if (retries += 1) < 2 
			end
		else
			# load base rom template folders
			system "mkdir projects/#{rom_name}"
			system "cp -r templates/#{base}/. projects/#{rom_name}"
			system "cp ./base/#{base}.xdelta ./xdeltas/#{rom_name}.xdelta"

			$rom_name = "projects/#{rom_name}"
			session[:rom_name] = $rom_name
			SessionSettings.set "pw", pw
			SessionSettings.set "rom_name", $rom_name
		end

	
		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}: Loaded Rom : #{params['rom_name']}"
		end

		p session
	  	redirect '/headers'
	end

	get '/rom/save' do
		return if SessionSettings.get("public")
		py = "python3"

		base = SessionSettings.get "base_version"
		rom_name = $rom_name.split("/")[1]



		
		if !$offline 
		#clear exports 

			system "rm -rf exports/*"

			# create base rom
			p "creating base rom"
			p "xdelta3 -d -s ./base/blank.nds ./base/#{base}.xdelta ./base/#{base}.nds"
			system "xdelta3 -d -s ./base/blank.nds ./base/#{base}.xdelta ./base/#{base}.nds"

			# create uploaded rom

			if File.size("./xdeltas/#{rom_name}.xdelta") > 50000000
				# When user chooses to load from base rom, xdelta file will be large
				p "uploaded rom is base rom"
				p "cp ./base/#{base}.nds ./#{rom_name}.nds"
				system "cp ./base/#{base}.nds ./#{rom_name}.nds"
			else
				p "creating edited rom"
				p "xdelta3 -d -s ./base/#{base}.nds ./xdeltas/#{rom_name}.xdelta #{rom_name}.nds"
				system "xdelta3 -d -s ./base/#{base}.nds ./xdeltas/#{rom_name}.xdelta #{rom_name}.nds"
			end
		end
		

		# begin
			retries ||= 0
			p "creating edited rom"
			SessionSettings.set("edited", []) if !SessionSettings.get("edited")
			
			`#{py} python/trpok_writer.py validate #{$rom_name}`if SessionSettings.get("edited").include? "trpok"
			`#{py} python/encounter_writer.py validate #{$rom_name}` if SessionSettings.get("edited").include? "encounter"
			Learnset.repair_all if SessionSettings.get("edited").include? "learnset"
			p "#{py} python/rom_saver.py #{$rom_name}"
			save = `#{py} python/rom_saver.py #{$rom_name}`
			p "edited rom created"
		# rescue
		# 	py = "python"
		# 	retry if !$offline		
		# end


		if !$offline
			p "generating xdelta"

			p "xdelta3 -e -s ./base/#{base}.nds ./exports/#{rom_name}.nds ./exports/#{rom_name}_edited.xdelta"
			system "xdelta3 -e -s ./base/#{base}.nds ./exports/#{rom_name}.nds ./exports/#{rom_name}_edited.xdelta"

			#delete base rom
			system "rm -rf ./base/#{base}.nds"
			p "deleting base rom"

			#delete uploaded rom
			system "rm -rf #{rom_name}.nds"
			p "deleting uploaded rom"

			#delete editted rom
			# system "rm -rf ./exports/#{rom_name}_edited.nds"
			p "deleting edited rom"


			send_file "./exports/#{rom_name}_edited.xdelta", :filename => "#{rom_name}_edited.xdelta" , :type => 'Application/octet-stream'
		end
		"Rom Saved in /exports"
	end

	get '/narc/:narc_id' do 
		
	end



	########################################## PERSONAL EDITOR ROUTES ####################

	get '/personal' do
		redirect '/' if !$rom_name
		@poke_data = Personal.poke_data
		@moves = Move.get_all
		@move_names = Move.get_names_from @moves


		@poke_data.each do |pok|
			if pok
				pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
			end # adds addtional move data to learnset data
		end	
		@pokemons = @poke_data[1..10]

		

		erb :personal
	end

	get '/personal/:from/copy_tms_to/:to' do 
		Personal.transfer_tm_data params[:from], params[:to]
		redirect '/personal'
	end

	get '/personal/scale/:scale' do 
		redirect '/' if !$rom_name
		Personal.scale_exp params[:scale].to_i

		redirect '/personal'
	end

	get '/learnsets/:id/:index/delete' do 
		redirect '/' if !$rom_name

		Learnset.delete params[:id].to_i, params[:index].to_i

		redirect '/personal'
	end

	get '/expanded_personal/:id' do 
		moves = Move.get_all
		tm_names = Tm.get_names
		tutor_moves = Personal.tutor_moves
		evolutions = Evolution.get_all

		pok = Personal.get_data_for "#{$rom_name}/json/personal/#{params[:id]}.json"

		pok["learnset"] = expand_learnset_data moves, pok["learnset"]

		erb :'_expanded_personal', :layout => false, :locals => { :pok => pok, :tm_names => tm_names, :tutor_moves => tutor_moves, :evolutions => evolutions }

	end

	# loading rest of personal files
	get '/personal/collection' do
		@poke_data = Personal.poke_data
		@moves = Move.get_all

		@poke_data.each do |pok|
			if pok
				pok["learnset"] = expand_learnset_data @moves, pok["learnset"]
			end # adds addtional move data to learnset data
		end

		@pokemons = @poke_data[11..-1]
		erb :personal_partial, layout: false
	end

	get '/personal/taken_sprite_indexes' do
		@taken = Personal.unavailable_sprite_indexes

		erb :sprites
	end

	post '/delete' do 
		return if SessionSettings.get("public")
		narc_name = params['data']['narc']
		created = Object.const_get(narc_name.capitalize).delete params["data"]
		return 200
	end


	# called by ajax when user makes an edit
	post '/update' do 
		return if SessionSettings.get("public")
		if !$rom_name
			return {url: '/'}.to_json
		end

		narc_name = params['data']['narc']
		
		if params['data']['narc_const']
			narc_name = params['data']['narc_const']
		end

		if params['data']['narc'] == 'spas'
			narc_name = "spa"
		end
		p params['data']

		Object.const_get(narc_name.capitalize).write_data params["data"]

		if narc_name == 'spas' or narc_name == "starters" or narc_name == "spa"
			return {url: '200 OK'}.to_json
		end

		if params['data']['field'].include?('odds') && narc_name == 'grotto'
			narc_name = 'grotto_odds'
		end

		if params['data']['field'].include?('hc_effect') && narc_name == 'move'
			narc_name = 'move_effects_table'
		end


		if params['data']['trtext']
			narc_name = "text"
			params['data']['file_name'] = "bank_381"
			params['data']['narc'] == "message_texts"
			Text.write_ppre_bank
		end
		p params['data']
		
		py = "python3"



		begin
			retries ||= 0
			command = "#{py} python/#{narc_name}_writer.py update #{params['data']['file_name']} #{$rom_name}"
			p command
			pid = spawn command
			Process.detach(pid)
		rescue
			py = "python"
			retry if (retries += 1) < 2 
		end


		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}: Project: #{$rom_name} Updated #{narc_name} File #{params['data']['file_name']} #{params['data']['field']} to #{params['data']['value']} "
		  SessionSettings.set "last_edit", Time.now.to_s
		  edited_narcs = SessionSettings.get "edited"
		  if !edited_narcs
		  	SessionSettings.set "edited", [narc_name]
		  else
		  	SessionSettings.set "edited", edited_narcs.push(narc_name).uniq
		  end

		end

		return {url: '200 OK'}.to_json
	end


	########################################## MOVE EDITOR ROUTES ####################

	get '/moves' do 	
		redirect '/' if !$rom_name
		@moves = Move.get_all
		@move_names = Move.get_names_from @moves

		erb :moves
	end

	get '/moves/extract_spas' do 
		`python3 python/spa_reader.py all #{$rom_name} -r`
		redirect '/moves?message=spa_extraction_success'
	end

	get '/moves/:id/script' do 
		id = params[:id]
		# (1..559).each do |id|
		# 	p id
			`python3 python/move_writer.py decompile #{id} #{$rom_name} > #{$rom_name}/move_scripts/#{id}.txt`
		# end
		@script = File.open("#{$rom_name}/move_scripts/#{id}.txt", "r").readlines

		send_file "#{$rom_name}/move_scripts/#{id}.txt", :filename => "move_script_#{id}.txt" , :type => 'Application/octet-stream'
	end

	post '/moves/:id/script' do 
		p params
		file = params["file"]["tempfile"]
		id = params[:id]

		File.open("#{$rom_name}/move_scripts/#{id}.txt", 'w') do |f|
	    	f.write(file.read)
	  	end

	  	p "python3 python/move_writer.py compile #{id} #{$rom_name}"
	  	`python3 python/move_writer.py compile #{id} #{$rom_name}`

	  	return {response: 200}.to_json
		  	
	end

	get '/moves/expand' do 
		rom = $rom_name.split("/")[1]
		p "python3 python/expansions/move_expander.py #{rom}"
		`python3 python/expansions/move_expander.py #{rom}`

		edited_narcs = SessionSettings.get "edited"
		  if !edited_narcs
		  	SessionSettings.set "edited", ["moves"]
		  else
		  	SessionSettings.set "edited", edited_narcs.push("moves").uniq
		  end
		redirect '/moves'
	end

	get '/tms' do 	
		redirect '/' if !$rom_name
		@moves = Move.get_all
		@tm_moves = Tm.get_tms_from @moves
		@move_names = Move.get_names_from @moves

		erb :tms
	end


	####################### Texts ###########################

	get '/story_texts/text/:id' do 
		redirect '/' if !$rom_name
		bank = "story_texts"
		n = params[:id]
		command = "dotnet tools/beatertext/BeaterText.dll -d #{$rom_name}/#{bank}/#{n}.bin #{$rom_name}/#{bank}/#{n}.txt"
		system command

		texts = File.open("#{$rom_name}/#{bank}/#{n}.txt").read()
		@texts = texts.split("# STR_")
		@index = n
		@narc_name = "story_texts"
		@bank = Text.get_bank @narc_name, @index
		
		erb :text
	end

	get '/message_texts/text/:id' do 
		redirect '/' if !$rom_name
		bank = "message_texts"
		n = params[:id]
		command = "dotnet tools/beatertext/BeaterText.dll -d #{$rom_name}/#{bank}/#{n}.bin #{$rom_name}/#{bank}/#{n}.txt"
		system command

		texts = File.open("#{$rom_name}/#{bank}/#{n}.txt").read()
		@texts = texts.split("# STR_")
		@index = n
		@narc_name = "message_texts"
		@bank = Text.get_bank @narc_name, @index
		
		erb :text
	end

	post '/texts/:id' do 
		return if SessionSettings.get("public")
		bank = params["bank"]
		p params
		Text.edit_bank params["narc"], params["id"], params["bank"]

		edited_narcs = SessionSettings.get "edited"
	  if !edited_narcs
	  	SessionSettings.set "edited", ["text"]
	  else
	  	SessionSettings.set "edited", edited_narcs.push("text").uniq
	  end
		return 200
	end

	get '/starters' do 

		if SessionSettings.base_rom == "BW"
			redirect '/'
		end
		@starters = SessionSettings.get "starters"
		# if !SessionSettings.get("date_created")
		# 	redirect "/headers"
		# end
		erb :starters
	end


	####################### HEADERS ###########################

	get '/headers' do 
		redirect '/' if !$rom_name


		
		begin 
			@header_data = Header.get_all
			@location_names = Header.location_names

		rescue
			session[:rom_name] = nil
			$rom_name =  nil
			redirect '/?message=rom_load_failed'
		end
		erb :headers
	end

	####################### ENCOUNTERS ###########################

	get '/encounters' do 
		redirect '/' if !$rom_name
		@encounters = Encounter.get_all
		@location_names = Header.location_names

		erb :encounters
	end

	get '/encounters/expand' do 
		rom = $rom_name.split("/")[1]
		p "python3 python/expansions/encounter_expander.py #{rom}"
		`python3 python/expansions/encounter_expander.py #{rom}`
		redirect '/encounters'
	end

	post '/encounter_season_copy' do 
		Encounter.copy_season_to_all params["data"]["id"], params["data"]["season"]
		p params
		"200 OK"
	end

	####################### TRAINERS ###########################

	get '/trainers' do 
		redirect '/' if !$rom_name

		@trainers = Trdata.get_all
		@trainer_poks = Trpok.get_all
		@move_names = Move.get_names_from Move.get_all
		@show_doc_view = params["doc_view"] 
		@show_doc_view = true if SessionSettings.get("public")
		@gender_table = Trdata.gender_table

		# if @show_doc_view
		# 	tr_count = -1
		# 	@trainers = @trainers[1..-1].sort_by do |tr|
		# 		tr_count += 1
		# 		@trainer_poks[tr_count]["level_0"] ? @trainer_poks[tr_count]["level_0"] : 101
		# 	end
		# 	@trainer_poks = @trainer_poks[1..-1].sort_by do |trpok| 
		# 		trpok["level_0"] ? trpok["level_0"] : 101
		# 	end
		# end


		n = 381
		bank = "message_texts"
		command = "dotnet tools/beatertext/BeaterText.dll -d #{$rom_name}/#{bank}/#{n}.bin #{$rom_name}/#{bank}/#{n}.txt"
		
		if SessionSettings.base_rom == "BW2"
			system command
		end


		@offsets = JSON.parse(File.open("#{$rom_name}/texts/trtexts_offsets.json", "r"){|f| f.read})
		@text_table = JSON.parse(File.open("#{$rom_name}/texts/trtexts.json", "r"){|f| f.read})
		@text_bank = JSON.parse(File.open("#{$rom_name}/message_texts/texts.json", "r"){|f| f.read})[381]

		@text_types = Trdata.text_types

		@names = Trdata.names
		@class_names = Trdata.class_names
		
		
		erb :trainers
	end

	get '/trainers/expand' do 
		rom = $rom_name.split("/")[1]
		"python3 python/expansions/trainer_expander.py #{rom}"
		`python3 python/expansions/trainer_expander.py #{rom}`
		redirect '/trainers'
	end

	get '/trainers/:trainer_id/:pok_id/natures/:desired_iv' do 
		@natures = Trpok.get_nature_info_for params[:trainer_id], params[:pok_id], params[:desired_iv].to_i 
		@iv = params[:desired_iv]
		erb :trpok_natures
	end

	get '/trainers/:to_copy/copy_to/:id' do 
		return if SessionSettings.get("public")
		Trdata.reset params[:id], params[:to_copy]
		redirect '/trainers'
	end

	post '/create' do
		narc_name = params['data']['narc']
		
		created = Object.const_get(narc_name.capitalize).create params["data"]

		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}:  Project: #{$rom_name} Trainer File #{params['data']['file_name']} created new trainer pok"
		end

		erb ("_" + narc_name).to_sym, :layout => false, :locals => { narc_name.to_sym => created, "#{narc_name}_index".to_sym => params['data']['sub_index'], :show => "show-flex", :doc_view => false }
	end

	get '/trpoks/moves/:trpok_id/:pok_index' do 
		moves = Trpok.fill_lvl_up_moves params[:lvl], params[:trpok_id], params[:pok_index]

		content_type :json
	  	return { moves: moves }.to_json

	end


	post '/batch_update' do 
		return if SessionSettings.get("public")
		narc_name = params['data']['narc']
		
		Object.const_get(narc_name.capitalize).write_data params["data"], true

		py = "python3"
		
		begin
			retries ||= 0
			command = "#{py} python/#{narc_name}_writer.py update #{params['data']['file_names'].join(',')} #{$rom_name}"
			p command
			pid = spawn command
			Process.detach(pid)
		rescue
			py = "python"
			retry if (retries += 1) < 2 
		end

		open('logs.txt', 'a') do |f|
		  f.puts "#{Time.now}: Project: #{$rom_name} Batch Updated #{narc_name} Files #{params['data']['field']} to #{params['data']['value']} "
		  edited_narcs = SessionSettings.get "edited"

		  if !edited_narcs
		  	SessionSettings.set "edited", [narc_name]
		  else
		  	SessionSettings.set "edited", edited_narcs.push(narc_name).uniq
		  end
		end

		return 200
	end

	####################################### ITEMS ###############

	get '/items' do
		redirect '/' if !$rom_name
		@items = Item.get_all

		erb :items
	end

	####################################### MARTS ###############

	get '/marts' do
		redirect '/' if !$rom_name
		@marts = Mart.get_all

		erb :marts
	end



	####################################### TEXTS ###############


	get '/story_texts' do 
		redirect '/' if !$rom_name

		@narc_name = 'story_texts'
		@texts = Text.get_all @narc_name
		@limit = 0

		erb :texts
	end

	get '/story_texts/search' do 
		redirect '/' if !$rom_name

		@terms = params[:terms]
		@narc_name = 'story_texts'
		@texts = Text.search @narc_name, @terms, params[:ignore_case]
		@limit = -1

		erb :texts

	end


	####################################### GROTTOS ###############

	get '/grottos' do
		redirect '/' if !$rom_name

		@grottos = Grotto.get_all
		@odds = Grotto.odds_data["readable"]

		erb :grottos
	end

	get '/grotto_odds' do 
		@grottos = Grotto.get_all
		@odds = Grotto.odds_data["readable"]
		erb :grotto_odds
	end

	####################################### TEXTS ###############


	get '/info_texts' do 
		redirect '/' if !$rom_name

		@narc_name = 'message_texts'
		@texts = Text.get_all @narc_name
		@limit = 0

		erb :texts
	end

	get '/info_texts/search' do 
		@terms = params[:terms]
		@narc_name = 'message_texts'
		@texts = Text.search @narc_name, @terms, params[:ignore_case]
		@limit = -1
		
		erb :texts
	end

	get '/texts/:narc_name/:bank_id' do 
		text = Text.get_bank(params[:narc_name], params[:bank_id])

		erb :_text, :layout => false, :locals => { :text => text, :narc_name => params[:narc_name], :bank_id => params[:bank_id] }
	end


	get '/logs' do
		@logs = open('logs.txt', 'a+') do |f|
		 	f.read.split("\n")
		end



		erb :logs

	end

	get '/export_showdown' do 
		if !SessionSettings.get("tr_locations_found")
			Trdata.get_locations
			SessionSettings.set("tr_locations_found", true)
		end

		Move.export_showdown
		Personal.export_showdown
		Trpok.export_all_showdown

		redirect '/dist/index.html?gen=5'
	end

	get '/export_docs' do 
		Action.docs
		redirect "/#{$rom_name.split("/")[1]}_pokedex.txt"
	end

	get '/publish_calc' do 
		if !SessionSettings.get("tr_locations_found")
			Trdata.get_locations
			SessionSettings.set("tr_locations_found", true)
		end
		Move.export_showdown
		Personal.export_showdown
		Trpok.export_all_showdown
		
		data = Action.np_payload

		if false
			File.write("./public/calcs/#{$rom_name.split("/")[1]}_calc.json", data.to_json)
			redirect "https://hzla.github.io/Dynamic-Calc/?data=Pokeweb-#{$rom_name.split("/")[1]}&gen=5"
		else
			return data.to_json
		end
	end


	get '/randomize' do 
		Randomizer.setup
		Action.rand_teams
		Action.rand_encs
		erb :randomize
	end

	####################################### SCRIPTS ###############


	get '/scripts/:id' do 
		redirect '/' if !$rom_name

		base_rom = SessionSettings.base_rom 
		id = params[:id]

		command = "dotnet tools/beaterscript/BeaterScript.dll -d #{$rom_name}/scripts/#{id}.bin #{base_rom} #{$rom_name}/scripts/#{id}.txt"

		system command
		system "open -a TextEdit #{$rom_name}/scripts/#{id}.txt"
		system "start notepad  #{$rom_name}/scripts/#{id}.txt"
		return 200
	end

	get '/scripts/:id/save' do 
		id = params[:id]
		command = "dotnet tools/beaterscript/BeaterScript.dll -m #{$rom_name}/scripts/#{id}.txt #{$rom_name}/scripts/#{id}.bin"
		p command
		system "export DEVKITARM=/opt/devkitpro/devkitARM"
		system command
		return 200
	end

	####################################### OVERWORLDS ###############

	get '/overworlds/:id/box' do 

		overworld = Overworld.get_data(params[:id].to_i, "raw")
		selected = params["selected"]

		@index = params[:id]


		map_data = Overworld.get_maps @index.to_i
		maps = map_data["maps"]
		tl_x = map_data["translate"][0]
		tl_y = map_data["translate"][1]

		erb :'_overworld', :layout => false, :locals => { :overworld => overworld, :tl_x => tl_x, :tl_y => tl_y, :maps => maps , :selected => selected}
	end

	get '/overworlds/:id' do 
		redirect '/' if !$rom_name
		
		if !SessionSettings.get("cords_found")
			MapMatrix.output_cords
			SessionSettings.set("cords_found", true)
		end

		@overworld = Overworld.get_data(params[:id].to_i, "raw")
		@index = params[:id]
		
		header_info = Header.find_location_by_map_id(@index.to_i)
		@location = header_info[0]
		@script = header_info[1]
		@text = header_info[2]

		@map_data = Overworld.get_maps @index.to_i
		@maps = @map_data["maps"]
		@tl_x = @map_data["translate"][0]
		@tl_y = @map_data["translate"][1]

		erb :overworld
	end

	put '/overworlds/:id/npc' do 
		Overworld.add_npc params["id"].to_i
		p params["id"]
		"200 OK"
	end

	delete '/overworlds/:id/npc' do
		Overworld.remove_npc params["id"].to_i, params["npc_index"].to_i
		"200 OK"
	end

	##### SETTINGS ########

	get '/settings' do 
		system "open -a TextEdit #{$rom_name}/session_settings.json"
		system "start notepad   #{$rom_name}/session_settings.json"
		return 200
	end


	get '/settings/set' do 
		return if SessionSettings.get("public")
		field = params["field"]
		current_value = SessionSettings.get(field)

		SessionSettings.set field, !current_value
		return [SessionSettings.get(field).to_s].to_json
	end

	get '/rom/delete' do 
		return if SessionSettings.get("public")
		xdelta_path = "./xdeltas/#{$rom_name.split("/")[1]}.xdelta"
		`rm -rf #{$rom_name}`
		`rm -rf #{xdelta_path}`
		redirect '/rom/new'
	end

	######################## SPA ##########


	get '/spas/:id' do 
		@colors = JSON.parse(File.open("#{$rom_name}/spas/#{params[:id]}_spa.json").read)["textures"]
		@textures = []
		@id = params[:id]
		parsed_textures = Dir.glob("#{$rom_name}/spas/#{params[:id]}_parsed_texture*.json").sort

		parsed_textures.each do |texture|
			@textures << JSON.parse(File.open(texture).read)
		end

		@fields = Spa.get_fields params[:id]
		@misc_fields =  [[:base_scale, 4294967295 ] , [:base_delay,65535], [:particle_duration,65535], [:air_resistance,255]]
		
		erb :spa
	end

	get '/spas/:id/pallete' do
		return if !$offline
		system "open -a TextEdit #{$rom_name}/spas/#{params[:id]}_spa.json"
		system "start notepad #{$rom_name}/spas/#{params[:id]}_spa.json"
		return 200
	end

	get '/spas/:to_copy/copy_to/:id' do 
		return if SessionSettings.get("public")
		
		p "python3 python/spa_reader.py #{params[:to_copy]}-#{params[:id]} #{$rom_name} -copy"
		`python3 python/spa_reader.py #{params[:to_copy]}-#{params[:id]} #{$rom_name} -copy`

		redirect "spas/#{params[:id]}?message=copy_successful"
	end

	get '/spas/:id/texture/:texture_id' do 
		return if !$offline
		# system "open -a TextEdit #{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin"
		# system "start notepad #{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin"

		# send_file  "#{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin", :filename => "#{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin" , :type => 'Application/octet-stream'

		`explorer .\#{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin`
		p "explorer .\\#{$rom_name}/spas/#{params[:id]}_texture_#{params[:texture_id]}.bin"
		return 200
	end

	get '/spas/:id/save' do 
		`python3 python/spa_reader.py #{params[:id]} #{$rom_name} -w`
		return 200
	end

	get '/spas/:id/export' do 
		`python3 python/spa_reader.py #{params[:id]} #{$rom_name} -w`
		send_file  "#{$rom_name}/spas/#{params[:id]}_edited.spa", :filename => "#{params[:id]}_edited.spa" , :type => 'Application/octet-stream'
	end

	get '/spas/:id/view' do 
		return if !$offline
		`python3 python/spa_reader.py #{params[:id]} #{$rom_name} -w`
		`./nitro_effect/NitroEffectMaker.exe ./#{$rom_name}/spas/#{params[:id]}_edited.spa`
		return 200
	end

	######################## MOVE EFFECTS ##########


	get '/moves/effects' do 

		@effects = Move.effects["readable"]
		@effect_mappings = Move.effect_mappings

		@moves = Move.get_all
		@move_names = Move.get_names_from @moves

		erb :move_effects
	end


	############ MISC

	get '/savereader' do 
		redirect '/savereader/inc_em'


		erb :save_reader
	end

	get '/savereader/:game' do 
		@game = params[:game]
		supported_games = {"rad_red" => "Radical Red", "inc_em" => "Inclement Emerald", "em_imp" => "Emerald Imperium", "runandbun" => "Run and Bun"}
		@game_title = supported_games[@game]
		erb :save_reader
	end



	post '/read_save' do 
		p params
		file = params["file"]["tempfile"]
		file_name = "save#{rand(100000)}.sav"
	
		File.open("./exports/#{file_name}", 'wb') do |f|
	    	f.write(file.read)
	  	end
	  	bin_data = IO.binread("./exports/#{file_name}")
	  	save_info = Save.read(bin_data, params["level"].to_i, params["game"], 0, params["invert"], params['evs'] == 'true')
	  	@showdown = save_info[:import_data]
	  	debug_info = save_info[:debug_info]
	  	`rm -rf ./exports/#{file_name}`

	  	return {showdown: @showdown, debug_info: debug_info}.to_json	
	end


	get '/:narc_name/:copy_from/copy_to/:copy_to' do 
		redirect_url = Pokenarc.copy params[:narc_name], params[:copy_from], params[:copy_to]
		redirect redirect_url
	end

end


