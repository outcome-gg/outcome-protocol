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

const exchange = process.env.TEST_EXCHANGE79;
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
// let resolutionAgent;
// let questionId;
// let conditionId
// let outcomeSlotCount;
// let parentCollectionId;
// let indexSetIN;
// let indexSetOUT;
// let collectionIdIN;
// let collectionIdOUT;
// let positionIdIN;
// let positionIdOUT;

// Order variables
let limitOrders;
let limitOrderFill;
let limitOrderPartialFill;
let limitOrderAcrossDifferentLevels;
let orderIds;

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

    // // Conditional Token variables

    // // to get conditionId
    // questionId = 'trump-becomes-the-47th-president-of-the-usa',
    // resolutionAgent = walletAddress2,

    // // to get collectionId
    // parentCollectionId = "", // from collateral
    // indexSetIN = "1", // 1 for IN, 2 for OUT
    // indexSetOUT = "2", // 1 for IN, 2 for OUT
    
    // // Expected:
    // conditionId = "2d175f731624549c34fe14840990e92d610d63ea205028af076ec5cbef4e231c",
    // collectionIdIN = "45f9415be8dff7be6a906246c469f46730bccd9984486f4ad316cf90eb2e951d",
    // collectionIdOUT = "4c028af9b5b5f60457c96be27af32080a9adce728390919566bb2fcbd03d65f9",
    // positionIdIN = "c142089dc805ae34099deb85df86d1b7ed1350416d6b95f7b6f714c7a47d21ee",
    // positionIdOUT = "1cea0591a5ef57897cb99c865e7e9101ae8dbf23bb520595bc301cbf09f9be66",

    // to process orders
    limitOrders = [
      {'isBid' : false, 'size' : 5, 'price' : 101},
      {'isBid' : false, 'size' : 5, 'price' : 103},
      {'isBid' : false, 'size' : 5, 'price' : 102},
      {'isBid' : false, 'size' : 5, 'price' : 102},
      {'isBid' : false, 'size' : 5, 'price' : 102},
      {'isBid' : false, 'size' : 5, 'price' : 102},
      {'isBid' : false, 'size' : 5, 'price' : 101},
      {'isBid' : false, 'size' : 5, 'price' : 100},
      {'isBid' : true, 'size' : 5, 'price' : 99},
      {'isBid' : true, 'size' : 5, 'price' : 98},
      {'isBid' : true, 'size' : 5, 'price' : 99},
      {'isBid' : true, 'size' : 5, 'price' : 97},
      ],
    limitOrderFill = [ 
      {'isBid' : true, 'size' : 3, 'price' : 101},
    ],
    limitOrderPartialFill = [
      {'isBid' : true, 'size' : 12, 'price' : 101},
    ],
    limitOrderAcrossDifferentLevels = [
      {'isBid' : false, 'size' : 15, 'price' : 103},
    ],

      orderIds = []
    ))

  // /************************************************************************ 
  // * Initialization and Setup
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
  * Order Processing & Management
  ************************************************************************/
  describe("Order Processing & Management", function () {
    it("+ve [metrics] should retrieve orderbook metrics (where no orders exists)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('nil')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(0)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(0)
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(0)
    });

    it("+ve should add a new bid order", async () => {
      let order = limitOrders[limitOrders.length - 1]
      expect(order.isBid).to.be.equal(true)

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.equal(0)

      orderIds.push(orderId_)
    })

    it("+ve [metrics] should retrieve orderbook metrics (where bid exists)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('97000')
      expect(data_.bestAsk).to.equal('nil')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(5)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(5)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(0)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1)
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(0)
    });

    it("+ve should add a new ask order", async () => {
      let order = limitOrders[0]
      expect(order.isBid).to.be.equal(false)

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.equal(0)

      orderIds.push(orderId_)
    })

    it("+ve [metrics] should retrieve orderbook metrics (where bid & ask exist)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('97000')
      expect(data_.bestAsk).to.equal('101000')
      expect(Number(data_.spread)).to.equal(4000)
      expect(Number(data_.midPrice)).to.equal(99000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(10)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(5)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(5)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1)
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(1)
    });

    it("+ve should add orders at different price levels", async () => {
      // add remaining limitOrders
      let orders = limitOrders.slice(1, limitOrders.length - 1);

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Orders" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(orders),
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
      const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
      const orderIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrderIds').value)
      const orderSizes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrderSizes').value)
      const executedtradesList_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Orders-Processed")
      for (let i = 0; i < orders.length; i++) {
        expect(successes_[i]).to.equal(true)
        expect(orderIds_[i]).to.not.equal('')
        expect(orderSizes_[i]).to.equal(orders[i].size)
        expect(executedtradesList_[i].length).to.equal(0)
        expect(orderSizes_[i]).to.equal(orders[i].size)

        orderIds.push(orderIds_[i])
      }
    })

    it("+ve [metrics] should retrieve orderbook metrics (after multiple orders w/o matching)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(60)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(40)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(4) // 4 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101000']).to.equal(10)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("-ve should reject an order with invalid (non-integer) size", async () => {
      // non-integer size
      let order = {'isBid' : false, 
        'size' : 5.1, 
        'price' : 101
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid size")
    })

    it("-ve should reject an order with invalid (negative) size", async () => {
      // negative size
      let order = {'isBid' : false, 
        'size' : -1, 
        'price' : 101
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid size")
    })

    it("-ve should reject an order with invalid (negative) price", async () => {
      // negative price
      let order = {'isBid' : false, 
        'size' : 5, 
        'price' : -101
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price")
    })

    it("-ve should reject an order with invalid (zero) price", async () => {
      // negative price
      let order = {'isBid' : false, 
        'size' : 5, 
        'price' : 0
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price")
    })

    it("+ve [metrics] should retrieve orderbook metrics (same after rejected orders)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(60)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(40)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(4) // 4 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101000']).to.equal(10)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should accept an order with 3dp precision price", async () => {
      // negative price
      let order = {'isBid' : false, 
        'size' : 5, 
        'price' : 101.123
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.equal(0)

      orderIds.push(orderId_)
    })

    it("+ve [metrics] should retrieve orderbook metrics (including new 3dp bid)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(65)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(45)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 4 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(10)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("-ve should reject an order with invalid (>3dp) price", async () => {
      // negative price
      let order = {'isBid' : false, 
        'size' : 5, 
        'price' : 201.1234
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price")
    })

    it("+ve should update an existing order (size)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order size
      order.size *= 2

      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.equal(0)
    })

    it("+ve [metrics] should retrieve orderbook metrics (after updated order)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(70)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(50)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 4 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(15)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should reject an update to existing order (isBid)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order direction
      order.isBid = !order.isBid

      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid isBid")
    })

    it("+ve should reject an update to existing order (price)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order price
      order.price = order.price + 1

      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price")
    })

    it("+ve should cancel an existing order", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // cancel order by setting size to zero
      order.size = 0

      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')
      expect(orderSize_).to.equal('0')
      expect(executedTrades_.length).to.equal(0)
      expect(orderSize_).to.equal(order.size.toString())
    })

    it("+ve [metrics] should retrieve orderbook metrics (after canceled order)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(60)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(40)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 4 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(5)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("-ve should reject cancelation of a non-existent order", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // cancel order by setting size to zero
      order.size = 0

      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid order id")
    })

    it("+ve [metrics] should retrieve orderbook metrics (no change after non-cancelation)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(60)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(40)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 5 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(5)
      expect(orderBookAsks['100000']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should fill an order (bid)", async () => {
      let order = {
        'isBid' : true, 
        'size' : 5, 
        'price' : 101
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderId_ = Messages[0].Tags.find(t => t.name === 'OrderId').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')

      expect(executedTrades_[0].size).to.equal(order.size)
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size).toString())
    })

    it("+ve [metrics] should retrieve orderbook metrics (after trade / filled order)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      // TRADE of 5 shares at 100.000

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('101000')
      expect(Number(data_.spread)).to.equal(2000)
      expect(Number(data_.midPrice)).to.equal(100000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(55)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(35)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 5 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(5)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should fill an order across multiple orders (bid)", async () => {
      let order = {
        'isBid' : true, 
        'size' : 10, 
        'price' : 102
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')

      expect(executedTrades_.length).to.equal(2)
      expect(executedTrades_[0].size).to.equal(5)
      expect(executedTrades_[1].size).to.equal(5)
      expect(executedTrades_[0].price).to.equal('101000')
      expect(executedTrades_[1].price).to.equal('101123')
      expect(orderSize_).to.equal('0')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size - executedTrades_[1].size).toString())
    })

    it("+ve [metrics] should retrieve orderbook metrics (after trade across orders)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      // TRADE matches asks of 5 shares at 101.000 + 5 shares at 101.123

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('102000')
      expect(Number(data_.spread)).to.equal(3000)
      expect(Number(data_.midPrice)).to.equal(100500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(45)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(20)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(25)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 5 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookBids['99000']).to.equal(10)
      expect(orderBookBids['98000']).to.equal(5)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should fill an order across different price levels (ask)", async () => {
      let order = {
        'isBid' : false, 
        'size' : 12, 
        'price' : 96.5
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')

      expect(executedTrades_.length).to.equal(3)
      expect(executedTrades_[0].size).to.equal(5)
      expect(executedTrades_[1].size).to.equal(5)
      expect(executedTrades_[2].size).to.equal(2)
      expect(executedTrades_[0].price).to.equal('99000')
      expect(executedTrades_[1].price).to.equal('99000')
      expect(executedTrades_[2].price).to.equal('98000')
      expect(orderSize_).to.equal('0')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size - executedTrades_[1].size - executedTrades_[2].size).toString())
    })

    it("+ve [metrics] should retrieve orderbook metrics (after ask order filled at diff levels)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      // ORDER is ask of 2 shares at 96.500
      // TRADE matches bids of 10 shares at 99.000 

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('98000')
      expect(data_.bestAsk).to.equal('102000')
      expect(Number(data_.spread)).to.equal(4000)
      expect(Number(data_.midPrice)).to.equal(100000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(33)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(8)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(25)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(5) // 5 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookBids['99000']).to.equal(0)
      expect(orderBookBids['98000']).to.equal(3)
      expect(orderBookBids['97000']).to.equal(5)
    });

    it("+ve should partially fill an order and create a new position (ask)", async () => {
      let order = {
        'isBid' : false, 
        'size' : 13, 
        'price' : 96.5
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')

      expect(executedTrades_.length).to.equal(2)
      expect(executedTrades_[0].size).to.equal(3)
      expect(executedTrades_[1].size).to.equal(5)
      expect(executedTrades_[0].price).to.equal('98000')
      expect(executedTrades_[1].price).to.equal('97000')
      expect(orderSize_).to.equal('5')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size - executedTrades_[1].size).toString())
    })

    it("+ve [metrics] should retrieve orderbook metrics (after all bids matched)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('96500')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(30)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(30)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(6) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookAsks['96500']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(0)
      expect(orderBookBids['98000']).to.equal(0)
      expect(orderBookBids['97000']).to.equal(0)
    });
  })

  /************************************************************************ 
  * Order Book Metrics & Queries
  ************************************************************************/
  describe("Order Book Metrics & Queries", function () {
    it("+ve should retrieve metrics", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('96500')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(30)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(30)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(6) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookAsks['96500']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(0)
      expect(orderBookBids['98000']).to.equal(0)
      expect(orderBookBids['97000']).to.equal(0)
    });

    it("+ve should retrieve best bid (where no bid exists)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Best-Bid" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Best-Bid")
      expect(data_).to.equal(null)
    });

    it("+ve [process] should add bid", async () => {
      let order = {
        'isBid' : true, 
        'size' : 5, 
        'price' : 95.5
      }

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Order" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(order),
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
      const success_ = Messages[0].Tags.find(t => t.name === 'Success').value
      const orderSize_ = Messages[0].Tags.find(t => t.name === 'OrderSize').value
      const executedTrades_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Processed")
      expect(success_).to.equal('true')
      expect(typeof(orderId_)).to.equal('string')
      expect(orderId_).to.not.equal('')

      expect(executedTrades_.length).to.equal(0)
      expect(orderSize_).to.equal('5')
      expect(orderSize_).to.equal((order.size).toString())
    })

    it("+ve should retrieve best bid (where bid exists)", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Best-Bid" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Best-Bid")
      expect(data_).to.equal('95500')
    });

    it("+ve should retrieve best ask", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Best-Ask" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Best-Ask")
      expect(data_).to.equal('96500')
    });

    it("+ve should retrieve spread", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Spread" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Spread")
      expect(data_).to.equal(1000)
    });

    it("+ve should retrieve midPrice", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Mid-Price" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Mid-Price")
      expect(data_).to.equal(96000)
    });

    it("+ve should calculate market depth", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Market-Depth" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = data_['bids']
      const priceLevelsAsks = data_['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      expect(action_).to.equal("Market-Depth")
      expect(data_['bids'].length).to.equal(4) // priceLevels
      expect(data_['asks'].length).to.equal(6) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookAsks['96500']).to.equal(5)
      expect(orderBookBids['99000']).to.equal(0)
      expect(orderBookBids['98000']).to.equal(0)
      expect(orderBookBids['97000']).to.equal(0)
      expect(orderBookBids['95500']).to.equal(5)
    });

    it("+ve should return total liquidity", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Total-Liquidity" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Total-Liquidity")
      expect(data_['total']).to.equal(35)
      expect(data_['bids']).to.equal(5)
      expect(data_['asks']).to.equal(30)
    });

    it("+ve [process] should execute all existing orders", async () => {
      let orders = [
        {
          'isBid' : false, 
          'size' : 5, 
          'price' : 95.5
        },
        {
          'isBid' : true, 
          'size' : 30, 
          'price' : 103
        }
      ]

      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Process-Orders" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(orders),
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
      const orderIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrderIds').value)
      const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
      const orderSizes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrderSizes').value)
      const executedTradesList_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Orders-Processed")
      expect(successes_.length).to.equal(2)
      expect(successes_[0]).to.equal(true)
      expect(successes_[1]).to.equal(true)
      expect(orderIds_.length).to.equal(2)
      expect(orderIds_[0]).to.not.equal('')
      expect(orderIds_[1]).to.not.equal('')
      expect(orderSizes_.length).to.equal(2)
      expect(orderSizes_[0]).to.equal(0)
      expect(orderSizes_[1]).to.equal(0)
      expect(executedTradesList_.length).to.equal(2)
      expect(executedTradesList_[0].length).to.equal(1)
      expect(executedTradesList_[1].length).to.equal(6)
    })

    it("-ve should return appropriate values when order book is empty", async () => {
      let messageId;
      await message({
        process: exchange,
        tags: [
          { name: "Action", value: "Get-Order-Book-Metrics" },
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
        process: exchange,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const priceLevelsBids = JSON.parse(data_.marketDepth)['bids']
      const priceLevelsAsks = JSON.parse(data_.marketDepth)['asks']

      let orderBookBids = {}
      let orderBookAsks = {}

      for (let i = 0; i < priceLevelsBids.length; i++) {
        let priceLevel = priceLevelsBids[i]
        if (orderBookBids[priceLevel.price] === undefined) {
          orderBookBids[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookBids[priceLevel.price] += priceLevel.totalLiquidity
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.totalLiquidity
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.totalLiquidity
        }
      }
    
      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('nil')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(0)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(4) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(6) // priceLevels
      expect(orderBookAsks['103000']).to.equal(0)
      expect(orderBookAsks['102000']).to.equal(0)
      expect(orderBookAsks['101123']).to.equal(0)
      expect(orderBookAsks['101000']).to.equal(0)
      expect(orderBookAsks['100000']).to.equal(0)
      expect(orderBookAsks['96500']).to.equal(0)
      expect(orderBookBids['99000']).to.equal(0)
      expect(orderBookBids['98000']).to.equal(0)
      expect(orderBookBids['97000']).to.equal(0)
      expect(orderBookBids['95500']).to.equal(0)
    });
  });

  /************************************************************************ 
  * Price Benchmarking & Risk Functions
  ************************************************************************/
  describe("Price Benchmarking & Risk Functions", function () {
    // it("+ve should calculate VWAP", async () => {
    //   // Assume orders were added
    //   let vwapMessageId;
    //   await message({
    //     process: exchange,
    //     tags: [{ name: "Action", value: "Get-VWAP" }],
    //     signer: createDataItemSigner(wallet),
    //     data: "",
    //   }).then((id) => {
    //     vwapMessageId = id;
    //   }).catch(console.error);
    
    //   let { Messages, Error } = await result({
    //     message: vwapMessageId,
    //     process: exchange,
    //   });
    
    //   expect(Messages.length).to.be.equal(1);
    //   let vwap = Messages[0].Data;
    //   expect(vwap).to.be.greaterThan(0);  // VWAP should be positive
    // });
    it("+ve should calculate bid exposure", async () => { /* Test Code */ });
    it("+ve should calculate ask exposure", async () => { /* Test Code */ });
    it("+ve should calculate net exposure", async () => { /* Test Code */ });
    it("-ve should return zero for exposures when no orders exist", async () => { /* Test Code */ });
  });

})