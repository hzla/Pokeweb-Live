const Moralis = require("moralis").default;
require("dotenv").config();

const ABI = require("./abi.json");
const fs = require('fs')
const { EvmChain } = require("@moralisweb3/common-evm-utils");
const decreaseMethodID = "0x5f963716"


var yesterday = new Date(new Date().getTime() - (24 * 60 * 60 * 1000));





let cursor = null

const runApp = async () => {
  


  await Moralis.start({
    apiKey:  process.env.MORALIS_KEY
  });
  
  const address = "0x5957582F020301a2f732ad17a69aB2D8B2741241";

  const chain = EvmChain.ARBITRUM;
  let page = 0


  do {
    const response = await Moralis.EvmApi.transaction.getWalletTransactions({
      address: address,
      chain: chain,
      limit: 100,
      toDate: yesterday,
      cursor: cursor
    });
  
  

    var txs = response.toJSON()
    cursor = txs.cursor


    console.log(page)

    fs.writeFile(`./txs-${page}.json`, JSON.stringify(txs, null, 2), err => {
      if (err) {
          console.log('Error writing file', err)
      } else {
          console.log(`Successfully wrote ${txs.result.length} txs`)
      }
    })

    page += 1
    if (page == 150) {break}
  } while (cursor != "" && cursor != null);
}

runApp();