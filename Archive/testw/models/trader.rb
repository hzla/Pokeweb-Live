class Trader < ActiveRecord::Base
	has_many :trades


	def get_pnl
		trades.order_by(timestamp: :desc)
	end

end