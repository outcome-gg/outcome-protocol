import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect, use } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'
import exp from "constants";

dotenv.config();

const cpmm = process.env.TEST_MARKET3;
const collateralToken = process.env.TEST_COLLATERAL_TOKEN3;
const conditionalTokens = process.env.TEST_MARKET3;

console.log("CPMM: ", cpmm)
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

let marketId;

/* 
* Tests
*/
describe("cpmm.integration.test", function () {
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
    positionIdIN = "35ba13152a8b2086a40393fb611dae5c74a8ada28a80effda1e58381b9edc2f4",
    positionIdOUT = "b52a990678dd524169490cfaa7300fc1c58bc3f06e0bd252e837cda920b93101",

    marketId = "123"
  ))

  /************************************************************************ 
  * cpmm.Init
  ************************************************************************/
  describe("cpmm.Init", function () {
    it("+ve should init cpmm", async () => {
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Init" },
          { name: "MarketId", value: marketId },
          { name: "ConditionId", value: conditionId },
          { name: "CollateralToken", value: collateralToken },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Name", value: "Outcome ETH LP Token 2" }, 
          { name: "Ticker", value: "OETH-LP-2" }, 
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
        process: cpmm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      expect(Messages[0].Data).to.be.equal('Successfully created market')

      const action_1 = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_1 = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const collateralToken_1 = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const positionIds_1 = Messages[0].Tags.find(t => t.name === 'PositionIds').value
      const name_1 = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_1 = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const logo_1 = Messages[0].Tags.find(t => t.name === 'Logo').value

      const action_0 = Messages[1].Tags.find(t => t.name === 'Action').value
      const conditionId_0 = Messages[1].Tags.find(t => t.name === 'ConditionId').value
      const outcomeSlotCount_0 = Messages[1].Tags.find(t => t.name === 'OutcomeSlotCount').value

      expect(action_1).to.equal("New-Market-Notice")
      expect(conditionId_1).to.equal(conditionId)
      expect(collateralToken_1).to.equal(collateralToken)
      expect(positionIds_1).to.equal(JSON.stringify([1, 2]))
      expect(name_1).to.equal("Outcome ETH LP Token 2")
      expect(ticker_1).to.equal("OETH-LP-2")
      expect(logo_1).to.equal("")

      expect(action_0).to.equal("Condition-Preparation-Notice")
      expect(conditionId_0).to.equal(conditionId)
      expect(outcomeSlotCount_0).to.equal('2')
    })

    it("+ve should fail to init cpmm after initialized", async () => {
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Init" },
          { name: "CollateralToken", value: collateralToken },
          { name: "ConditionId", value: conditionId },
          { name: "Name", value: "Outcome ETH LP Token" }, 
          { name: "Ticker", value: "OETH" }, 
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
        process: cpmm,
      });

      if (Error) {
        console.log(Error)
      }

      // aoconnect Error not capturing the error message
      // but present in the AOS process logs
      expect(Messages.length).to.be.equal(0)
    })
  })

  /************************************************************************ 
  * cpmm.Info
  ************************************************************************/
  describe("cpmm.Info", function () {
    it("+ve should get info", async () => {
      let messageId;
      await message({
        process: cpmm,
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
        process: cpmm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      console.log(Messages[0].Tags)

      const name_ = Messages[0].Tags.find(t => t.name === 'Name').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      const logo_ = Messages[0].Tags.find(t => t.name === 'Logo').value
      const denomination_ = Messages[0].Tags.find(t => t.name === 'Denomination').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const lpFee_ = Messages[0].Tags.find(t => t.name === 'LpFee').value
      const lpFeePoolWeight_ = Messages[0].Tags.find(t => t.name === 'LpFeePoolWeight').value
      const lpFeeTotalWithdrawn_ = Messages[0].Tags.find(t => t.name === 'LpFeeTotalWithdrawn').value
      const takeFee_ = Messages[0].Tags.find(t => t.name === 'TakeFee').value

      expect(name_).to.equal("Outcome ETH LP Token 2")
      expect(ticker_).to.equal("OETH-LP-2")
      expect(logo_).to.equal("")
      expect(denomination_).to.equal("12")
      expect(conditionId_).to.equal(conditionId)
      expect(collateralToken_).to.equal(collateralToken)
      expect(lpFeePoolWeight_).to.equal("0")
      expect(lpFeeTotalWithdrawn_).to.equal("0")
      expect(lpFee_).to.equal("0.01") // 1%
      expect(takeFee_).to.equal("0.025") // 2.5%
    })
  })

  /************************************************************************ 
  * cpmm.Add-Funding
  ************************************************************************/
  describe("cpmm.Add-Funding", function () {
    it("+ve should add initial funding as per distribution", async () => {
      let messageId;
      const quantity = parseAmount(100, 12)
      const xDistribution = JSON.stringify([50, 50])
      const xAction = "Add-Funding"
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: cpmm },
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
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_0 = Messages[0].Tags.find(t => t.name === 'X-Distribution').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_1 = Messages[1].Tags.find(t => t.name === 'X-Distribution').value
      
      expect(action_0).to.equal("Debit-Notice")
      expect(recipient_0).to.equal(cpmm)
      expect(quantity_0).to.equal(quantity)
      expect(xAction_0).to.equal(xAction)
      expect(xDistribution_0).to.equal(xDistribution)

      expect(action_1).to.equal("Credit-Notice")
      expect(sender_1).to.equal(walletAddress)
      expect(quantity_1).to.equal(quantity)
      expect(xAction_1).to.equal(xAction)
      expect(xDistribution_1).to.equal(xDistribution)
    })

    it("+ve should have transferred CollateralTokens to ConditionalTokens as per previous step", async () => {
      // await new Promise(resolve => setTimeout(resolve, 10000));
      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Balance" },
          { name: "Recipient", value: conditionalTokens },
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

      expect(Messages.length).to.be.equal(1)

      const account_ = Messages[0].Tags.find(t => t.name === 'Account').value
      const balance_ = Messages[0].Tags.find(t => t.name === 'Balance').value
      const ticker_ = Messages[0].Tags.find(t => t.name === 'Ticker').value
      
      expect(account_).to.equal(conditionalTokens)
      expect(balance_).to.equal(parseAmount(100, 12))
      expect(ticker_).to.equal("PNTS")
    })

    it("+ve should have minted LP tokens as per previous step's x-action", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000)); // 20000
      let messageId;
      await message({
        process: cpmm,
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
        process: cpmm,
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
      expect(ticker_).to.equal("OETH-LP-2")
    })

    it("+ve should have minted position tokens to cpmm in exchange for the LP tokens", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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

      // Note that now we have sequential positionIds where Ids "1" and "2" are for IN and OUT, indexed 0 and 1, respectively
      expect(balances[0][cpmm]).to.equal(parseAmount(100, 12))
      expect(balances[1][cpmm]).to.equal(parseAmount(100, 12))
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
          { name: "Recipient", value: cpmm },
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
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_0 = Messages[0].Tags.find(t => t.name === 'X-Distribution').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const xDistribution_1 = Messages[1].Tags.find(t => t.name === 'X-Distribution').value
      
      expect(action_0).to.equal("Debit-Notice")
      expect(recipient_0).to.equal(cpmm)
      expect(quantity_0).to.equal(quantity)
      expect(xAction_0).to.equal(xAction)
      expect(xDistribution_0).to.equal(xDistribution)

      expect(action_1).to.equal("Credit-Notice")
      expect(sender_1).to.equal(walletAddress)
      expect(quantity_1).to.equal(quantity)
      expect(xAction_1).to.equal(xAction)
      expect(xDistribution_1).to.equal(xDistribution)
    })

    it("+ve should have minted more LP tokens as per previous step's x-action", async () => {
      await new Promise(resolve => setTimeout(resolve, 1000)); // 20000
      let messageId;
      await message({
        process: cpmm,
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
        process: cpmm,
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
      expect(ticker_).to.equal("OETH-LP-2")
    })

    it("+ve should have minted more position tokens to cpmm in exchange for the LP tokens", async () => {
      // await new Promise(resolve => setTimeout(resolve, 1000)); // 5000
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

      expect(balances[0][cpmm]).to.equal(parseAmount(200, 12))
      expect(balances[1][cpmm]).to.equal(parseAmount(200, 12))
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
            { name: "Recipient", value: cpmm },
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
      await new Promise(resolve => setTimeout(resolve, 1000)); // 10000
      balanceAfter = await getBalance();

      expect(balanceBefore).to.be.equal(balanceAfter)
      expect(balanceBefore).to.not.equal(0)
    })

    it("-ve should fail add negative funding", async () => {
      let messageId;
      const quantity = (-1000000000001).toString()
      const xDistribution = JSON.stringify([])
      const xAction = "Add-Funding"
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: cpmm },
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
  * cpmm.Remove-Funding
  ************************************************************************/
  describe("cpmm.Remove-Funding", function () {
    before(async () => {
      // Add delay to allow for previous test to complete
      // await new Promise(resolve => setTimeout(resolve, 7000));
    })

    it("+ve should remove funding", async () => {
      let messageId;
      let userBalanceBefore;
      let userBalanceAfter;
      let cpmmBalanceBefore;
      let cpmmBalanceAfter;

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
          process: cpmm,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: cpmm },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        return Messages
      }

      userBalanceBefore = await getBalance(cpmm, walletAddress);
      cpmmBalanceBefore = await getBalance(cpmm, cpmm);

      let Messages = await removeFunding();

      await new Promise(resolve => setTimeout(resolve, 2000));

      userBalanceAfter = await getBalance(cpmm, walletAddress);
      cpmmBalanceAfter = await getBalance(cpmm, cpmm);

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const xAction_0 = Messages[0].Tags.find(t => t.name === 'X-Action').value
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value

      // Debits LP tokens from the sender to the cpmm
      expect(action_0).to.equal('Debit-Notice')
      expect(xAction_0).to.equal('Remove-Funding')
      expect(quantity_0).to.equal(quantity)
      expect(recipient_0).to.equal(cpmm)

      // Credits the cpmm with the LP tokens
      expect(action_1).to.equal('Credit-Notice')
      expect(xAction_1).to.equal('Remove-Funding')
      expect(quantity_1).to.equal(quantity)
      expect(sender_1).to.equal(walletAddress)

      // Check balances
      expect(userBalanceBefore).to.equal(parseAmount(200, 12))
      expect(userBalanceAfter).to.equal(parseAmount(150, 12))
      expect(cpmmBalanceBefore).to.equal(parseAmount(0, 12))
      expect(cpmmBalanceAfter).to.equal(parseAmount(0, 12))
    })

    it("+ve should check positions after remove funding", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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
  
      expect(balances[0][cpmm]).to.equal('150000000000000')
      expect(balances[1][cpmm]).to.equal('150000000000000')

      expect(balances[0][walletAddress]).to.equal('50000000000000')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })

    it("-ve should fail to remove funding greater than balance", async () => {
      let messageId;
      let userBalanceBefore;
      let userBalanceAfter;
      let cpmmBalanceBefore;
      let cpmmBalanceAfter;

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
          process: cpmm,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: cpmm },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        return Messages
      }

      userBalanceBefore = await getBalance(cpmm, walletAddress);
      cpmmBalanceBefore = await getBalance(cpmm, cpmm);

      let Messages = await removeFunding();

      userBalanceAfter = await getBalance(cpmm, walletAddress);
      cpmmBalanceAfter = await getBalance(cpmm, cpmm);

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const error_ = Messages[0].Tags.find(t => t.name === 'Error').value

      expect(action_).to.equal('Transfer-Error')
      expect(error_).to.equal('Insufficient Balance!')

      expect(userBalanceBefore).to.equal(parseAmount(150, 12))
      expect(userBalanceAfter).to.equal(parseAmount(150, 12))
      expect(cpmmBalanceBefore).to.equal(parseAmount(0, 12))
      expect(cpmmBalanceAfter).to.equal(parseAmount(0, 12))
    })
  })

  /************************************************************************ 
  * cpmm.Calc-Buy-Amount
  ************************************************************************/
  describe("cpmm.Calc-Buy-Amount", function () {
    it("+ve should calculate buy amount", async () => {
      let messageId;
      const investmentAmount = parseAmount(50, 12);
      const positionId = "1";
      
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Calc-Buy-Amount" },
          { name: "InvestmentAmount", value: investmentAmount },
          { name: "PositionId", value: positionId },
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
        process: cpmm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const buyAmount_ = Messages[0].Data
      
      expect(buyAmount_).to.equal('86718045112781')
    })
  })

  /************************************************************************ 
  * cpmm.Calc-Sell-Amount
  ************************************************************************/
  describe("cpmm.Calc-Sell-Amount", function () {
    it("+ve should calculate sell amount", async () => {
      let messageId;
      const returnAmount = parseAmount(50, 12);
      const positionId = "1";
      
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Calc-Sell-Amount" },
          { name: "ReturnAmount", value: returnAmount },
          { name: "PositionId", value: positionId },
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
        process: cpmm,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const sellAmount_ = Messages[0].Data
      
      expect(sellAmount_).to.equal('126647182484748')
    })
  })

  /************************************************************************ 
  * cpmm.Buy
  ************************************************************************/
  describe("cpmm.Buy", function () {
    it("+ve should check positions of user and cpmm before buy", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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
  
      expect(balances[0][cpmm]).to.equal('150000000000000')
      expect(balances[1][cpmm]).to.equal('150000000000000')

      expect(balances[0][walletAddress]).to.equal('50000000000000')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })

    it("+ve should buy position tokens", async () => {
      const investmentAmount = parseAmount(10, 12);
      const outcomeIndex = "1";
      const positionId = "1";

      async function calcBuyAmount(amount, positionId_) {
        let messageId;
        
        await message({
          process: cpmm,
          tags: [
            { name: "Action", value: "Calc-Buy-Amount" },
            { name: "InvestmentAmount", value: amount },
            { name: "PositionId", value: positionId_ },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        const buyAmount_ = Messages[0].Data
        return buyAmount_
      }

      async function buy(amount, positionId_, minAmount) {
        let messageId;
        
        await message({
          process: collateralToken,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: cpmm },
            { name: "Quantity", value: amount },
            { name: "X-Action", value: "Buy" },
            { name: "X-PositionId", value: positionId_ },
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

      async function getBalance(token, tokenId, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-By-Id" },
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

      const balanceBefore = await getBalance(conditionalTokens, positionId, walletAddress);
      const buyAmount = await calcBuyAmount(investmentAmount, outcomeIndex);

      await buy(investmentAmount, outcomeIndex, buyAmount.toString());

      // wait for the buy to be processed
      await new Promise(resolve => setTimeout(resolve, 2000)); // 20000
      const balanceAfter = await getBalance(conditionalTokens, positionId, walletAddress);

      expect(buyAmount).to.be.equal((balanceAfter - balanceBefore).toString())
    })

    it("+ve should check positions of user and cpmm after buy", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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
  
      expect(balances[0][cpmm]).to.equal('140712945590995')
      expect(balances[1][cpmm]).to.equal('159900000000000')

      expect(balances[0][walletAddress]).to.equal('69187054409005')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })

    it("+ve should buy more position tokens", async () => {
      const investmentAmount = parseAmount(10, 12);
      const outcomeIndex = "1";
      const positionId = "1";

      async function calcBuyAmount(amount, positionId_) {
        let messageId;
        
        await message({
          process: cpmm,
          tags: [
            { name: "Action", value: "Calc-Buy-Amount" },
            { name: "InvestmentAmount", value: amount },
            { name: "PositionId", value: positionId_ },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        const buyAmount_ = Messages[0].Data
        return buyAmount_
      }

      async function buy(amount, positionId_, minAmount) {
        let messageId;
        
        await message({
          process: collateralToken,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: cpmm },
            { name: "Quantity", value: amount },
            { name: "X-Action", value: "Buy" },
            { name: "X-PositionId", value: positionId_ },
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

      async function getBalance(token, tokenId, recipient) {
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-By-Id" },
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

      const balanceBefore = await getBalance(conditionalTokens, positionId, walletAddress);
      const buyAmount = await calcBuyAmount(investmentAmount, outcomeIndex);

      await buy(investmentAmount, outcomeIndex, buyAmount.toString());

      // wait for the buy to be processed
      await new Promise(resolve => setTimeout(resolve, 2000)); // 20000
      const balanceAfter = await getBalance(conditionalTokens, positionId, walletAddress);

      expect(buyAmount).to.be.equal((balanceAfter - balanceBefore).toString())
    })

    it("+ve should check positions of user and cpmm after buy more", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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
      expect(balances[0][cpmm]).to.equal('132508833922263')
      expect(balances[1][cpmm]).to.equal('169800000000000')

      // @dev as expected, the user balance has increased by less than previous buy
      expect(balances[0][walletAddress]).to.equal('87291166077737')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })
  })

  /************************************************************************ 
  * cpmm.Sell
  ************************************************************************/
  describe("cpmm.Sell", function () {
    it("+ve should sell position tokens", async () => {
      const returnAmount = parseAmount(9.2, 12); // User Balance - 8% (to account for fees)
      const outcomeIndex = "1";
      const positionId = "1";

      async function calcSellAmount(returnAmount, positionId_) {
        let messageId;
        
        await message({
          process: cpmm,
          tags: [
            { name: "Action", value: "Calc-Sell-Amount" },
            { name: "ReturnAmount", value: returnAmount },
            { name: "PositionId", value: positionId_ },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        const sellAmount_ = Messages[0].Data
        return sellAmount_
      }

      async function sell(returnAmount, index, maxSellAmount) {
        let messageId;
        
        await message({
          process: conditionalTokens,
          tags: [
            { name: "Action", value: "Sell" },
            { name: "Recipient", value: cpmm },
            { name: "TokenId", value: positionId },
            { name: "Quantity", value: maxSellAmount },
            { name: "ReturnAmount", value: returnAmount },
            { name: "PositionId", value: index },
            { name: "MaxOutcomeTokensToSell", value: maxSellAmount },
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

      async function getConditionalBalance(token, tokenId, recipient) {
        console.log(token, tokenId, recipient)
        let messageId;
        await message({
          process: token,
          tags: [
            { name: "Action", value: "Balance-By-Id" },
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

      const userConditionalBalanceBefore = await getConditionalBalance(conditionalTokens, positionId, walletAddress);
      const userCollateralBalanceBefore = await getBalance(collateralToken, walletAddress);
      const cpmmConditionalBalanceBefore = await getConditionalBalance(conditionalTokens, positionId, cpmm);
      const cpmmCollateralBalanceBefore = await getBalance(collateralToken, cpmm);
      const maxSellAmount = await calcSellAmount(returnAmount, positionId);

      await sell(returnAmount, outcomeIndex, maxSellAmount.toString());

      // wait for the sell to be processed
      await new Promise(resolve => setTimeout(resolve, 2000)); // 20000
      const userConditionalBalanceAfter = await getConditionalBalance(conditionalTokens, positionId, walletAddress);
      const userCollateralBalanceAfter = await getBalance(collateralToken, walletAddress);
      const cpmmConditionalBalanceAfter = await getConditionalBalance(conditionalTokens, positionId, cpmm);
      const cpmmCollateralBalanceAfter = await getBalance(collateralToken, cpmm);

      // @dev: This is the actual amount sold / burned during the position merge process
      const sellAmount = "9292929292930"
      expect(Number(sellAmount)).to.be.lessThan(Number(maxSellAmount))
      expect(sellAmount).to.be.equal((userConditionalBalanceBefore - userConditionalBalanceAfter).toString())

      // User: Expect returnAmount of collateral tokens to be credited to user
      expect(returnAmount).to.be.equal((userCollateralBalanceAfter - userCollateralBalanceBefore).toString())

      // cpmm: Expect cpmm balances to remain the same
      expect(cpmmConditionalBalanceBefore).to.be.equal(cpmmConditionalBalanceAfter)

      //cpmm: expect fee to have been added to cpmm's balance
      // @dev: This is a 1% fee on the sell amount (approx.)
      // const feeAmount = 92929292930; <-- This is the previous test, which is no longer valid

      // @dev Updating this test to reflect that CTF and CPMM are now the same process, meaning
      // i) there is no change in balance due the feeAmount as this is transferred from A to A
      // ii) collateral is now held by the process, meaning the returnAmount is returned to the user
      expect(cpmmCollateralBalanceAfter.toString()).to.be.equal((Number(cpmmCollateralBalanceBefore - returnAmount)).toString())

      // @dev This is the previous test, which is no longer valid
      // expect(cpmmCollateralBalanceAfter.toString()).to.be.equal((Number(cpmmCollateralBalanceBefore) + feeAmount).toString())
    })

    it("+ve should check positions of user and cpmm after sell", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
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
      expect(balances[0][cpmm]).to.equal('132508833922263')
      expect(balances[1][cpmm]).to.equal('160507070707070')

      expect(balances[0][walletAddress]).to.equal('77998236784807')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })
  })

  /************************************************************************ 
  * cpmm.Remove-Funding and collect Fees
  ************************************************************************/
  describe("cpmm.Remove-Funding-With-Fees", function () {
    before(async () => {
      // Add delay to allow for previous test to complete
      // await new Promise(resolve => setTimeout(resolve, 5000));
    })

    it("+ve should return collected fees before remove funding", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Collected-Fees" },
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
        process: cpmm,
      });
  
      if (Error) {
        console.log(Error)
      }
  
      expect(Messages.length).to.be.equal(1)
  
      const collectedFees = JSON.parse(Messages[0].Data)

      expect(collectedFees).to.equal(292929292930)
    })

    it("+ve should return fees withdrawable before remove funding", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Fees-Withdrawable" },
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
        process: cpmm,
      });
  
      if (Error) {
        console.log(Error)
      }
  
      expect(Messages.length).to.be.equal(1)
  
      const collectedFees = JSON.parse(Messages[0].Data)

      expect(collectedFees).to.equal(292929292930)
    })

    it("+ve should remove funding with fees", async () => {
      let messageId;
      let userLPTokenBalanceBefore;
      let userLPTokenBalanceAfter;
      let cpmmLPTokenBalanceBefore;
      let cpmmLPTokenBalanceAfter;
      let userCollateralBalanceBefore;
      let userCollateralBalanceAfter;

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
          process: cpmm,
          tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: cpmm },
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
          process: cpmm,
        });

        if (Error) {
          console.log(Error)
        }

        return Messages
      }

      userLPTokenBalanceBefore = await getBalance(cpmm, walletAddress);
      cpmmLPTokenBalanceBefore = await getBalance(cpmm, cpmm);
      userCollateralBalanceBefore = await getBalance(collateralToken, walletAddress);

      let Messages = await removeFunding();

      await new Promise(resolve => setTimeout(resolve, 5000)); // 10000

      userLPTokenBalanceAfter = await getBalance(cpmm, walletAddress);
      cpmmLPTokenBalanceAfter = await getBalance(cpmm, cpmm);
      userCollateralBalanceAfter = await getBalance(collateralToken, walletAddress);

      expect(Messages.length).to.be.equal(3)

      const action_0 = Messages[1].Tags.find(t => t.name === 'Action').value
      const xAction_0 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const recipient_0 = Messages[1].Tags.find(t => t.name === 'Recipient').value
      const quantity_0 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      
      const action_1 = Messages[2].Tags.find(t => t.name === 'Action').value
      const xAction_1 = Messages[2].Tags.find(t => t.name === 'X-Action').value
      const sender_1 = Messages[2].Tags.find(t => t.name === 'Sender').value
      const quantity_1 = Messages[2].Tags.find(t => t.name === 'Quantity').value

      // Debits LP tokens from the sender to the cpmm
      expect(action_0).to.equal('Debit-Notice')
      expect(xAction_0).to.equal('Remove-Funding')
      expect(quantity_0).to.equal(quantity)
      expect(recipient_0).to.equal(cpmm)

      // Credits the cpmm with the LP tokens
      expect(action_1).to.equal('Credit-Notice')
      expect(xAction_1).to.equal('Remove-Funding')
      expect(quantity_1).to.equal(quantity)
      expect(sender_1).to.equal(walletAddress)  

      // Check balances
      expect(userLPTokenBalanceBefore).to.equal(parseAmount(150, 12))
      expect(userLPTokenBalanceAfter).to.equal(parseAmount(100, 12))
      expect(cpmmLPTokenBalanceBefore).to.equal(parseAmount(0, 12))
      expect(cpmmLPTokenBalanceAfter).to.equal(parseAmount(0, 12))
      expect(userCollateralBalanceBefore).to.equal('9789200000000000')
      expect(userCollateralBalanceAfter).to.equal('9789492929292930')
    })

    it("+ve should have retrieved position tokens from cpmm in exchange for the LP tokens", async () => {
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
      
      // @dev unchanged
      expect(balances[0][cpmm]).to.equal('132508833922263')
      expect(balances[1][cpmm]).to.equal('160507070707070')

      expect(balances[0][walletAddress]).to.equal('77998236784807')
      expect(balances[1][walletAddress]).to.equal('50000000000000')
    })

    it("+ve should return collected fees after remove funding", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Collected-Fees" },
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
        process: cpmm,
      });
  
      if (Error) {
        console.log(Error)
      }
  
      expect(Messages.length).to.be.equal(1)
  
      const collectedFees = JSON.parse(Messages[0].Data)

      expect(collectedFees).to.equal(0)
    })

    it("+ve should return fees withdrawable after remove funding", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Fees-Withdrawable" },
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
        process: cpmm,
      });
  
      if (Error) {
        console.log(Error)
      }
  
      expect(Messages.length).to.be.equal(1)
  
      const collectedFees = JSON.parse(Messages[0].Data)

      expect(collectedFees).to.equal(0)
    })

    it("+ve should withdraw fees", async () => {
      // await new Promise(resolve => setTimeout(resolve, 5000));
      let messageId;
      await message({
        process: cpmm,
        tags: [
          { name: "Action", value: "Withdraw-Fees" },
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
        process: cpmm,
      });
  
      if (Error) {
        console.log(Error)
      }
  
      expect(Messages.length).to.be.equal(1)
  
      const withdrawnFees = JSON.parse(Messages[0].Data)

      expect(withdrawnFees).to.equal(0)
    })
  })
})