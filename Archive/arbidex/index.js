const Moralis = require("moralis").default;
require("dotenv").config();

const ABI = require("./abi.json");
const address = "0x22199a49A999c351eF7927602CFB187ec3cae489"
const vault = "0x489ee077994B6658eAfA855C308275EAd8097C4A"
const account = "0xe8c19db00287e3536075114b2576c70773e039bd"
const WBTC = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"
const WETH = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
const USDC = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"


const collateralTokens = [WBTC,WETH,USDC,USDC]
const indexTokens = [WBTC,WETH,WBTC,WETH]
const isLong = [true,true,false,false]



Moralis.start({
    apiKey: process.env.MORALIS_KEY
}).then(async()=>{
  
 //    const response = await Moralis.EvmApi.utils.runContractFunction({
 //    address: address,
 //    functionName: "getPositions",
 //    abi: ABI,
 //    chain: 42161,
 //    params: {
 //        "_vault": vault,
 //        "_account": account,
 //        "_collateralTokens": collateralTokens,
 //        "_indexTokens": indexTokens,
 //        "_isLong": isLong
 //    }

	// });
	// console.log(formatResponse(response.raw))

    const response = await Moralis.EvmApi.utils.endpointWeights();

    console.log(response?.toJSON());
})






function formatResponse(response) {
    // console.log(response)
    let positions = {}
    let positionNames = ["btcLong", "ethLong", "btcShort", "ethShort"]
    let fields = ["size","collateral", "averagePrice", "entryFundingRate", "hasRealisedProfit", "realisedProfit", "lastIncreasedTime", "hasProfit", "delta"]
    let divisors = [29,29,29,10,0,0,0,0,29]

    for (let i = 0;i < 4;i++) {
        positions[positionNames[i]] = {}
        for (let j = 0; j < 9;j++) {
            let index = i * 9 + j
            if (j == 0 && response[index] == '0') {
                break
            } 
            positions[positionNames[i]][fields[j]] = parseInt(response[index]) / Math.pow(10, divisors[j])
        }
    }
    return positions
}






// arguments
// 1. 0x489ee077994b6658eafa855c308275ead8097c4a (vault address)
// 2. your account address
// 3. list of addresses of collateral tokens (any token can be collateral. for longs collateral is the same as index, for shorts collateral is stablecoin)
// 4. list of addresses of all index tokens (e.g. for Arbitrum we have BTC, ETH, LINK and UNI)
// 5. list of flags if it long or short

// 3, 4 and 5 arguments should have the same length, i-th item of each represents position. for example with this you’ll get 2 positions (WETH long and WETH short):
// 3. collateralTokens=[USDC, WETH]
// ind4. exTokens=[WETH, WETH]
// 5. isLong=[false, true]

// it will return data even if position does not exist. but all values will be null values (so you can filter it on your side)

// and it returns flat array of values of all positions, you can check values indexes here https://github.com/gmx-io/gmx-contracts/blob/master/contracts/peripherals/Reader.sol#L377-L383