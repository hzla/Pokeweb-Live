require 'ethereum.rb'
require 'pry'
require 'json'
require 'httparty'
require 'date'

class Gmx

	attr_accessor :reader, :wbtc, :weth, :usdc

	def initialize
		client = Ethereum::HttpClient.new('https://weathered-polished-seed.arbitrum-mainnet.discover.quiknode.pro/3645e6d37df1cdfaba185b39d45eff7d16238456/')
		address = "0x22199a49A999c351eF7927602CFB187ec3cae489"
		abi = JSON.parse(File.open("abis/gmx.json").read)
		
		@reader = Ethereum::Contract.create(name: "GMX", address: address, abi: abi, client: client)
		@wbtc = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"
		@weth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
		@usdc = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
	end

	def positions(account)
		vault = "0x489ee077994B6658eAfA855C308275EAd8097C4A"
		collateral_tokens = [wbtc,weth,usdc,usdc]
		index_tokens = [wbtc,weth,wbtc,weth]
		is_long = [true,true,false,false]
		positions = reader.call.get_positions(vault, account, collateral_tokens, index_tokens, is_long)
		format_positions(positions)
	end

	def self.actions(account, after=nil)
		url = "https://api.gmx.io/actions?account=#{account}"
		url += "&after=#{after}" if after
		response = JSON.parse(HTTParty.get(url).read_body)
	end


	

	def self.max_usd_notional_size(actions, token)
		sizes = []
		max = {"Long" => 0, "Short" => 0}
		max_size_at = nil
		curr_size = {"Long" => 0, "Short" => 0}
		curr_notional_size = {"Long" => 0, "Short" => 0}
		direction = ""
		trade_log = []

		fee = 0.001
		fees_paid = 0

		positional_pnl = {"Long" => 0, "Short" => 0}
		total_pnl = 0
		last_position_cost_basis = {"Long" => 0 , "Short" => 0}

		positional_realised_pnl = {"Long" => 0, "Short" => 0} 


		actions.each_with_index do |action, i|	
			params = JSON.parse(action["data"]["params"])
			actions[i]["data"]["params"] = params
			action_name = action["data"]["action"]
			next if params["indexToken"] != token	
			info = {}
			info[:long] = curr_size["Long"] / 10**30
			info[:short] = curr_size["Short"] / 10**30
			info[:at] = Time.at(action["data"]["timestamp"].to_i).to_datetime

			# If creating a new position order
			if action_name == "CreateIncreasePosition" or action_name == "CreateDecreasePosition"
				direction = params["isLong"] == true ? "Long" : "Short"
			elsif action_name == "IncreasePosition-#{direction}" 
				#increasing position
				
				#pg.18 compute new cost basis 
		
				curr_size[direction] += params["sizeDelta"].to_i
				fees_paid += params["sizeDelta"].to_i * fee
				curr_notional_size[direction] += params["sizeDelta"].to_f / params["price"].to_i

				if last_position_cost_basis[direction] == 0
					last_position_cost_basis[direction] = params["price"].to_i
				else
					last_position_cost_basis[direction] = curr_size[direction] / curr_notional_size[direction]
				end

				# profit is difference in price of asset times number of asset owned
				if direction == "Long"
					positional_pnl[direction] = (params["price"].to_i - last_position_cost_basis[direction]) * curr_notional_size[direction]
				else
					positional_pnl[direction] = (last_position_cost_basis[direction] - params["price"].to_i) * curr_notional_size[direction]
				end

				if curr_size[direction] > max[direction]
					max[direction] = curr_size[direction]
					max_size_at = Time.at(action["data"]["timestamp"].to_i).to_datetime
				end

			elsif action_name == "DecreasePosition-#{direction}" 
				#reducing position
				
				if direction == "Long"
					positional_pnl[direction] = (params["price"].to_i - last_position_cost_basis[direction]) * curr_notional_size[direction]
				else
					positional_pnl[direction] = (last_position_cost_basis[direction] - params["price"].to_i) * curr_notional_size[direction]
				end

				
				positional_realised_pnl[direction] += positional_pnl[direction] * (params["sizeDelta"].to_f / curr_size[direction])

				# subtract already realized profits from this action when calculating profits from current position because they are already included from the previous calculations
				positional_pnl[direction] -= positional_pnl[direction] * (params["sizeDelta"].to_f / curr_size[direction])

				curr_size[direction] -= params["sizeDelta"].to_i
				fees_paid += params["sizeDelta"].to_i * fee
				curr_notional_size[direction] -= params["sizeDelta"].to_f / params["price"].to_i

				if curr_size[direction] == 0
					curr_notional_size[direction] = 0
					total_pnl += positional_pnl[direction] + positional_realised_pnl[direction]
					positional_pnl[direction] = 0
					positional_realised_pnl[direction] = 0
				end

			elsif action_name.include?("LiquidatePosition")		
				liquidation_direction = action_name.split("-")[1]
				curr_size[liquidation_direction] = 0
				curr_notional_size[direction] = 0
				positional_pnl[direction] = 0
				total_pnl -= params["collateral"].to_i
			end

			actions[i][:fees_paid] = fees_paid / 10**30
			actions[i][:realised] = positional_realised_pnl[direction]
			actions[i][:notional] = curr_notional_size[direction]
			actions[i][:nominal] = curr_size[direction]
			actions[i][:positional_pnl] = positional_pnl[direction] + positional_realised_pnl[direction]
			actions[i][:total_pnl] = (total_pnl + positional_pnl[direction] + positional_realised_pnl[direction]) / 10**30
		end

		File.write("pnl.json", JSON.pretty_generate(actions))

		max["Long"] = max["Long"] / 10**30
		max["Short"] = max["Short"] / 10**30
		p curr_notional_size
		{max: max, at: max_size_at, pnl: total_pnl}
	end

	def format_positions(positions)
		formatted = {}
		position_names = ["btcLong", "ethLong", "btcShort", "ethShort"]
		fields = ["size","collateral", "averagePrice", "entryFundingRate", "hasRealisedProfit", "realisedProfit", "lastIncreasedTime", "hasProfit", "delta"]
		divisors = [30,30,30,10,0,0,0,0,30]

		position_names.each_with_index do |pos, i|
			formatted[position_names[i]] = {}
			fields.each_with_index do |field, j|
				idx = i * 9 + j
				if j == 0 && positions[idx] == 0
					break
				end
				formatted[position_names[i]][fields[j]] = (positions[idx] /  10**divisors[j])
			end
		end
		formatted
	end
