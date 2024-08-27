import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'
import exp from "constants";

dotenv.config();

const amm = process.env.TEST_AMM3;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

console.log("AMM: ", amm)
console.log("COLLATERAL TOKEN: ", collateralToken)
console.log("CONDITIONAL TOKENS: ", conditionalTokens)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

// Txn execution variables
let wallet;
let wallet2;
let walletAddress;
let walletAddress2;

// Conditional Token variables
let resolutionAgent;
let questionId;
let conditionId
let outcomeSlotCount;
let parentCollectionId;
let indexSetIN;
let indexSetOUT;
let collectionIdIN;
let collectionIdOUT;
let positionIdIN;
let positionIdOUT;

/* 
* Tests
*/
describe("amm.integration.test", function () {
  before(async () => ( 
    // Txn execution variables
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet2.json')).toString(),
    ),
    walletAddress = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I',
    walletAddress2 = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',

    // Conditional Token variables

    // to get conditionId
    questionId = 'trump-becomes-the-47th-president-of-the-usa',
    resolutionAgent = walletAddress2,

    // to get collectionId
    parentCollectionId = "", // from collateral
    indexSetIN = "1", // 1 for IN, 2 for OUT
    indexSetOUT = "2", // 1 for IN, 2 for OUT
    
    // Expected:
    conditionId = "2d175f731624549c34fe14840990e92d610d63ea205028af076ec5cbef4e231c",
    collectionIdIN = "45f9415be8dff7be6a906246c469f46730bccd9984486f4ad316cf90eb2e951d",
    collectionIdOUT = "4c028af9b5b5f60457c96be27af32080a9adce728390919566bb2fcbd03d65f9",
    positionIdIN = "c142089dc805ae34099deb85df86d1b7ed1350416d6b95f7b6f714c7a47d21ee",
    positionIdOUT = "1cea0591a5ef57897cb99c865e7e9101ae8dbf23bb520595bc301cbf09f9be66"
  ))

  /************************************************************************ 
  * ConditionalTokens.Setup
  ************************************************************************/
  describe("amm.ConditionalTokens.Setup", function () {
    it("+ve should get conditionId", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Condition-Id" },
          { name: "ResolutionAgent", value: resolutionAgent },
          { name: "QuestionId", value: questionId },
          { name: "OutcomeSlotCount", value: "2" }, 
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

      expect(action_).to.equal("Condition-Id")
      expect(conditionId_).to.equal(conditionId)
      expect(questionId_).to.equal(questionId)
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal("2")
    })

    it("+ve should get collectionId for IN", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
          { name: "ConditionId", value: conditionId }, // from previous step
          { name: "IndexSet", value: indexSetIN }, // 1 for IN, 2 for OUT
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal(indexSetIN)
      expect(collectionId_).to.equal(collectionIdIN)
    })

    it("+ve should get collectionId for OUT", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
          { name: "ConditionId", value: conditionId }, // from previous step
          { name: "IndexSet", value: indexSetOUT }, // 1 for IN, 2 for OUT
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal(indexSetOUT)
      expect(collectionId_).to.equal(collectionIdOUT)
    })

    it("+ve should get positionId for IN", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Position-Id" },
          { name: "CollectionId", value: collectionIdIN }, // from previous step
          { name: "CollateralToken", value: collateralToken }, 
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
      const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

      expect(action_).to.equal("Position-Id")
      expect(collateralToken_).to.equal(collateralToken)
      expect(collectionId_).to.equal(collectionIdIN)
      expect(positionId_).to.equal(positionIdIN)
    })

    it("+ve should get positionId for OUT", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Position-Id" },
          { name: "CollectionId", value: collectionIdOUT }, // from previous step
          { name: "CollateralToken", value: collateralToken }, 
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
      const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

      expect(action_).to.equal("Position-Id")
      expect(collateralToken_).to.equal(collateralToken)
      expect(collectionId_).to.equal(collectionIdOUT)
      expect(positionId_).to.equal(positionIdOUT)
    })

    it("+ve should prepare condition", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId,
          outcomeSlotCount: 2
        }),
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

      expect(action_).to.equal("Condition-Preparation-Notice")
      expect(questionId_).to.equal(questionId)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + "2").toString('hex'))
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(2)
    })
  })

  /************************************************************************ 
  * amm.Init
  ************************************************************************/
  describe("amm.Init", function () {
    it("+ve should init amm", async () => {
      let messageId;
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Init" },
          { name: "ConditionId", value: conditionId },
          { name: "ConditionalTokens", value: conditionalTokens },
          { name: "CollateralToken", value: collateralToken },
          { name: "CollectionIds", value: JSON.stringify([collectionIdIN, collectionIdOUT]) },
          { name: "PositionIds", value: JSON.stringify([positionIdIN, positionIdOUT]) },
          { name: "DataIndex", value: "" },
          { name: "Fee", value: "10000000000" }, // 1% fee (10^10)
          { name: "Name", value: "Outcome ETH LP Token 2" }, 
          { name: "Ticker", value: "OETH1" }, 
          { name: "Logo", value: "" }, 
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      expect(Messages[0].Data).to.be.equal('Successfully created market')

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const conditionalTokens_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokens').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const positionIds_ = Messages[0].Tags.find(t => t.name === 'PositionIds').value
      const fee_ = Messages[0].Tags.find(t => t.name === 'Fee').value
      const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value

      expect(action_).to.equal("New-Market-Notice")
      expect(conditionId_).to.equal(conditionId)
      expect(conditionalTokens_).to.equal(conditionalTokens)
      expect(collateralToken_).to.equal(collateralToken)
      expect(positionIds_).to.equal(JSON.stringify([positionIdIN, positionIdOUT]))
      expect(fee_).to.equal("10000000000")
      expect(name_).to.equal("Outcome ETH LP Token 2")
      expect(ticker_).to.equal("OETH1")
      expect(logo_).to.equal("")
    })

    // it("+ve should fail to init amm after initialized", async () => {
    //   let messageId;
    //   await message({
    //     process: amm,
    //     tags: [
    //       { name: "Action", value: "Init" },
    //       { name: "ConditionalTokens", value: conditionalTokens },
    //       { name: "CollateralToken", value: collateralToken },
    //       { name: "ConditionId", value: "" },
    //       { name: "DataIndex", value: "" },
    //       { name: "Fee", value: "10000000000" }, // 1% fee (10^10)
    //       { name: "Name", value: "Outcome ETH LP Token" }, 
    //       { name: "Ticker", value: "OETH" }, 
    //       { name: "Logo", value: "" }, 
    //     ],
    //     signer: createDataItemSigner(wallet),
    //     data: "",
    //   })
    //   .then((id) => {
    //     messageId = id;
    //   })
    //   .catch(console.error);

    //   let { Messages, Error } = await result({
    //     message: messageId,
    //     process: amm,
    //   });

    //   if (Error) {
    //     console.log(Error)
    //   }

    //   // aoconnect Error not capturing the error message
    //   // but present in the AOS process logs
    //   expect(Messages.length).to.be.equal(0)
    // })
  })

  /************************************************************************ 
  * amm.Info
  ************************************************************************/
  describe("amm.Info", function () {
    it("+ve should get market info", async () => {
      let messageId;
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Token-Info" },
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
      const denomination_ = Messages[0].Tags.find(t => t.name === 'Denomination').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const conditionalTokens_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokens').value
      const feePoolWeight_ = Messages[0].Tags.find(t => t.name === 'FeePoolWeight').value
      const fee_ = Messages[0].Tags.find(t => t.name === 'Fee').value

      expect(name_).to.equal("Outcome ETH LP Token 2")
      expect(ticker_).to.equal("OETH1")
      expect(logo_).to.equal("")
      expect(denomination_).to.equal("12")
      expect(conditionId_).to.equal(conditionId)
      expect(collateralToken_).to.equal(collateralToken)
      expect(conditionalTokens_).to.equal(conditionalTokens)
      expect(feePoolWeight_).to.equal("0")
      expect(fee_).to.equal("10000000000")
    })
  })

  /************************************************************************ 
  * amm.Add-Funding
  ************************************************************************/
  describe("amm.Add-Funding", function () {
    it("+ve should add initial funding as per distribution", async () => {
      let messageId;
      const quantity = parseAmount(100, 12)
      const xDistribution = JSON.stringify([50, 50])
      const xAction = "Add-Funding"
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: amm },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: xAction },
          { name: "X-Distribution", value: xDistribution },
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

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const fromProcess_0 = Messages[0].Tags.find(t => t.name === 'From-Process').value
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_0 = Messages[0].Tags.find(t => t.name === 'X-Distribution').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const fromProcess_1 = Messages[1].Tags.find(t => t.name === 'From-Process').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_1 = Messages[1].Tags.find(t => t.name === 'X-Distribution').value
      
      expect(action_0).to.equal("Debit-Notice")
      expect(fromProcess_0).to.equal(collateralToken)
      expect(recipient_0).to.equal(amm)
      expect(quantity_0).to.equal(quantity)
      expect(xAction_0).to.equal(xAction)
      expect(xDistribution_0).to.equal(xDistribution)

      expect(action_1).to.equal("Credit-Notice")
      expect(fromProcess_1).to.equal(collateralToken)
      expect(sender_1).to.equal(walletAddress)
      expect(quantity_1).to.equal(quantity)
      expect(xAction_1).to.equal(xAction)
      expect(xDistribution_1).to.equal(xDistribution)
    })

    it("+ve should have minted LP tokens as per previous step's x-action", async () => {
      await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Balance" },
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const account_ = Messages[0].Tags.find(t => t.name === 'Account').value
      const balance_ = Messages[0].Tags.find(t => t.name === 'Balance').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      
      expect(account_).to.equal(walletAddress)
      expect(balance_).to.equal(parseAmount(100, 12))
      expect(ticker_).to.equal("OETH1")
    })

    it("+ve should have minted outcome tokens to amm in exchange for the LP tokens", async () => {
      await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balances-All" },
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const balances = JSON.parse(Messages[0].Data)

      expect(balances[positionIdIN][amm]).to.equal(parseAmount(100, 12))
      expect(balances[positionIdOUT][amm]).to.equal(parseAmount(100, 12))
    })

    it("+ve should add subsequent funding w/o distribution", async () => {
      let messageId;
      const quantity = parseAmount(100, 12)
      const xDistribution = JSON.stringify([])
      const xAction = "Add-Funding"
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: amm },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: xAction },
          { name: "X-Distribution", value: xDistribution },
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

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const fromProcess_0 = Messages[0].Tags.find(t => t.name === 'From-Process').value
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_0 = Messages[0].Tags.find(t => t.name === 'X-Distribution').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const fromProcess_1 = Messages[1].Tags.find(t => t.name === 'From-Process').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_1 = Messages[1].Tags.find(t => t.name === 'X-Distribution').value
      
      expect(action_0).to.equal("Debit-Notice")
      expect(fromProcess_0).to.equal(collateralToken)
      expect(recipient_0).to.equal(amm)
      expect(quantity_0).to.equal(quantity)
      expect(xAction_0).to.equal(xAction)
      expect(xDistribution_0).to.equal(xDistribution)

      expect(action_1).to.equal("Credit-Notice")
      expect(fromProcess_1).to.equal(collateralToken)
      expect(sender_1).to.equal(walletAddress)
      expect(quantity_1).to.equal(quantity)
      expect(xAction_1).to.equal(xAction)
      expect(xDistribution_1).to.equal(xDistribution)
    })

    it("+ve should have minted more LP tokens as per previous step's x-action", async () => {
      let messageId;
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Balance" },
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const account_ = Messages[0].Tags.find(t => t.name === 'Account').value
      const balance_ = Messages[0].Tags.find(t => t.name === 'Balance').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      
      expect(account_).to.equal(walletAddress)
      expect(balance_).to.equal(parseAmount(200, 12))
      expect(ticker_).to.equal("OETH1")
    })

    it("+ve should have minted more outcome tokens to amm in exchange for the LP tokens", async () => {
      await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balances-All" },
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
        process: conditionalTokens,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const balances = JSON.parse(Messages[0].Data)

      expect(balances[positionIdIN][amm]).to.equal(parseAmount(200, 12))
      expect(balances[positionIdOUT][amm]).to.equal(parseAmount(200, 12))
    })

    it("-ve should fail to add subsequent funding w/ distribution", async () => {
      let balanceBefore;
      let balanceAfter;
      async function getBalance() {
        let messageId;
        await message({
          process: collateralToken,
          tags: [
            { name: "Action", value: "Balance" },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: collateralToken,
        });

        const balance = Messages[0].Data
        return balance
      }

      async function addFundingWithDistributionAfterInitialFunding() {
        let messageId;
        const quantity = parseAmount(100, 12)
        const xDistribution = JSON.stringify([50, 50])
        const xAction = "Add-Funding"
        await message({
          process: collateralToken,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: amm },
            { name: "Quantity", value: quantity },
            { name: "X-Action", value: xAction },
            { name: "X-Distribution", value: xDistribution },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: collateralToken,
        });

        // Credit and Debit messages
        expect(Messages.length).to.be.equal(2)
      }

      balanceBefore = await getBalance();
      await addFundingWithDistributionAfterInitialFunding();
      // wait for failed forwarded call transfer of funds to be returned
      await new Promise(resolve => setTimeout(resolve, 5000));
      balanceAfter = await getBalance();

      expect(balanceBefore).to.be.equal(balanceAfter)
      expect(balanceBefore).to.not.equal(0)
    })

    it("-ve should fail add negative funding", async () => {
      let messageId;
      const quantity = (-1000000000000).toString()
      const xDistribution = JSON.stringify([])
      const xAction = "Add-Funding"
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: amm },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: xAction },
          { name: "X-Distribution", value: xDistribution },
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

      // Error handling message: Quantity must be greater than 0
      expect(Messages.length).to.be.equal(0)
    })
  })

  /************************************************************************ 
  * amm.Remove-Funding
  ************************************************************************/
  describe("amm.Remove-Funding", function () {
    before(async () => {
      // Add delay to allow for previous test to complete
      await new Promise(resolve => setTimeout(resolve, 5000));
    })

    it("+ve should remove funding", async () => {
      let messageId;
      let userBalanceBefore;
      let userBalanceAfter;
      let ammBalanceBefore;
      let ammBalanceAfter;

      const quantity = parseAmount(50, 12)
      const xAction = "Remove-Funding"

      async function getBalance(token, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance" },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      async function removeFunding() {
        await message({
          process: amm,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: amm },
            { name: "Quantity", value: quantity },
            { name: "X-Action", value: xAction },
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
          process: amm,
        });

        if (Error) {
          console.log(Error)
        }

        return Messages
      }

      userBalanceBefore = await getBalance(amm, walletAddress);
      ammBalanceBefore = await getBalance(amm, amm);

      let Messages = await removeFunding();

      userBalanceAfter = await getBalance(amm, walletAddress);
      ammBalanceAfter = await getBalance(amm, amm);

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value

      // Debits LP tokens from the sender to the amm
      expect(action_0).to.equal('Debit-Notice')
      expect(xAction_0).to.equal('Remove-Funding')
      expect(quantity_0).to.equal(quantity)
      expect(recipient_0).to.equal(amm)

      // Credits the amm with the LP tokens
      expect(action_1).to.equal('Credit-Notice')
      expect(xAction_1).to.equal('Remove-Funding')
      expect(quantity_1).to.equal(quantity)
      expect(sender_1).to.equal(walletAddress)

      // Check balances
      expect(userBalanceBefore).to.equal(parseAmount(200, 12))
      expect(userBalanceAfter).to.equal(parseAmount(150, 12))
      expect(ammBalanceBefore).to.equal(parseAmount(0, 12))
      expect(ammBalanceAfter).to.equal(parseAmount(0, 12))
    })

    it("-ve should fail to remove funding greater than balance", async () => {
      let messageId;
      let userBalanceBefore;
      let userBalanceAfter;
      let ammBalanceBefore;
      let ammBalanceAfter;

      const quantity = parseAmount(200, 12)
      const xAction = "Remove-Funding"

      async function getBalance(token, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance" },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      async function removeFunding() {
        await message({
          process: amm,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: amm },
            { name: "Quantity", value: quantity },
            { name: "X-Action", value: xAction },
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
          process: amm,
        });

        if (Error) {
          console.log(Error)
        }

        return Messages
      }

      userBalanceBefore = await getBalance(amm, walletAddress);
      ammBalanceBefore = await getBalance(amm, amm);

      let Messages = await removeFunding();

      userBalanceAfter = await getBalance(amm, walletAddress);
      ammBalanceAfter = await getBalance(amm, amm);

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const error_ = Messages[0].Tags.find(t => t.name === 'Error').value

      expect(action_).to.equal('Transfer-Error')
      expect(error_).to.equal('Insufficient Balance!')

      expect(userBalanceBefore).to.equal(parseAmount(150, 12))
      expect(userBalanceAfter).to.equal(parseAmount(150, 12))
      expect(ammBalanceBefore).to.equal(parseAmount(0, 12))
      expect(ammBalanceAfter).to.equal(parseAmount(0, 12))
    })
  })

  /************************************************************************ 
  * amm.Calc-Buy-Amount
  ************************************************************************/
  describe("amm.Calc-Buy-Amount", function () {
    it("+ve should calculate buy amount", async () => {
      let messageId;
      const investmentAmount = parseAmount(50, 12);
      const outcomeIndex = "1";
      
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Calc-Buy-Amount" },
          { name: "InvestmentAmount", value: investmentAmount },
          { name: "OutcomeIndex", value: outcomeIndex },
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const buyAmount_ = Messages[0].Tags.find(t => t.name === 'BuyAmount').value
      
      expect(buyAmount_).to.equal('89179358717434')
    })
  })

  /************************************************************************ 
  * amm.Calc-Sell-Amount
  ************************************************************************/
  describe("amm.Calc-Sell-Amount", function () {
    it("+ve should calculate sell amount", async () => {
      let messageId;
      const returnAmount = parseAmount(50, 12);
      const outcomeIndex = "1";
      
      await message({
        process: amm,
        tags: [
          { name: "Action", value: "Calc-Sell-Amount" },
          { name: "ReturnAmount", value: returnAmount },
          { name: "OutcomeIndex", value: outcomeIndex },
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
        process: amm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const sellAmount_ = Messages[0].Tags.find(t => t.name === 'SellAmount').value
      
      expect(sellAmount_).to.equal('118072618072620')
    })
  })

  /************************************************************************ 
  * amm.Buy
  ************************************************************************/
  describe("amm.Buy", function () {
    it("+ve should buy outcome tokens", async () => {
      const investmentAmount = parseAmount(10, 12);
      const outcomeIndex = "1";
      const positionId = positionIdIN;

      async function calcBuyAmount(amount, index) {
        let messageId;
        
        await message({
          process: amm,
          tags: [
            { name: "Action", value: "Calc-Buy-Amount" },
            { name: "InvestmentAmount", value: amount },
            { name: "OutcomeIndex", value: index },
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
          process: amm,
        });

        if (Error) {
          console.log(Error)
        }

        const buyAmount_ = Messages[0].Tags.find(t => t.name === 'BuyAmount').value
        return buyAmount_
      }

      async function buy(amount, index, minAmount) {
        let messageId;
        
        await message({
          process: collateralToken,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: amm },
            { name: "Quantity", value: amount },
            { name: "X-Action", value: "Buy" },
            { name: "X-OutcomeIndex", value: index },
            { name: "X-MinOutcomeTokensToBuy", value: minAmount },
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
      }

      async function getBalanceOf(token, tokenId, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-Of" },
            { name: "TokenId", value: tokenId },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      const balanceOfBefore = await getBalanceOf(conditionalTokens, positionId, walletAddress);
      const buyAmount = await calcBuyAmount(investmentAmount, outcomeIndex);

      await buy(investmentAmount, outcomeIndex, buyAmount.toString());

      // wait for the buy to be processed
      await new Promise(resolve => setTimeout(resolve, 5000));
      const balanceOfAfter = await getBalanceOf(conditionalTokens, positionId, walletAddress);

      expect(buyAmount).to.be.equal((balanceOfAfter - balanceOfBefore).toString())
    })
  })

  /************************************************************************ 
  * amm.Sell
  ************************************************************************/
  describe("amm.Sell", function () {
    it("+ve should sell outcome tokens", async () => {
      const returnAmount = parseAmount(9.2, 12); // User Balance - 8% (to account for fees)
      const outcomeIndex = "1";
      const positionId = positionIdIN;

      async function calcSellAmount(returnAmount, index) {
        let messageId;
        
        await message({
          process: amm,
          tags: [
            { name: "Action", value: "Calc-Sell-Amount" },
            { name: "ReturnAmount", value: returnAmount },
            { name: "OutcomeIndex", value: index },
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
          process: amm,
        });

        if (Error) {
          console.log(Error)
        }

        const sellAmount_ = Messages[0].Tags.find(t => t.name === 'SellAmount').value
        return sellAmount_
      }

      async function sell(returnAmount, index, maxSellAmount) {
        let messageId;
        
        await message({
          process: conditionalTokens,
          tags: [
            { name: "Action", value: "Transfer-Single" },
            { name: "Recipient", value: amm },
            { name: "TokenId", value: positionId },
            { name: "Quantity", value: maxSellAmount },
            { name: "X-Action", value: "Sell" },
            { name: "X-ReturnAmount", value: returnAmount },
            { name: "X-OutcomeIndex", value: index },
            { name: "X-MaxOutcomeTokensToSell", value: maxSellAmount },
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
      }

      async function getBalanceOf(token, tokenId, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-Of" },
            { name: "TokenId", value: tokenId },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      async function getBalance(token, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance" },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      const userBalanceOfBefore = await getBalanceOf(conditionalTokens, positionId, walletAddress);
      const userBalanceBefore = await getBalance(collateralToken, walletAddress);
      const ammBalanceOfBefore = await getBalanceOf(conditionalTokens, positionId, amm);
      const ammBalanceBefore = await getBalance(collateralToken, amm);
      const maxSellAmount = await calcSellAmount(returnAmount, outcomeIndex);

      await sell(returnAmount, outcomeIndex, maxSellAmount.toString());

      // wait for the sell to be processed
      await new Promise(resolve => setTimeout(resolve, 5000));
      const userBalanceOfAfter = await getBalanceOf(conditionalTokens, positionId, walletAddress);
      const userBalanceAfter = await getBalance(collateralToken, walletAddress);
      const ammBalanceOfAfter = await getBalanceOf(conditionalTokens, positionId, amm);
      const ammBalanceAfter = await getBalance(collateralToken, amm);

      // @dev: This is the actual amount sold / burned during the position merge process
      const sellAmount = "9292929292930"
      expect(Number(sellAmount)).to.be.lessThan(Number(maxSellAmount))
      expect(sellAmount).to.be.equal((userBalanceOfBefore - userBalanceOfAfter).toString())

      // User: Expect returnAmount of collateral tokens to be credited to user
      expect(returnAmount).to.be.equal((userBalanceAfter - userBalanceBefore).toString())

      // AMM: Expect amm balances to remain the same
      expect(ammBalanceOfBefore).to.be.equal(ammBalanceOfAfter)

      //AMM: expect fee to have been added to amm's balance
      // @dev: This is a 1% fee on the sell amount (approx.)
      const feeAmount = 92929292930;
      expect(ammBalanceAfter.toString()).to.be.equal((Number(ammBalanceBefore) + feeAmount).toString())
    })

    it("-ve should fail sell outcome tokens great than balance - fee", async () => {
      const returnAmount = parseAmount(10, 12); // Not accounting for balance
      const outcomeIndex = "1";
      const positionId = positionIdIN;

      async function calcSellAmount(returnAmount, index) {
        let messageId;
        
        await message({
          process: amm,
          tags: [
            { name: "Action", value: "Calc-Sell-Amount" },
            { name: "ReturnAmount", value: returnAmount },
            { name: "OutcomeIndex", value: index },
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
          process: amm,
        });

        if (Error) {
          console.log(Error)
        }

        const sellAmount_ = Messages[0].Tags.find(t => t.name === 'SellAmount').value
        return sellAmount_
      }

      async function sell(returnAmount, index, maxSellAmount) {
        let messageId;
        
        await message({
          process: conditionalTokens,
          tags: [
            { name: "Action", value: "Transfer-Single" },
            { name: "Recipient", value: amm },
            { name: "TokenId", value: positionId },
            { name: "Quantity", value: maxSellAmount },
            { name: "X-Action", value: "Sell" },
            { name: "X-ReturnAmount", value: returnAmount },
            { name: "X-OutcomeIndex", value: index },
            { name: "X-MaxOutcomeTokensToSell", value: maxSellAmount },
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
      }

      async function getBalanceOf(token, tokenId, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-Of" },
            { name: "TokenId", value: tokenId },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      async function getBalance(token, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance" },
            { name: "Recipient", value: recipient },
          ],
          signer: createDataItemSigner(wallet),
          data: "",
        })
        .then((id) => {
          messageId = id;
        })
        .catch(console.error);

        let { Messages } = await result({
          message: messageId,
          process: token,
        });

        const balance = Messages[0].Data
        return balance
      }

      const userBalanceOfBefore = await getBalanceOf(conditionalTokens, positionId, walletAddress);
      const userBalanceBefore = await getBalance(collateralToken, walletAddress);
      const ammBalanceOfBefore = await getBalanceOf(conditionalTokens, positionId, amm);
      const ammBalanceBefore = await getBalance(collateralToken, amm);
      const maxSellAmount = await calcSellAmount(returnAmount, outcomeIndex);

      await sell(returnAmount, outcomeIndex, maxSellAmount.toString());

      // wait for the sell to be processed
      await new Promise(resolve => setTimeout(resolve, 5000));
      const userBalanceOfAfter = await getBalanceOf(conditionalTokens, positionId, walletAddress);
      const userBalanceAfter = await getBalance(collateralToken, walletAddress);
      const ammBalanceOfAfter = await getBalanceOf(conditionalTokens, positionId, amm);
      const ammBalanceAfter = await getBalance(collateralToken, amm);

      // User: Excpect user balances to remain the same
      expect(userBalanceOfBefore).to.be.equal(userBalanceOfAfter)
      expect(userBalanceBefore).to.be.equal(userBalanceAfter)

      // AMM: Expect amm balances to remain the same
      expect(ammBalanceOfBefore).to.be.equal(ammBalanceOfAfter)
      expect(ammBalanceBefore).to.be.equal(ammBalanceAfter)
    })
  })
})