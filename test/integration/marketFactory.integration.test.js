import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'

dotenv.config();

const marketFactory = process.env.TEST_MARKET_FACTORY7;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN3;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

console.log("MARKET_FACTORY: ", marketFactory)
console.log("COLLATERAL_TOKEN: ", collateralToken)
console.log("CONDITIONAL_TOKENS: ", conditionalTokens)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

//Global variables
let processId
let messageId

// Txn execution variables
let wallet;
let wallet2;
let walletAddress;
let walletAddress2;

// Market variables
let question;
let questionId;
let resolutionAgent;
let conditionId;
let outcomeSlotCount;
let parentCollectionId;
let marketId;
let partition;
let distribution;
let marketProcessId;

/* 
* Tests
*/
describe("marketFactory.integration.test", function () {
  before(async () => ( 
    processId = marketFactory,
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet2.json')).toString(),
    ),
    // txn execution variables
    walletAddress = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I',
    walletAddress2 = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',
    // market variables
    question = "Trump becomes the 47th US President",
    questionId = keccak256(question + marketFactory).toString('hex'),
    resolutionAgent = walletAddress2,
    outcomeSlotCount = '2',
    parentCollectionId = "",
    conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount).toString('hex'),
    marketId = keccak256(collateralToken + parentCollectionId + conditionId + walletAddress).toString('hex'),
    partition = JSON.stringify([1,1]),
    distribution = JSON.stringify([50,50])
  ))

  /***********************************************************************
  * MarketFactory: MARKET PREPARATION
  ************************************************************************/

  describe("MarketFactory", function () {
    it("+ve should create a market", async () => {
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Recipient", value: marketFactory },
          { name: "X-Action", value: "Create-Market" },
          { name: "X-Question", value: question },
          { name: "X-ResolutionAgent", value: resolutionAgent },
          { name: "X-OutcomeSlotCount", value: outcomeSlotCount },
          { name: "X-ParentCollectionId", value: "" },
          { name: "X-Partition", value: partition },
          { name: "X-Distribution", value: distribution },

        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: collateralToken,
      });

      if (Error) {
        console.log(Error)
      }

      // credit + debit notices
      expect(Messages.length).to.be.equal(2)
    })

    it("+ve should get market data (status==created)", async () => {
      console.log("Waiting 120s for market to be created...")
      await new Promise(resolve => setTimeout(resolve, 120000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId },

        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: marketFactory,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      // @dev set marketProcessId for later tests
      marketProcessId = data_.process_id
      
      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("created")
    })

    it("+ve should init a market", async () => {
      console.log("marketId: ", marketId) 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Init-Market" },
          { name: "MarketId", value: marketId }
        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: marketFactory,
      });

      if (Error) {
        console.log(Error)
      }

      // init notices?
      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const marketId_ = Messages[0].Tags.find(t => t.name === 'MarketId').value

      // @dev Market-Init-Notice is returned later as shown via this message:
      // https://www.ao.link/#/message/g2osUv9Ocpotip_JY9TO11JGoUxyWEEBeJqiopdU-vM
      // expect(action_).to.equal("Market-Init-Notice")
      expect(action_).to.equal("Init")
      expect(marketId_).to.equal(marketId)
    })

    it("+ve should get market data (status==init)", async () => {
      console.log("Waiting 3s for market to be init...")
      await new Promise(resolve => setTimeout(resolve, 3000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId },

        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: marketFactory,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("init")
    })

    it("+ve should get market data (status==funded)", async () => {
      console.log("Waiting 5s for market to be funded...")
      await new Promise(resolve => setTimeout(resolve, 5000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId },

        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: marketFactory,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("funded")
    })

    it("+ve should have sent LP Tokens", async () => {
      await message({
        process: marketProcessId,
        tags: [
          { name: "Action", value: "Balances" },
        ],
        signer: createDataItemSigner(wallet),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: marketProcessId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const data_ = JSON.parse(Messages[0].Data)

      expect(data_[walletAddress]).to.equal('100000000000000')
    })
  })
})