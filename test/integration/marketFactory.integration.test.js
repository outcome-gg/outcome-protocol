import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'
import exp from "constants";

dotenv.config();

const marketFactory = process.env.TEST_MARKET_FACTORY9;
const collateralToken = process.env.TEST_MOCK_DAI;

console.log("MARKET_FACTORY: ", marketFactory)
console.log("COLLATERAL_TOKEN: ", collateralToken)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

//Global variables
let processId;
let messageId;
let originalMessageId;
let spawnedMarketProcessId;

// Txn execution variables
let wallet;
let wallet2;
let walletAddress;
let walletAddress2;

// Market variables
let resolutionAgent;
let question;
let rules;
let outcomeSlotCount;
let creatorFee;
let creatorFeeTarget;
let category;
let subcategory;
let logo;


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
    resolutionAgent = walletAddress2,
    question = "Trump becomes the 47th US President",
    rules = "Where we're going we don't need rules",
    outcomeSlotCount = '2',
    creatorFee = "250",
    creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-1",
    category = "Politics",
    subcategory = "US Politics",
    logo = "https://www.ao.market/logo.png"
  ))

  /***********************************************************************
  * MarketFactory: SPAWN MARKET
  ************************************************************************/
  describe("MarketFactory.Spawn-Market", function () {
    it("+ve should spawn a market", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Spawn-Market" },
          { name: "CollateralToken", value: collateralToken },
          { name: "ResolutionAgent", value: resolutionAgent },
          { name: "Question", value: question },
          { name: "Rules", value: rules },
          { name: "OutcomeSlotCount", value: outcomeSlotCount },
          { name: "CreatorFee", value: creatorFee },
          { name: "CreatorFeeTarget", value: creatorFeeTarget },
          { name: "Category", value: category },
          { name: "Subcategory", value: subcategory },
          { name: "Logo", value: logo }
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

      expect(Messages.length).to.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const creator_ = Messages[0].Tags.find(t => t.name === 'Creator').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget_ = Messages[0].Tags.find(t => t.name === 'CreatorFeeTarget').value
      const question_ = Messages[0].Tags.find(t => t.name === 'Question').value
      const rules_ = Messages[0].Tags.find(t => t.name === 'Rules').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
      const category_ = Messages[0].Tags.find(t => t.name === 'Category').value
      const subcategory_ = Messages[0].Tags.find(t => t.name === 'Subcategory').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
      const originalMessageId_ = Messages[0].Tags.find(t => t.name === 'Original-Msg-Id').value

      expect(action_).to.equal("Spawn-Market-Notice")
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(collateralToken_).to.equal(collateralToken)
      expect(creator_).to.equal(walletAddress)
      expect(creatorFee_).to.equal(creatorFee)
      expect(creatorFeeTarget_).to.equal(creatorFeeTarget)
      expect(question_).to.equal(question)
      expect(rules_).to.equal(rules)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount)
      expect(category_).to.equal(category)
      expect(subcategory_).to.equal(subcategory)
      expect(logo_).to.equal(logo)
      expect(originalMessageId_).to.equal(messageId)
      originalMessageId = originalMessageId_
    })

    it("+ve should get spawned market process id", async () => {
      console.log("Waiting 8s for market process to spawn...")
      await new Promise(resolve => setTimeout(resolve, 8000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Process-Id" },
          { name: "Original-Msg-Id", value: originalMessageId },
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

      expect(Messages.length).to.equal(1)
      spawnedMarketProcessId = Messages[0].Data
    })

    it("+ve should get markets pending", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Markets-Pending" },
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

      expect(Messages.length).to.equal(1)

      const data_ = JSON.parse(Messages[0].Data)
      expect(data_[0]).to.equal(spawnedMarketProcessId)
    })

    it("+ve should get latest process id for creator", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Latest-Process-Id-For-Creator" },
          { name: "Creator", value: walletAddress },
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

      const latestPositionIdForCreator = Messages[0].Data
      expect(latestPositionIdForCreator).to.equal(spawnedMarketProcessId)
    })

    it("+ve should get markets pending", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Markets-Pending" },
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

      expect(Messages.length).to.equal(1)

      const marketsPending = JSON.parse(Messages[0].Data)
      expect(marketsPending.length).to.equal(1)
      expect(marketsPending[0]).to.equal(spawnedMarketProcessId)
    })

    it("+ve should get no markets init", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Markets-Init" },
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

      expect(Messages.length).to.equal(1)

      const marketsInit = JSON.parse(Messages[0].Data)
      expect(marketsInit.length).to.equal(0)
    })
  })

  /***********************************************************************
  * MarketFactory: INIT MARKET
  ************************************************************************/
  describe("MarketFactory.Init-Market", function () {
    it("+ve should init a market", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Init-Market" },
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

      expect(Messages.length).to.be.equal(4)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const action_3 = Messages[3].Tags.find(t => t.name === 'Action').value
      
      expect(action_0).to.equal("Eval")
      expect(action_1).to.equal("Log-Market")
      expect(action_2).to.equal("Log-Market")
      expect(action_3).to.equal("Init-Market-Notice")
    })

    it("+ve should get markets init", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Markets-Init" },
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

      expect(Messages.length).to.equal(1)

      const marketsInit = JSON.parse(Messages[0].Data)
      expect(marketsInit.length).to.equal(1)
      expect(marketsInit[0]).to.equal(spawnedMarketProcessId)
    })
  })

  /***********************************************************************
  * MarketFactory: SPAWNED MARKET
  ************************************************************************/
  describe("MarketFactory.Spawned-Market", function () {
    it("+ve should get spawned market info", async () => {
      console.log("Waiting 10s for market process to init...")
      await new Promise(resolve => setTimeout(resolve, 10000)); 
      console.log("spawnedMarketProcessId: ", spawnedMarketProcessId)
      await message({
        process: spawnedMarketProcessId,
        tags: [
          { name: "Action", value: "Info" },
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
        process: spawnedMarketProcessId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)

      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const dataIndex_ = Messages[0].Tags.find(t => t.name === 'DataIndex').value
      
      expect(configurator_).to.equal("8hKbJUFUGnLlxK5_j7kVnH40tcvXQPsYEuBZ0fwke1U")
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(collateralToken_).to.equal(collateralToken)
      expect(dataIndex_).to.equal("odLEQRm_H6ZqUejiTbkS1Zuq3YfCDz5dcYFLy0gm-eM")
      
      const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const denomination_ = Messages[0].Tags.find(t => t.name === 'Denomination').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
      
      expect(name_.split("-")[0]).to.equal("Outcome")
      expect(ticker_.split("-")[0]).to.equal("OUTCOME")
      expect(denomination_).to.equal("12")
      expect(logo_).to.equal(logo)

      const creator_ = Messages[0].Tags.find(t => t.name === 'Creator').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget_ = Messages[0].Tags.find(t => t.name === 'CreatorFeeTarget').value
      
      expect(creator_).to.equal(walletAddress)
      expect(creatorFee_).to.equal(creatorFee)
      expect(creatorFeeTarget_).to.equal(creatorFeeTarget)
      
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value
      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value
      
      expect(protocolFee_).to.equal("250")
      expect(protocolFeeTarget_).to.equal("m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0")

      const lpFee = Messages[0].Tags.find(t => t.name === 'LpFee').value
      const lpFeePoolWeight = Messages[0].Tags.find(t => t.name === 'LpFeePoolWeight').value
      const lpFeeTotalWithdrawn = Messages[0].Tags.find(t => t.name === 'LpFeeTotalWithdrawn').value
      
      expect(lpFee).to.equal("100")
      expect(lpFeePoolWeight).to.equal("0")
      expect(lpFeeTotalWithdrawn).to.equal("0")

      const question_ = Messages[0].Tags.find(t => t.name === 'Question').value
      const positionIds_ = Messages[0].Tags.find(t => t.name === 'PositionIds').value
      
      expect(question_).to.equal(question)
      expect(positionIds_).to.equal('["1","2"]')
    })
  })
})