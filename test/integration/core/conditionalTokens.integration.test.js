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
// let conditionId
// let outcomeSlotCount;
// let parentCollectionId;
// let indexSetIN;
// let indexSetOUT;
// let collectionIdIN;
// let collectionIdOUT;
// let positionIdIN;
// let positionIdOUT;
let collectionIds;

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
    resolutionAgent = walletAddress2,

    // to track collectionIds
    collectionIds = []

    // // to get collectionId
    // parentCollectionId = "", // from collateral
    // indexSetIN = "1", // 1 for IN, 2 for OUT
    // indexSetOUT = "2", // 1 for IN, 2 for OUT
    
    // // Expected:
    // conditionId = "2d175f731624549c34fe14840990e92d610d63ea205028af076ec5cbef4e231c",
    // collectionIdIN = "45f9415be8dff7be6a906246c469f46730bccd9984486f4ad316cf90eb2e951d",
    // collectionIdOUT = "4c028af9b5b5f60457c96be27af32080a9adce728390919566bb2fcbd03d65f9",
    // positionIdIN = "c142089dc805ae34099deb85df86d1b7ed1350416d6b95f7b6f714c7a47d21ee",
    // positionIdOUT = "1cea0591a5ef57897cb99c865e7e9101ae8dbf23bb520595bc301cbf09f9be66"
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
      const partition = [0b000000111, 0b000111000, 0b111000000] // Binary decimals labelled A, B, C
      const quantity = "100"

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

      expect(action_2).to.equal("Position-Split-Notice")
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

      expect(action_2).to.equal("Position-Split-Notice")
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

      expect(action_2).to.equal("Position-Split-Notice")
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
      const outcomeBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'OutcomeBalances').value)

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
      expect(outcomeBalances_0[0]).to.equal("16")
      expect(outcomeBalances_0[1]).to.equal("1")

      expect(action_1).to.equal("Mint-Single-Notice")
      expect(tokenId_1).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(quantity_1).to.equal("2")

      expect(action_2).to.equal("Positions-Merge-Notice")
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

      
      console.log("Messages.length", Messages.length)

      console.log("Messages[0].Tags", Messages[0].Tags)
      console.log("Messages[1].Tags", Messages[1].Tags)


      expect(Messages.length).to.be.equal(2)

      // conditional-token notice
      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const outcomeBalances_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'OutcomeBalances').value)

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
      expect(outcomeBalances_0[0]).to.equal("30")
      expect(outcomeBalances_0[1]).to.equal("30")
      expect(outcomeBalances_0[2]).to.equal("9")

      expect(action_1).to.equal("Transfer")
      expect(quantity_1).to.equal("70")
      expect(recipient_1).to.equal(walletAddress)
      expect(xAction_1).to.equal("Positions-Merge-Completion")
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
          { name: "Quantities", value: JSON.stringify(['4']) },
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

      console.log("Messages[0].Tags", Messages[0].Tags)
      console.log("Messages[1].Tags", Messages[1].Tags)

      const action_0 = Messages[0].Tags.find(t => t.name === 'Action').value
      const quantities_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'Quantities').value)
      const tokenIds_0 = JSON.parse(Messages[0].Tags.find(t => t.name === 'TokenIds').value)
      const recipient_0 = Messages[0].Tags.find(t => t.name === 'Recipient').value
    
      const action_1 = Messages[1].Tags.find(t => t.name === 'Action').value
      const quantities_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'Quantities').value)
      const tokenIds_1 = JSON.parse(Messages[1].Tags.find(t => t.name === 'TokenIds').value)
      const sender_1 = Messages[1].Tags.find(t => t.name === 'Sender').value
    
      expect(action_0).to.equal("Debit-Batch-Notice")
      expect(quantities_0[0]).to.equal("4")
      expect(tokenIds_0[0]).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(recipient_0).to.equal(walletAddress2)

      expect(action_1).to.equal("Credit-Batch-Notice")
      expect(quantities_1[0]).to.equal("4")
      expect(tokenIds_1[0]).to.equal("2a569cefec1dce1f4013ee059b66a1c0987ccdf1eeb7694582c9f47c44f1cc06")
      expect(sender_1).to.equal(walletAddress)
    })
  })

  /************************************************************************ 
  * Reporting
  ************************************************************************/
  // describe("Prepare Condition", function () {
  //   it("-ve should not allow reporting (incorrect resolution agent)", async () => {
  //   })

  //   it("-ve should not allow reporting (incorrect question id)", async () => {
  //   })

  //   it("-ve should not allow reporting (no slots)", async () => {
  //   })

  //   it("-ve should not allow reporting (wrong number of slots)", async () => {
  //   })

  //   it("-ve should not allow reporting (zero payouts in all slots)", async () => {
  //   })

  //   it("+ve should allow reporting (and send notice)", async () => {
  //   })

  //   it("+ve should get payout numerators (post reporting)", async () => {
  //   })

  //   it("+ve should get payout denominator (post reporting)", async () => {
  //   })
  // })

  /************************************************************************ 
  * Redeeming
  ************************************************************************/
  // describe("Redeeming", function () {
  //   it("+ve should redeem (and send notice)", async () => {
  //   })

  //   it("+ve should verify zerod-out redeemed positions (and not affect others)", async () => {
  //   })
  // })
  /************************************************************************ 
  * Parlays
  ************************************************************************/
  // describe("Parlays", function () {
  //   it("+ve should create 2-way parlay", async () => {
  //   })

  //   it("+ve should create 2-way parlay", async () => {
  //   })

  //   it("+ve should verify 3-way parlay", async () => {
  //   })

  //   it("+ve should verify 5-way parlay", async () => {
  //   })

  //   it("+ve should verify 7-way parlay", async () => {
  //   })
  // })
})