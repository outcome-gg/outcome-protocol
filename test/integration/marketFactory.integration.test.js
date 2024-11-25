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

console.log("MARKET_FACTORY: ", marketFactory)
console.log("COLLATERAL_TOKEN: ", collateralToken)

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
let collateralTokenTicker;
let lpTokenLogo;
let payoutNumerators;
// Parlay variables
// -- market 2
let question2;
let questionId2;
let conditionaId2;
let marketId2;
let marketProcessId2;
let resolutionAgent2;
let payoutNumerators2;
// -- market 3
let question3;
let questionId3;
let conditionaId3;
let marketId3;
let marketProcessId3;
let resolutionAgent3;
let payoutNumerators3;

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
    distribution = JSON.stringify([50,50]),
    payoutNumerators = JSON.stringify([1,0]),
    // collateral token ticker
    collateralTokenTicker = 'DAI',
    // lp token logo
    lpTokenLogo = '',
    // parlay variables
    // -- market 2
    question2 = "Bitcoin breaks $100k in 2024",
    questionId2 = keccak256(question2 + marketFactory).toString('hex'),
    resolutionAgent2= walletAddress,
    conditionaId2 = keccak256(resolutionAgent2 + questionId2 + outcomeSlotCount).toString('hex'),
    marketId2 = keccak256(collateralToken + parentCollectionId + conditionaId2 + walletAddress).toString('hex'),
    payoutNumerators2 = JSON.stringify([1,0]),
    // -- market 3
    question3 = "World War 3 in 2025",
    questionId3 = keccak256(question3 + marketFactory).toString('hex'),
    resolutionAgent3 = walletAddress2,
    conditionaId3 = keccak256(resolutionAgent3 + questionId3 + outcomeSlotCount).toString('hex'),
    marketId3 = keccak256(collateralToken + parentCollectionId + conditionaId3 + walletAddress).toString('hex'),
    payoutNumerators3 = JSON.stringify([1,0])
    
  ))

  /***********************************************************************
  * MarketFactory: CREATE MARKET
  ************************************************************************/
  describe("MarketFactory.Create-Market", function () {
    it("+ve should approve a collateral", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Update-Lookup" },
          { name: "CollateralToken", value: collateralToken },
          { name: "CollateralTokenTicker", value: collateralTokenTicker },
          { name: "LpTokenLogo", value: lpTokenLogo },
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
      
      expect(action_).to.equal("Lookup-Updated")
      expect(data_.ticker).to.equal(collateralTokenTicker)
      expect(data_.logo).to.equal(lpTokenLogo)
    })

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
      console.log("Waiting 15s for market to be created...")
      await new Promise(resolve => setTimeout(resolve, 15000)); 
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
      console.log("marketProcessId: ", marketProcessId)
      
      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("created")
    })

    it("+ve should init a market", async () => {
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
      console.log("Waiting 5s for market to be init...")
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

  /***********************************************************************
  * MarketFactory: CREATE MARKET 2
  ************************************************************************/
  describe("MarketFactory.Create-Market.2", function () {
    it("+ve should create market 2", async () => {
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Recipient", value: marketFactory },
          { name: "X-Action", value: "Create-Market" },
          { name: "X-Question", value: question2 },
          { name: "X-ResolutionAgent", value: resolutionAgent2 },
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

    it("+ve should get market 2 data (status==created)", async () => {
      console.log("Waiting 15s for market to be created...")
      await new Promise(resolve => setTimeout(resolve, 15000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId2 },

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
      marketProcessId2 = data_.process_id
      console.log("marketProcessId2: ", marketProcessId2)
      
      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("created")
    })

    it("+ve should init market 2", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Init-Market" },
          { name: "MarketId", value: marketId2 }
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
      expect(marketId_).to.equal(marketId2)
    })

    it("+ve should get market 2 data (status==init)", async () => {
      console.log("Waiting 5s for market to be init...")
      await new Promise(resolve => setTimeout(resolve, 5000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId2 },

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

    it("+ve should get market 2 data (status==funded)", async () => {
      console.log("Waiting 5s for market to be funded...")
      await new Promise(resolve => setTimeout(resolve, 5000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId2 },

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

    it("+ve should have sent market 2 LP Tokens", async () => {
      await message({
        process: marketProcessId2,
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
        process: marketProcessId2,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const data_ = JSON.parse(Messages[0].Data)

      expect(data_[walletAddress]).to.equal('100000000000000')
    })
  })

  /***********************************************************************
  * MarketFactory: CREATE MARKET 3
  ************************************************************************/
  describe("MarketFactory.Create-Market.3", function () {
    it("+ve should create market 3", async () => {
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Recipient", value: marketFactory },
          { name: "X-Action", value: "Create-Market" },
          { name: "X-Question", value: question3 },
          { name: "X-ResolutionAgent", value: resolutionAgent3 },
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

    it("+ve should get market 3 data (status==created)", async () => {
      console.log("Waiting 15s for market to be created...")
      await new Promise(resolve => setTimeout(resolve, 15000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId3 },

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
      marketProcessId3 = data_.process_id
      console.log("marketProcessId3: ", marketProcessId3)
      
      expect(action_).to.equal("Market-Data")
      expect(data_.status).to.equal("created")
    })

    it("+ve should init market A", async () => {
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Init-Market" },
          { name: "MarketId", value: marketId3 }
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
      expect(marketId_).to.equal(marketId3)
    })

    it("+ve should get market 3 data (status==init)", async () => {
      console.log("Waiting 5s for market to be init...")
      await new Promise(resolve => setTimeout(resolve, 5000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId3 },

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

    it("+ve should get market A data (status==funded)", async () => {
      console.log("Waiting 5s for market to be funded...")
      await new Promise(resolve => setTimeout(resolve, 5000)); 
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Get-Market-Data" },
          { name: "MarketId", value: marketId3 },

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

    it("+ve should have sent market 3 LP Tokens", async () => {
      await message({
        process: marketProcessId3,
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
        process: marketProcessId3,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const data_ = JSON.parse(Messages[0].Data)

      expect(data_[walletAddress]).to.equal('100000000000000')
    })
  })
  
  /***********************************************************************
  * MarketFactory: CREATE PARLAY
  ************************************************************************/
  describe("MarketFactory.Parlay-Market", function () {
    it("+ve should create parlay", async () => {
      let marketId_1 = "435fc0cde62808b14fad4bf210a587ab9740d6a927e7d7030d49e57dc5e88df5"
      let marketId_2 = "f958f828483eb87d78a524181ccee4cf047af0f1b9cc77ce050e813e13d75b85"
      let marketId_3 = "7dffa283a47067c40a8b35437db5782a326d7681c6acfb5af1caadce8cefb3bd"
      await message({
        process: marketFactory,
        tags: [
          { name: "Action", value: "Create-Parlay" },
          { name: "MarketIds", value: JSON.stringify([marketId_1, marketId_2, marketId_3]) },
          { name: "IndexSets", value: JSON.stringify(["1", "1", "1"]) },
          { name: "Distribution", value: distribution },
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
    })
  })

  /***********************************************************************
  * MarketFactory: REPORT PAYOUTS
  ************************************************************************/
  // describe("MarketFactory.Report-Payouts", function () {
  //   it("+ve should report payouts for market 1", async () => {
  //     await message({
  //       process: marketFactory,
  //       tags: [
  //         { name: "Action", value: "Report-Payouts" },
  //         { name: "MarketId", value: marketId },
  //         { name: "PayoutNumerators", value: payoutNumerators },
  //       ],
  //       signer: createDataItemSigner(wallet2),
  //       data: "",
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: marketFactory,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value

  //     expect(action_).to.equal("Payouts-Reported")
  //   })
  //   it("+ve should report payouts for market 2", async () => {
  //     await message({
  //       process: marketFactory,
  //       tags: [
  //         { name: "Action", value: "Report-Payouts" },
  //         { name: "MarketId", value: marketId2 },
  //         { name: "PayoutNumerators", value: payoutNumerators2 },
  //       ],
  //       signer: createDataItemSigner(wallet),
  //       data: "",
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: marketFactory,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value

  //     expect(action_).to.equal("Payouts-Reported")
  //   })
  //   it("+ve should report payouts for market 3", async () => {
  //     await message({
  //       process: marketFactory,
  //       tags: [
  //         { name: "Action", value: "Report-Payouts" },
  //         { name: "MarketId", value: marketId3 },
  //         { name: "PayoutNumerators", value: payoutNumerators3 },
  //       ],
  //       signer: createDataItemSigner(wallet2),
  //       data: "",
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: marketFactory,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value

  //     expect(action_).to.equal("Payouts-Reported")
  //   })
  // })

  /***********************************************************************
  * MarketFactory: DERIVE PAYOUTS FOR PARLAY
  ************************************************************************/
  // describe("MarketFactory.Parlay-Market", function () {
  //   it("+ve should create a parlay market", async () => {
  //     let marketId_1 = "435fc0cde62808b14fad4bf210a587ab9740d6a927e7d7030d49e57dc5e88df5"
  //     let marketId_2 = "f958f828483eb87d78a524181ccee4cf047af0f1b9cc77ce050e813e13d75b85"
  //     let marketId_3 = "7dffa283a47067c40a8b35437db5782a326d7681c6acfb5af1caadce8cefb3bd"
  //     await message({
  //       process: marketFactory,
  //       tags: [
  //         { name: "Action", value: "Derive-Payout" },
  //         { name: "MarketIds", value: JSON.stringify([marketId_1, marketId_2, marketId_3]) },
  //         { name: "IndexSets", value: JSON.stringify(["1", "1", "1"]) },
  //         { name: "Distribution", value: distribution },
  //       ],
  //       signer: createDataItemSigner(wallet2),
  //       data: "",
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: marketFactory,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)
  //   })
  // })
})