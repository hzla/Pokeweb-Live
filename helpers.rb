
# THIS FILE CONTAINS METHODS USED BY THE FRONTEND ERB

class String
  def titleize
  	if !self 
  		return "-"
  	end
    downcase.gsub("-", " ").split(/([ _-])/).map(&:capitalize).join
  end

  def is_integer?
    self.to_i.to_s == self
  end

  def move_titleize
  	if !self 
  		return ""
  	end
    downcase.split(/([ _-])/).map(&:capitalize).join
  end

  def name_titleize
  	if !self 
  		return ""
  	end
    downcase.split(/(?<=[ _-])/).map(&:capitalize).join
  end

  def move_untitleize
  	upcase
  end

  def squish!
    gsub!("\n", '')
    self
  end

  def smogonlize
  	downcase.gsub("-", "").gsub(" ", "").gsub("'","")
  end
end

class Integer
	def name_titleize
		self == 0 ? "-" : to_s
	end
end

class NilClass
	def titleize
		"-"
	end

	def downcase
		"-"
	end

	def capitalize
		""
	end

	 def name_titleize
	  	"-"
 	 end

 	def move_titleize
  	   ""
  	end
end

class Integer
	def ljust n
		self.to_s.rjust n
	end
end

# adds addtional move data to learnset data
def expand_learnset_data(moves, learnset)
	move_data = []

	(0..24).each do |move|
		if learnset["move_id_#{move}_index"]
			
			ls_data = {"move_name" => learnset["move_id_#{move}"], "lvl_learned" => learnset["lvl_learned_#{move}"], "move_id" => learnset["move_id_#{move}_index"], "index" => move }
			# all data for this specific move

			all_move_data = moves[ls_data["move_id"]]
			# copy these fields to be presented
			if learnset["move_id_#{move}_index"] > 673
				all_move_data = moves[ls_data["move_id"] - (673 - RomInfo.original_move_count)]
			end

			["type", "category", "power", "accuracy"].each do |field|
				begin
					ls_data[field] = all_move_data[1][field]
				rescue
					p field
					# p all_move_data[1]
					# binding.pry
					# raise
					next
				end
			end
			move_data << ls_data
		else
			move_data << {"index" => move }
		end
	end

	# sort by lvl learned, and break ties move index
	move_data.sort_by do |n| 

		if n["lvl_learned"]
			order = n["lvl_learned"].to_i
			if n["move_id"] == 0
				order += 200
			end
			order
		else
			101 + n["index"].to_i
		end




	end
end



def to_gen(pok_id)
	case pok_id
	when 0..151
	  gen = "gen1"
	when 152..251
	  gen = "gen2"
	when 252..386
	  gen = "gen3"
	when 387..493
	  gen = "gen4"
	when 494..649
	  gen = "gen5"
	when 650..721
	  gen = "gen6"
	when 722..809
	  gen = "gen7"
	when 810..898
	  gen = "gen8"
	else
	  gen = ""
	end
	gen
end


def img(name, classes="", data=["", ""])
	"<img src='/images/" + "#{name.gsub("'", "")}'" +  "class='#{classes}' loading='lazy' data-#{data[0]}='#{data[1]}' />"
end

def svg(name, classes="", data=["", ""], html="")
	div_start = "<div class='#{classes}' data-#{data[0]}='#{data[1]}'>"
	div_end = "</div>"
	svg = erb(name.to_sym, :layout => false, :locals => { :classes => classes, :data => data })

	div_start + html + svg + div_end
end

def field(field_name, class_name, data={})
	
	div = "<div autocorrect='off' class='#{class_name}' contenteditable='true' data-narc='#{data[:narc]}' data-field-name='#{field_name}'"
	if data[:autofill]
		div += "data-autocomplete-spy data-autofill='#{data[:autofill]}' "
	end

	if data[:type]
		div += "data-type='#{data[:type]}'"
	end

	if data[:check]
		div += "data-check='#{data[:check]}'"
	end
	
	div += '>'

	div += data[:value].to_s

	div += "</div>"

	div
end


#  field 'location_name', 'hdr-location', {value: @header_data[n.to_s]["location_name"],  narc: "header", autofill: "location_names"}


# <div class="hdr-location" data-autocomplete-spy contenteditable="true" data-autofill="location_names" data-field-name="location_name" data-narc="header"><%= @header_data[n.to_s]["location_name"] %></div>



def autofill(obj)
	obj["autofill"] ? "data-autocomplete-spy" : ""
end