end

class Kwenta
	attr_accessor :reader, :btc_market, :eth_market

	def initialize
		client = Ethereum::HttpClient.new('https://soft-purple-mound.optimism.discover.quiknode.pro/9a6465486bdaad8e6c97f28c105c360fa1a5b68c/')
		markets = "0xF7D3D05cCeEEcC9d77864Da3DdE67Ce9a0215A9D"
		abi = JSON.parse(File.open("abis/kwenta.json").read)

		@btc_market = "0x59b007E9ea8F89b069c43F8f45834d30853e3699"
		@eth_market = "0x2B3bb4c683BFc5239B029131EEf3B1d214478d93"
		@reader = Ethereum::Contract.create(name: "Kwenta", address: markets, abi: abi, client: client)	
	end

	def get_positions(market, account)
		format_positions(reader.call.position_details(market, account))
	end

	def get_avg_usd_notional_size(account)
	end

	def format_positions(positions)
		formatted = {}
		fields = ["position_id", "notional_value_usd", "margin", "entry", "notional_token", "notional_usd", "pnl_usd", "skip", "position_value_usd"]
		fields.each_with_index do |field, i|
			next if i == 7 
			formatted[field] = positions[(i * 64)..(((i + 1) * 64) - 1)].to_i(16) / 10**18
		end
		formatted
	end
end


# kwenta = Kwenta.new
# pp kwenta.get_positions(kwenta.btc_market, "0xe8c19dB00287e3536075114B2576c70773E039BD")
# pp kwenta.get_positions(kwenta.eth_market, "0xe8c19dB00287e3536075114B2576c70773E039BD")



# use multicall



# positions = []
# gmx = Gmx.new

# accounts.each do |a|
# 	p a
# 	positions << gmx.get_positions(a[:address])
# end

# File.write("positions.json", positions.to_json)





















