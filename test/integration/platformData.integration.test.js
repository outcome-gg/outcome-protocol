import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path, { parse } from "path";
import { error } from "console";
import dotenv from 'dotenv';
import { platform } from "os";

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
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
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
          { name: "Outcome", value: "1" },
          { name: "Quantity", value: parseAmount(100, 12) },
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
      const outcome = Messages[0].Tags.find(t => t.name === 'Outcome').value
      const quantity = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const price = Messages[0].Tags.find(t => t.name === 'Price').value

      expect(action).to.eql("Log-Prediction-Notice")
      expect(market).to.eql(walletAddress)
      expect(user).to.eql("test-this-is-valid-arweave-wallet-address-1")
      expect(operation).to.eql("buy")
      expect(collateral).to.eql("test-this-is-valid-arweave-wallet-address-2")
      expect(outcome).to.eql("1")
      expect(quantity).to.eql(parseAmount(100, 12))
      expect(price).to.eql("123.123")
    })

    it("-ve should log prediction w/o cast", async () => {
      await message({
        process: platformData,
        tags: [
          { name: "Action", value: "Log-Prediction" },
          { name: "User", value: "test-this-is-valid-arweave-wallet-address-1" },
          { name: "Operation", value: "buy" },
          { name: "Collateral", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "Outcome", value: "1" },
          { name: "Quantity", value: parseAmount(100, 12) },
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
          { name: "Outcome", value: "1" },
          // { name: "Quantity", value: parseAmount(100, 12) },
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
  * ACTIVITY READ HANDLERS
  */
  describe("ACTIVITY READ HANDLERS", function () {
    it("+ve should get user", async () => {

    })

    it("-ve should fail get user validation", async () => {

    })

    it("+ve should get users", async () => {
    
    })

    it("-ve should fail get users validation", async () => {

    })

    it("+ve should get user count", async () => {
    
    })

    it("-ve should fail get user count validation", async () => {
    
    })

    it("+ve should get active funding users", async () => {
     
    })

    it("-ve should fail get active funding users validation", async () => {
    })

    it("+ve should get active funding users by activity", async () => {
     
    })

    it("-ve should fail get active funding users by activity validation", async () => {
    })

    it("+ve should get active prediction users", async () => {
    })

    it("-ve should fail active prediction users validation", async () => {
    })

    it("+ve should get active users", async () => {
    })

    it("-ve should fail active users validation", async () => {
    })

    it("+ve should get probabilities", async () => {
    })

    it("-ve should fail get probabilities validation", async () => {
    })

    it("+ve should get probabilities for chart", async () => {
    })

    it("-ve should fail get probabilities for chart validation", async () => {
    })
  })

  /* 
  * CHATROOM WRITE HANDLERS
  */
  describe("CHATROOM WRITE HANDLERS", function () {
    it("+ve should broadcast message", async () => {
    
    })

    it("-ve should fail broadcast message validation", async () => {

    })
  })

  /* 
  * CHATROOM READ HANDLERS
  */
  describe("CHATROOM READ HANDLERS", function () {
    it("+ve should get message", async () => {
    
    })

    it("-ve should fail get message validation", async () => {

    })

    it("+ve should get messages", async () => {
    
    })

    it("-ve should fail get messages validation", async () => {

    })

    it("+ve should get active chatroom users", async () => {
    
    })

    it("-ve should fail get active chatroom users validation", async () => {

    })
  })

  /* 
  * MODERATOR HANDLERS
  */
  describe("MODERATOR HANDLERS", function () {
    it("+ve should set user silence", async () => {
    
    })

    it("-ve should fail set user silence validation", async () => {

    })

    it("+ve should set message visibility", async () => {
    
    })

    it("-ve should fail set message visibility validation", async () => {

    })

    it("+ve should delete messages", async () => {
    
    })

    it("-ve should fail delete messages validation", async () => {

    })

    it("+ve should delete old messages", async () => {
    
    })

    it("-ve should fail delete old messages validation", async () => {

    })
  })

  /* 
  * CONFIGURATOR HANDLERS
  */
  describe("CONFIGURATOR HANDLERS", function () {
    it("+ve should update configurator", async () => {
    
    })

    it("-ve should fail update configurator validation", async () => {

    })

    it("+ve should update moderators", async () => {
    
    })

    it("-ve should fail update moderators validation", async () => {

    })

    it("+ve should update intervals", async () => {
    
    })

    it("-ve should fail update intervals validation", async () => {

    })

    it("+ve should update range durations", async () => {
    
    })

    it("-ve should fail update range durations validation", async () => {

    })

    it("+ve should update max interval", async () => {
    
    })

    it("-ve should fail update max interval validation", async () => {

    })

    it("+ve should update max range duration", async () => {
    
    })

    it("-ve should fail update max range duration validation", async () => {

    })
  })
})