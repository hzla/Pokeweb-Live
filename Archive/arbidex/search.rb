require 'json'


lb = JSON.parse(File.read("leaderboard2.json"))["leaderboard"]

min_trades = 30




# Frontrunner defined as 
def is_frontrunner?(account)
	account["wins"] >= 30 && (account["losses"].to_f / account["wins"]) <= 0.1 && account["averageLeverage"] >= 10
end
profit = 0
team_profit = 0
lb.each do |account|
	if is_frontrunner?(account)
		profit += account["profitLoss"] - (account["fees"] / 2)
		team_profit += account["fees"] / 4
	end
end


p team_profit



