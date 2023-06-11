require 'httparty'
require 'json'
require 'pry'


class Moralis

	attr_accessor :address, :abi
	attr_accessor :abi


	def initialize(key, address, abi, chain, chain_id)
		@key = key
		@address = address
		@abi = JSON.parse(File.open("abis/#{abi}.json").read)
		@chain = chain
		@chain_id = chain_id
	end

	def run_contract_function(function_name, params)
		endpoint = "https://deep-index.moralis.io/api/v2/#{@address}/function?chain=arbitrum&function_name=#{function_name}"

		options = {
			headers: {"X-API-Key": @key, "accept": "application/json"},
			body: { "abi" => @abi, "params" => params.to_json}
		}
		


		response = HTTParty.post(endpoint, options)

		p response

		binding.pry

	end

	# curl https://arb-mainnet.g.alchemy.com/v2/vUMOZfItrGYfpm8_lI4eBUYimknCyXmz -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"alchemy_getTokenBalances","params": ["0x3f5ce5fbfe3e9af3971dd833d26ba9b5c936f0be", ["0x607f4c5bb672230e8672085532f7e901544a7375", "0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6", "0x63b992e6246d88f07fc35a056d2c365e6d441a3d", "0x6467882316dc6e206feef05fba6deaa69277f155", "0x647f274b3a7248d6cf51b35f08e7e7fd6edfb271"]],"id":"42"}'

	# curl https://arb-mainnet.g.alchemy.com/v2/vUMOZfItrGYfpm8_lI4eBUYimknCyXmz -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to": "0x22199a49A999c351eF7927602CFB187ec3cae489",  }],"id":"42"}'


end


key = "EqLLTKQDEy0SlfgLkMzkrNPoYjGmTAbc4YE7ellCwohacxQDzOMnc7ekyth19Hcn"
address = "0x22199a49A999c351eF7927602CFB187ec3cae489"
abi = "gmx"
chain = "arb"
chain_id = 42161


vault = "0x489ee077994B6658eAfA855C308275EAd8097C4A"
account = "0xe8c19db00287e3536075114b2576c70773e039bd"
WBTC = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"
WETH = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
USDC = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"


collateral_tokens = [WBTC,WETH,USDC,USDC]
index_tokens = [WBTC,WETH,WBTC,WETH]
is_long = [true,true,false,false]

params = {
    "_vault": vault,
    "_account": account,
    "_collateralTokens": collateral_tokens,
    "_indexTokens": index_tokens,
    "_isLong": is_long
}


m = Moralis.new(key, address, abi, chain, chain_id)

m.run_contract_function("BASIS_POINTS_DIVISOR", {})




