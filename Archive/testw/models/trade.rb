class Trade < ActiveRecord::Base
	belongs_to :user
	has_many :actions


	def self.load_to_db
		(0..100).each do |n|
			p n 
			puts "\n" * 50
			trades = JSON.parse(File.read("lib/trades/#{n}.json"))

			
			trades.each do |trade|
				# Create trader if new
				trader = Trader.where(address: trade["account"]).first
				if !trader
					trader = Trader.create(address: trade["account"])
				end

				# Add trade


				full_trade = Trade.create(
					tx_hash: trade["id"],
					address: trade["account"],
					fees: trade["fee"].to_f,
					closed: (!!trade["closedPosition"] == true),
					liquidated: (!!trade["liquidatedPosition"] == true),
					trader_id: trader.id
				)


				# Add individual trade methods
				["increaseList", "decreaseList", "closedPosition", "liquidatedPosition"].each do |action_type|
					if trade[action_type]



						trade[action_type].each do |action|

							if action_type == "increaseList" or action_type == "decreaseList"
								Action.create(
									tx_hash: trade["id"],
									method: action_type,
									trader_id: trader.id,
									trade_id: full_trade.id,
									collateral_delta: action["collateralDelta"].to_i,
									size_delta: action["size_delta"].to_i,
									price: action["price"].to_i,
									fee: action["fee"].to_i,
									timestamp: action["timestamp"]
								)
							elsif action_type == "closedPosition"
								action = trade[action_type]

								Action.create(
									tx_hash: trade["id"],
									method: action_type,
									trader_id: trader.id,
									trade_id: full_trade.id,
									collateral_delta: action["collateral"].to_i,
									size_delta: action["size"].to_i,
									price: action["averagePrice"].to_i,
									timestamp: action["timestamp"]
								)
							else #liquidation
								action = trade[action_type]

								Action.create(
									tx_hash: trade["id"],
									method: action_type,
									trader_id: trader.id,
									trade_id: full_trade.id,
									collateral_delta: action["collateral"].to_i,
									size_delta: action["size"].to_i,
									price: action["markPrice"].to_i,
									timestamp: action["timestamp"]
								)
							end
						end
					end
				end
			end
		end
	end

# closedPosition {
#         id
#         collateral
#         size
#         averagePrice
#         timestamp
#       }
#       liquidatedPosition {
#         id
#         size
#         collateral
#         realisedPnl
#         markPrice
#         timestamp
#       }


	def self.query(address=nil)
			query = "{
	  trades(orderBy: timestamp, orderDirection: asc, first: 1000) {
	    id
	    fee
	    account
	    isLong
	    status
	    collateralToken
	    indexToken
	    timestamp
	    realisedPnl
	    realisedPnlPercentage
	    entryReferrer
	    sizeDelta
	    size
	    collateralDelta
	    collateral
	    
	    increaseList {
	      id
	      timestamp
	      collateralDelta
	      sizeDelta
	      price
	      fee
	    }
	    decreaseList {
	      id
	      timestamp
	      collateralDelta
	      sizeDelta
	      price
	      fee
	    }
	    updateList {
	      id
	      timestamp
	      collateral
	      size
	      averagePrice
	      markPrice
	    }
	    closedPosition {
	      id
	      collateral
	      size
	      averagePrice
	      timestamp
	    }
	    liquidatedPosition {
	      id
	      size
	      collateral
	      realisedPnl
	      markPrice
	      timestamp
	    }
	  }
	}"

	url = "https://api.thegraph.com/subgraphs/name/nissoh/gmx-arbitrum"

	response = HTTParty.post(url, headers: { 
	        'Content-Type'  => 'application/json'
	      },
	      body: { 
	        query: query
	      }.to_json)

	response
	end
end