import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { error } from "console";
import dotenv from 'dotenv';
import { platform } from "os";
import exp from "constants";

dotenv.config();

const platformData = process.env.TEST_PLATFORM_DATA2;
console.log("TEST_PLATFORM_DATA: ", platformData)
// Get the current file path
const __filename = fileURLToPath(import.meta.url);
// Get the directory name of the current module
const __dirname = path.dirname(__filename);


/* 
* Global variables
*/
let messageId
let wallet 
let walletAddress
let wallet2 
let walletAddress2

/* 
* Tests
*/
describe("platformData.integration.test", function () {
  before(async () => ( 
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet2.json')).toString(),
    ),
    walletAddress = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I',
    walletAddress2 = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0'
  ))

  /* 
  * INFO HANDLER
  */
  describe("INFO HANDLER", function () {
    it("+ve should get info", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Info" }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      const configurator = Messages[0].Tags.find(t => t.name === 'Configurator').value
      const moderators = JSON.parse(Messages[0].Tags.find(t => t.name === 'Moderators').value)
      expect(configurator).to.eql("test-this-is-valid-arweave-wallet-address-1")
      expect(moderators.length).to.equal(3)
      expect(moderators[0]).to.eql("test-this-is-valid-arweave-wallet-address-2")
      expect(moderators[1]).to.eql("test-this-is-valid-arweave-wallet-address-3")
      expect(moderators[2]).to.eql("test-this-is-valid-arweave-wallet-address-4")
      expect(Messages[0].Data).to.eql('["Users","Markets","Messages","Fundings","Predictions","ProbabilitySets","Probabilities"]')
    })
  })

  /* 
  * ACTIVITY WRITE HANDLERS
  */
  describe("ACTIVITY WRITE HANDLERS", function () {
    it("+ve should log market", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Market" },
          { name: "Market", value: walletAddress },
          { name: "Creator", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "CreatorFee", value: "200" },
          { name: "CreatorFeeTarget", value: "test-this-is-valid-arweave-wallet-address-3" },
          { name: "Question", value: "Trump wins the US election" },
          { name: "Rules", value: "This market will resolve to 'IN' if Trump wins the 2024 US Presidential Election. Otherwise, this market will resolve to 'No'.\n\nThe resolution source for this market is the New York Times: https://www.nytimes.com/." },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-4" },
          { name: "ResolutionAgent", value: "test-this-is-valid-arweave-wallet-address-5" },
          { name: "Category", value: "politics" },
          { name: "Subcategory", value: "US election" },
          { name: "Logo", value: "https://www.arweave.net/123456" },
          { name: "Cast", value: "true" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      const action = Messages[0].Tags.find(t => t.name === 'Action').value
      const marketFactory = Messages[0].Tags.find(t => t.name === 'MarketFactory').value
      const market = Messages[0].Tags.find(t => t.name === 'Market').value
      const creator = Messages[0].Tags.find(t => t.name === 'Creator').value
      const creatorFee = Messages[0].Tags.find(t => t.name === 'CreatorFee').value
      const creatorFeeTarget = Messages[0].Tags.find(t => t.name === 'CreatorFeeTarget').value
      const question = Messages[0].Tags.find(t => t.name === 'Question').value
      const outcomeSlotCount = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
      const collateral = Messages[0].Tags.find(t => t.name === 'Collateral').value
      const resolutionAgent = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const category = Messages[0].Tags.find(t => t.name === 'Category').value
      const subcategory = Messages[0].Tags.find(t => t.name === 'Subcategory').value
      const logo = Messages[0].Tags.find(t => t.name === 'Logo').value

      expect(action).to.eql("Log-Market-Notice")
      expect(marketFactory).to.eql(walletAddress)
      expect(market).to.eql(walletAddress)
      expect(creator).to.eql("test-this-is-valid-arweave-wallet-address-2")
      expect(creatorFee).to.eql("200")
      expect(creatorFeeTarget).to.eql("test-this-is-valid-arweave-wallet-address-3")
      expect(question).to.eql("Trump wins the US election")
      expect(outcomeSlotCount).to.eql("2")
      expect(collateral).to.eql("test-this-is-valid-arweave-wallet-address-4")
      expect(resolutionAgent).to.eql("test-this-is-valid-arweave-wallet-address-5")
      expect(category).to.eql("politics")
      expect(subcategory).to.eql("US election")
      expect(logo).to.eql("https://www.arweave.net/123456")
    })

    it("+ve should log market w/o cast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Market" },
          { name: "Market", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Creator", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "CreatorFee", value: "200" },
          { name: "CreatorFeeTarget", value: "test-this-is-valid-arweave-wallet-address-3" },
          { name: "Question", value: "Trump wins the US election" },
          { name: "Rules", value: "This market will resolve to 'IN' if Trump wins the 2024 US Presidential Election. Otherwise, this market will resolve to 'No'.\n\nThe resolution source for this market is the New York Times: https://www.nytimes.com/." },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-4" },
          { name: "ResolutionAgent", value: "test-this-is-valid-arweave-wallet-address-5" },
          { name: "Category", value: "politics" },
          { name: "Subcategory", value: "US election" },
          { name: "Logo", value: "https://www.arweave.net/123456" }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(0)
     
    })

    it("-ve should fail log market validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Market" },
          { name: "Market", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Creator", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "CreatorFee", value: "200" },
          { name: "CreatorFeeTarget", value: "test-this-is-NOT-valid" },
          { name: "Question", value: "Trump wins the US election" },
          { name: "Rules", value: "This market will resolve to 'IN' if Trump wins the 2024 US Presidential Election. Otherwise, this market will resolve to 'No'.\n\nThe resolution source for this market is the New York Times: https://www.nytimes.com/." },
          { name: "OutcomeSlotCount", value: "2" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-4" },
          { name: "ResolutionAgent", value: "test-this-is-valid-arweave-wallet-address-5" },
          { name: "Category", value: "politics" },
          { name: "Subcategory", value: "US election" },
          { name: "Logo", value: "https://www.arweave.net/123456" }
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
        process: platformData,
      });

      expect(Error).to.contain("CreatorFeeTarget must be a valid Arweave address!")
    })

    it("+ve should log funding", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Funding" },
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Operation", value: "add" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Cast", value: "true" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      const action = Messages[0].Tags.find(t => t.name === 'Action').value
      const market = Messages[0].Tags.find(t => t.name === 'Market').value
      const user = Messages[0].Tags.find(t => t.name === 'User').value
      const operation = Messages[0].Tags.find(t => t.name === 'Operation').value
      const collateral = Messages[0].Tags.find(t => t.name === 'Collateral').value
      const quantity = Messages[0].Tags.find(t => t.name === 'Quantity').value

      expect(action).to.eql("Log-Funding-Notice")
      expect(market).to.eql(walletAddress)
      expect(user).to.eql("test-this-is-valid-arweave-wallet-address-1")
      expect(operation).to.eql("add")
      expect(collateral).to.eql("test-this-is-valid-arweave-wallet-address-2")
      expect(quantity).to.eql(parseAmount(100, 12))
    })

    it("+ve should log funding w/o cast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Funding" },
          { name: "User", value: walletAddress },
          { name: "Operation", value: "add" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "Quantity", value: parseAmount(100, 12) }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(0)
      // DbAdmin:exec("SELECT * FROM Fundings") shows the funding was logged 
    })

    it("-ve should fail log funding validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Funding" },
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Operation", value: "add" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          // { name: "Quantity", value: parseAmount(100, 12) }
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
        process: platformData,
      });

      expect(Error).to.contain("Quantity is required!")
    })

    it("+ve should log prediction", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Prediction" },
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Operation", value: "buy" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Outcome", value: "1" },
          { name: "Shares", value: parseAmount(1, 12) },
          { name: "Price", value: "123.123" },
          { name: "Cast", value: "true" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      const action = Messages[0].Tags.find(t => t.name === 'Action').value
      const market = Messages[0].Tags.find(t => t.name === 'Market').value
      const user = Messages[0].Tags.find(t => t.name === 'User').value
      const operation = Messages[0].Tags.find(t => t.name === 'Operation').value
      const collateral = Messages[0].Tags.find(t => t.name === 'Collateral').value
      const quantity = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const outcome = Messages[0].Tags.find(t => t.name === 'Outcome').value
      const shares = Messages[0].Tags.find(t => t.name === 'Shares').value
      const price = Messages[0].Tags.find(t => t.name === 'Price').value

      expect(action).to.eql("Log-Prediction-Notice")
      expect(market).to.eql(walletAddress)
      expect(user).to.eql("test-this-is-valid-arweave-wallet-address-1")
      expect(operation).to.eql("buy")
      expect(collateral).to.eql("test-this-is-valid-arweave-wallet-address-2")
      expect(quantity).to.eql(parseAmount(100, 12))
      expect(outcome).to.eql("1")
      expect(shares).to.eql(parseAmount(1, 12))
      expect(price).to.eql("123.123")
    })

    it("-ve should log prediction w/o cast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Prediction" },
          { name: "User", value: walletAddress2 },
          { name: "Operation", value: "buy" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Outcome", value: "2" },
          { name: "Shares", value: parseAmount(1, 12) },
          { name: "Price", value: "123.123" }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(0)
      // DbAdmin:exec("SELECT * FROM Predictions") shows the funding was logged 
    })

    it("-ve should fail log prediction validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Prediction" },
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Operation", value: "buy" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          // { name: "Quantity", value: parseAmount(100, 12) },
          { name: "Outcome", value: "1" },
          { name: "Shares", value: parseAmount(1, 12) },
          { name: "Price", value: "123.123" },
          { name: "Cast", value: "true" },
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
        process: platformData,
      });

      expect(Error).to.contain("Quantity is required!")
    })

    it("+ve should log probabilities", async () => {
      const probabilities_ = {"1": 0.2, "2": 0.8}
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Probabilities" },
          { name: "Probabilities", value: JSON.stringify(probabilities_) },
          { name: "Cast", value: "true" }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      const action = Messages[0].Tags.find(t => t.name === 'Action').value
      const probabilities = JSON.parse(Messages[0].Tags.find(t => t.name === 'Probabilities').value)

      expect(action).to.eql("Log-Probabilities-Notice")
      expect(probabilities["1"]).to.eql(probabilities_["1"])
      expect(probabilities["2"]).to.eql(probabilities_["2"])
    })

    it("+ve should log probabilities w/o cast", async () => {
      const probabilities_ = {"1": 0.2, "2": 0.8}
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Probabilities" },
          { name: "Probabilities", value: JSON.stringify(probabilities_) }
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(0)
      // DbAdmin:exec("SELECT * FROM Probabilities") shows the funding was logged 
      // DbAdmin:exec("SELECT * FROM ProbabilitySets") shows the funding was logged 
    })

    it("-ve should fail log probabilities validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Probabilities" },
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
        process: platformData,
      });

      expect(Error).to.contain("Probabilities is required!")
    })
  })

  /* 
  * CHATROOM WRITE HANDLERS
  */
  describe("CHATROOM WRITE HANDLERS", function () {
    it("+ve should broadcast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Broadcast" },
          { name: "Market", value: walletAddress },
          { name: "Cast", value: "true" },
        ],
        signer: createDataItemSigner(wallet),
        data: "Here is my message",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const action = Messages[0].Tags.find(t => t.name === 'Action').value
      const market = Messages[0].Tags.find(t => t.name === 'Market').value
      const body = Messages[0].Data

      expect(action).to.equal("Broadcast-Notice")
      expect(market).to.equal(walletAddress)
      expect(body).to.equal("Here is my message")
    })

    it("+ve should broadcast w/o cast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Broadcast" },
          { name: "Market", value: walletAddress }
        ],
        signer: createDataItemSigner(wallet2),
        data: "Another message",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(0)
      // DbAdmin:exec("SELECT * FROM Messages") shows the message was inserted
    })

    it("-ve should fail broadcast message validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Broadcast" }
        ],
        signer: createDataItemSigner(wallet),
        data: "Here is my message",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: platformData,
      });

      expect(Error).to.contain("Market is required!")
    })
  })

  /* 
  * READ HANDLERS
  */
  describe("READ HANDLERS", function () {
    it("+ve should query", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Query" },
        ],
        signer: createDataItemSigner(wallet),
        data: "SELECT * FROM Users WHERE id = 'test-this-is-valid-arweave-wallet-address-1';",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const users = JSON.parse(Messages[0].Data)
      const user = users[0]

      expect(user["id"]).to.equal("test-this-is-valid-arweave-wallet-address-1")
      expect(user["silenced"]).to.equal(0)
      expect(Number(user["timestamp"])).to.be.greaterThan(1737389232801)
    })

    it("-ve should fail query validation", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Query" },
        ],
        signer: createDataItemSigner(wallet),
        data: "DELETE * FROM Users;",
      })
      .then((id) => {
        messageId = id;
      })
      .catch(console.error);

      let { Messages, Error } = await result({
        message: messageId,
        process: platformData,
      });

      expect(Error).to.contain("Forbidden keyword found in query!")
    })

    it("+ve should get market", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Market" },
          { name: "Market", value: walletAddress },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const market = JSON.parse(Messages[0].Data)
      
      expect(market["id"]).to.equal(walletAddress)
      expect(market["creator"]).to.equal("test-this-is-valid-arweave-wallet-address-2")
      expect(market["creator_fee"]).to.equal(200)
      expect(market["creator_fee_target"]).to.equal("test-this-is-valid-arweave-wallet-address-3")
      expect(market["question"]).to.equal("Trump wins the US election")
      expect(market["outcome_slot_count"]).to.equal(2)
      expect(market["collateral"]).to.equal("test-this-is-valid-arweave-wallet-address-4")
      expect(market["resolution_agent"]).to.equal("test-this-is-valid-arweave-wallet-address-5")
      expect(market["category"]).to.equal("politics")
      expect(market["subcategory"]).to.equal("US election")
      expect(market["logo"]).to.equal("https://www.arweave.net/123456")
      expect(market["bet_volume"]).to.equal(2 * 100*10**12) // log prediction sent twice with 100*10**12
      expect(market["net_funding"]).to.equal(2 * 100*10**12) // log funding sent twice with 100*10**12
      expect(JSON.parse(market["probabilities"])["1"]).to.equal(0.2)
      expect(JSON.parse(market["probabilities"])["2"]).to.equal(0.8)
    })

    it("+ve should get no market w/ non-existant-market", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Market" },
          { name: "Market", value: "test-this-is-valid-arweave-wallet-address-0" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const market = JSON.parse(Messages[0].Data)
      
      expect(market).to.equal(null)
    })

    it("+ve should get markets", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
      expect(markets[1]["id"]).to.equal(walletAddress)
      expect(markets[1]["creator"]).to.equal("test-this-is-valid-arweave-wallet-address-2")
      expect(markets[1]["creator_fee"]).to.equal(200)
      expect(markets[1]["creator_fee_target"]).to.equal("test-this-is-valid-arweave-wallet-address-3")
      expect(markets[1]["question"]).to.equal("Trump wins the US election")
      expect(markets[1]["outcome_slot_count"]).to.equal(2)
      expect(markets[1]["collateral"]).to.equal("test-this-is-valid-arweave-wallet-address-4")
      expect(markets[1]["resolution_agent"]).to.equal("test-this-is-valid-arweave-wallet-address-5")
      expect(markets[1]["category"]).to.equal("politics")
      expect(markets[1]["subcategory"]).to.equal("US election")
      expect(markets[1]["logo"]).to.equal("https://www.arweave.net/123456")
      expect(markets[1]["bet_volume"]).to.equal(2 * 100*10**12) // log prediction sent twice with 100*10**12
      expect(markets[1]["net_funding"]).to.equal(2 * 100*10**12) // log funding sent twice with 100*10**12
      expect(JSON.parse(markets[1]["probabilities"])["1"]).to.equal(0.2)
      expect(JSON.parse(markets[1]["probabilities"])["2"]).to.equal(0.8)
    })

    it("+ve should get markets w/ status==closed", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Status", value: "closed" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("+ve should get markets w/ status==resolved", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Status", value: "resolved" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("-ve should fail to get markets w/ status==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Status", value: "foo" },
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
        process: platformData,
      });
      
      expect(Error).to.contain("Status must be 'open', 'closed', or 'resolved'!")
    })

    it("+ve should get markets w/ minFunding==300*10**12", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "MinFunding", value: parseAmount(300, 12) },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("-ve should fail get markets w/ minFunding==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "MinFunding", value: "foo" },
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
        process: platformData,
      });

      expect(Error).to.contain("MinFunding must be a number!")
    })

    it("+ve should get markets w/ creator==walletAddress2", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Creator", value: walletAddress2 },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("-ve should fail to get markets w/ creator==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Creator", value: "foo" },
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
        process: platformData,
      });

      expect(Error).to.contain("Creator must be a valid Arweave address!")
    })

    it("+ve should get markets w/ category==politics", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Category", value: "politics" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
    })

    it("+ve should no get markets w/ category==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Category", value: "foo" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("+ve should get markets w/ subcategory==US election", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Subcategory", value: "US election" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
    })

    it("+ve should get no markets w/ subcategory==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Subcategory", value: "foo" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("+ve should get markets w/ keyword==election", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Keyword", value: "election" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
    })

    it("+ve should get no markets w/ keyword==foo", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Keyword", value: "foo" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("+ve should get markets w/ orderBy==bet_volume", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "OrderBy", value: "bet_volume" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
      expect(markets[0]["bet_volume"]).to.be.greaterThan(markets[1]["bet_volume"])
    })

    it("+ve should get markets w/ orderBy==bet_volume orderDirection=ASC", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "OrderBy", value: "bet_volume" },
          { name: "OrderDirection", value: "ASC" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(2)
      expect(markets[1]["bet_volume"]).to.be.greaterThan(markets[0]["bet_volume"])
    })

    it("+ve should get markets w/ limit and offset", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Limit", value: "1" },
          { name: "Offset", value: "1" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(1)
      expect(markets[0]["id"]).to.equal(walletAddress)
      expect(markets[0]["creator"]).to.equal("test-this-is-valid-arweave-wallet-address-2")
      expect(markets[0]["creator_fee"]).to.equal(200)
      expect(markets[0]["creator_fee_target"]).to.equal("test-this-is-valid-arweave-wallet-address-3")
      expect(markets[0]["question"]).to.equal("Trump wins the US election")
      expect(markets[0]["outcome_slot_count"]).to.equal(2)
      expect(markets[0]["collateral"]).to.equal("test-this-is-valid-arweave-wallet-address-4")
      expect(markets[0]["resolution_agent"]).to.equal("test-this-is-valid-arweave-wallet-address-5")
      expect(markets[0]["category"]).to.equal("politics")
      expect(markets[0]["subcategory"]).to.equal("US election")
      expect(markets[0]["logo"]).to.equal("https://www.arweave.net/123456")
      expect(markets[0]["bet_volume"]).to.equal(2 * 100*10**12) // log prediction sent twice with 100*10**12
      expect(markets[0]["net_funding"]).to.equal(2 * 100*10**12) // log funding sent twice with 100*10**12
    })

    it("+ve should get no markets w/ limit and offset > num of results", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Markets" },
          { name: "Limit", value: "1" },
          { name: "Offset", value: "5" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const markets = JSON.parse(Messages[0].Data)
      
      expect(markets.length).to.be.equal(0)
    })

    it("+ve should get broadcasts", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Broadcasts" },
          { name: "Market", value: walletAddress },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const broadcasts = JSON.parse(Messages[0].Data)
      console.log("broadcasts: ", broadcasts)
      expect(broadcasts.length).to.be.equal(2)
      expect(broadcasts[0]["user"]).to.equal(walletAddress2)
      expect(broadcasts[0]["message"]).to.equal("Another message")
      expect(broadcasts[0]["net_funding"]).to.equal(0)
      expect(broadcasts[0]["net_shares"]).to.equal('{"2":1000000000000}')
      expect(broadcasts[1]["user"]).to.equal(walletAddress)
      expect(broadcasts[1]["message"]).to.equal("Here is my message")
      expect(broadcasts[1]["net_funding"]).to.equal(100000000000000)
      expect(broadcasts[1]["net_shares"]).to.equal('{}')
      expect(broadcasts[0]["timestamp"]).to.be.greaterThan(broadcasts[1]["timestamp"])
    })

    it("+ve should get broadcasts w/ offset", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Get-Broadcasts" },
          { name: "Market", value: walletAddress },
          { name: "OrderDirection", value: "ASC" },
          { name: "Offset", value: "1" },
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
        process: platformData,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.equal(1)
      const broadcasts = JSON.parse(Messages[0].Data)
      console.log("broadcasts: ", broadcasts)
      expect(broadcasts.length).to.be.equal(1)
      expect(broadcasts[0]["user"]).to.equal(walletAddress2)
      expect(broadcasts[0]["message"]).to.equal("Another message")
      expect(broadcasts[0]["net_funding"]).to.equal(0)
      expect(broadcasts[0]["net_shares"]).to.equal('{"2":1000000000000}')

    })
  })

  /* 
  * MODERATOR HANDLERS
  */
  // describe("MODERATOR HANDLERS", function () {
  //   it("+ve should set user silence", async () => {
    
  //   })

  //   it("-ve should fail set user silence validation", async () => {

  //   })

  //   it("+ve should set message visibility", async () => {
    
  //   })

  //   it("-ve should fail set message visibility validation", async () => {

  //   })

  //   it("+ve should delete messages", async () => {
    
  //   })

  //   it("-ve should fail delete messages validation", async () => {

  //   })

  //   it("+ve should delete old messages", async () => {
    
  //   })

  //   it("-ve should fail delete old messages validation", async () => {

  //   })
  // })

  /* 
  * CONFIGURATOR HANDLERS
  */
  // describe("CONFIGURATOR HANDLERS", function () {
  //   it("+ve should update configurator", async () => {
    
  //   })

  //   it("-ve should fail update configurator validation", async () => {

  //   })

  //   it("+ve should update moderators", async () => {
    
  //   })

  //   it("-ve should fail update moderators validation", async () => {

  //   })

  //   it("+ve should update intervals", async () => {
    
  //   })

  //   it("-ve should fail update intervals validation", async () => {

  //   })

  //   it("+ve should update range durations", async () => {
    
  //   })

  //   it("-ve should fail update range durations validation", async () => {

  //   })

  //   it("+ve should update max interval", async () => {
    
  //   })

  //   it("-ve should fail update max interval validation", async () => {

  //   })

  //   it("+ve should update max range duration", async () => {
    
  //   })

  //   it("-ve should fail update max range duration validation", async () => {

  //   })
  // })
})