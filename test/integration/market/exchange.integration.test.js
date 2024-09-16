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
      expect(executedTrades_[0].price).to.equal('101123')
      expect(executedTrades_[1].price).to.equal('101000')
      expect(orderSize_).to.equal('0')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size - executedTrades_[1].size).toString())
    })

    it("+ve should fill an order across different price levels (ask)", async () => {
      let order = {
        'isBid' : false, 
        'size' : 8, 
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
      expect(executedTrades_[0].size).to.equal(5)
      expect(executedTrades_[1].size).to.equal(3)
      expect(executedTrades_[0].price).to.equal('99000')
      expect(executedTrades_[1].price).to.equal('97000')
      expect(orderSize_).to.equal('0')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size - executedTrades_[1].size).toString())
    })

    it("+ve should partially fill an order and create a new position (ask)", async () => {
      let order = {
        'isBid' : false, 
        'size' : 8, 
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

      expect(executedTrades_.length).to.equal(1)
      expect(executedTrades_[0].size).to.equal(2)
      expect(executedTrades_[0].price).to.equal('97000')
      expect(orderSize_).to.equal('6')
      expect(orderSize_).to.equal((order.size - executedTrades_[0].size).toString())
    })
  })


 
    // // TODO: Move test
    // it("+ve should calculate correct VWAP", async () => {
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



  /************************************************************************ 
  * exchange.Process-Orders
  ************************************************************************/
  // describe("exchange.Process-Orders", function () {
  //   // it("+ve should process all add orders", async () => {
  //   //   let messageId;
  //   //   await message({
  //   //     process: exchange,
  //   //     tags: [
  //   //       { name: "Action", value: "Process-Orders" },
  //   //     ],
  //   //     signer: createDataItemSigner(wallet),
  //   //     data: JSON.stringify(limitOrders.slice(0,2)),
  //   //   })
  //   //   .then((id) => {
  //   //     messageId = id;
  //   //   })
  //   //   .catch(console.error);

  //   //   let { Messages, Error } = await result({
  //   //     message: messageId,
  //   //     process: exchange,
  //   //   });

  //   //   if (Error) {
  //   //     console.log(Error)
  //   //   }

  //   //   expect(Messages.length).to.be.equal(1)

  //   //   const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //   //   const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
  //   //   const ordersIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrdersIds').value)
  //   //   const originalOrders_ = JSON.parse(Messages[0].Data)

  //   //   console.log("ordersIds_: ", ordersIds_)

  //   //   expect(successes_.length).to.equal(2)
  //   //   expect(ordersIds_.length).to.equal(2)

  //   //   expect(action_).to.equal("Orders-Processed")
  //   //   expect(originalOrders_[0].size).to.equal(limitOrders[0].size)
  //   //   expect(originalOrders_[0].price).to.equal(limitOrders[0].price)
  //   //   expect(originalOrders_[0].isBid).to.equal(limitOrders[0].isBid)
  //   //   expect(successes_[0]).to.equal(true)

  //   //   expect(originalOrders_[1].size).to.equal(limitOrders[1].size)
  //   //   expect(originalOrders_[1].price).to.equal(limitOrders[1].price)
  //   //   expect(originalOrders_[1].isBid).to.equal(limitOrders[1].isBid)
  //   //   expect(successes_[1]).to.equal(true)
  //   })

  //   it("+ve should process all update orders", async () => {
  //     // let messageId;
  //     // await message({
  //     //   process: exchange,
  //     //   tags: [
  //     //     { name: "Action", value: "Process-Orders" },
  //     //   ],
  //     //   signer: createDataItemSigner(wallet),
  //     //   data: JSON.stringify(limitOrders),
  //     // })
  //     // .then((id) => {
  //     //   messageId = id;
  //     // })
  //     // .catch(console.error);

  //     // let { Messages, Error } = await result({
  //     //   message: messageId,
  //     //   process: exchange,
  //     // });

  //     // if (Error) {
  //     //   console.log(Error)
  //     // }

  //     // expect(Messages.length).to.be.equal(1)

  //     // const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     // const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
  //     // const ordersIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrdersIds').value)
  //     // const originalOrders_ = JSON.parse(Messages[0].Data)

  //     // console.log("ordersIds_: ", ordersIds_)

  //     // expect(successes_.length).to.equal(limitOrders.length)
  //     // expect(ordersIds_.length).to.equal(limitOrders.length)

  //     // expect(action_).to.equal("Orders-Processed")
  //     // for (let i = 0; i < limitOrders.length; i++) {
  //     //   expect(originalOrders_[i].size).to.equal(limitOrders[i].size)
  //     //   expect(originalOrders_[i].price).to.equal(limitOrders[i].price)
  //     //   expect(originalOrders_[i].isBid).to.equal(limitOrders[i].isBid)
  //     //   expect(successes_[i]).to.equal(true)
  //     // }
  //   })

  //   it("+ve should process all remove orders", async () => {
  //     // let messageId;
  //     // await message({
  //     //   process: exchange,
  //     //   tags: [
  //     //     { name: "Action", value: "Process-Orders" },
  //     //   ],
  //     //   signer: createDataItemSigner(wallet),
  //     //   data: JSON.stringify(limitOrders),
  //     // })
  //     // .then((id) => {
  //     //   messageId = id;
  //     // })
  //     // .catch(console.error);

  //     // let { Messages, Error } = await result({
  //     //   message: messageId,
  //     //   process: exchange,
  //     // });

  //     // if (Error) {
  //     //   console.log(Error)
  //     // }

  //     // expect(Messages.length).to.be.equal(1)

  //     // const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     // const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
  //     // const ordersIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrdersIds').value)
  //     // const originalOrders_ = JSON.parse(Messages[0].Data)

  //     // console.log("ordersIds_: ", ordersIds_)

  //     // expect(successes_.length).to.equal(limitOrders.length)
  //     // expect(ordersIds_.length).to.equal(limitOrders.length)

  //     // expect(action_).to.equal("Orders-Processed")
  //     // for (let i = 0; i < limitOrders.length; i++) {
  //     //   expect(originalOrders_[i].size).to.equal(limitOrders[i].size)
  //     //   expect(originalOrders_[i].price).to.equal(limitOrders[i].price)
  //     //   expect(originalOrders_[i].isBid).to.equal(limitOrders[i].isBid)
  //     //   expect(successes_[i]).to.equal(true)
  //     // }
  //   })

  //   // it("+ve should process all mixed-type orders", async () => {
  //   //   let messageId;
  //   //   await message({
  //   //     process: exchange,
  //   //     tags: [
  //   //       { name: "Action", value: "Process-Orders" },
  //   //     ],
  //   //     signer: createDataItemSigner(wallet),
  //   //     data: JSON.stringify(limitOrders),
  //   //   })
  //   //   .then((id) => {
  //   //     messageId = id;
  //   //   })
  //   //   .catch(console.error);

  //   //   let { Messages, Error } = await result({
  //   //     message: messageId,
  //   //     process: exchange,
  //   //   });

  //   //   if (Error) {
  //   //     console.log(Error)
  //   //   }

  //   //   expect(Messages.length).to.be.equal(1)

  //   //   const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //   //   const successes_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Successes').value)
  //   //   const ordersIds_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'OrdersIds').value)
  //   //   const originalOrders_ = JSON.parse(Messages[0].Data)

  //   //   console.log("ordersIds_: ", ordersIds_)

  //   //   expect(successes_.length).to.equal(limitOrders.length)
  //   //   expect(ordersIds_.length).to.equal(limitOrders.length)

  //   //   expect(action_).to.equal("Orders-Processed")
  //   //   for (let i = 0; i < limitOrders.length; i++) {
  //   //     expect(originalOrders_[i].size).to.equal(limitOrders[i].size)
  //   //     expect(originalOrders_[i].price).to.equal(limitOrders[i].price)
  //   //     expect(originalOrders_[i].isBid).to.equal(limitOrders[i].isBid)
  //   //     expect(successes_[i]).to.equal(true)
  //   //   }
  //   // })
  // })

  /************************************************************************ 
  * Order Book Metrics & Queries
  ************************************************************************/
  describe("Order Book Metrics & Queries", function () {
    it("+ve should retrieve best bid/ask", async () => { /* Test Code */ });
    it("+ve should calculate spread", async () => { /* Test Code */ });
    it("+ve should calculate market depth", async () => { /* Test Code */ });
    it("+ve should return total volume", async () => { /* Test Code */ });
    it("-ve should return appropriate values when order book is empty", async () => { /* Test Code */ });
  });

  /************************************************************************ 
  * Order Details Queries
  ************************************************************************/
  describe("Order Book Metrics & Queries", function () {
    it("+ve should retrieve best bid/ask", async () => { /* Test Code */ });
    it("+ve should calculate spread", async () => { /* Test Code */ });
    it("+ve should calculate market depth", async () => { /* Test Code */ });
    it("+ve should return total volume", async () => { /* Test Code */ });
    it("-ve should return appropriate values when order book is empty", async () => { /* Test Code */ });
  });

  /************************************************************************ 
  * Price Benchmarking & Risk Functions
  ************************************************************************/
  describe("Price Benchmarking & Risk Functions", function () {
    it("+ve should calculate VWAP", async () => { /* Test Code */ });
    it("+ve should calculate bid exposure", async () => { /* Test Code */ });
    it("+ve should calculate ask exposure", async () => { /* Test Code */ });
    it("+ve should calculate net exposure", async () => { /* Test Code */ });
    it("-ve should return zero for exposures when no orders exist", async () => { /* Test Code */ });
  });

})