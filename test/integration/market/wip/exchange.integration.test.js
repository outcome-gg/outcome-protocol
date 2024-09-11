import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "../utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'
import exp from "constants";

dotenv.config();

const exchange = process.env.TEST_EXCHANGE2;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

console.log("EXCHANGE: ", exchange)
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
let limitOrders;

/* 
* Tests
*/
describe("exchange.integration.test", function () {
  before(async () => ( 
    // Txn execution variables
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../../wallet2.json')).toString(),
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
    positionIdOUT = "1cea0591a5ef57897cb99c865e7e9101ae8dbf23bb520595bc301cbf09f9be66",

    // to process orders
    limitOrders = [
      {'type' : 'limit', 
        'side' : 'ask', 
        'quantity' : 5, 
        'price' : 101,
        'tradeId' : 100},
      {'type' : 'limit', 
        'side' : 'ask', 
        'quantity' : 5, 
        'price' : 103,
        'tradeId' : 101},
      {'type' : 'limit', 
        'side' : 'ask', 
        'quantity' : 5, 
        'price' : 101,
        'tradeId' : 102},
      {'type' : 'limit', 
        'side' : 'ask', 
        'quantity' : 5, 
        'price' : 101,
        'tradeId' : 103},
      {'type' : 'limit', 
        'side' : 'bid', 
        'quantity' : 5, 
        'price' : 99,
        'tradeId' : 100},
      {'type' : 'limit', 
        'side' : 'bid', 
        'quantity' : 5, 
        'price' : 98,
        'tradeId' : 101},
      {'type' : 'limit', 
        'side' : 'bid', 
        'quantity' : 5, 
        'price' : 99,
        'tradeId' : 102},
      {'type' : 'limit', 
        'side' : 'bid', 
        'quantity' : 5, 
        'price' : 97,
        'tradeId' : 103},
      ]
    ))

  // /************************************************************************ 
  // * ConditionalTokens.Setup
  // ************************************************************************/
  // describe("exchange.ConditionalTokens.Setup", function () {
  //   it("+ve should get conditionId", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Condition-Id" },
  //         { name: "ResolutionAgent", value: resolutionAgent },
  //         { name: "QuestionId", value: questionId },
  //         { name: "OutcomeSlotCount", value: "2" }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
  //     const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  //     const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  //     expect(action_).to.equal("Condition-Id")
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(questionId_).to.equal(questionId)
  //     expect(resolutionAgent_).to.equal(resolutionAgent)
  //     expect(outcomeSlotCount_).to.equal("2")
  //   })

  //   it("+ve should get collectionId for IN", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Collection-Id" },
  //         { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
  //         { name: "ConditionId", value: conditionId }, // from previous step
  //         { name: "IndexSet", value: indexSetIN }, // 1 for IN, 2 for OUT
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

  //     expect(action_).to.equal("Collection-Id")
  //     expect(parentCollectionId_).to.equal(parentCollectionId)
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(indexSet_).to.equal(indexSetIN)
  //     expect(collectionId_).to.equal(collectionIdIN)
  //   })

  //   it("+ve should get collectionId for OUT", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Collection-Id" },
  //         { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
  //         { name: "ConditionId", value: conditionId }, // from previous step
  //         { name: "IndexSet", value: indexSetOUT }, // 1 for IN, 2 for OUT
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

  //     expect(action_).to.equal("Collection-Id")
  //     expect(parentCollectionId_).to.equal(parentCollectionId)
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(indexSet_).to.equal(indexSetOUT)
  //     expect(collectionId_).to.equal(collectionIdOUT)
  //   })

  //   it("+ve should get positionId for IN", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Position-Id" },
  //         { name: "CollectionId", value: collectionIdIN }, // from previous step
  //         { name: "CollateralToken", value: collateralToken }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
  //     const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

  //     expect(action_).to.equal("Position-Id")
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(collectionId_).to.equal(collectionIdIN)
  //     expect(positionId_).to.equal(positionIdIN)
  //   })

  //   it("+ve should get positionId for OUT", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Position-Id" },
  //         { name: "CollectionId", value: collectionIdOUT }, // from previous step
  //         { name: "CollateralToken", value: collateralToken }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
  //     const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

  //     expect(action_).to.equal("Position-Id")
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(collectionId_).to.equal(collectionIdOUT)
  //     expect(positionId_).to.equal(positionIdOUT)
  //   })

  //   it("+ve should prepare condition", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Prepare-Condition" },
  //       ],
  //       signer: createDataItemSigner(wallet),
  //       data: JSON.stringify({
  //         resolutionAgent: resolutionAgent,
  //         questionId: questionId,
  //         outcomeSlotCount: 2
  //       }),
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  //     const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  //     expect(action_).to.equal("Condition-Preparation-Notice")
  //     expect(questionId_).to.equal(questionId)
  //     expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + "2").toString('hex'))
  //     expect(resolutionAgent_).to.equal(resolutionAgent)
  //     expect(outcomeSlotCount_).to.equal('2')
  //   })
  // })

  // /************************************************************************ 
  // * exchange.Init
  // ************************************************************************/
  // describe("exchange.Init", function () {
  //   it("+ve should init exchange", async () => {
  //     let messageId;
  //     await message({
  //       process: exchange,
  //       tags: [
  //         { name: "Action", value: "Init" },
  //         { name: "ConditionId", value: conditionId },
  //         { name: "ConditionalTokens", value: conditionalTokens },
  //         { name: "CollateralToken", value: collateralToken },
  //         { name: "CollectionIds", value: JSON.stringify([collectionIdIN, collectionIdOUT]) },
  //         { name: "PositionIds", value: JSON.stringify([positionIdIN, positionIdOUT]) },
  //         { name: "DataIndex", value: "" },
  //         { name: "Fee", value: "10000000000" }, // 1% fee (10^10)
  //         { name: "Name", value: "Outcome ETH LP Token 2" }, 
  //         { name: "Ticker", value: "OETH1" }, 
  //         { name: "Logo", value: "" }, 
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
  //       process: exchange,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)
  //     expect(Messages[0].Data).to.be.equal('Successfully created market')

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const conditionalTokens_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokens').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const positionIds_ = Messages[0].Tags.find(t => t.name === 'PositionIds').value
  //     const fee_ = Messages[0].Tags.find(t => t.name === 'Fee').value
  //     const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
  //     const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
  //     const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value

  //     expect(action_).to.equal("New-Market-Notice")
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(conditionalTokens_).to.equal(conditionalTokens)
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(positionIds_).to.equal(JSON.stringify([positionIdIN, positionIdOUT]))
  //     expect(fee_).to.equal("10000000000")
  //     expect(name_).to.equal("Outcome ETH LP Token 2")
  //     expect(ticker_).to.equal("OETH1")
  //     expect(logo_).to.equal("")
  //   })
  // })

  /************************************************************************ 
  * exchange.Process-Order
  ************************************************************************/
  describe("exchange.Process-Order", function () {
    it("+ve should process order", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(limitOrders[0]),
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderInBook_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrderInBook').value)
      const trades_ = JSON.parse(Messages[0].Data)

      console.log("orderInBook_: ", orderInBook_)

      expect(action_).to.equal("Order-Processed")
      expect(orderId_).to.equal(1)
      expect(orderInBook_.quantity).to.equal(5)
      expect(orderInBook_.price).to.equal(101)
      expect(orderInBook_.side).to.equal('ask')
      expect(orderInBook_.orderId).to.equal(1)
      expect(orderInBook_.timestamp).to.equal(1)
      expect(orderInBook_.tradeId).to.equal(100)
      expect(orderInBook_.type).to.equal('limit')
      expect(trades_.length).to.equal(0)
    })
  })

  // /************************************************************************ 
  // * exchange.Process-Orders
  // ************************************************************************/
  // describe("exchange.Process-Orders", function () {
  //   it("+ve should process orders", async () => {
  //     let messageId;
  //     await message({
  //       process: exchange,
  //       tags: [
  //         { name: "Action", value: "Process-Orders" },
  //       ],
  //       signer: createDataItemSigner(wallet),
  //       data: JSON.stringify(limitOrders.slice(0,2)),
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: exchange,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const ordersInBook_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrdersInBook').value)
  //     const tradesList_ = JSON.parse(Messages[0].Data)

  //     console.log("ordersInBook_: ", ordersInBook_)
  //     console.log("tradesList_: ", tradesList_)

  //     expect(ordersInBook_.length).to.equal(2)
  //     expect(tradesList_.length).to.equal(2)

  //     expect(action_).to.equal("Orders-Processed")
  //     expect(ordersInBook_[0].quantity).to.equal(limitOrders[0].quantity)
  //     expect(ordersInBook_[0].price).to.equal(limitOrders[0].price)
  //     expect(ordersInBook_[0].side).to.equal(limitOrders[0].side)
  //     expect(ordersInBook_[0].orderId).to.equal(2)
  //     expect(ordersInBook_[0].timestamp).to.equal(2)
  //     expect(ordersInBook_[0].tradeId).to.equal(limitOrders[0].tradeId)
  //     expect(ordersInBook_[0].type).to.equal(limitOrders[0].type)
  //     expect(tradesList_[0].length).to.equal(0)

  //     expect(ordersInBook_[1].quantity).to.equal(limitOrders[1].quantity)
  //     expect(ordersInBook_[1].price).to.equal(limitOrders[1].price)
  //     expect(ordersInBook_[1].side).to.equal(limitOrders[1].side)
  //     expect(ordersInBook_[1].orderId).to.equal(3)
  //     expect(ordersInBook_[1].timestamp).to.equal(3)
  //     expect(ordersInBook_[1].tradeId).to.equal(limitOrders[1].tradeId)
  //     expect(ordersInBook_[1].type).to.equal(limitOrders[1].type)
  //     expect(tradesList_[1].length).to.equal(0)
  //   })
  // })

  // /************************************************************************ 
  // * amm.Info
  // ************************************************************************/
  // describe("amm.Info", function () {
  //   it("+ve should get market info", async () => {
  //     let messageId;
  //     await message({
  //       process: amm,
  //       tags: [
  //         { name: "Action", value: "Token-Info" },
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
  //       process: amm,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
  //     const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
  //     const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
  //     const denomination_ = Messages[0].Tags.find(t => t.name === 'Denomination').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const conditionalTokens_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokens').value
  //     const feePoolWeight_ = Messages[0].Tags.find(t => t.name === 'FeePoolWeight').value
  //     const fee_ = Messages[0].Tags.find(t => t.name === 'Fee').value

  //     expect(name_).to.equal("Outcome ETH LP Token 2")
  //     expect(ticker_).to.equal("OETH1")
  //     expect(logo_).to.equal("")
  //     expect(denomination_).to.equal("12")
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(conditionalTokens_).to.equal(conditionalTokens)
  //     expect(feePoolWeight_).to.equal("0")
  //     expect(fee_).to.equal("10000000000")
  //   })
  // })
})