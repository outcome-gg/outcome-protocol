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

const dlob = process.env.TEST_DLOB;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

console.log("DLOB: ", dlob)
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

// Order variables
let limitOrders;
let limitOrderFill;
let limitOrderPartialFill;
let limitOrderAcrossDifferentLevels;
let orderIds;

// Conditional Token variables
let resolutionAgent;
let questionId;
let conditionId
let parentCollectionId;
let indexSetIN;
let indexSetOUT;
let collectionIdIN;
let collectionIdOUT;
let positionIdIN;
let positionIdOUT;

// Funding variables
let fundQuantity
let shareQuantity;

/* 
* Tests
*/
describe("dlob.integration.test", function () {
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

    // Conditional Token variables ---------------------------

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

    // DLOB variables ----------------------------------------
    fundQuantity = (10*10**10).toString(),
    shareQuantity = (10*10**10).toString(),

    // DLOB variables ----------------------------------------

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

  /************************************************************************ 
  * ConditionalTokens.Setup
  ************************************************************************/
  describe("dlob.ConditionalTokens.Setup", function () {
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
      expect(outcomeSlotCount_).to.equal('2')
    })

    it("+ve should split a position (from collateral)", async () => {
      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: shareQuantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: "" }, // from collateral
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify([0b01, 0b10]) },
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
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should have minted an IN position (from collateral)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balances-Of" },
          { name: "TokenId", value: positionIdIN },
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
      expect(balances[walletAddress]).to.equal(shareQuantity)
    })

    it("+ve should have minted an OUT position (from collateral)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balances-Of" },
          { name: "TokenId", value: positionIdOUT },
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
      expect(balances[walletAddress]).to.equal(shareQuantity)
    })
  })

  /************************************************************************ 
  * Initialization and Setup
  ************************************************************************/
  describe("dlob.Init", function () {
    it("+ve should init dlob", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Init" },
          { name: "ConditionalTokens", value: conditionalTokens },
          { name: "ConditionalTokensId", value: positionIdIN },
          { name: "CollateralToken", value: collateralToken },
          { name: "DataIndex", value: "" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      expect(Messages[0].Data).to.be.equal('Successfully initialized DLOB')

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionalTokens_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokens').value
      const conditionalTokensId_ = Messages[0].Tags.find(t => t.name === 'ConditionalTokensId').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value

      expect(action_).to.equal("Init-DLOB-Notice")
      expect(conditionalTokens_).to.equal(conditionalTokens)
      expect(conditionalTokensId_).to.equal(positionIdIN)
      expect(collateralToken_).to.equal(collateralToken)
    })

    it("-ve should fail to init twice", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Init" },
          { name: "ConditionalTokens", value: conditionalTokens },
          { name: "ConditionalTokensId", value: positionIdIN },
          { name: "CollateralToken", value: collateralToken },
          { name: "DataIndex", value: "" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      expect(Messages[0].Data).to.be.equal('DLOB already initialized!')

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      expect(action_).to.equal("Init-DLOB-Error")
    })
  })

  /************************************************************************ 
  * Fund Management
  ************************************************************************/
  describe("dlob.Fund Management", function () {
    it("+ve should get balance info (no balances)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Balance-Info")
      expect(data_.lockedFunds).to.equal(0)
      expect(data_.availableShares).to.equal(0)
      expect(data_.lockedShares).to.equal(0)
      expect(data_.availableFunds).to.equal(0)
    })

    it("+ve [transfer] should add funds", async () => {
      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: dlob },
          { name: "Quantity", value: fundQuantity }
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Notice")
      expect(quantity_).to.equal("100000000000")
      expect(recipient_).to.equal(dlob)
    })

    it("+ve should get balance info (new available funds)", async () => {
      await delay(1000)
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000)
      expect(data_.availableShares).to.equal(0)
      expect(data_.lockedFunds).to.equal(0)
      expect(data_.lockedShares).to.equal(0)
    })

    it("+ve [transfer] should add shares", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Single" },
          { name: "Recipient", value: dlob },
          { name: "TokenId", value: positionIdIN },
          { name: "Quantity", value: shareQuantity }
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

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const tokenId_ = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Single-Notice")
      expect(quantity_).to.equal("100000000000")
      expect(tokenId_).to.equal(positionIdIN)
      expect(recipient_).to.equal(dlob)
    })

    it("+ve should get balance info (new available shares)", async () => {
      await delay(1000)
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000)
      expect(data_.availableShares).to.equal(100000000000)
      expect(data_.lockedFunds).to.equal(0)
      expect(data_.lockedShares).to.equal(0)
    })

    it("+ve should withdraw funds (partial)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Funds" },
          { name: "Quantity", value: (Number(fundQuantity)/2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const message_ = Messages[1].Data

      expect(action_).to.equal("Withdraw-Funds-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(message_).to.equal("Withdraw funds succeeded")
    })

    it("-ve should fail to withdraw funds (quantity > balance)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Funds" },
          { name: "Quantity", value: (Number(fundQuantity)*2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const message_ = Messages[0].Data

      expect(action_).to.equal("Withdraw-Funds-Error")
      expect(message_).to.equal("Insufficient fund balance")
    })

    it("+ve should withdraw shares (partial)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Shares" },
          { name: "Quantity", value: (Number(shareQuantity)/2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const message_ = Messages[1].Data

      expect(action_).to.equal("Withdraw-Shares-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(message_).to.equal("Withdraw shares succeeded")
    })

    it("-ve should fail to withdraw shares (quantity > balance)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Shares" },
          { name: "Quantity", value: (Number(shareQuantity)*2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const message_ = Messages[0].Data

      expect(action_).to.equal("Withdraw-Shares-Error")
      expect(message_).to.equal("Insufficient share balance")
    })

    it("+ve should withdraw funds (all)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Funds" },
          { name: "Quantity", value: (Number(fundQuantity)/2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const message_ = Messages[1].Data

      expect(action_).to.equal("Withdraw-Funds-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(message_).to.equal("Withdraw funds succeeded")
    })

    it("+ve should withdraw shares (all)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Withdraw-Shares" },
          { name: "Quantity", value: (Number(shareQuantity)/2).toString() },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const message_ = Messages[1].Data

      expect(action_).to.equal("Withdraw-Shares-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(message_).to.equal("Withdraw shares succeeded")
    })

    it("+ve should get balance info (zero balances)", async () => {
      await delay(1000)
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(0)
      expect(data_.availableShares).to.equal(0)
      expect(data_.lockedFunds).to.equal(0)
      expect(data_.lockedShares).to.equal(0)
    })

    it("+ve [process] should add a new bid order (from collateral)", async () => {
      let order = limitOrders[limitOrders.length - 1]
      expect(order.isBid).to.be.equal(true)

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: dlob },
          { name: "Quantity", value: (Number(fundQuantity)/2).toString() },
          { name: "X-Action", value: "Process-Order" },
          { name: "X-Data", value: JSON.stringify(order) },
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(recipient_).to.equal(dlob)
    })

    it("+ve [transfer] should add funds (for process order from balance)", async () => {
      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: dlob },
          { name: "Quantity", value: (Number(fundQuantity)/2).toString() }
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(recipient_).to.equal(dlob)
    })

    it("+ve [process] should add a new bid order (from balance)", async () => {
      let order = limitOrders[limitOrders.length - 1]
      expect(order.isBid).to.be.equal(true)

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
      expect(success_).to.equal("true")
      expect(orderId_).to.not.equal("")
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.be.equal(0)
    })

    it("+ve should get balance info (order amount to locked funds)", async () => {
      await delay(1000)
      let order = limitOrders[limitOrders.length - 1]
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const lockedFunds = order.size * order.price * 2

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000 - lockedFunds)
      expect(data_.availableShares).to.equal(0)
      expect(data_.lockedFunds).to.equal(lockedFunds)
      expect(data_.lockedShares).to.equal(0)
    })

    it("+ve [process] should add a new ask order (from conditionalTokens)", async () => {
      let order = limitOrders[0]
      expect(order.isBid).to.be.equal(false)

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Single" },
          { name: "Recipient", value: dlob },
          { name: "Quantity", value: (Number(shareQuantity)/2).toString() },
          { name: "TokenId", value: positionIdIN },
          { name: "X-Action", value: "Process-Order" },
          { name: "X-Data", value: JSON.stringify(order) },
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

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const tokenId_ = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Single-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(tokenId_).to.equal(positionIdIN)
      expect(recipient_).to.equal(dlob)
    })

    it("+ve [transfer] should add shares", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Single" },
          { name: "Recipient", value: dlob },
          { name: "TokenId", value: positionIdIN },
          { name: "Quantity", value: (Number(shareQuantity)/2).toString() }
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

      expect(Messages.length).to.be.equal(2)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_ = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const tokenId_ = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const recipient_ = Messages[0].Tags.find(t => t.name === 'Recipient').value

      expect(action_).to.equal("Debit-Single-Notice")
      expect(quantity_).to.equal("50000000000")
      expect(tokenId_).to.equal(positionIdIN)
      expect(recipient_).to.equal(dlob)
    })

    it("+ve [process] should add a new ask order (from balance)", async () => {
      let order = limitOrders[0]
      expect(order.isBid).to.be.equal(false)

      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Process-Order" },
          { name: "Quantity", value: (Number(shareQuantity)/2).toString() },
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
        process: dlob,
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
      expect(success_).to.equal("true")
      expect(orderId_).to.not.equal("")
      expect(orderSize_).to.equal(order.size.toString())
      expect(executedTrades_.length).to.be.equal(0)
    })

    it("+ve should get balance info (available balance to locked shares)", async () => {
      await delay(1000)
      let bidOrder = limitOrders[limitOrders.length - 1]
      let askOrder = limitOrders[0]
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const lockedFunds = bidOrder.size * bidOrder.price * 2
      const lockedShares = askOrder.size * 2

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000 - lockedFunds)
      expect(data_.availableShares).to.equal(100000000000 - lockedShares)
      expect(data_.lockedFunds).to.equal(lockedFunds)
      expect(data_.lockedShares).to.equal(lockedShares)
    })

    it("+ve [process] should add bid order (to match/trade from balance)", async () => {
      let order = limitOrderFill[0]
      expect(order.isBid).to.be.equal(true)

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
      expect(success_).to.equal("true")
      expect(orderId_).to.not.equal("")
      expect(orderSize_).to.equal("0")
      expect(executedTrades_.length).to.be.equal(1)
      expect(executedTrades_[0].price).to.be.equal((order.price*1000).toString())
      expect(executedTrades_[0].size).to.be.equal(order.size)
    })

    it("+ve should get balance info (matched order to available funds/shares)", async () => {
      await delay(1000)
      const bidOrder = limitOrders[limitOrders.length - 1]
      const askOrder = limitOrders[0]
      const fillOrder = limitOrderFill[0]
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const lockedFunds = bidOrder.size * bidOrder.price * 2
      const lockedShares = askOrder.size * 2 - fillOrder.size

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000 - lockedFunds)
      expect(data_.availableShares).to.equal(100000000000 - lockedShares)
      expect(data_.lockedFunds).to.equal(lockedFunds)
      expect(data_.lockedShares).to.equal(lockedShares)
    })

    it("+ve [process] should add ask order (to partially-match/trade from balance)", async () => {
      let order = {'isBid' : false, 'size' : 12, 'price' : 97}

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
      expect(success_).to.equal("true")
      expect(orderId_).to.not.equal("")
      expect(orderSize_).to.equal("2")
      expect(executedTrades_.length).to.be.equal(2)
      expect(executedTrades_[0].price).to.be.equal((order.price * 1000).toString())
      expect(executedTrades_[0].size).to.be.equal(5)
      expect(executedTrades_[1].price).to.be.equal((order.price * 1000).toString())
      expect(executedTrades_[1].size).to.be.equal(5)
    })

    it("+ve should get balance info (partially matched order to available funds/shares)", async () => {
      await delay(1000)
      const bidOrder = limitOrders[limitOrders.length - 1]
      const askOrder = limitOrders[0]
      const fillOrder = limitOrderFill[0]
      
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Balance-Info" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const lockedShares = askOrder.size * 2 - fillOrder.size + 2 // remaining shares from partial match

      expect(action_).to.equal("Balance-Info")
      expect(data_.availableFunds).to.equal(100000000000)
      expect(data_.availableShares).to.equal(100000000000 - lockedShares)
      expect(data_.lockedFunds).to.equal(0)
      expect(data_.lockedShares).to.equal(lockedShares)
    })

    it("+ve [process] should add ask order (to clear LOB for next tests)", async () => {
      let order = {'isBid' : true, 'size' : 9, 'price' : 101}

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
      expect(success_).to.equal("true")
      expect(orderId_).to.not.equal("")
      expect(orderSize_).to.equal("0")
      expect(executedTrades_.length).to.be.equal(3)
    })
  })

  /************************************************************************ 
  * Order Processing & Management
  ************************************************************************/
  describe("Order Processing & Management", function () {
    it("+ve [metrics] should retrieve orderbook metrics (where no orders exists)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const liquidity = limitOrders[limitOrders.length - 1].size * limitOrders[limitOrders.length - 1].price

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('97000')
      expect(data_.bestAsk).to.equal('nil')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(liquidity)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(liquidity)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(0)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1)
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(0)
    });

    it("+ve should add a new ask order", async () => {
      let order = limitOrders[0]
      expect(order.isBid).to.be.equal(false)

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const bidLiquidity = limitOrders[limitOrders.length - 1].size * limitOrders[limitOrders.length - 1].price
      const askLiquidity = limitOrders[0].size * limitOrders[0].price

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('97000')
      expect(data_.bestAsk).to.equal('101000')
      expect(Number(data_.spread)).to.equal(4000)
      expect(Number(data_.midPrice)).to.equal(99000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(bidLiquidity + askLiquidity)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(bidLiquidity)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(askLiquidity)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1)
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(1)
    });

    it("+ve should add orders at different price levels", async () => {
      // add remaining limitOrders
      let orders = limitOrders.slice(1, limitOrders.length - 1);

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
    });

    it("+ve [metrics] should retrieve orderbook metrics (after multiple orders w/o matching)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(6030)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(4065)
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
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid size precision")
    })

    it("-ve should reject an order with invalid (negative) size", async () => {
      // negative size
      let order = {'isBid' : false, 
        'size' : -1, 
        'price' : 101
      }

      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(6030)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(4065)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(6535.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(4570.615)
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
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price precision")
    })

    it("+ve should update an existing order (size)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order size
      order.size *= 2

      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(7040.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(5075.615)
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

    it("-ve should reject an update to existing order (isBid)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order direction
      order.isBid = !order.isBid

      await message({
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid isBid")
    })

    it("-ve should reject an update to existing order (price)", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // update the order price
      order.price = order.price + 1

      await message({
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const errorMessage_ = Messages[0].Data

      expect(action_).to.equal("Process-Order-Error")
      expect(errorMessage_).to.equal("Invalid price")
    })

    it("+ve [metrics] should retrieve orderbook metrics (unchanged after invalid orders)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(7040.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(5075.615)
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

    it("+ve should cancel an existing order", async () => {
      let messageId;

      let order = JSON.parse(JSON.stringify(limitOrders[0]));
      // set the order id
      order.uid = orderIds[1]
      // cancel order by setting size to zero
      order.size = 0

      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(6030.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(4065.615)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('100000')
      expect(Number(data_.spread)).to.equal(1000)
      expect(Number(data_.midPrice)).to.equal(99500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(6030.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(4065.615)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // TRADE of 5 shares at 100.000

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('101000')
      expect(Number(data_.spread)).to.equal(2000)
      expect(Number(data_.midPrice)).to.equal(100000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(5530.615)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(3565.615)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(4) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['101123']).to.equal(5)
      expect(orderBookAsks['101000']).to.equal(5)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // TRADE matches asks of 5 shares at 101.000 + 5 shares at 101.123

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('99000')
      expect(data_.bestAsk).to.equal('102000')
      expect(Number(data_.spread)).to.equal(3000)
      expect(Number(data_.midPrice)).to.equal(100500)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(4520)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(1965)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(2555)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(3) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(2) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 2 shares at 96.500
      // TRADE matches bids of 10 shares at 99.000 

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('98000')
      expect(data_.bestAsk).to.equal('102000')
      expect(Number(data_.spread)).to.equal(4000)
      expect(Number(data_.midPrice)).to.equal(100000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(3334)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(779)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(2555)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(2) // 3 priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(2) // 5 priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('96500')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(3037.5)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(3037.5)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(0) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(3) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['96500']).to.equal(5)
    });
  })

  /************************************************************************ 
  * Order Book Metrics & Queries
  ************************************************************************/
  describe("Order Book Metrics & Queries", function () {
    it("+ve should retrieve metrics", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('nil')
      expect(data_.bestAsk).to.equal('96500')
      expect(data_.spread).to.equal('nil')
      expect(data_.midPrice).to.equal('nil')
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(3037.5)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(0)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(3037.5)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(0) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(3) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['96500']).to.equal(5)
    });

    it("+ve should retrieve best bid (where no bid exists)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      expect(action_).to.equal("Market-Depth")
      expect(data_['bids'].length).to.equal(1) // priceLevels
      expect(data_['asks'].length).to.equal(3) // priceLevels
      expect(orderBookAsks['103000']).to.equal(5)
      expect(orderBookAsks['102000']).to.equal(20)
      expect(orderBookAsks['96500']).to.equal(5)
      expect(orderBookBids['95500']).to.equal(5)
    });

    it("+ve should return total liquidity", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Total-Liquidity")
      expect(data_['total']).to.equal(3515)
      expect(data_['bids']).to.equal(477.5)
      expect(data_['asks']).to.equal(3037.5)
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
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
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(0) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(0) // priceLevels
    });
  });

  /************************************************************************ 
  * Order Details Queries
  ************************************************************************/
  describe("Order Details Queries", function () {
    const orders = [
      {
        'isBid' : false, 
        'size' : 5, 
        'price' : 90
      },
      {
        'isBid' : true, 
        'size' : 30, 
        'price' : 88
      }
    ]
    let orderIds = []

    it("+ve [process] should add bid/ask orders", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
      expect(orderSizes_[0]).to.equal(5)
      expect(orderSizes_[1]).to.equal(30)
      expect(executedTradesList_.length).to.equal(2)
      expect(executedTradesList_[0].length).to.equal(0)
      expect(executedTradesList_[1].length).to.equal(0)

      orderIds = orderIds_
    })

    it("+ve [metrics] should retrieve orderbook metrics (after processing orders)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('88000')
      expect(data_.bestAsk).to.equal('90000')
      expect(Number(data_.spread)).to.equal(2000)
      expect(Number(data_.midPrice)).to.equal(89000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(3090)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(2640)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(450)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(1) // priceLevels
      expect(orderBookAsks['90000']).to.equal(5)
      expect(orderBookBids['88000']).to.equal(30)
    });
   
    it("+ve should get order details (id exists)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Order-Details" },
          { name: "OrderId", value: orderIds[0] },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.equal("Order-Details")
      expect(data_['isBid']).to.equal(orders[0].isBid)
      expect(data_['size']).to.equal(orders[0].size)
      expect(data_['price']).to.equal((orders[0].price * 1000).toString()) // 3dp
    });

    it("-ve should get order details (id doesn't exist)", async () => {
      const orderId = 'orderId1234567890'
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Order-Details" },
          { name: "OrderId", value: orderId },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Details-Error")
      expect(data_).to.equal(orderId)
    });
    
    it("+ve should get order price (id exists)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Order-Price" },
          { name: "OrderId", value: orderIds[0] },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Price")
      expect(data_).to.equal((orders[0].price * 1000).toString()) // 3dp
    });

    it("-ve should get order price (id doesn't exist)", async () => {
      const orderId = 'orderId1234567890'
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Order-Price" },
          { name: "OrderId", value: orderId },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Price-Error")
      expect(data_).to.equal(orderId)
    });

    it("+ve should check order validity (valid)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Check-Order-Validity" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(orders[0]),
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const isValid_ = Messages[0].Tags.find(t => t.name === 'IsValid').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Validity")
      expect(isValid_).to.equal("true")
      expect(data_).to.equal("Order is valid")
    });

    it("+ve should check order validity (invalid isBid)", async () => {
      let messageId;
      let order = {
        'isBid' : false, 
        'size' : 5, 
        'price' : 90
      }
      order.isBid = 'foo'

      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Check-Order-Validity" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const isValid_ = Messages[0].Tags.find(t => t.name === 'IsValid').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Validity")
      expect(isValid_).to.equal("false")
      expect(data_).to.equal("Invalid isBid")
    });

    it("+ve should check order validity (invalid size)", async () => {
      let messageId;
      let order = {
        'isBid' : false, 
        'size' : 5, 
        'price' : 90
      }
      order.size = 'foo'

      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Check-Order-Validity" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const isValid_ = Messages[0].Tags.find(t => t.name === 'IsValid').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Validity")
      expect(isValid_).to.equal("false")
      expect(data_).to.equal("Invalid size")
    });

    it("+ve should check order validity (invalid price)", async () => {
      let messageId;
      let order = {
        'isBid' : false, 
        'size' : 5, 
        'price' : 90
      }
      order.price = 'foo'

      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Check-Order-Validity" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const isValid_ = Messages[0].Tags.find(t => t.name === 'IsValid').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Validity")
      expect(isValid_).to.equal("false")
      expect(data_).to.equal("Invalid price")
    });

    it("+ve should check order validity (invalid order id)", async () => {
      let messageId;
      let order = {
        'isBid' : false, 
        'size' : 0, 
        'price' : 90
      }
      order.size = 'foo'

      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Check-Order-Validity" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const isValid_ = Messages[0].Tags.find(t => t.name === 'IsValid').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Order-Validity")
      expect(isValid_).to.equal("false")
      expect(data_).to.equal("Invalid size")
    });
  });

  /************************************************************************ 
  * Price Benchmarking & Risk Functions
  ************************************************************************/
  describe("Price Benchmarking & Risk Functions", function () {
    const orders = [
      {
        'isBid' : false, 
        'size' : 5, 
        'price' : 90
      },
      {
        'isBid' : true, 
        'size' : 30, 
        'price' : 88
      }
    ]

    const moreOrders = [
      {
        'isBid' : false, 
        'size' : 5, 
        'price' : 96
      },
      {
        'isBid' : true, 
        'size' : 60, 
        'price' : 22
      }
    ]

    const reverseOrders = [
      {
        'isBid' : false, 
        'size' : 30, 
        'price' : 88
      },
      {
        'isBid' : false, 
        'size' : 60, 
        'price' : 22
      },
      {
        'isBid' : true, 
        'size' : 5, 
        'price' : 90
      },
      {
        'isBid' : true, 
        'size' : 5, 
        'price' : 96
      }
      

    ]

    it("+ve [metrics] should retrieve orderbook metrics (before testing risk)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('88000')
      expect(data_.bestAsk).to.equal('90000')
      expect(Number(data_.spread)).to.equal(2000)
      expect(Number(data_.midPrice)).to.equal(89000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(3090)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(2640)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(450)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(1) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(1) // priceLevels
      expect(orderBookAsks['90000']).to.equal(5)
      expect(orderBookBids['88000']).to.equal(30)
    });

    it("+ve should calculate VWAP", async () => {let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-VWAP" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const vwap = data_
      const asksVwap = vwap.asks
      const bidsVwap = vwap.bids

      expect(action_).to.equal("VWAP")
      expect(asksVwap).to.equal(orders[0].price * 1000)
      expect(bidsVwap).to.equal(orders[1].price * 1000)
    });

    it("+ve should calculate bid exposure", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Bid-Exposure" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Bid-Exposure")
      expect(data_).to.equal(orders[1].price * 1000 * orders[1].size)
    });

    it("+ve should calculate ask exposure", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Ask-Exposure" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Ask-Exposure")
      expect(data_).to.equal(orders[0].price * 1000 * orders[0].size)
    });

    it("+ve should calculate net exposure", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Net-Exposure" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = Messages[0].Data

      expect(action_).to.equal("Net-Exposure")
      expect(data_).to.equal(orders[1].price * 1000 * orders[1].size - orders[0].price * 1000 * orders[0].size)
    });

    it("+ve should get risk metrics (w/ orders)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Risk-Metrics" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const vwap = data_.vwap
      const asksVwap = vwap.asks
      const bidsVwap = vwap.bids
      const askExposure = data_.exposure.ask
      const bidExposure = data_.exposure.bid
      const netExposure = data_.exposure.net

      expect(action_).to.equal("Risk-Metrics")
      expect(asksVwap).to.equal(orders[0].price * 1000)
      expect(bidsVwap).to.equal(orders[1].price * 1000)
      expect(askExposure).to.equal(orders[0].price * 1000 * orders[0].size)
      expect(bidExposure).to.equal(orders[1].price * 1000 * orders[1].size)
      expect(netExposure).to.equal(bidExposure - askExposure)
    });

    it("+ve [process] should add moreOrders (to check VWAP)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Process-Orders" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(moreOrders),
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: dlob,
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
      expect(orderSizes_[0]).to.equal(moreOrders[0].size)
      expect(orderSizes_[1]).to.equal(moreOrders[1].size)
      expect(executedTradesList_.length).to.equal(2)
      expect(executedTradesList_[0].length).to.equal(0)
      expect(executedTradesList_[1].length).to.equal(0)
    })

    it("+ve [metrics] should retrieve orderbook metrics (after moreOrders)", async () => {
      let messageId;
      await message({
        process: dlob,
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
        process: dlob,
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
          orderBookBids[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookBids[priceLevel.price] += priceLevel.levelSize
        }
      }

      for (let i = 0; i < priceLevelsAsks.length; i++) {
        let priceLevel = priceLevelsAsks[i]
        if (orderBookAsks[priceLevel.price] === undefined) {
          orderBookAsks[priceLevel.price] = priceLevel.levelSize
        } else {
          orderBookAsks[priceLevel.price] += priceLevel.levelSize
        }
      }

      // ORDER is ask of 5 shares at 96.500
      // TRADE matches bids of 3 and 5 shares at 98.000 and 97.000, respectively

      expect(action_).to.equal("Order-Book-Metrics")
      expect(data_.bestBid).to.equal('88000')
      expect(data_.bestAsk).to.equal('90000')
      expect(Number(data_.spread)).to.equal(2000)
      expect(Number(data_.midPrice)).to.equal(89000)
      expect(JSON.parse(data_.totalLiquidity)['total']).to.equal(4890)
      expect(JSON.parse(data_.totalLiquidity)['bids']).to.equal(3960)
      expect(JSON.parse(data_.totalLiquidity)['asks']).to.equal(930)
      expect(JSON.parse(data_.marketDepth)['bids'].length).to.equal(2) // priceLevels
      expect(JSON.parse(data_.marketDepth)['asks'].length).to.equal(2) // priceLevels
      expect(orderBookAsks['96000']).to.equal(5)
      expect(orderBookAsks['90000']).to.equal(5)
      expect(orderBookBids['88000']).to.equal(30)
      expect(orderBookBids['22000']).to.equal(60)
    });

    it("+ve should get risk metrics (w/ more orders)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Risk-Metrics" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const vwap = data_.vwap
      const asksVwap = vwap.asks
      const bidsVwap = vwap.bids
      const askExposure = data_.exposure.ask
      const bidExposure = data_.exposure.bid
      const netExposure = data_.exposure.net

      expect(action_).to.equal("Risk-Metrics")
      expect(asksVwap).to.equal(1000 * ((orders[0].price * orders[0].size) + (moreOrders[0].price * moreOrders[0].size)) / ( orders[0].size + moreOrders[0].size))
      expect(bidsVwap).to.equal(1000 * ((orders[1].price * orders[1].size) + (moreOrders[1].price * moreOrders[1].size)) / ( orders[1].size + moreOrders[1].size))
      expect(askExposure).to.equal((orders[0].price * 1000 * orders[0].size) + (moreOrders[0].price * 1000 * moreOrders[0].size))
      expect(bidExposure).to.equal((orders[1].price * 1000 * orders[1].size) + (moreOrders[1].price * 1000 * moreOrders[1].size))
      expect(netExposure).to.equal(bidExposure - askExposure)
    });

    it("+ve [process] should add reverseOrders (to remove all orders)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Process-Orders" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify(reverseOrders),
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: dlob,
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
      expect(successes_.length).to.equal(4)
      expect(successes_[0]).to.equal(true)
      expect(successes_[1]).to.equal(true)
      expect(successes_[2]).to.equal(true)
      expect(successes_[3]).to.equal(true)
      expect(orderIds_.length).to.equal(4)
      expect(orderIds_[0]).to.not.equal('')
      expect(orderIds_[1]).to.not.equal('')
      expect(orderIds_[2]).to.not.equal('')
      expect(orderIds_[3]).to.not.equal('')
      expect(orderSizes_.length).to.equal(4)
      expect(orderSizes_[0]).to.equal(0)
      expect(orderSizes_[1]).to.equal(0)
      expect(orderSizes_[2]).to.equal(0)
      expect(orderSizes_[3]).to.equal(0)
      expect(executedTradesList_.length).to.equal(4)
      expect(executedTradesList_[0].length).to.not.equal(0)
      expect(executedTradesList_[1].length).to.not.equal(0)
      expect(executedTradesList_[2].length).to.not.equal(0)
      expect(executedTradesList_[3].length).to.not.equal(0)
    })
    
    it("+ve should risk metrics with zero exposures (w/o orders)", async () => {
      let messageId;
      await message({
        process: dlob,
        tags: [
          { name: "Action", value: "Get-Risk-Metrics" },
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
        process: dlob,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const data_ = JSON.parse(Messages[0].Data)

      const vwap = data_.vwap
      const asksVwap = vwap.asks
      const bidsVwap = vwap.bids
      const askExposure = data_.exposure.ask
      const bidExposure = data_.exposure.bid
      const netExposure = data_.exposure.net

      expect(action_).to.equal("Risk-Metrics")
      expect(asksVwap).to.equal(0)
      expect(bidsVwap).to.equal(0)
      expect(askExposure).to.equal(0)
      expect(bidExposure).to.equal(0)
      expect(netExposure).to.equal(0)
    });
  });
})