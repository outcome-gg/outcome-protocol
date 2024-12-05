import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances } from "./utils.js";
import { expect, use } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { assert, error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'
import exp from "constants";

dotenv.config();

const market = process.env.TEST_MARKET4;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN3;
const configurator = process.env.TEST_CONFIGURATOR;

console.log("MARKET: ", market)
console.log("COLLATERAL TOKEN: ", collateralToken)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

// Txn execution variables
let wallet;
let wallet2;
let walletAddress;
let walletAddress2;

// Market variables
let conditionId
let marketId;
let questionId;
let resolutionAgent;

// Configurator variables
let delay;

// Update protocol fee target variables
let updateProtocolFeeTargetProcess;
let updateProtocolFeeTargetAction;
let updateProtocolFeeTargetTagName;
let updateProtocolFeeTargetTagValue;
let hashUpdateProtocolFeeTarget;


let hashUpdateConfigurator;
let hashUpdateIncentives;
let hashUpdateTakeFee;
let hashUpdateLogo;

/* 
* Tests
*/
describe("market.configurator.test", function () {
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

    // Market variables
    questionId = 'trump-becomes-the-47th-president-of-the-usa',
    resolutionAgent = walletAddress2,
    conditionId = "2d175f731624549c34fe14840990e92d610d63ea205028af076ec5cbef4e231c",
    marketId = "123",

    // Configurator variables
    delay = 5000,

    // Update protocol fee target variables
    updateProtocolFeeTargetProcess = market,
    updateProtocolFeeTargetAction = "Update-Protocol-Fee-Target",
    updateProtocolFeeTargetTagName = "ProtocolFeeTarget",
    updateProtocolFeeTargetTagValue = "BAR",
    hashUpdateProtocolFeeTarget = keccak256(updateProtocolFeeTargetProcess + updateProtocolFeeTargetAction + updateProtocolFeeTargetTagName + updateProtocolFeeTargetTagValue).toString('hex')
  ))

  /************************************************************************ 
  * market.Init
  ************************************************************************/
  describe("market.Init", function () {
    it("+ve should fail to init market when take fee > 10%", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Init" },
          { name: "MarketId", value: marketId },
          { name: "CollateralToken", value: collateralToken },
          { name: "ConditionId", value: conditionId },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Name", value: "Outcome ETH LP Token" }, 
          { name: "Ticker", value: "OETH" }, 
          { name: "Logo", value: "" }, 
          { name: "LpFee", value: "100" }, 
          { name: "CreatorFee", value: "250" }, // 2.5%
          { name: "CreatorFeeTarget", value: walletAddress2 }, 
          { name: "ProtocolFee", value: "751" }, // 7.51% 
          { name: "ProtocolFeeTarget", value: walletAddress2 }, 
          { name: "Configurator", value: walletAddress2 }, 
          { name: "Incentives", value: walletAddress2 }, 
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
        process: market,
      });

      // aoconnect Error not capturing the error message
      // but present in the AOS process logs
      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Take Fee capped at 10%!")
    })

    it("+ve should init market", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Init" },
          { name: "MarketId", value: marketId },
          { name: "ConditionId", value: conditionId },
          { name: "CollateralToken", value: collateralToken },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Name", value: "Outcome ETH LP Token 2" }, 
          { name: "Ticker", value: "OETH-LP-2" }, 
          { name: "Logo", value: "" }, 
          { name: "LpFee", value: "100" }, 
          { name: "CreatorFee", value: "250" }, // 2.5%
          { name: "CreatorFeeTarget", value: walletAddress2 }, 
          { name: "ProtocolFee", value: "250" }, 
          { name: "ProtocolFeeTarget", value: walletAddress2 }, 
          { name: "Configurator", value: walletAddress2 }, 
          { name: "Incentives", value: walletAddress2 }, 
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_0 = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const outcomeSlotCount_0 = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

      expect(action_0).to.equal("Condition-Preparation-Notice")
      expect(conditionId_0).to.equal(conditionId)
      expect(outcomeSlotCount_0).to.equal('2')

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const conditionId_1 = Messages[1].Tags.find(t => t.name === 'ConditionId').value
      const collateralToken_1 = Messages[1].Tags.find(t => t.name === 'CollateralToken').value
      const positionIds_1 = Messages[1].Tags.find(t => t.name === 'PositionIds').value
      const name_1 = Messages[1].Tags.find(t => t.name === 'Name').value
      const ticker_1 = Messages[1].Tags.find(t => t.name === 'Ticker').value
      const logo_1 = Messages[1].Tags.find(t => t.name === 'Logo').value
      const configurator_1 = Messages[1].Tags.find(t => t.name === 'Configurator').value
      const lpFee_1 = Messages[1].Tags.find(t => t.name === 'LpFee').value
      const creatorFee_1 = Messages[1].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget_1 = Messages[1].Tags.find(t => t.name === 'CreatorFeeTarget').value
      const protocolFee_1 = Messages[1].Tags.find(t => t.name === 'ProtocolFee').value
      const protocolFeeTarget_1 = Messages[1].Tags.find(t => t.name === 'ProtocolFeeTarget').value

      expect(Messages[1].Data).to.be.equal('Successfully created market')
      expect(action_1).to.equal("New-Market-Notice")
      expect(conditionId_1).to.equal(conditionId)
      expect(collateralToken_1).to.equal(collateralToken)
      expect(positionIds_1).to.equal(JSON.stringify(["1", "2"]))
      expect(name_1).to.equal("Outcome ETH LP Token 2")
      expect(ticker_1).to.equal("OETH-LP-2")
      expect(logo_1).to.equal("")
      expect(configurator_1).to.equal(walletAddress2)
      expect(lpFee_1).to.equal("100")
      expect(creatorFee_1).to.equal("250")
      expect(creatorFeeTarget_1).to.equal(walletAddress2)
      expect(protocolFee_1).to.equal("250")
      expect(protocolFeeTarget_1).to.equal(walletAddress2)
    })

    it("+ve should fail to init market after initialized", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Init" },
          { name: "MarketId", value: marketId },
          { name: "CollateralToken", value: collateralToken },
          { name: "ConditionId", value: conditionId },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Name", value: "Outcome ETH LP Token" }, 
          { name: "Ticker", value: "OETH" }, 
          { name: "Logo", value: "" }, 
          { name: "LpFee", value: "100" }, 
          { name: "CreatorFee", value: "250" }, // 2.5%
          { name: "CreatorFeeTarget", value: walletAddress }, 
          { name: "ProtocolFee", value: "250" }, 
          { name: "ProtocolFeeTarget", value: walletAddress2 }, 
          { name: "Configurator", value: walletAddress2 }, 
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
        process: market,
      });

      // aoconnect Error not capturing the error message
      // but present in the AOS process logs
      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Market already initialized!")
    })
  })

  /************************************************************************ 
  * market.Info
  ************************************************************************/
  describe("market.Info", function () {
    it("+ve should get info", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
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
      const lpFee_ = Messages[0].Tags.find(t => t.name === 'LpFee').value
      const lpFeePoolWeight_ = Messages[0].Tags.find(t => t.name === 'LpFeePoolWeight').value
      const lpFeeTotalWithdrawn_ = Messages[0].Tags.find(t => t.name === 'LpFeeTotalWithdrawn').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget_ = Messages[0].Tags.find(t => t.name === 'CreatorFeeTarget').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value
      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value
      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value

      expect(name_).to.equal("Outcome ETH LP Token 2")
      expect(ticker_).to.equal("OETH-LP-2")
      expect(logo_).to.equal("")
      expect(denomination_).to.equal("12")
      expect(conditionId_).to.equal(conditionId)
      expect(collateralToken_).to.equal(collateralToken)
      expect(lpFeePoolWeight_).to.equal("0")
      expect(lpFeeTotalWithdrawn_).to.equal("0")
      expect(lpFee_).to.equal("100") // 100bps, 1%
      expect(configurator_).to.equal(walletAddress2)
      expect(creatorFee_).to.equal("250") // 250bps, 2.5%
      expect(creatorFeeTarget_).to.equal(walletAddress2)
      expect(protocolFee_).to.equal("250") // 250bps, 2.5%
      expect(protocolFeeTarget_).to.equal(walletAddress2)
    })
  })

  /************************************************************************ 
  * market.Update-Market.Incentives
  ************************************************************************/
  describe("market.Update-Market.Incentives", function () {
    it("-ve should fail to update incentives (not configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Incentives" },
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
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update incentives (missing Incentives tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Incentives" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Incentives is required!")
    })

    it("+ve should update incentives", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Incentives" },
          { name: "Incentives", value: "FOO" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const protocolFeeTarget_ = Messages[0].Data
      
      expect(action_).to.equal("Incentives-Updated")
      expect(protocolFeeTarget_).to.equal("FOO")
    })

    it("+ve should get info (updated incentives)", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const incentives_ = Messages[0].Tags.find(t => t.name === 'Incentives').value

      expect(incentives_).to.equal("FOO")
    })
  })

  /************************************************************************ 
  * market.Update-Market.TakeFee
  ************************************************************************/
  describe("market.Update-Market.TakeFee", function () {
    it("-ve should fail to update takeFee (not configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Take-Fee" },
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
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update takeFee (missing CreatorFee tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Take-Fee" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("CreatorFee is required!")
    })

    it("-ve should fail to update takeFee (missing ProtocolFee tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Take-Fee" },
          { name: "CreatorFee", value: "123" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("ProtocolFee is required!")
    })

    it("+ve should update incentives", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Take-Fee" },
          { name: "CreatorFee", value: "123" },
          { name: "ProtocolFee", value: "456" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value
      const takeFee_ = Messages[0].Data
      
      expect(action_).to.equal("Take-Fee-Updated")
      expect(creatorFee_).to.equal("123")
      expect(protocolFee_).to.equal("456")
      expect(takeFee_).to.equal(123+456)
    })

    it("+ve should get info (updated takeFee)", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value

      expect(creatorFee_).to.equal("123")
      expect(protocolFee_).to.equal("456")
    })
  })

  /************************************************************************ 
  * market.Update-Market.Protocol-Fee-Target
  ************************************************************************/
  describe("market.Update-Market.Protocol-Fee-Target", function () {
    it("-ve should fail to update protocolFeeTarget (not configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Protocol-Fee-Target" },
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
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update protocolFeeTarget (missing ProtocolFeeTarget tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Protocol-Fee-Target" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("ProtocolFeeTarget is required!")
    })

    it("+ve should update protocolFeeTarget", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Protocol-Fee-Target" },
          { name: "ProtocolFeeTarget", value: "FOO" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const protocolFeeTarget_ = Messages[0].Data
      
      expect(action_).to.equal("Protocol-Fee-Target-Updated")
      expect(protocolFeeTarget_).to.equal("FOO")
    })

    it("+ve should get info (updated protocolFeeTarget)", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value

      expect(protocolFeeTarget_).to.equal("FOO")
    })
  })

  /************************************************************************ 
  * market.Update-Market.Logo
  ************************************************************************/
  describe("market.Update-Market.Logo", function () {
    it("-ve should fail to update logo (not configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Logo" },
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
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update logo (missing Logo tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Logo" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Logo is required!")
    })

    it("+ve should update logo", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Logo" },
          { name: "Logo", value: "FOO" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const logo_ = Messages[0].Data
      
      expect(action_).to.equal("Logo-Updated")
      expect(logo_).to.equal("FOO")
    })

    it("+ve should get info (updated logo)", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value

      expect(logo_).to.equal("FOO")
    })
  })

  /************************************************************************ 
  * market.Update-Market.Configurator
  ************************************************************************/
  describe("market.Update-Market.Configurator", function () {
    it("-ve should fail to update configurator (not configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Configurator" },
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
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update configurator (missing Configurator tag)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Configurator" },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Configurator is required!")
    })

    it("+ve should update configurator", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Configurator" },
          { name: "Configurator", value: configurator },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const configurator_ = Messages[0].Data
      
      expect(action_).to.equal("Configurator-Updated")
      expect(configurator_).to.equal(configurator)
    })

    it("+ve should get info (updated configurator)", async () => {
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value

      expect(configurator_).to.equal(configurator)
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.Protocol-Fee-Target
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.Protocol-Fee-Target", function () {
    it("+ve should stage update (update protocolFeeTarget)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProtocolFeeTargetProcess },
          { name: "UpdateAction", value:  updateProtocolFeeTargetAction },
          { name: "UpdateTagName", value: updateProtocolFeeTargetTagName },
          { name: "UpdateTagValue", value: updateProtocolFeeTargetTagValue },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Update-Staged")
      expect(hash_).to.equal(hashUpdateProtocolFeeTarget)
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProtocolFeeTargetProcess },
          { name: "UpdateAction", value:  updateProtocolFeeTargetAction },
          { name: "UpdateTagName", value: updateProtocolFeeTargetTagName },
          { name: "UpdateTagValue", value: updateProtocolFeeTargetTagValue },
        ],
        signer: createDataItemSigner(wallet2),
        data: "",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tagValue_0 = Messages[0].Tags.find(t => t.name === updateProtocolFeeTargetTagName).value

      expect(target_0).to.equal(updateProtocolFeeTargetProcess)
      expect(action_0).to.equal(updateProtocolFeeTargetAction)
      expect(tagValue_0).to.equal(updateProtocolFeeTargetTagValue)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateProtocolFeeTarget)
    })

    it("+ve should get info (updated configurator)", async () => {
      await new Promise(r => setTimeout(r, delay));
      let messageId;
      await message({
        process: market,
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
        process: market,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value

      expect(protocolFeeTarget_).to.equal(updateProtocolFeeTargetTagValue)
    })
  })
})