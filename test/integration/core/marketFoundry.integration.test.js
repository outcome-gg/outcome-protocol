import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "../utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path from "path";
import { error } from "console";
import dotenv from 'dotenv';
import keccak256 from 'keccak256'

dotenv.config();

const marketFoundry = process.env.TEST_MARKET_FOUNDRY4;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

console.log("MARKET_FOUNDRY: ", marketFoundry)
console.log("CONDITIONAL_TOKENS: ", conditionalTokens)

// Get the current file path
const __filename = fileURLToPath(import.meta.url);

// Get the directory name of the current module
const __dirname = path.dirname(__filename);

/* 
* Global variables
*/
let processId
let messageId
let wallet 
let walletAddress
let wallet2 
let walletAddress2
let initData = new Object()
let adminAddress1
let admin1
let emergencyAdminAddress1
let emergencyAdmin1
let adminAddress2
let admin2
let emergencyAdminAddress2
let emergencyAdmin2
let protocolProcessAddress1
let protocolProcess1
let protocolProcessAddress2
let protocolProcess2
let resolutionAgent
let marketId = 'foo'

/* 
* Tests
*/
describe("marketFoundry.integration.test", function () {
  before(async () => ( 
    processId = marketFoundry,
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../../wallet2.json')).toString(),
    ),
    walletAddress = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I',
    walletAddress2 = 'm6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0',
    adminAddress1 = walletAddress,
    admin1 = wallet,
    emergencyAdminAddress1 = walletAddress,
    emergencyAdmin1 = wallet,
    adminAddress2 = walletAddress2,
    admin2 = wallet2,
    emergencyAdminAddress2 = walletAddress2,
    emergencyAdmin2 = wallet2,
    protocolProcessAddress1 = walletAddress,
    protocolProcess1 = wallet,
    protocolProcessAddress2 = walletAddress2,
    protocolProcess2 = wallet2,
    resolutionAgent = walletAddress
  ))


  /***********************************************************************
  * MarketFoundry: DB
  ************************************************************************/

  /* 
  * MarketFoundry.DB-Init
  */
  describe("marketFoundry.DB-Init", function () {
    it("+ve should init db", async () => {
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "DB-Init" }
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)
      expect(Messages[0].Data).to.eql('["Questions","Conditions","Markets"]')
    })
  })

  /***********************************************************************
  * MarketFoundry: QUESTIONS
  ************************************************************************/

  /* 
  * MarketFoundry.Prepare-Question
  */
  describe("marketFoundry.Prepare-Question", function () {
    it("+ve should prepare a question", async () => {
      const question = "Trump becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Prepare-Question" },
          { name: "Question", value: question }
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value

      expect(action_).to.eql('Question-Prepared')
      expect(questionId_).to.eql(questionId)
      expect(Messages[0].Data).to.eql(question)
    })

    it("+ve should receive a question given an id", async () => {
      const question = "Trump becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Get-Question" },
          { name: "QuestionId", value: questionId }
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.greaterThanOrEqual(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value

      const questionData = JSON.parse(Messages[0].Data)

      const question_ = questionData.question
      const proposed_by_ = questionData.proposed_by
      const proposed_at_ = questionData.proposed_at

      expect(action_).to.eql('Question-Received')
      expect(questionId_).to.eql(questionId)
      expect(question_).to.eql(question)
      expect(proposed_by_).to.eql(walletAddress)
      expect(Number(proposed_at_)).to.greaterThan(1725340525954)
    })
  })

  /***********************************************************************
  * MarketFoundry: CONDITIONS
  ************************************************************************/

  /* 
  * MarketFoundry.Prepare-Condition
  */
  describe("marketFoundry.Prepare-Condition", function () {
    it("+ve should return null for an unprepared condition", async () => {
      const question = "Trump becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Get-Condition" },
          { name: "ConditionId", value: conditionId },
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      // Message 0 sent to conditional tokens
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_ = Messages[0].Target
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.eql('Condition-Received')
      expect(target_).to.eql(walletAddress)
      expect(data_).to.eql(null)
    })

    it("+ve should prepare a condition by admin", async () => {
      const question = "Trump becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
          { name: "QuestionId", value: questionId },
          { name: "ResolutionAgent", value: resolutionAgent }
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      // Message 0 sent to conditional tokens
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_0 = Messages[0].Target
      const data_0 = JSON.parse(Messages[0].Data)

      // Message 1 sent in response to user
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const conditionId_1 = Messages[1].Tags.find(t => t.name === 'ConditionId').value
      const target_1 = Messages[1].Target
      const data_1 = JSON.parse(Messages[1].Data)

      expect(action_0).to.eql('Prepare-Condition')
      expect(target_0).to.eql(conditionalTokens)
      expect(data_0['outcomeSlotCount']).to.eql(2)
      expect(data_0['resolutionAgent']).to.eql(walletAddress2)
      expect(data_0['questionId']).to.eql(questionId)

      expect(action_1).to.eql('Condition-Drafted')
      expect(target_1).to.eql(walletAddress)
      expect(conditionId_1).to.eql(conditionId)
      expect(data_1['outcomeSlotCount']).to.eql(2)
      expect(data_1['resolutionAgent']).to.eql(walletAddress2)
      expect(data_1['questionId']).to.eql(questionId)
    })

    it("+ve should prepare a condition by non-admin", async () => {
      const question = "Biden becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
          { name: "QuestionId", value: questionId },
          { name: "ResolutionAgent", value: resolutionAgent }
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(2)

      // Message 0 sent to conditional tokens
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_0 = Messages[0].Target
      const data_0 = JSON.parse(Messages[0].Data)

      // Message 1 sent in response to user
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const conditionId_1 = Messages[1].Tags.find(t => t.name === 'ConditionId').value
      const target_1 = Messages[1].Target
      const data_1 = JSON.parse(Messages[1].Data)

      expect(action_0).to.eql('Prepare-Condition')
      expect(target_0).to.eql(conditionalTokens)
      expect(data_0['outcomeSlotCount']).to.eql(2)
      expect(data_0['resolutionAgent']).to.eql(walletAddress2)
      expect(data_0['questionId']).to.eql(questionId)

      expect(action_1).to.eql('Condition-Drafted')
      expect(target_1).to.eql(walletAddress2)
      expect(conditionId_1).to.eql(conditionId)
      expect(data_1['outcomeSlotCount']).to.eql(2)
      expect(data_1['resolutionAgent']).to.eql(walletAddress2)
      expect(data_1['questionId']).to.eql(questionId)
    })

    it("+ve should get a prepared condition drafted by admin", async () => {
      const question = "Trump becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      // wait for condition to be prepared
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Get-Condition" },
          { name: "ConditionId", value: conditionId },
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      // Message 0 sent to conditional tokens
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_ = Messages[0].Target
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.eql('Condition-Received')
      expect(target_).to.eql(walletAddress)
      expect(data_['id']).to.eql(conditionId)
      expect(data_['question_id']).to.eql(questionId)
      expect(data_['resolution_agent']).to.eql(walletAddress2)
      expect(data_['status']).to.eql('registered')
      expect(data_['drafted_by']).to.eql(walletAddress)
      expect(Number(data_['drafted_at'])).to.be.greaterThan(1725374918898)
      expect(Number(data_['prepared_at'])).to.be.greaterThan(1725374918898)
      expect(Number(data_['registered_at'])).to.be.greaterThan(1725374918898)
    })

    it("+ve should get a prepared condition drafted by non-admin", async () => {
      const question = "Biden becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      // wait for condition to be prepared
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Get-Condition" },
          { name: "ConditionId", value: conditionId },
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      // Message 0 sent to conditional tokens
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_ = Messages[0].Target
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.eql('Condition-Received')
      expect(target_).to.eql(walletAddress)
      expect(data_['id']).to.eql(conditionId)
      expect(data_['question_id']).to.eql(questionId)
      expect(data_['resolution_agent']).to.eql(walletAddress2)
      expect(data_['status']).to.eql('prepared')
      expect(data_['drafted_by']).to.eql(walletAddress2)
      expect(Number(data_['drafted_at'])).to.be.greaterThan(1725374918898)
      expect(Number(data_['prepared_at'])).to.be.greaterThan(1725374918898)
    })

    it("+ve should register a prepared condition drafted by non-admin", async () => {
      const question = "Biden becomes the 47th US President"
      const questionId = keccak256(question + processId + walletAddress).toString('hex')
      const resolutionAgent = walletAddress2
      const conditionId = keccak256(resolutionAgent + questionId + "2").toString('hex')

      // wait for condition to be prepared
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Register-Condition" },
          { name: "ConditionId", value: conditionId },
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
        process: processId,
      });

      if (Error) {
        console.log(Error)
      }

      expect(Messages.length).to.be.equal(1)

      // Message 0 sent to conditional tokens
      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const target_ = Messages[0].Target
      const data_ = JSON.parse(Messages[0].Data)

      expect(action_).to.eql('Condition-Registered')
      expect(target_).to.eql(walletAddress)
      expect(data_['id']).to.eql(conditionId)
      expect(data_['question_id']).to.eql(questionId)
      expect(data_['resolution_agent']).to.eql(walletAddress2)
      expect(data_['status']).to.eql('registered')
      expect(data_['drafted_by']).to.eql(walletAddress2)
      expect(Number(data_['drafted_at'])).to.be.greaterThan(1725374918898)
      expect(Number(data_['prepared_at'])).to.be.greaterThan(1725374918898)
      expect(Number(data_['registered_at'])).to.be.greaterThan(1725374918898)
    })
  })

  // /***********************************************************************
  // * MarketFoundry: INIT
  // ************************************************************************/

  // /* 
  // * MarketFoundry.Init
  // */
  // describe("marketFoundry.Create-Market", function () {
  //   it("+ve should create a market", async () => {
  //     await message({
  //       process: processId,
  //       tags: [
  //         { name: "Action", value: "Create-Market" }
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
  //       process: processId,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     console.log("Messages: ", Messages)

  //     expect(Messages.length).to.be.greaterThanOrEqual(1)
  //     console.log(Messages[0].Data)
  //     // expect(Messages[0].Data).to.eql('["Users","Agents","Messages","MarketGroups","Markets","Wagers","Wins","Shares","ChatSubscriptions","MarketSubscriptions","UserSubscriptions","AgentSubscriptions"]')
  //   })
  // })
})