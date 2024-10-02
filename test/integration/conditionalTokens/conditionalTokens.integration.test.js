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

const collateralToken = process.env.TEST_COLLATERAL_TOKEN;
const conditionalTokens = process.env.TEST_CONDITIONAL_TOKENS;

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
let questionId1;
let questionId2;
let parlayQuestionId1;
let parlayQuestionId2;
let collectionIds;
let parlayCollectionIds;

/* 
* Tests
*/
describe("conditionalTokens.integration.test", function () {
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

    // Conditional Token variables

    // to get conditionId
    questionId1 = 'trump-becomes-the-47th-president-of-the-usa',
    questionId2 = 'biden-becomes-the-47th-president-of-the-usa',

    // quarter-finals
    parlayQuestionId1 = 'bulls-beat-the-pistons-in-the-nba-quarter-finals',
    parlayQuestionId2 = 'lakers-beat-the-celtics-in-the-nba-quarter-finals',
  
    resolutionAgent = walletAddress2,

    // to track collectionIds
    collectionIds = [],
    parlayCollectionIds = []
  ))

  /************************************************************************ 
  * ConditionalTokens.Setup
  ************************************************************************/
  // describe("Setup", function () {
  //   it("+ve should get conditionId", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Condition-Id" },
  //         { name: "ResolutionAgent", value: resolutionAgent },
  //         { name: "QuestionId", value: questionId1 },
  //         { name: "OutcomeSlotCount", value: "2" }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
  //     const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  //     const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  //     expect(action_).to.equal("Condition-Id")
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(questionId_).to.equal(questionId)
  //     expect(resolutionAgent_).to.equal(resolutionAgent)
  //     expect(outcomeSlotCount_).to.equal("2")
  //   })

  //   it("+ve should get collectionId for IN", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Collection-Id" },
  //         { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
  //         { name: "ConditionId", value: conditionId }, // from previous step
  //         { name: "IndexSet", value: indexSetIN }, // 1 for IN, 2 for OUT
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

  //     expect(action_).to.equal("Collection-Id")
  //     expect(parentCollectionId_).to.equal(parentCollectionId)
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(indexSet_).to.equal(indexSetIN)
  //     expect(collectionId_).to.equal(collectionIdIN)
  //   })

  //   it("+ve should get collectionId for OUT", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Collection-Id" },
  //         { name: "ParentCollectionId", value: parentCollectionId }, // from collateral
  //         { name: "ConditionId", value: conditionId }, // from previous step
  //         { name: "IndexSet", value: indexSetOUT }, // 1 for IN, 2 for OUT
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

  //     expect(action_).to.equal("Collection-Id")
  //     expect(parentCollectionId_).to.equal(parentCollectionId)
  //     expect(conditionId_).to.equal(conditionId)
  //     expect(indexSet_).to.equal(indexSetOUT)
  //     expect(collectionId_).to.equal(collectionIdOUT)
  //   })

  //   it("+ve should get positionId for IN", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Position-Id" },
  //         { name: "CollectionId", value: collectionIdIN }, // from previous step
  //         { name: "CollateralToken", value: collateralToken }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
  //     const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

  //     expect(action_).to.equal("Position-Id")
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(collectionId_).to.equal(collectionIdIN)
  //     expect(positionId_).to.equal(positionIdIN)
  //   })

  //   it("+ve should get positionId for OUT", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Get-Position-Id" },
  //         { name: "CollectionId", value: collectionIdOUT }, // from previous step
  //         { name: "CollateralToken", value: collateralToken }, 
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
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  //     const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
  //     const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value

  //     expect(action_).to.equal("Position-Id")
  //     expect(collateralToken_).to.equal(collateralToken)
  //     expect(collectionId_).to.equal(collectionIdOUT)
  //     expect(positionId_).to.equal(positionIdOUT)
  //   })

  //   it("+ve should prepare condition", async () => {
  //     let messageId;
  //     await message({
  //       process: conditionalTokens,
  //       tags: [
  //         { name: "Action", value: "Prepare-Condition" },
  //       ],
  //       signer: createDataItemSigner(wallet),
  //       data: JSON.stringify({
  //         resolutionAgent: resolutionAgent,
  //         questionId: questionId,
  //         outcomeSlotCount: 2
  //       }),
  //     })
  //     .then((id) => {
  //       messageId = id;
  //     })
  //     .catch(console.error);

  //     let { Messages, Error } = await result({
  //       message: messageId,
  //       process: conditionalTokens,
  //     });

  //     if (Error) {
  //       console.log(Error)
  //     }

  //     expect(Messages.length).to.be.equal(1)

  //     const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
  //     const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
  //     const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
  //     const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  //     const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  //     expect(action_).to.equal("Condition-Preparation-Notice")
  //     expect(questionId_).to.equal(questionId)
  //     expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId1 + "2").toString('hex'))
  //     expect(resolutionAgent_).to.equal(resolutionAgent)
  //     expect(outcomeSlotCount_).to.equal('2')
  //   })
  // })

  /************************************************************************ 
  * Prepare Condition
  ************************************************************************/
  describe("Prepare Condition", function () {
    it("-ve should not prepare a condition (with no outcome slots)", async () => {
      const outcomeSlotCount = 0;
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId1,
          outcomeSlotCount: parseInt(outcomeSlotCount)
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

      //AOS Error: there should be more than one outcome slot
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not prepare a condition (with only one outcome slots)", async () => {
      const outcomeSlotCount = 1;
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId1,
          outcomeSlotCount: parseInt(outcomeSlotCount)
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

      //AOS Error: there should be more than one outcome slot
      expect(Messages.length).to.be.equal(0)
    })

    it("+ve should prepare a condition (and send notice)", async () => {
      const outcomeSlotCount = 9;
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId1,
          outcomeSlotCount: parseInt(outcomeSlotCount)
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
      expect(questionId_).to.equal(questionId1)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex'))
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
    })

    it("-ve should not prepare the same condition (once created)", async () => {
      const outcomeSlotCount = 9;
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId1,
          outcomeSlotCount: parseInt(outcomeSlotCount)
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

      // AOS Error: condition already prepared
      expect(Messages.length).to.be.equal(0)
    })

    it("+ve should get outcome slot count (for condition)", async () => {
      // same values as previous test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Outcome-Slot-Count" },
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
        process: conditionalTokens,
      });

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

      expect(action_).to.equal("Outcome-Slot-Count")
      expect(conditionId_).to.equal(conditionId)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
    })

    it("+ve should leave payout denominator unset (for condition)", async () => {
      // same values as previous test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Denominator" },
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
        process: conditionalTokens,
      });

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const denominator_ = Messages[0].Tags.find(t => t.name === 'Denominator').value
    
      expect(action_).to.equal("Denominator")
      expect(conditionId_).to.equal(conditionId)
      expect(denominator_).to.equal("0") // should be zero; unset
    })

    it("+ve should prepare a second condition (and send notice)", async () => {
      const outcomeSlotCount = 2;
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Prepare-Condition" },
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          resolutionAgent: resolutionAgent,
          questionId: questionId2,
          outcomeSlotCount: parseInt(outcomeSlotCount)
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
      expect(questionId_).to.equal(questionId2)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex'))
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
    })
  })

  /************************************************************************ 
  * Split Position
  ************************************************************************/
  describe("Split Positions", function () {
    it("-ve should not split (unprepared condition)", async () => {
      // different values to previous test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      
      // Binary decimals 7, 56, 448: 3 options each with 3**2 9 propper subsets, 81 combinations in total
      const partition = [0b000000111, 0b000111000, 0b111000000] 
      const quantity = "100"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      // Error: condition not prepared yet
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not split (index sets that aren't disjoint)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      const partition = [0b000000111, 0b000111000, 0b111000111] // not disjoint
      const quantity = "100"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      // Error: partition not disjoint
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not split (partitioning more than condition outcome slots)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      const partition = [0b000000001, 0b000000010, 0b000000100, 0b000001000, 0b000010000, 0b000100000, 0b001000000, 0b010000000, 0b100000000, 0b1000000000] // partitioning more than outcome slots
      const quantity = "100"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      // Error: got invalid index set
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not split (given a singleton partition)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      const partition = [0b000000111] // singleton partition
      const quantity = "100"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      // Error: got empty or single partion
      expect(Messages.length).to.be.equal(0)
    })

    it("+ve should split (from collateral with notice)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      const partition = [0b000000111, 0b000111000, 0b111000000] // Binary decimals labelled A, B, C
      const quantity = "100"

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify updated collateral balance (conditionalTokens +100)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balance_).to.equal(100)
    })

    it("+ve should split second condition (from collateral with notice)", async () => {
      // same values as second test
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral
      const partition = [0b01, 0b10] // Binary decimals labelled IN, OUT
      const quantity = "100"

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify updated collateral balance (conditionalTokens +100)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balance_).to.equal(200)
    })

    it("+ve should verify position mint amounts (with Balance-All)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("100")
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("100")
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("100")
      // second condition
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("100")
    })

    it("+ve should verify position mint amounts (with Balance-Of)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balances-Of" },
          { name: "TokenId", value: "2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06" },
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

      expect(Messages.length).to.be.equal(1)

      const balancesOf_ = JSON.parse(Messages[0].Data)

      expect(balancesOf_[walletAddress]).to.equal("100")
    })

    it("+ve should get collection id (condition 1, indexSet A)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId },
          { name: "ConditionId", value: conditionId },
          { name: "IndexSet", value: "7" }, // 0b000000111 == 7
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal("7") // 0b000000111 == 7
      expect(collectionId_).to.equal("e4f5613105ec90ba8f5eea07410b509f6664dd8a2f1be9fbf9cdef124827b4dd")

      collectionIds.push(collectionId_)
    })

    it("+ve should get position id", async () => {
      // same collection id as previous test
      const collectionId = collectionIds[0];

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Position-Id" },
          { name: "CollateralToken", value: collateralToken },
          { name: "CollectionId", value: collectionId }, 
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const collateralToken_ = Messages[0].Tags.find(t => t.name === 'CollateralToken').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value
      const positionId_ = Messages[0].Tags.find(t => t.name === 'PositionId').value
    
      expect(action_).to.equal("Position-Id")
      expect(collateralToken_).to.equal(collateralToken)
      expect(collectionId_).to.equal(collectionIds[0])
      expect(positionId_).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
    })

    //@dev ref: https://docs.gnosis.io/conditionaltokens/docs/devguide05
    //@dev this is the same as A -> A&IN, A&OUT
    it("+ve should split (from parentCollection of same collection)", async () => {
      // same values as original test
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = collectionIds[0] // collectionId for indexSet 0b000000111
      const partition = [0b000000110, 0b000000001] // disjoint set of parent (6 & 1)
      const quantity = "20"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      expect(Messages.length).to.be.equal(3)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
 
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenIds_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'Quantities').value)

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const stakeholder_2 = Messages[2].Tags.find(t => t.name === 'Stakeholder').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantity_0).to.equal("20")

      expect(action_1).to.equal("Mint-Batch-Notice")
      expect(tokenIds_1[0]).to.equal("4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770")
      expect(tokenIds_1[1]).to.equal("be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30")
      expect(quantities_1[0]).to.equal("20")
      expect(quantities_1[1]).to.equal("20")

      expect(action_2).to.equal("Split-Position-Notice")
      expect(conditionId_2).to.equal("a78dfbe0312214db9e0949b363d5543134046461d00a61feef498584e9c31ca3")
      expect(stakeholder_2).to.equal(walletAddress)
      expect(quantity_2).to.equal("20")
      expect(partition_2[0]).to.equal(6)
      expect(partition_2[1]).to.equal(1)
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    it("+ve should verify updated position balances (with Balances-All)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("80") // split
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("100")
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("100")
      // second condition
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("100")
      // split from first condition
      expect(balances_["be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30"][walletAddress]).to.equal("20")
      expect(balances_["4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770"][walletAddress]).to.equal("20")
    })

    it("+ve should verify updated collateral balance (conditionalTokens +/-0)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balance_).to.equal(200)
    })

    it("+ve should get collection id (condition 2, indexSet IN)", async () => {
      // same values as original test
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId },
          { name: "ConditionId", value: conditionId },
          { name: "IndexSet", value: "1" }, // 0b01 == 1
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal("1") // 0b01 == 1
      expect(collectionId_).to.equal("52333217d89d7b004c3da4d6a06a97493dc78219371b5fc48bda7116c0a6a23b")

      collectionIds.push(collectionId_)
    })

    it("+ve should split (from a parentCollection of different collection: IN -> A,B,C)", async () => {
      const outcomeSlotCount = 9;
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = collectionIds[1] // collectionId for indexSet condition 2 0b01: IN
      const partition = [0b111000000, 0b000111000, 0b000000111] // disjoint set A, B, C
      const quantity = "15"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      expect(Messages.length).to.be.equal(3)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenIds_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'Quantities').value)

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const stakeholder_2 = Messages[2].Tags.find(t => t.name === 'Stakeholder').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a")
      expect(quantity_0).to.equal("15")

      expect(action_1).to.equal("Mint-Batch-Notice")
      expect(tokenIds_1[0]).to.equal("eb5a50032b2d6662e0e5f89c2fc45fbacbdfa8cfdacce260e272b0df56780c50")
      expect(tokenIds_1[1]).to.equal("1b428749c3b62e80cc4dcf72f47cac0f73ccf0a54c3c8a35d810c98b8830d516")
      expect(tokenIds_1[2]).to.equal("a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485")
      expect(quantities_1[0]).to.equal("15")
      expect(quantities_1[1]).to.equal("15")
      expect(quantities_1[2]).to.equal("15")

      expect(action_2).to.equal("Split-Position-Notice")
      expect(conditionId_2).to.equal("a78dfbe0312214db9e0949b363d5543134046461d00a61feef498584e9c31ca3")
      expect(stakeholder_2).to.equal(walletAddress)
      expect(quantity_2).to.equal("15")
      expect(partition_2[0]).to.equal(448) // 0b000000111
      expect(partition_2[1]).to.equal(56) // 0b000111000
      expect(partition_2[2]).to.equal(7) // 0b111000000
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    it("+ve should split (from a parentCollection of different collection: A -> IN,OUT)", async () => {
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = collectionIds[0] // collectionId for indexSet condition 1 0b111000000: A
      const partition = [0b01, 0b10] // disjoint set IN, OUT
      const quantity = "3"

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Split-Position" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: quantity
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

      expect(Messages.length).to.be.equal(3)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenIds_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'Quantities').value)

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const stakeholder_2 = Messages[2].Tags.find(t => t.name === 'Stakeholder').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantity_0).to.equal("3")

      expect(action_1).to.equal("Mint-Batch-Notice")
      expect(tokenIds_1[0]).to.equal("a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485")
      expect(tokenIds_1[1]).to.equal("b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a")
      expect(quantities_1[0]).to.equal("3")
      expect(quantities_1[1]).to.equal("3")

      expect(action_2).to.equal("Split-Position-Notice")
      expect(conditionId_2).to.equal("c696ccc93ba9275d17c93fb9581cfa08bb7a02299fe0599c12e0ae8cf1d7425c")
      expect(stakeholder_2).to.equal(walletAddress)
      expect(quantity_2).to.equal("3")
      expect(partition_2[0]).to.equal(1) // 0b01
      expect(partition_2[1]).to.equal(2) // 0b10
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    //@dev "communicative" meaning that "$->A->LO" == "$->LO->A"
    //@dev ref: https://docs.gnosis.io/conditionaltokens/docs/devguide05
    //@dev this is the same as A -> A&LO, A&HI
    it("+ve should verify communicative conditional chaining (via balances)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // A,B,C split from collateral
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("77") // -3
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("100")
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("100")
      // IN, OUT split from collateral
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("85") // -15
      // A&HI, A&LO split from A
      expect(balances_["be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30"][walletAddress]).to.equal("20")
      expect(balances_["4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770"][walletAddress]).to.equal("20")
      // B&IN, C&IN split from IN
      expect(balances_["eb5a50032b2d6662e0e5f89c2fc45fbacbdfa8cfdacce260e272b0df56780c50"][walletAddress]).to.equal("15") // +15
      expect(balances_["1b428749c3b62e80cc4dcf72f47cac0f73ccf0a54c3c8a35d810c98b8830d516"][walletAddress]).to.equal("15") // +15
      // A&OUT split from A
      expect(balances_["b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a"][walletAddress]).to.equal("3") // +3
      // A&IN split from IN and A
      expect(balances_["a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485"][walletAddress]).to.equal("18") // +15+3
    })

    it("+ve should verify unchanged collateral balance (conditionalTokens +/-0)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      // first condition
      expect(balance_).to.equal(200)
    })
  })

  /************************************************************************ 
  * Merge Positions
  ************************************************************************/
  describe("Merge Positions", function () {
    it("-ve should not merge (amount exceed balances in to-be-merged positions)", async () => {
      const outcomeSlotCount = 2
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = collectionIds[0] // collectionId for indexSet condition 1 0b111000000: A
      const partition = [0b01, 0b10] // disjoint set IN, OUT

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Merge-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: "4" // balance is 3
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

      // Error: User must have sufficient tokens!
      expect(Messages.length).to.be.equal(0)
    })

    it("+ve should merge (to non-collateral-parent and send notice)", async () => {
      const outcomeSlotCount = 2
      const conditionId = keccak256(resolutionAgent + questionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = collectionIds[0] // collectionId for indexSet condition 1 0b111000000: A
      const partition = [0b01, 0b10] // disjoint set IN, OUT

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Merge-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: "2" // balance is 3
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

      expect(Messages.length).to.be.equal(3)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const remainingBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'RemainingBalances').value)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Batch-Notice")
      expect(tokenIds_0[0]).to.equal("a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485")
      expect(tokenIds_0[1]).to.equal("b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a")
      expect(quantities_0[0]).to.equal("2")
      expect(quantities_0[1]).to.equal("2")
      expect(remainingBalances_0[0]).to.equal("16")
      expect(remainingBalances_0[1]).to.equal("1")

      expect(action_1).to.equal("Mint-Single-Notice")
      expect(tokenId_1).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantity_1).to.equal("2")

      expect(action_2).to.equal("Merge-Positions-Notice")
      expect(conditionId_2).to.equal("c696ccc93ba9275d17c93fb9581cfa08bb7a02299fe0599c12e0ae8cf1d7425c")
      expect(quantity_2).to.equal("2")
      expect(partition_2[0]).to.equal(1) // 0b01
      expect(partition_2[1]).to.equal(2) // 0b10
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    it("+ve should verify merges (via balances)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // A,B,C split from collateral
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("79") // +2
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("100")
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("100")
      // IN, OUT split from collateral
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("85") 
      // A&HI, A&LO split from A
      expect(balances_["be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30"][walletAddress]).to.equal("20")
      expect(balances_["4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770"][walletAddress]).to.equal("20")
      // B&IN, C&IN split from IN
      expect(balances_["eb5a50032b2d6662e0e5f89c2fc45fbacbdfa8cfdacce260e272b0df56780c50"][walletAddress]).to.equal("15") 
      expect(balances_["1b428749c3b62e80cc4dcf72f47cac0f73ccf0a54c3c8a35d810c98b8830d516"][walletAddress]).to.equal("15") 
      // A&OUT split from A
      expect(balances_["b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a"][walletAddress]).to.equal("1") // -2
      // A&IN split from IN and A
      expect(balances_["a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485"][walletAddress]).to.equal("16") // -2
    })

    it("+ve should verify unchanged collateral balance (conditionalTokens +/-0)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      expect(balance_).to.equal(200)
    })

    it("+ve should merge (to collateral-parent and send notice)", async () => {
      const outcomeSlotCount = 9
      const conditionId = keccak256(resolutionAgent + questionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // merge to collateral
      const partition = [0b111000000, 0b000111000, 0b000000111] // disjoint set A, B, C

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Merge-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: "70" // min balance is 79
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

      expect(Messages.length).to.be.equal(2)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const remainingBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'RemainingBalances').value)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const recipient_1 = Messages[1].Tags.find(t => t.name === 'Recipient').value
      const xAction_1 = Messages[1].Tags.find(t => t.name === 'X-Action').value
      const xConditionId_1 = Messages[1].Tags.find(t => t.name === 'X-ConditionId').value
      const xCollateralToken_1 = Messages[1].Tags.find(t => t.name === 'X-CollateralToken').value 
      const xParentCollectionId_1 = Messages[1].Tags.find(t => t.name === 'X-ParentCollectionId').value
      const xPartition_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'X-Partition').value)

      expect(action_0).to.equal("Burn-Batch-Notice")
      expect(tokenIds_0[0]).to.equal("a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3")
      expect(tokenIds_0[1]).to.equal("210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d")
      expect(tokenIds_0[2]).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantities_0[0]).to.equal("70")
      expect(quantities_0[1]).to.equal("70")
      expect(quantities_0[2]).to.equal("70")
      expect(remainingBalances_0[0]).to.equal("30")
      expect(remainingBalances_0[1]).to.equal("30")
      expect(remainingBalances_0[2]).to.equal("9")

      expect(action_1).to.equal("Transfer")
      expect(quantity_1).to.equal("70")
      expect(recipient_1).to.equal(walletAddress)
      expect(xAction_1).to.equal("Merge-Positions-Completion")
      expect(xConditionId_1).to.equal("a78dfbe0312214db9e0949b363d5543134046461d00a61feef498584e9c31ca3")
      expect(xCollateralToken_1).to.equal(collateralToken)
      expect(xParentCollectionId_1).to.equal(parentCollectionId)
      expect(xPartition_1[0]).to.equal(448) // 0b000000111
      expect(xPartition_1[1]).to.equal(56) // 0b000111000
      expect(xPartition_1[2]).to.equal(7) // 0b111000000
    })

    it("+ve should verify positions are burned (post merge)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // A,B,C split from collateral
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("9") // -70
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("30") // -70
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("30") // -70
      // IN, OUT split from collateral
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("85") 
      // A&HI, A&LO split from A
      expect(balances_["be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30"][walletAddress]).to.equal("20")
      expect(balances_["4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770"][walletAddress]).to.equal("20")
      // B&IN, C&IN split from IN
      expect(balances_["eb5a50032b2d6662e0e5f89c2fc45fbacbdfa8cfdacce260e272b0df56780c50"][walletAddress]).to.equal("15") 
      expect(balances_["1b428749c3b62e80cc4dcf72f47cac0f73ccf0a54c3c8a35d810c98b8830d516"][walletAddress]).to.equal("15") 
      // A&OUT split from A
      expect(balances_["b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a"][walletAddress]).to.equal("1") 
      // A&IN split from IN and A
      expect(balances_["a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485"][walletAddress]).to.equal("16") 
    })

    it("+ve should verify collateral tokens are returned (post merge)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      expect(balance_).to.equal(130) // -70
    })
  })

  /************************************************************************ 
  * Transfer Position
  ************************************************************************/
  describe("Prepare Condition", function () {
    it("+ve should get balance-of", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Balance-Of" },
          { name: "TokenId", value: "2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06" }
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

      expect(Messages.length).to.be.equal(1)

      const balance_ = JSON.parse(Messages[0].Data)

      expect(balance_).to.equal(9) // -70
    })

    it("-ve should not send single transfer (more than split balance)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Single" },
          { name: "TokenId", value: "2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06" },
          { name: "Quantity", value: "10" },
          { name: "Recipient", value: walletAddress2 }
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const error_ = Messages[0].Tags.find(t => t.name === 'Error').value
      const tokenId_ = Messages[0].Tags.find(t => t.name === 'Token-Id').value

      expect(action_).to.equal("Transfer-Error")
      expect(error_).to.equal("Insufficient Balance!")
      expect(tokenId_).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
    })

    it("+ve should send single transfer (with notice)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Single" },
          { name: "TokenId", value: "2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06" },
          { name: "Quantity", value: "5" },
          { name: "Recipient", value: walletAddress2 }
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

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
    
      expect(action_0).to.equal("Debit-Single-Notice")
      expect(quantity_0).to.equal("5")
      expect(tokenId_0).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(recipient_0).to.equal(walletAddress2)

      expect(action_1).to.equal("Credit-Single-Notice")
      expect(quantity_1).to.equal("5")
      expect(tokenId_1).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(sender_1).to.equal(walletAddress)
    })

    it("-ve should not send batch transfer (more than split balance)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Batch" },
          { name: "TokenIds", value: JSON.stringify(["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"]) },
          { name: "Quantities", value: JSON.stringify(['5']) },
          { name: "Recipient", value: walletAddress2 }
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const error_ = Messages[0].Tags.find(t => t.name === 'Error').value
      const tokenId_ = Messages[0].Tags.find(t => t.name === 'Token-Id').value

      expect(action_).to.equal("Transfer-Error")
      expect(error_).to.equal("Insufficient Balance!")
      expect(tokenId_).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
    })

    it("+ve should send batch transfer (with notice)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Transfer-Batch" },
          { name: "TokenIds", value: JSON.stringify(["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"]) },
          { name: "Quantities", value: JSON.stringify(['2']) },
          { name: "Recipient", value: walletAddress2 }
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

      expect(Messages.length).to.be.equal(2)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantities_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'Quantities').value)
      const tokenIds_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'TokenIds').value)
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
    
      expect(action_0).to.equal("Debit-Batch-Notice")
      expect(quantities_0[0]).to.equal("2")
      expect(tokenIds_0[0]).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(recipient_0).to.equal(walletAddress2)

      expect(action_1).to.equal("Credit-Batch-Notice")
      expect(quantities_1[0]).to.equal("2")
      expect(tokenIds_1[0]).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(sender_1).to.equal(walletAddress)
    })
  })

  /************************************************************************ 
  * Reporting
  ************************************************************************/
  describe("Prepare Condition", function () {
    it("-ve should not allow reporting (incorrect resolution agent)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet), // not resolution agent
        data: JSON.stringify({
          questionId: questionId1,
          payouts: [1, 1, 1, 0, 0, 0, 0, 0, 0], // A wins
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

      // Error: condition not prepared or found (resolution agent id contained within hash)
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not allow reporting (incorrect question id)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2), // resolution agent
        data: JSON.stringify({
          questionId: "foo", // incorrect question id
          payouts: [1, 1, 1, 0, 0, 0, 0, 0, 0], // A wins
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

      // Error: condition not prepared or found
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not allow reporting (no slots)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId1,
          payouts: [], // no slots
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

      // Error: there should be more than one outcome slot
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not allow reporting (wrong number of slots)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId1,
          payouts: [1, 0], // wrong number of slots
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

      // Error: condition not prepared or found
      expect(Messages.length).to.be.equal(0)
    })

    it("-ve should not allow reporting (zero payouts in all slots)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId1,
          payouts: [0, 0, 0, 0, 0, 0, 0, 0, 0], // no winner
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

      // Error: payout is all zeros
      expect(Messages.length).to.be.equal(0)
    })

    it("+ve should allow reporting (and send notice)", async () => {
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId1,
          payouts: [1, 1, 1, 0, 0, 0, 0, 0, 0], // A wins
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const payoutNumerators_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value)

      expect(action_).to.equal("Condition-Resolution-Notice")
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal('9')
      expect(questionId_).to.equal(questionId1)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId1 + '9').toString('hex'))
      expect(payoutNumerators_[0]).to.equal(1)
      expect(payoutNumerators_[1]).to.equal(1)
      expect(payoutNumerators_[2]).to.equal(1)
      expect(payoutNumerators_[3]).to.equal(0)
      expect(payoutNumerators_[4]).to.equal(0)
      expect(payoutNumerators_[5]).to.equal(0)
      expect(payoutNumerators_[6]).to.equal(0)
      expect(payoutNumerators_[7]).to.equal(0)
      expect(payoutNumerators_[8]).to.equal(0)
    })

    it("+ve should get payout numerators (post reporting)", async () => {
      const conditionId = keccak256(resolutionAgent + questionId1 + '9').toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Payout-Numerators" },
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
        process: conditionalTokens,
      });

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const payoutNumerators_ = Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value

      expect(action_).to.equal("Payout-Numerators")
      expect(conditionId_).to.equal(conditionId)
      expect(payoutNumerators_).to.equal(JSON.stringify([1,1,1,0,0,0,0,0,0]))
    })

    it("+ve should get payout denominator (post reporting)", async () => {
      const conditionId = keccak256(resolutionAgent + questionId1 + '9').toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Payout-Denominator" },
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
        process: conditionalTokens,
      });

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const payoutDenominator_ = Messages[0].Tags.find(t => t.name === 'PayoutDenominator').value
    
      expect(action_).to.equal("Payout-Denominator")
      expect(conditionId_).to.equal(conditionId)
      expect(payoutDenominator_).to.equal("3")
    })
  })

  /************************************************************************ 
  * Redeeming
  ************************************************************************/
  describe("Redeeming", function () {
    it("+ve should redeem (and send notice)", async () => {
      const conditionId = keccak256(resolutionAgent + questionId1 + '9').toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Redeem-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          parentCollectionId: "", 
          conditionId: conditionId,
          indexSets: [0b000000111, 0b000111000, 0b111000000], // disjoint set A, B, C
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

      expect(Messages.length).to.be.equal(5)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
    
      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const tokenId_2 = Messages[2].Tags.find(t => t.name === 'TokenId').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
    
      const action_3 = Messages[3].Tags.find(t => t.name === 'Action').value
      const recipient_3 = Messages[3].Tags.find(t => t.name === 'Recipient').value
      const quantity_3 = Messages[3].Tags.find(t => t.name === 'Quantity').value
    
      const action_4 = Messages[4].Tags.find(t => t.name === 'Action').value
      const redeemer_4 = Messages[4].Tags.find(t => t.name === 'Redeemer').value
      const payout_4 = Messages[4].Tags.find(t => t.name === 'Payout').value
      const collateralToken_4 = Messages[4].Tags.find(t => t.name === 'CollateralToken').value
      const indexSets_4 = Messages[4].Tags.find(t => t.name === 'IndexSets').value
      const conditionId_4 = Messages[4].Tags.find(t => t.name === 'ConditionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantity_0).to.equal("2")

      expect(action_1).to.equal("Burn-Single-Notice")
      expect(tokenId_1).to.equal("210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d")
      expect(quantity_1).to.equal("30")
  
      expect(action_2).to.equal("Burn-Single-Notice")
      expect(tokenId_2).to.equal("a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3")
      expect(quantity_2).to.equal("30")
    
      expect(action_3).to.equal("Transfer")
      expect(recipient_3).to.equal(walletAddress)
      expect(quantity_3).to.equal("2")

      expect(action_4).to.equal("Payout-Redemption-Notice")
      expect(redeemer_4).to.equal(walletAddress)
      expect(payout_4).to.equal("2")
      expect(collateralToken_4).to.equal(collateralToken)
      expect(indexSets_4).to.equal(JSON.stringify([7,56,448]))
      expect(conditionId_4).to.equal(conditionId)
    })

    it("+ve should verify zerod-out redeemed positions (and not affect others)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // A,B,C split from collateral
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress]).to.equal("0") // redeemed
      expect(balances_["a4df2384449477962779f1c84c7c8576a7e553e2b5f4f2c8a6867016c8350bc3"][walletAddress]).to.equal("0") // redeemed
      expect(balances_["210f5a2759cf3bd3d76a22dabfda4bb2552993fe5968ca1fa444a503bbfd570d"][walletAddress]).to.equal("0") // redeemed
      //wallet address 2
      expect(balances_["2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06"][walletAddress2]).to.equal("7") // not redeemed
      // IN, OUT split from collateral
      expect(balances_["57eb31d9b46ae3959d8fc5df467552bd1bb3b6f5554162c77beed49648699ba8"][walletAddress]).to.equal("100")
      expect(balances_["cd0aa400e245543a80795533ed5d75e416e0e78b347965fe6097cfb55421b16a"][walletAddress]).to.equal("85") 
      // A&HI, A&LO split from A
      expect(balances_["be6063e1fcab5e2bf2bf27830a1b94a7efb504d232480a7cf0fd324f74682e30"][walletAddress]).to.equal("20")
      expect(balances_["4314febbea54043b317c4ec77794eab1f262a278d84db8f73589bf5c1e66b770"][walletAddress]).to.equal("20")
      // B&IN, C&IN split from IN
      expect(balances_["eb5a50032b2d6662e0e5f89c2fc45fbacbdfa8cfdacce260e272b0df56780c50"][walletAddress]).to.equal("15") 
      expect(balances_["1b428749c3b62e80cc4dcf72f47cac0f73ccf0a54c3c8a35d810c98b8830d516"][walletAddress]).to.equal("15") 
      // A&OUT split from A
      expect(balances_["b1078a54de03ee4ca6970e2f2e2d878b43aec8c411e083a46543e13e3d42683a"][walletAddress]).to.equal("1") 
      // A&IN split from IN and A
      expect(balances_["a870103e2c2d5e373cf5846fffce694625e02dc4084203d225151ca28f660485"][walletAddress]).to.equal("16") 
    })
  })

  /************************************************************************ 
  * Parlays
  ************************************************************************/
  describe("Parlays", function () {
    it("+ve should prepare a condition (quarter: bulls-beat-pistons)", async () => {
      const outcomeSlotCount = 2;
      const questionId = parlayQuestionId1;
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
          outcomeSlotCount: parseInt(outcomeSlotCount)
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
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
    })

    it("+ve should prepare a condition (quarter: lakers-beat-celtics)", async () => {
      const outcomeSlotCount = 2;
      const questionId = parlayQuestionId2;
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
          outcomeSlotCount: parseInt(outcomeSlotCount)
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
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
    })

    it("+ve should get collection id (bulls-beat-pistons: IN)", async () => {
      // same values as original test
      const outcomeSlotCount = 2;
      const questionId = parlayQuestionId1
      const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId },
          { name: "ConditionId", value: conditionId },
          { name: "IndexSet", value: "1" }, // 0b01 == 1
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal("1") // 0b01 == 1
      expect(collectionId_).to.equal("5b7b6bd2bdd3fb012a4cccbb918c5bb541f999b07d27ed0460944ad9a03d5c52")

      parlayCollectionIds.push(collectionId_)
    })

    it("+ve should get collection id (lakers-beat-celtics: IN)", async () => {
      // same values as original test
      const outcomeSlotCount = 2;
      const questionId = parlayQuestionId2
      const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = "" // split from collateral

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Get-Collection-Id" },
          { name: "ParentCollectionId", value: parentCollectionId },
          { name: "ConditionId", value: conditionId },
          { name: "IndexSet", value: "1" }, // 0b01 == 1
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const parentCollectionId_ = Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const indexSet_ = Messages[0].Tags.find(t => t.name === 'IndexSet').value
      const collectionId_ = Messages[0].Tags.find(t => t.name === 'CollectionId').value

      expect(action_).to.equal("Collection-Id")
      expect(parentCollectionId_).to.equal(parentCollectionId)
      expect(conditionId_).to.equal(conditionId)
      expect(indexSet_).to.equal("1") // 0b01 == 1
      expect(collectionId_).to.equal("e636bb0cf13d0cb41a486f3e0a9b8e8bde2b7821ffbc9a8a60ee6e9a736bc4ef")

      parlayCollectionIds.push(collectionId_)
    })

    it("+ve should create leg-one of 2-way parlay (bulls-beat-pistons)", async () => {
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + parlayQuestionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = ""
      const partition = [0b01, 0b10] // IN, OUT
      const quantity = "1000"

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify leg-one of 2-way parlay (bulls-beat-pistons)", async () => {
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // Leg-one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("1000")
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("1000") 
    })

    it("+ve should create 2-way parlay (bulls-beat-pistons + lakers-beat-celtics)", async () => {
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + parlayQuestionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = parlayCollectionIds[0]
      const partition = [0b01, 0b10] // IN, OUT
      const quantity = "500" // half of original stake

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify 2-way parlay (bulls-beat-pistons + lakers-beat-celtics)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("500") // IN: split
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("1000") // OUT
      
      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("500") 
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("500") 
    })

    it("+ve should create leg-one of 2-way parlay in reverse (lakers-beat-celtics)", async () => {
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + parlayQuestionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = ""
      const partition = [0b01, 0b10] // IN, OUT
      const quantity = "2000"

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify leg-one 2-way parlay in reverse (lakers-beat-celtics)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

     // Leg one of 2-way parlay
     expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("500") // IN: split
     expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("1000") // OUT
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("2000") 
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("2000") 

     // Two-way parlay
     expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("500") 
     expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("500") 
    })

    it("+ve should create same 2-way parlay in reverse (lakers-beat-celtics + bulls-beat-pistons)", async () => {
      const outcomeSlotCount = 2;
      const conditionId = keccak256(resolutionAgent + parlayQuestionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = parlayCollectionIds[1]
      const partition = [0b01, 0b10] // IN, OUT
      const quantity = "1200" 

      let messageId;
      await message({
        process: collateralToken,
        tags: [
          { name: "Action", value: "Transfer" },
          { name: "Recipient", value: conditionalTokens },
          { name: "Quantity", value: quantity },
          { name: "X-Action", value: "Create-Position" },
          { name: "X-ParentCollectionId", value: parentCollectionId },
          { name: "X-ConditionId", value: conditionId },
          { name: "X-Partition", value: JSON.stringify(partition) },
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

      expect(Messages.length).to.be.equal(2)
      
      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value

      expect(action_0).to.equal("Debit-Notice")
      expect(action_1).to.equal("Credit-Notice")
    })

    it("+ve should verify same 2-way parlay in reverse (lakers-beat-celtics + bulls-beat-pistons)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)

      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("500") // IN: split 
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("1000") // OUT
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("800") // IN: split 
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("2000") // OUT

      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("1700") // Lakers-beat-celtics + bulls-beat-pistons
      expect(balances_["e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196"][walletAddress]).to.equal("1200") // Lakers-beat-celtics + pistons-beat-bulls
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("500") // bulls-beat-pistons + celts-beat-lakers
    })

    it("+ve should allow reporting (on leg-one of 2-way parlay)", async () => {
      const questionId = parlayQuestionId1
      const outcomeSlotCount = 2
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId,
          payouts: [1, 0], // IN wins
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const payoutNumerators_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value)

      expect(action_).to.equal("Condition-Resolution-Notice")
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
      expect(questionId_).to.equal(questionId)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
      expect(payoutNumerators_[0]).to.equal(1)
      expect(payoutNumerators_[1]).to.equal(0)
    })

    it("+ve should redeem (leg-one of 2-way parlay)", async () => {
      const conditionId = keccak256(resolutionAgent + parlayQuestionId1 + '2').toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Redeem-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          parentCollectionId: "", 
          conditionId: conditionId,
          indexSets: [0b01, 0b10], // IN, OUT
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

      expect(Messages.length).to.be.equal(4)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
    
      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const recipient_2 = Messages[2].Tags.find(t => t.name === 'Recipient').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
    
      const action_3 = Messages[3].Tags.find(t => t.name === 'Action').value
      const redeemer_3 = Messages[3].Tags.find(t => t.name === 'Redeemer').value
      const payout_3 = Messages[3].Tags.find(t => t.name === 'Payout').value
      const collateralToken_3 = Messages[3].Tags.find(t => t.name === 'CollateralToken').value
      const indexSets_3 = Messages[3].Tags.find(t => t.name === 'IndexSets').value
      const conditionId_3 = Messages[3].Tags.find(t => t.name === 'ConditionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277")
      expect(quantity_0).to.equal("500")

      expect(action_1).to.equal("Burn-Single-Notice")
      expect(tokenId_1).to.equal("b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243")
      expect(quantity_1).to.equal("1000")
    
      expect(action_2).to.equal("Transfer")
      expect(recipient_2).to.equal(walletAddress)
      expect(quantity_2).to.equal("500")

      expect(action_3).to.equal("Payout-Redemption-Notice")
      expect(redeemer_3).to.equal(walletAddress)
      expect(payout_3).to.equal("500")
      expect(collateralToken_3).to.equal(collateralToken)
      expect(indexSets_3).to.equal(JSON.stringify([1,2]))
      expect(conditionId_3).to.equal(conditionId)
    })

    it("+ve should verify 2-way parlay (after reporting bulls-beat-pistons -> IN)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)
     
      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("0") // Redeemed
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("0") // Redeemed
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("800") // Unchanged
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("2000") // Unchanged

      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("1700") // Unchanged: Lakers-beat-celtics + bulls-beat-pistons
      expect(balances_["e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196"][walletAddress]).to.equal("1200") // Unchanged: Lakers-beat-celtics + pistons-beat-bulls
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("500") // Unchanged: bulls-beat-pistons + celts-beat-lakers
    })

    it("+ve should allow reporting (on leg-two of 2-way parlay)", async () => {
      const questionId = parlayQuestionId2
      const outcomeSlotCount = 2
      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Report-Payouts" },
        ],
        signer: createDataItemSigner(wallet2),
        data: JSON.stringify({
          questionId: questionId,
          payouts: [1, 0], // IN wins
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

      expect(Messages.length).to.be.equal(1)

      const action_ = Messages[0].Tags.find(t => t.name === 'Action').value
      const resolutionAgent_ = Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
      const outcomeSlotCount_ = Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
      const questionId_ = Messages[0].Tags.find(t => t.name === 'QuestionId').value
      const conditionId_ = Messages[0].Tags.find(t => t.name === 'ConditionId').value
      const payoutNumerators_ = JSON.parse(Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value)

      expect(action_).to.equal("Condition-Resolution-Notice")
      expect(resolutionAgent_).to.equal(resolutionAgent)
      expect(outcomeSlotCount_).to.equal(outcomeSlotCount.toString())
      expect(questionId_).to.equal(questionId)
      expect(conditionId_).to.equal(keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
      expect(payoutNumerators_[0]).to.equal(1)
      expect(payoutNumerators_[1]).to.equal(0)
    })

    it("+ve should redeem (leg-two of 2-way parlay)", async () => {
      const conditionId = keccak256(resolutionAgent + parlayQuestionId2 + '2').toString('hex')

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Redeem-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          parentCollectionId: "", 
          conditionId: conditionId,
          indexSets: [0b01, 0b10], // IN, OUT
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

      expect(Messages.length).to.be.equal(4)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenId_0 = Messages[0].Tags.find(t => t.name === 'TokenId').value
      const quantity_0 = Messages[0].Tags.find(t => t.name === 'Quantity').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value
    
      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const recipient_2 = Messages[2].Tags.find(t => t.name === 'Recipient').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
    
      const action_3 = Messages[3].Tags.find(t => t.name === 'Action').value
      const redeemer_3 = Messages[3].Tags.find(t => t.name === 'Redeemer').value
      const payout_3 = Messages[3].Tags.find(t => t.name === 'Payout').value
      const collateralToken_3 = Messages[3].Tags.find(t => t.name === 'CollateralToken').value
      const indexSets_3 = Messages[3].Tags.find(t => t.name === 'IndexSets').value
      const conditionId_3 = Messages[3].Tags.find(t => t.name === 'ConditionId').value

      expect(action_0).to.equal("Burn-Single-Notice")
      expect(tokenId_0).to.equal("bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657")
      expect(quantity_0).to.equal("800")

      expect(action_1).to.equal("Burn-Single-Notice")
      expect(tokenId_1).to.equal("69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7")
      expect(quantity_1).to.equal("2000")
    
      expect(action_2).to.equal("Transfer")
      expect(recipient_2).to.equal(walletAddress)
      expect(quantity_2).to.equal("800")

      expect(action_3).to.equal("Payout-Redemption-Notice")
      expect(redeemer_3).to.equal(walletAddress)
      expect(payout_3).to.equal("800")
      expect(collateralToken_3).to.equal(collateralToken)
      expect(indexSets_3).to.equal(JSON.stringify([1,2]))
      expect(conditionId_3).to.equal(conditionId)
    })

    it("+ve should verify 2-way parlay (after reporting lakers-beat-celtics -> IN)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)
      
      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("0") // (Redeemed)
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("0") // (Redeemed)
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("0") // Redeemed
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("0") // Redeemed

      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("1700") // Unchanged: Lakers-beat-celtics + bulls-beat-pistons
      expect(balances_["e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196"][walletAddress]).to.equal("1200") // Unchanged: Lakers-beat-celtics + pistons-beat-bulls
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("500") // Unchanged: bulls-beat-pistons + celts-beat-lakers
    })

    it("+ve should merge (winning parlay with parent: bulls-beat-pistons)", async () => {
      const outcomeSlotCount = 2
      const conditionId = keccak256(resolutionAgent + parlayQuestionId2 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = parlayCollectionIds[0] 
      const partition = [0b01, 0b10] 

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Merge-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: "500" // min balance
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

      expect(Messages.length).to.be.equal(3)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const remainingBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'RemainingBalances').value)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Batch-Notice")
      expect(tokenIds_0[0]).to.equal("e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7")
      expect(tokenIds_0[1]).to.equal("cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e")
      expect(quantities_0[0]).to.equal("500")
      expect(quantities_0[1]).to.equal("500")
      expect(remainingBalances_0[0]).to.equal("1200")
      expect(remainingBalances_0[1]).to.equal("0")

      expect(action_1).to.equal("Mint-Single-Notice")
      expect(tokenId_1).to.equal("536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277")
      expect(quantity_1).to.equal("500")

      expect(action_2).to.equal("Merge-Positions-Notice")
      expect(conditionId_2).to.equal("29af3b452b0f8bdcc0f08eaafcb65943f51addb38101dd45e2940f435d1fa159")
      expect(quantity_2).to.equal("500")
      expect(partition_2[0]).to.equal(1) // 0b01
      expect(partition_2[1]).to.equal(2) // 0b10
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    it("+ve should verify merge (of leg-two)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)
      
      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("500") // Merged
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("0") // (Redeemed)
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("0") // (Redeemed)
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("0") // (Redeemed)

      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("1200") // -500: Lakers-beat-celtics + bulls-beat-pistons
      expect(balances_["e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196"][walletAddress]).to.equal("1200") // Unchanged: Lakers-beat-celtics + pistons-beat-bulls
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("0") // -500: bulls-beat-pistons + celts-beat-lakers
    })

    it("+ve should merge (winning parlay with parent: lakers-beat-celtics)", async () => {
      const outcomeSlotCount = 2
      const conditionId = keccak256(resolutionAgent + parlayQuestionId1 + outcomeSlotCount.toString()).toString('hex')
      const parentCollectionId = parlayCollectionIds[1] 
      const partition = [0b01, 0b10] 

      let messageId;
      await message({
        process: conditionalTokens,
        tags: [
          { name: "Action", value: "Merge-Positions" }
        ],
        signer: createDataItemSigner(wallet),
        data: JSON.stringify({
          collateralToken: collateralToken,
          conditionId: conditionId,
          partition: partition,
          parentCollectionId: parentCollectionId,
          quantity: "1200" // min balance
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

      expect(Messages.length).to.be.equal(3)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const remainingBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'RemainingBalances').value)

      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const tokenId_1 = Messages[1].Tags.find(t => t.name === 'TokenId').value
      const quantity_1 = Messages[1].Tags.find(t => t.name === 'Quantity').value

      const action_2 = Messages[2].Tags.find(t => t.name === 'Action').value
      const conditionId_2 = Messages[2].Tags.find(t => t.name === 'ConditionId').value
      const quantity_2 = Messages[2].Tags.find(t => t.name === 'Quantity').value
      const partition_2 = JSON.parse(Messages[2].Tags.find(t => t.name === 'Partition').value)
      const collateralToken_2 = Messages[2].Tags.find(t => t.name === 'CollateralToken').value
      const parentCollectionId_2 = Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value

      expect(action_0).to.equal("Burn-Batch-Notice")
      expect(tokenIds_0[0]).to.equal("e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7")
      expect(tokenIds_0[1]).to.equal("e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196")
      expect(quantities_0[0]).to.equal("1200")
      expect(quantities_0[1]).to.equal("1200")
      expect(remainingBalances_0[0]).to.equal("0")
      expect(remainingBalances_0[1]).to.equal("0")

      expect(action_1).to.equal("Mint-Single-Notice")
      expect(tokenId_1).to.equal("bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657")
      expect(quantity_1).to.equal("1200")

      expect(action_2).to.equal("Merge-Positions-Notice")
      expect(conditionId_2).to.equal("32b4874aeba62c889d6d7896e33b8cc1e6ac36d6abb749d3374b24f6f1410502")
      expect(quantity_2).to.equal("1200")
      expect(partition_2[0]).to.equal(1) // 0b01
      expect(partition_2[1]).to.equal(2) // 0b10
      expect(collateralToken_2).to.equal(collateralToken)
      expect(parentCollectionId_2).to.equal(parentCollectionId)
    })

    it("+ve should verify merge (of leg-two)", async () => {
      await new Promise(r => setTimeout(r, 1000));
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

      expect(Messages.length).to.be.equal(1)

      const balances_ = JSON.parse(Messages[0].Data)
      
      // Leg one of 2-way parlay
      expect(balances_["536233f389c0b61ecd189cfff77b09349a64baaf129b442eb641d63795824277"][walletAddress]).to.equal("500") // (Merged)
      expect(balances_["b18bc299fb3aa2e97416f3fcab9b87dc4db5535e03d3ec36d2fb5ffd20f26243"][walletAddress]).to.equal("0") // (Redeemed)
     
      // Leg one of 2-way parlay (reverse)
      expect(balances_["bf7b21d16bb135e169d380b1f40b1efb5091c98827dea26722319dbbc35ed657"][walletAddress]).to.equal("1200") // Merged
      expect(balances_["69331937a6e3adf69e226903d47b364917eb18b286677f5938492a8e0de0abc7"][walletAddress]).to.equal("0") // (Redeemed)

      // Two-way parlay
      expect(balances_["e03bd59e7f0378fc01fa58c48c626d9178b03af891763d494cf2fce620812fe7"][walletAddress]).to.equal("0") // -1200: Lakers-beat-celtics + bulls-beat-pistons
      expect(balances_["e5252bf459d4c07929df06de80625e01ffd96650119c0f1d4d7add306d60f196"][walletAddress]).to.equal("0") // -1200: Lakers-beat-celtics + pistons-beat-bulls
      expect(balances_["cf86e1d05088445c94bfc5556e8a9582c69148162187ee992bf4338198ce3c3e"][walletAddress]).to.equal("0") // Unchanged: bulls-beat-pistons + celts-beat-lakers
    })
  })
})