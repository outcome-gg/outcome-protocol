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

const configurator = process.env.TEST_CONFIGURATOR2;

console.log("CONFIGURATOR: ", configurator)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

// Txn execution variables
let wallet;
let wallet2;
let walletAddress;
let walletAddress2;

// Configurator variables
let admin;
let delay;
let staged;
let updateProcess;
let updateAction;
let updateTags;
let updateData;
let updateDelay;
let updateAdmin;
let hash;
let hashAdmin;
let hashDelay;
let hashNoTags;
let hashNoData;

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

    // Configurator variables
    admin = walletAddress,
    delay = 3000, // 3 seconds
    staged = {},
    updateProcess = "test-this-is-valid-arweave-wallet-address-1",
    updateAction = "UPDATE_ACTION",
    updateTags = JSON.stringify({"TAG1": "FOO", "TAG2": "BAR"}),
    updateData = JSON.stringify({"DATA": 123}),
    updateAdmin = walletAddress2,
    updateDelay = 4000, // 4 seconds
    hash = keccak256(updateProcess + updateAction + updateTags + updateData).toString('hex'),
    hashAdmin = keccak256(walletAddress2).toString('hex'),
    hashDelay = keccak256(updateDelay.toString()).toString('hex'),
    hashNoTags = keccak256(updateProcess + updateAction + "" + updateData).toString('hex'),
    hashNoData = keccak256(updateProcess + updateAction + updateTags + "").toString('hex')
  ))

  /************************************************************************ 
  * configurator.Info
  ************************************************************************/
  describe("configurator.Info", function () {
    it("+ve should get info", async () => {
      let messageId;
      await message({
        process: configurator,
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const admin_ = Messages[0].Tags.find(t => t.name === 'Admin').value
      const delay_ = Messages[0].Tags.find(t => t.name === 'Delay').value
      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      
      expect(admin_).to.equal(admin)
      expect(delay_).to.equal(delay.toString())
      expect(Object.keys(staged_).length).to.equal(0)
    })
  })

  /************************************************************************ 
  * configurator.Stage-Update
  ************************************************************************/
  describe("configurator.Stage-Update", function () {
    it("+ve should fail to stage update (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to stage update (missing updateProcess)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateProcess is required!")
    })

    it("+ve should fail to stage update (missing updateAction)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess},
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateAction is required!")
    })

    it("+ve should fail to stage update (invalid updateTags)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateTags must be valid JSON!")
    })

    it("+ve should fail to stage update (invalid updateData)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateData must be valid JSON!")
    })

    it("+ve should stage update (no tags)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const updateProcess_ = Messages[0].Tags.find(t => t.name === 'UpdateProcess').value
      const updateAction_ = Messages[0].Tags.find(t => t.name === 'UpdateAction').value
      const updateTags_ = Messages[0].Tags.find(t => t.name === 'UpdateTags').value
      const updateData_ = Messages[0].Tags.find(t => t.name === 'UpdateData').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Notice")
      expect(updateProcess_).to.equal(updateProcess)
      expect(updateAction_).to.equal(updateAction)
      expect(updateTags_).to.equal("")
      expect(updateData_).to.equal(updateData)
      expect(hash_).to.equal(hashNoTags)
    })

    it("+ve should stage update (no data)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const updateProcess_ = Messages[0].Tags.find(t => t.name === 'UpdateProcess').value
      const updateAction_ = Messages[0].Tags.find(t => t.name === 'UpdateAction').value
      const updateTags_ = Messages[0].Tags.find(t => t.name === 'UpdateTags').value
      const updateData_ = Messages[0].Tags.find(t => t.name === 'UpdateData').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Notice")
      expect(updateProcess_).to.equal(updateProcess)
      expect(updateAction_).to.equal(updateAction)
      expect(updateTags_).to.equal(updateTags)
      expect(updateData_).to.equal("")
      expect(hash_).to.equal(hashNoData)
    })

    it("+ve should stage update", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const updateProcess_ = Messages[0].Tags.find(t => t.name === 'UpdateProcess').value
      const updateAction_ = Messages[0].Tags.find(t => t.name === 'UpdateAction').value
      const updateTags_ = Messages[0].Tags.find(t => t.name === 'UpdateTags').value
      const updateData_ = Messages[0].Tags.find(t => t.name === 'UpdateData').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Notice")
      expect(updateProcess_).to.equal(updateProcess)
      expect(updateAction_).to.equal(updateAction)
      expect(updateTags_).to.equal(updateTags)
      expect(updateData_).to.equal(updateData)
      expect(hash_).to.equal(hash)
    })

    it("+ve should have updated info (staged)", async () => {
      let messageId;
      await message({
        process: configurator,
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      expect(Object.keys(staged_).length).to.equal(3)
    })
  })

  /************************************************************************ 
  * configurator.Unstage-Update
  ************************************************************************/
  describe("configurator.Unstage-Update", function () {
    it("+ve should fail to unstage update (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to unstage update (missing updateProcess)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateProcess is required!")
    })

    it("+ve should fail to unstage update (missing updateAction)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
          { name: "UpdateProcess", value: updateProcess },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateAction is required!")
    })

    it("+ve should fail to unstage update (invalid updateTags)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateTags must be valid JSON!")
    })

    it("+ve should fail to unstage update (invalid updateData)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateData must be valid JSON!")
    })

    it("+ve should fail to unstage update (unstaged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
          { name: "UpdateProcess", value: "test-this-is-valid-arweave-wallet-address-2" },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should unstage update", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Unstage-Update-Notice")
      expect(hash_).to.equal(hash)
    })

    it("+ve should have updated info (unstaged)", async () => {
      let messageId;
      await message({
        process: configurator,
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      expect(Object.keys(staged_).length).to.equal(2)
    })
  })

  /************************************************************************ 
  * configurator.Action-Update
  ************************************************************************/
  describe("configurator.Action-Update", function () {
    it("+ve should fail to action update (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to action update (missing updateProcess)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateProcess is required!")
    })

    it("+ve should fail to action update (missing updateAction)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateAction is required!")
    })

    it("+ve should fail to action update (invalid updateTags)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateTags must be valid JSON!")
    })

    it("+ve should fail to action update (invalid updateData)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: "FOO" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateData must be valid JSON!")
    })

    it("+ve should fail to action update (update not staged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should stage update", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Notice")
      expect(hash_).to.equal(hash)
    })

    it("+ve should fail to action update (delay not passed)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged long enough!")
    })

    it("+ve should action update", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update" },
          { name: "UpdateProcess", value: updateProcess },
          { name: "UpdateAction", value: updateAction },
          { name: "UpdateTags", value: updateTags },
          { name: "UpdateData", value: updateData },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      const target_0 = Messages[0].Target
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tag1_0 = Messages[0].Tags.find(t => t.name === 'TAG1').value
      const tag2_0 = Messages[0].Tags.find(t => t.name === 'TAG2').value
      const data_0 = Messages[0].Data

      expect(target_0).to.equal(updateProcess)
      expect(action_0).to.equal(updateAction)
      expect(tag1_0).to.contain("FOO")
      expect(tag2_0).to.contain("BAR")
      expect(data_0).to.equal(updateData)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const hash_1 = Messages[1].Tags.find(t => t.name === 'Hash').value

      expect(action_1).to.equal("Action-Update-Notice")
      expect(hash_1).to.equal(hash)
    })

    it("+ve should have updated info (unstaged)", async () => {
      let messageId;
      await message({
        process: configurator,
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      expect(Object.keys(staged_).length).to.equal(2)
    })
  })

  /************************************************************************ 
  * configurator.Stage-Update-Admin
  ************************************************************************/
  describe("configurator.Stage-Update-Admin", function () {
    it("+ve should fail to stage update admin (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Admin" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to stage update admin (missing updateAdmin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Admin" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateAdmin is required!")
    })

    it("+ve should stage update admin", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Admin" },
          { name: "UpdateAdmin", value: walletAddress2 },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Admin-Notice")
      expect(hash_).to.equal(hashAdmin)
    })
  })

  /************************************************************************ 
  * configurator.Unstage-Update-Admin
  ************************************************************************/
  describe("configurator.Unstage-Update-Admin", function () {
    it("+ve should fail to unstage update admin (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Admin" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to unstage update admin (update not staged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Admin" },
          { name: "UpdateAdmin", value: "test-this-is-valid-arweave-wallet-address-2" }, 
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should unstage update admin", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Admin" },
          { name: "UpdateAdmin", value: updateAdmin },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Unstage-Update-Admin-Notice")
      expect(hash_).to.equal(hashAdmin)
    })
  })

  /************************************************************************ 
  * configurator.Action-Update-Admin
  ************************************************************************/
  describe("configurator.Action-Update-Admin", function () {
    it("+ve should stage update admin", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Admin" },
          { name: "UpdateAdmin", value: updateAdmin },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Admin-Notice")
      expect(hash_).to.equal(hashAdmin)
    })

    it("+ve should fail to action update admin (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Admin" },
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to action update admin (unstaged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Admin" },
          { name: "UpdateAdmin", value: "test-this-is-valid-arweave-wallet-address-2" },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should fail to action update admin (delay not passed)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Admin" },
          { name: "UpdateAdmin", value: updateAdmin },
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
        process: configurator,
      });

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged long enough!")
    })

    it("+ve should action update admin", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Admin" },
          { name: "UpdateAdmin", value: updateAdmin },
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Action-Update-Admin-Notice")
      expect(hash_).to.equal(hashAdmin)
    })

    it("+ve should have updated info (admin)", async () => {
      let messageId;
      await message({
        process: configurator,
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
        process: configurator,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      const admin_ = Messages[0].Tags.find(t => t.name === 'Admin').value
      const delay_ = Messages[0].Tags.find(t => t.name === 'Delay').value
      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      
      expect(admin_).to.equal(updateAdmin)
      expect(delay_).to.equal(delay.toString())
      expect(Object.keys(staged_).length).to.equal(2)
    })
  })

  /************************************************************************ 
  * configurator.Stage-Update-Delay
  ************************************************************************/
  describe("configurator.Stage-Update-Delay", function () {
    it("+ve should fail to stage update delay (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
        ],
        signer: createDataItemSigner(wallet), // no longer admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to stage update delay (missing updateDelay)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateDelay is required!")
    })

    it("+ve should fail to stage update delay (non-integer)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: "FOO" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateDelay must be a number!")
    })

    it("+ve should fail to stage update delay (negative)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: "-123" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateDelay must be greater than zero!")
    })

    it("+ve should fail to stage update delay (zero)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: "0" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateDelay must be greater than zero!")
    })

    it("+ve should fail to stage update delay (decimal)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: "1.1" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("UpdateDelay must be an integer!")
    })

    it("+ve should stage update delay", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: updateDelay.toString() },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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
      const updateDelay_ = Messages[0].Tags.find(t => t.name === 'UpdateDelay').value
      const hash_ = Messages[0].Tags.find(t => t.name === 'Hash').value

      expect(action_).to.equal("Stage-Update-Delay-Notice")
      expect(updateDelay_).to.equal(updateDelay.toString())
      expect(hash_).to.equal(hashDelay)
    })
  })

  /************************************************************************ 
  * configurator.Unstage-Update-Delay
  ************************************************************************/
  describe("configurator.Unstage-Update-Delay", function () {
    it("+ve should fail to unstage update delay (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Delay" },
        ],
        signer: createDataItemSigner(wallet), // no longer admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to unstage update delay (update not staged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Delay" },
          { name: "UpdateDelay", value: "123" }, 
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should unstage update delay", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Unstage-Update-Delay" },
          { name: "UpdateDelay", value: updateDelay.toString() },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(action_).to.equal("Unstage-Update-Delay-Notice")
      expect(hash_).to.equal(hashDelay)
    })
  })

  /************************************************************************ 
  * configurator.Action-Update-Delay
  ************************************************************************/
  describe("configurator.Action-Update-Delay", function () {
    it("+ve should stage update delay", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Stage-Update-Delay" },
          { name: "UpdateDelay", value: updateDelay.toString() },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(action_).to.equal("Stage-Update-Delay-Notice")
      expect(hash_).to.equal(hashDelay)
    })

    it("+ve should fail to action update delay (non-admin)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Delay" },
        ],
        signer: createDataItemSigner(wallet), // no longer admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Sender must be admin!")
    })

    it("+ve should fail to action update delay (unstaged)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Delay" },
          { name: "UpdateDelay", value: "123" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged!")
    })

    it("+ve should fail to action update delay (delay not passed)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Delay" },
          { name: "UpdateDelay", value: updateDelay.toString() },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(Messages.length).to.be.equal(0)
      expect(Error).to.include("Update not staged long enough!")
    })

    it("+ve should action update delay", async () => {
      await new Promise(r => setTimeout(r, delay + 1));
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Action-Update-Delay" },
          { name: "UpdateDelay", value: updateDelay.toString() },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      expect(action_).to.equal("Action-Update-Delay-Notice")
      expect(hash_).to.equal(hashDelay)
    })

    it("+ve should have updated info (delay)", async () => {
      let messageId;
      await message({
        process: configurator,
        tags: [
          { name: "Action", value: "Info" },
        ],
        signer: createDataItemSigner(wallet2), // new admin
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

      const admin_ = Messages[0].Tags.find(t => t.name === 'Admin').value
      const delay_ = Messages[0].Tags.find(t => t.name === 'Delay').value
      const staged_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'Staged').value)
      
      expect(admin_).to.equal(updateAdmin)
      expect(delay_).to.equal(updateDelay.toString())
      expect(Object.keys(staged_).length).to.equal(2)
    })
  })
})