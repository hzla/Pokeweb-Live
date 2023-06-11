require_relative 'gmx'


# page_length = 0
# after = nil
# actions = []

# actions += Gmx.actions("0xe8c19dB00287e3536075114B2576c70773E039BD")
# page_length = actions.length
# p page_length

# after = actions[-1]["id"]



# until page_length < 100
# 	page = Gmx.actions("0xe8c19dB00287e3536075114B2576c70773E039BD", after)
# 	actions += page
# 	page_length = page.length
# 	after = actions[-1]["id"]
# 	p actions.length	
# end

actions = JSON.parse(File.read("gmx_actions.json")).reverse
eth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
wbtc = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"

p Gmx.max_usd_notional_size(actions, wbtc)





# p actions.length
# File.write("gmx_actions.json", actions.to_json)

