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
import { hash } from "crypto";

dotenv.config();

const market = process.env.MOCK_SPAWNED_MARKET5;
const collateralToken = process.env.DEV_MOCK_DAI;
const testConfigurator = process.env.TEST_CONFIGURATOR;

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
let configurator;
let delay;

// update variables
let updateProcess = market;

// Update incentives variables
let updateIncentivesAction;
let updateIncentivesTags;
let updateIncentivesData;
let hashUpdateIncentives;

// Update take fee variables
let updateTakeFeeAction;
let updateTakeFeeTags;
let updateTakeFeeData;
let hashUpdateTakeFee;

// Update protocol fee target variables
let updateProtocolFeeTargetAction;
let updateProtocolFeeTargetTags;
let updateProtocolFeeTargetData;
let hashUpdateProtocolFeeTarget;

// Update logo variables
let updateLogoAction;
let updateLogoTags;
let updateLogoData;
let hashUpdateLogo;

// Update configurator variables
let updateConfiguratorAction;
let updateConfiguratorTags;
let updateConfiguratorData;
let hashUpdateConfigurator;


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
    marketId = "123",

    // Configurator variables
    configurator = walletAddress,
    delay = 5000,

    // Update variables
    updateProcess = market,

    // Update incentives variables
    updateIncentivesAction = "Update-Incentives",
    updateIncentivesTags = JSON.stringify({"Incentives" : "test-this-is-valid-arweave-wallet-address-1"}),
    updateIncentivesData = "",
    hashUpdateIncentives = keccak256(updateProcess + updateIncentivesAction + updateIncentivesTags + updateIncentivesData).toString('hex'),

    // Update take fee variables
    updateTakeFeeAction = "Update-Take-Fee",
    updateTakeFeeTags = JSON.stringify({"CreatorFee" : "123", "ProtocolFee" : "456"}),
    updateTakeFeeData = "",
    hashUpdateTakeFee = keccak256(updateProcess + updateTakeFeeAction + updateTakeFeeTags + updateTakeFeeData).toString('hex'),

    // Update protocol fee target variables
    updateProtocolFeeTargetAction = "Update-Protocol-Fee-Target",
    updateProtocolFeeTargetTags = JSON.stringify({"ProtocolFeeTarget" : "test-this-is-valid-arweave-wallet-address-1"}),
    updateProtocolFeeTargetData = "",
    hashUpdateProtocolFeeTarget = keccak256(updateProcess + updateProtocolFeeTargetAction + updateProtocolFeeTargetTags + updateProtocolFeeTargetData).toString('hex'),

    // Update logo variables
    updateLogoAction = "Update-Logo",
    updateLogoTags = JSON.stringify({"Logo" : "FOO"}),
    updateLogoData = "",
    hashUpdateLogo = keccak256(updateProcess + updateLogoAction + updateLogoTags + updateLogoData).toString('hex'),

    // Update configurator variables
    updateConfiguratorAction = "Update-Configurator",
    updateConfiguratorTags = JSON.stringify({"Configurator" : "test-this-is-valid-arweave-wallet-address-1"}),
    updateConfiguratorData = "",
    hashUpdateConfigurator = keccak256(updateProcess + updateConfiguratorAction + updateConfiguratorTags + updateConfiguratorData).toString('hex')
  ))

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

      expect(Messages.length).to.equal(1)

      const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
      const denomination_ = Messages[0].Tags.find(t => t.name === 'Denomination').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const lpFee_ = Messages[0].Tags.find(t => t.name === 'LpFee').value
      const lpFeePoolWeight_ = Messages[0].Tags.find(t => t.name === 'LpFeePoolWeight').value
      const lpFeeTotalWithdrawn_ = Messages[0].Tags.find(t => t.name === 'LpFeeTotalWithdrawn').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget_ = Messages[0].Tags.find(t => t.name === 'CreatorFeeTarget').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value
      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value
      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value

      expect(name_.startsWith("MOCK_SPAWNED_MARKET")).to.equal(true)
      expect(ticker_.startsWith("MSM")).to.equal(true)
      expect(logo_).to.equal("https://test.com/logo.png")
      expect(denomination_).to.equal("12")
      expect(collateralToken_).to.equal(collateralToken)
      expect(lpFeePoolWeight_).to.equal("0")
      expect(lpFeeTotalWithdrawn_).to.equal("0")
      expect(lpFee_).to.equal("100") // 100bps, 1%
      expect(configurator_).to.equal(configurator)
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
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update incentives (missing Incentives tag)", async () => {
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
      expect(Error).to.include("Incentives is required!")
    })

    it("+ve should update incentives", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Incentives" },
          { name: "Incentives", value: "test-this-is-valid-arweave-wallet-address-1" },
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const protocolFeeTarget_ = Messages[0].Data
      
      expect(action_).to.equal("Incentives-Updated")
      expect(protocolFeeTarget_).to.equal("test-this-is-valid-arweave-wallet-address-1")
    })

    it("+ve should get info (updated incentives)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const incentives_ = Messages[0].Tags.find(t => t.name === 'Incentives').value

      expect(incentives_).to.equal("test-this-is-valid-arweave-wallet-address-1")
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
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update takeFee (missing CreatorFee tag)", async () => {
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value
      const takeFee_ = Messages[0].Data
      
      expect(action_).to.equal("Take-Fee-Updated")
      expect(creatorFee_).to.equal("123")
      expect(protocolFee_).to.equal("456")
      expect(takeFee_).to.equal((123+456).toString())
    })

    it("+ve should get info (updated takeFee)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update protocolFeeTarget (missing ProtocolFeeTarget tag)", async () => {
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
      expect(Error).to.include("ProtocolFeeTarget is required!")
    })

    it("+ve should update protocolFeeTarget", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Protocol-Fee-Target" },
          { name: "ProtocolFeeTarget", value: "test-this-is-valid-arweave-wallet-address-1" },
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const protocolFeeTarget_ = Messages[0].Data
      
      expect(action_).to.equal("Protocol-Fee-Target-Updated")
      expect(protocolFeeTarget_).to.equal("test-this-is-valid-arweave-wallet-address-1")
    })

    it("+ve should get info (updated protocolFeeTarget)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const protocolFeeTarget_ = Messages[0].Tags.find(t => t.name === 'ProtocolFeeTarget').value

      expect(protocolFeeTarget_).to.equal("test-this-is-valid-arweave-wallet-address-1")
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
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update logo (missing Logo tag)", async () => {
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
      expect(Error).to.include("Sender must be configurator!")
    })

    it("-ve should fail to update configurator (missing Configurator tag)", async () => {
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
      expect(Error).to.include("Configurator is required!")
    })

    it("+ve should update configurator", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Update-Configurator" },
          { name: "Configurator", value: testConfigurator },
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

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const configurator_ = Messages[0].Data
      
      expect(action_).to.equal("Configurator-Updated")
      expect(configurator_).to.equal(testConfigurator)
    })

    it("+ve should get info (updated configurator)", async () => {
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value

      expect(configurator_).to.equal(testConfigurator)
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.Incentives
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.Incentives", function () {
    it("+ve should stage update (update incentives)", async () => {
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateIncentivesAction },
          { name: "UpdateTags", value: updateIncentivesTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Update-Staged")
      expect(hash_).to.equal(hashUpdateIncentives)
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateIncentivesAction },
          { name: "UpdateTags", value: updateIncentivesTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tag_0 = Messages[0].Tags.find(t => t.name === "Incentives").value

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateIncentivesAction)
      expect(tag_0).to.equal("test-this-is-valid-arweave-wallet-address-1")

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateIncentives)
    })

    it("+ve should get info (updated incentives)", async () => {
      await new Promise(r => setTimeout(r, delay));
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const incentives_ = Messages[0].Tags.find(t => t.name === 'Incentives').value

      expect(incentives_).to.equal("test-this-is-valid-arweave-wallet-address-1")
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.TakeFee
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.TakeFee", function () {
    it("+ve should stage update (update takeFee)", async () => {
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateTakeFeeAction },
          { name: "UpdateTags", value: updateTakeFeeTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Update-Staged")
      expect(hash_).to.equal(hashUpdateTakeFee)
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateTakeFeeAction },
          { name: "UpdateTags", value: updateTakeFeeTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tag1_0 = Messages[0].Tags.find(t => t.name === "CreatorFee").value
      const tag2_0 = Messages[0].Tags.find(t => t.name === "ProtocolFee").value

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateTakeFeeAction)
      expect(tag1_0).to.equal("123")
      expect(tag2_0).to.equal("456")

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateTakeFee)
    })

    it("+ve should get info (updated creator + protocol fees)", async () => {
      await new Promise(r => setTimeout(r, delay));
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const creatorFee_ = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const protocolFee_ = Messages[0].Tags.find(t => t.name === 'ProtocolFee').value

      expect(creatorFee_).to.equal("123")
      expect(protocolFee_).to.equal("456")
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.Protocol-Fee-Target
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.Protocol-Fee-Target", function () {
    it("+ve should stage update (update protocolFeeTarget)", async () => {
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateProtocolFeeTargetAction },
          { name: "UpdateTags", value: updateProtocolFeeTargetTags },
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
        process: testConfigurator,
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
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateProtocolFeeTargetAction },
          { name: "UpdateTags", value: updateProtocolFeeTargetTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tag_0 = Messages[0].Tags.find(t => t.name === "ProtocolFeeTarget").value

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateProtocolFeeTargetAction)
      expect(tag_0).to.equal("test-this-is-valid-arweave-wallet-address-1")

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateProtocolFeeTarget)
    })

    it("+ve should get info (updated protocol fee target)", async () => {
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

      expect(protocolFeeTarget_).to.equal("test-this-is-valid-arweave-wallet-address-1")
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.Logo
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.Logo", function () {
    it("+ve should stage update (update logo)", async () => {
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateLogoAction },
          { name: "UpdateTags", value: updateLogoTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Update-Staged")
      expect(hash_).to.equal(hashUpdateLogo)
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateLogoAction },
          { name: "UpdateTags", value: updateLogoTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tag_0 = Messages[0].Tags.find(t => t.name === "Logo").value

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateLogoAction)
      expect(tag_0).to.equal("FOO")

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateLogo)
    })

    it("+ve should get info (updated logo)", async () => {
      await new Promise(r => setTimeout(r, delay));
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value

      expect(logo_).to.equal("FOO")
    })
  })

  /************************************************************************ 
  * market.Update-Market-Via-Configurator.Configurator
  ************************************************************************/
  describe("market.Update-Market-Via-Configurator.Configurator", function () {
    it("+ve should stage update (update configurator)", async () => {
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateConfiguratorAction },
          { name: "UpdateTags", value: updateConfiguratorTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Update-Staged")
      expect(hash_).to.equal(hashUpdateConfigurator)
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: testConfigurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value:  updateConfiguratorAction },
          { name: "UpdateTags", value: updateConfiguratorTags },
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
        process: testConfigurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      
      const tag_0 = Messages[0].Tags.find(t => t.name === "Configurator").value

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateConfiguratorAction)
      expect(tag_0).to.equal("test-this-is-valid-arweave-wallet-address-1")

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Update-Actioned")
      expect(hash_1).to.equal(hashUpdateConfigurator)
    })

    it("+ve should get info (updated configurator)", async () => {
      await new Promise(r => setTimeout(r, delay));
      let messageId;
      await message({
        process: market,
        tags: [
          { name: "Action", value: "Info" },
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

      const configurator_ = Messages[0].Tags.find(t => t.name === 'Configurator').value

      expect(configurator_).to.equal("test-this-is-valid-arweave-wallet-address-1")
    })
  })

})