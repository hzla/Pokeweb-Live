const Moralis = require("moralis").default;
require("dotenv").config();

const ABI = require("./vela.json");
const address = "0x5957582f020301a2f732ad17a69ab2d8b2741241"


Moralis.start({
    apiKey: process.env.MORALIS_KEY
}).then(async()=>{
  
    const response = await Moralis.EvmApi.utils.runContractFunction({
    address: address,
    functionName: "getVLPPrice",
    abi: ABI,
    chain: 42161,

	});
    const value = parseInt(response.raw) * 4.2995345

    const fs = require('fs');
    const time = new Date().toLocaleString("en-US", { timeZone: "America/Los_Angeles" });
    

	console.log(`${value} ${time}\n`)

    fs.appendFileSync('dex.txt', `${value} ${time} ${response.raw}\n`);
})



