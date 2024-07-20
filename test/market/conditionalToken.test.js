import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../aos.helper.js'
import fs from 'node:fs'
import keccak256 from 'keccak256'

const genRanHex = size => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

/* 
 * LOAD MODULE
 */
test('load conditionalToken module', async () => {
  const code = fs.readFileSync('./src/market/conditionalToken.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["conditionalToken"] = _load()
      return "ok"
    `
  })

  assert.equal(result.Output.data.output, "ok")
})

/* 
 * LOAD MOCK COLLATERAL TOKEN
 */
test('load mock collateral token module', async () => {
  const code = fs.readFileSync('./src/mock/token.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["conditionalToken"] = _load()
      return "ok"
    `
  })

  assert.equal(result.Output.data.output, "ok")
})

// NOTE: This test passes but makes unit tests hang.. 
// test('mock collateral token balance', async () => {
//   const result = await Send({
//     From: "1234",
//     Action: 'Balances',
//     Data: ''
//   })

//   const balances = JSON.parse(result.Messages[0].Data)

//   assert.equal(balances["9876"], '10000000000000000')
// })

/* 
 * TEST MODULE
 */

/* 
 * Prepare Condition
 */
test('Prepare-Condition: should not be able to prepare a condition with no outcome slots', async () => {
  const resolutionAgent = '123';
  // non-random questionId
  const questionId = '1234';
  const outcomeSlotCount = 0;

  const result = await Send({
    From: "1234",
    Action: 'Prepare-Condition',
    Data: JSON.stringify({
      resolutionAgent: resolutionAgent,
      questionId: questionId,
      outcomeSlotCount: outcomeSlotCount
    })
  })

  assert.match(result, /there should be more than one outcome slot/)
})

test('Prepare-Condition: should not be able to prepare a condition with just one outcome slot', async () => {
  const resolutionAgent = '123';
  // randomize questionId
  const questionId = genRanHex(64);
  const outcomeSlotCount = 1;

  const result = await Send({
    From: "1234",
    Action: 'Prepare-Condition',
    Data: JSON.stringify({
      resolutionAgent: resolutionAgent,
      questionId: questionId,
      outcomeSlotCount: outcomeSlotCount
    })
  })

  assert.match(result, /there should be more than one outcome slot/)
})

test('Prepare-Condition: should send a Condition-Preparation-Notice', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;

  const result = await Send({
    From: "1234",
    Action: 'Prepare-Condition',
    Data: JSON.stringify({
      resolutionAgent: resolutionAgent,
      questionId: questionId,
      outcomeSlotCount: outcomeSlotCount
    })
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const questionId_ = result.Messages[0].Tags.find(t => t.name === 'QuestionId').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const resolutionAgent_ = result.Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  const outcomeSlotCount_ = result.Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  assert.equal(action_, "Condition-Preparation-Notice")
  assert.equal(questionId_, questionId)
  assert.equal(conditionId_, keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
  assert.equal(resolutionAgent_, resolutionAgent)
  assert.equal(outcomeSlotCount_, outcomeSlotCount)
})

test('Prepare-Condition: should make outcome slot count available via Get-Outcome-Slot-Count', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  // same values as previous test
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Outcome-Slot-Count',
    ConditionId: conditionId,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const outcomeSlotCount_ = result.Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  assert.equal(action_, "Outcome-Slot-Count")
  assert.equal(conditionId_, conditionId)
  assert.equal(outcomeSlotCount_, outcomeSlotCount)
})

test('Prepare-Condition: should leave payout denominator unset', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  // same values as previous test
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Denominator',
    ConditionId: conditionId,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const denominator_ = result.Messages[0].Tags.find(t => t.name === 'Denominator').value

  assert.equal(action_, "Denominator")
  assert.equal(conditionId_, conditionId)
  // should be zero / unset
  assert.equal(denominator_, 0)
})

test('Prepare-Condition: should not be able to prepare the same condition more than once', async () => {
  const resolutionAgent = '123';
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;

  const result = await Send({
    From: "1234",
    Action: 'Prepare-Condition',
    Data: JSON.stringify({
      resolutionAgent: resolutionAgent,
      questionId: questionId,
      outcomeSlotCount: outcomeSlotCount
    })
  })

  assert.match(result, /condition already prepared/)
})

/* 
 * Split Position
 */
test('Split-Position: should not split on unprepared conditions', async () => {
  const resolutionAgent = "123";
  // randomize questionId
  const questionId = genRanHex(64);
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  // Binary decimals 1, 2, 4: labelled A, B, C
  // const partition = [0b001, 0b010, 0b100] 

  // Binary decimals 7, 56, 448: 3 options each with 3**2 9 propper subsets, 81 combinations in total
  const partition = [0b000000111, 0b000111000, 0b111000000] 
  const quantity = '100'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: partition,
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  assert.match(result, /condition not prepared yet/)
})

test('Split-Position: should not split if given index sets arent disjoint', async () => {
  const resolutionAgent = "123";
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  const quantity = '100'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: [0b000000111, 0b000111000, 0b111000111], // partition not disjoint
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  assert.match(result, /partition not disjoint/)
})

test('Split-Position: should not split if partitioning more than conditions outcome slots', async () => {
  const resolutionAgent = "123";
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  const quantity = '100'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: [0b000000001, 0b000000010, 0b000000100, 0b000001000, 0b000010000, 0b000100000, 0b001000000, 0b010000000, 0b100000000, 0b1000000000], // partitioning more than outcome slots
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  assert.match(result, /got invalid index set/)
})

test('Split-Position: should not split if given a singleton partition', async () => {
  const resolutionAgent = "123";
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  const quantity = '100'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: [0b000000111], // singleton partition
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  assert.match(result, /got empty or singleton partition/)
})

test('Split-Position: should not split if given an incomplete singleton partition', async () => {
  const resolutionAgent = "123";
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  const quantity = '100'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: [0b000000001], // Incomplete partition
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  assert.match(result, /got empty or singleton partition/)
})

test('Split-Position: should transfer split collateral from trader with a Position-Split-Notice', async () => {
  const resolutionAgent = "123";
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  // Binary decimals 1, 2, 4: labelled A, B, C
  const partition = [0b000000111, 0b000111000, 0b111000000] 
  const quantity = '100'

  // mocking reponse from the collateral token after transfer
  const result = await Send({
    From: collateralToken,
    Action: 'Credit-Notice',
    Sender: "9876",
    Recipient: "9876",
    Quantity: quantity,
    ['X-Action']: 'Create-Position',
    ['X-ParentCollectionId']: parentCollectionId,
    ['X-ConditionId']: conditionId,
    ['X-Partition']: JSON.stringify(partition)
  })

  // semi-fungible token notice
  assert.equal(result.Messages[0].Data, "Successfully minted batch")

  // conditional-token notice
  const action_ = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const stakeholder_ = result.Messages[1].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_ = result.Messages[1].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_ = result.Messages[1].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_ = result.Messages[1].Tags.find(t => t.name === 'ConditionId').value
  const partition_ = result.Messages[1].Tags.find(t => t.name === 'Partition').value
  const quantity_ = result.Messages[1].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_, "Position-Split-Notice")
  assert.equal(stakeholder_, "9876")
  assert.equal(collateralToken_, collateralToken)
  assert.equal(parentCollectionId_, parentCollectionId)
  assert.equal(conditionId_, conditionId)
  assert.equal(JSON.stringify(partition_), JSON.stringify(partition))
  assert.equal(quantity_, quantity)
})

test('Split-Position: should Get-Collection-Id', async () => {
  const resolutionAgent = "123";
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Collection-Id',
    ParentCollectionId: "",
    ConditionId: conditionId,
    IndexSet: 0b000000111,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const parentCollectionId_ = result.Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const indexSet_ = result.Messages[0].Tags.find(t => t.name === 'IndexSet').value
  const collectionId_ = result.Messages[0].Tags.find(t => t.name === 'CollectionId').value

  assert.equal(action_, "Collection-Id")
  assert.equal(parentCollectionId_, "")
  assert.equal(conditionId_, conditionId)
  assert.equal(indexSet_, 0b000000111)
  assert.equal(collectionId_, "8d59b8b8776d713d497228f1122692bed70be6c1fe8feb9031e43c51f273f94f")
})

test('Split-Position: should Get-Position-Id', async () => {
  const collateralToken = "9876"
  const collectionId = "8d59b8b8776d713d497228f1122692bed70be6c1fe8feb9031e43c51f273f94f"

  const result = await Send({
    From: "1234",
    Action: 'Get-Position-Id',
    CollateralToken: collateralToken,
    CollectionId: collectionId,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const collateralToken_ = result.Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  const collectionId_ = result.Messages[0].Tags.find(t => t.name === 'CollectionId').value
  const positionId_ = result.Messages[0].Tags.find(t => t.name === 'PositionId').value

  assert.equal(action_, "Position-Id")
  assert.equal(collateralToken_, collateralToken)
  assert.equal(collectionId_, collectionId)
  assert.equal(positionId_, "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")
})

test('Split-Position: should mint amounts in positions associated with partition verified with Balances-Of', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-Of',
    TokenId: "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532",
    Data: ''
  })

  const balancesOfId = JSON.parse(result.Messages[0].Data)
  assert.equal(balancesOfId["9876"], '100')
})

test('Split-Position: should mint amounts in positions associated with partition verified with Balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '100')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
})


test('Split-Position: New Prepare-Condition: should send a Condition-Preparation-Notice', async () => {
  // non-randomized questionId
  const questionId = 'NEW-NON-RANDOM';
  const outcomeSlotCount = 2;
  const resolutionAgent = '456';

  const result = await Send({
    From: "1234",
    Action: 'Prepare-Condition',
    Data: JSON.stringify({
      resolutionAgent: resolutionAgent,
      questionId: questionId,
      outcomeSlotCount: outcomeSlotCount
    })
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const questionId_ = result.Messages[0].Tags.find(t => t.name === 'QuestionId').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const resolutionAgent_ = result.Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  const outcomeSlotCount_ = result.Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value

  assert.equal(action_, "Condition-Preparation-Notice")
  assert.equal(questionId_, questionId)
  assert.equal(conditionId_, keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex'))
  assert.equal(resolutionAgent_, resolutionAgent)
  assert.equal(outcomeSlotCount_, outcomeSlotCount)
})

test('Split-Position: should split from a parentCollection from the same condition and send a Position-Split-Notice', async () => {
  const resolutionAgent = "123";
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  // collateralToken supplied even though splitting from parent
  const collateralToken = "9876"

  // collectionId for indexSet: 0b000000111
  const parentCollectionId = "8d59b8b8776d713d497228f1122692bed70be6c1fe8feb9031e43c51f273f94f"

  // partition to be disjoint set of parent
  const partition = [0b000000110, 0b000000001]
  
  const quantity = '20'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: partition,
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  // burn notice
  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantity_0 = result.Messages[0].Tags.find(t => t.name === 'Quantity').value
  const tokenId_0 = result.Messages[0].Tags.find(t => t.name === 'TokenId').value
  assert.equal(action_0, "Burn-Single-Notice")
  assert.equal(quantity_0, "20")
  assert.equal(tokenId_0, "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")

  // mint notice
  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantities_1 = result.Messages[1].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_1 = result.Messages[1].Tags.find(t => t.name === 'TokenIds').value
  assert.equal(action_1, "Mint-Batch-Notice")
  assert.equal(JSON.parse(quantities_1)[0], "20")
  assert.equal(JSON.parse(quantities_1)[1], "20")
  assert.equal(JSON.parse(tokenIds_1)[0], "35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01")
  assert.equal(JSON.parse(tokenIds_1)[1], "b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335")

  //position-split notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Position-Split-Notice")
  assert.equal(stakeholder_2, "9876")
  assert.equal(collateralToken_2, collateralToken)
  assert.equal(parentCollectionId_2, parentCollectionId)
  assert.equal(conditionId_2, conditionId)
  assert.equal(JSON.stringify(partition_2), JSON.stringify(partition))
  assert.equal(quantity_2, quantity)
})

test('Split-Position: should return updated balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '80')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
})

test('Split-Position: should transfer LO/HI split collateral from trader with a Position-Split-Notice', async () => {
  // non-randomized questionId
  const questionId = 'NEW-NON-RANDOM';
  const outcomeSlotCount = 2;
  const resolutionAgent = '456';
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const collateralToken = "9876"
  const parentCollectionId = ""
  // Binary decimals LO/HI
  const partition = [0b01, 0b10] 
  const quantity = '100'

  // mocking reponse from the collateral token after transfer
  const result = await Send({
    From: collateralToken,
    Action: 'Credit-Notice',
    Sender: "9876",
    Recipient: "9876",
    Quantity: quantity,
    ['X-Action']: 'Create-Position',
    ['X-ParentCollectionId']: parentCollectionId,
    ['X-ConditionId']: conditionId,
    ['X-Partition']: JSON.stringify(partition)
  })

  // semi-fungible token notice
  assert.equal(result.Messages[0].Data, "Successfully minted batch")

  // conditional-token notice
  const action_ = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const stakeholder_ = result.Messages[1].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_ = result.Messages[1].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_ = result.Messages[1].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_ = result.Messages[1].Tags.find(t => t.name === 'ConditionId').value
  const partition_ = result.Messages[1].Tags.find(t => t.name === 'Partition').value
  const quantity_ = result.Messages[1].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_, "Position-Split-Notice")
  assert.equal(stakeholder_, "9876")
  assert.equal(collateralToken_, collateralToken)
  assert.equal(parentCollectionId_, parentCollectionId)
  assert.equal(conditionId_, conditionId)
  assert.equal(JSON.stringify(partition_), JSON.stringify(partition))
  assert.equal(quantity_, quantity)
})

test('Split-Position: should return updated balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  // original
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '80')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
  // split
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '100')

})

test('Split-Position: should Get-Collection-Id for LO vs HI', async () => {
  // non-randomized questionId
  const questionId = 'NEW-NON-RANDOM';
  const outcomeSlotCount = 2;
  const resolutionAgent = '456';
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Collection-Id',
    ParentCollectionId: "",
    ConditionId: conditionId,
    IndexSet: 0b01,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const parentCollectionId_ = result.Messages[0].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const indexSet_ = result.Messages[0].Tags.find(t => t.name === 'IndexSet').value
  const collectionId_ = result.Messages[0].Tags.find(t => t.name === 'CollectionId').value

  assert.equal(action_, "Collection-Id")
  assert.equal(parentCollectionId_, "")
  assert.equal(conditionId_, conditionId)
  assert.equal(indexSet_, 0b01)
  assert.equal(collectionId_, "d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c")
})

//@dev ref: https://docs.gnosis.io/conditionaltokens/docs/devguide05
//@dev this is the same as LO -> LO&A, LO&B, LO&C
test('Split-Position: should split from a parentCollection from a different condition and send a Position-Split-Notice', async () => {
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const resolutionAgent = "123";
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  // collateralToken supplied even though splitting from parent
  const collateralToken = "9876"

  // collectionId for indexSet: NEW-NON-RANDOM 0b01
  const parentCollectionId = "d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c"

  // partition to be disjoint sets A, B and C
  const partition = [0b111000000, 0b000111000, 0b000000111]
  
  const quantity = '30'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: partition,
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  // console.log("result", result)
  // console.log("Tags0", result.Messages[0].Tags)
  // console.log("Tags1", result.Messages[1].Tags)
  // console.log("Tags2", result.Messages[2].Tags)

  // burn notice
  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantity_0 = result.Messages[0].Tags.find(t => t.name === 'Quantity').value
  const tokenId_0 = result.Messages[0].Tags.find(t => t.name === 'TokenId').value
  assert.equal(action_0, "Burn-Single-Notice")
  assert.equal(quantity_0, "30")
  assert.equal(tokenId_0, "9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5")

  // mint notice
  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantities_1 = result.Messages[1].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_1 = result.Messages[1].Tags.find(t => t.name === 'TokenIds').value
  assert.equal(action_1, "Mint-Batch-Notice")
  assert.equal(JSON.parse(quantities_1)[0], "30")
  assert.equal(JSON.parse(quantities_1)[1], "30")
  assert.equal(JSON.parse(tokenIds_1)[0], "9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80")
  assert.equal(JSON.parse(tokenIds_1)[1], "6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c")
  assert.equal(JSON.parse(tokenIds_1)[2], "1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b")

  //position-split notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Position-Split-Notice")
  assert.equal(stakeholder_2, "9876")
  assert.equal(collateralToken_2, collateralToken)
  assert.equal(parentCollectionId_2, parentCollectionId)
  assert.equal(conditionId_2, conditionId)
  assert.equal(JSON.stringify(partition_2), JSON.stringify(partition))
  assert.equal(quantity_2, quantity)
})

test('Split-Position: should return updated balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  // original: $ -> (A,B,C|D) ?
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '80')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
  // split: C|D -> (C,D) 
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new HI|LO ?
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '70') 
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  // new split: LO -> (LO&A, LO&B, LO&C|D)
  assert.equal(balances["9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80"]["9876"], '30')
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '30')
  assert.equal(balances["6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c"]["9876"], '30') 
})

//@dev "communicative" meaning that "$->A->LO" == "$->LO->A"
//@dev ref: https://docs.gnosis.io/conditionaltokens/docs/devguide05
//@dev this is the same as A -> A&LO, A&HI
test('Split-Position: the chaining of conditionals should be communicative', async () => {
  // non-randomized questionId
  const questionId = 'NEW-NON-RANDOM';
  const outcomeSlotCount = 2;
  const resolutionAgent = '456';
  
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  
  // collateralToken supplied even though splitting from parent
  const collateralToken = "9876"

  // collectionId for indexSet: NON-RANDOM 0b000000111
  const parentCollectionId = "8d59b8b8776d713d497228f1122692bed70be6c1fe8feb9031e43c51f273f94f"

  // partition to be only available disjoint set LO|HI
  const partition = [0b01, 0b10]
  
  const quantity = '60'

  const result = await Send({
    From: "9876",
    Action: 'Split-Position',
    Recipient: "9876",
    Data: JSON.stringify({
      collateralToken: collateralToken,
      conditionId: conditionId,
      partition: partition,
      parentCollectionId: parentCollectionId,
      quantity: quantity
    })
  })

  // console.log("result2:", result)

  // console.log("#2::", result.Messages[1].Tags)

  // burn notice
  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantity_0 = result.Messages[0].Tags.find(t => t.name === 'Quantity').value
  const tokenId_0 = result.Messages[0].Tags.find(t => t.name === 'TokenId').value
  assert.equal(action_0, "Burn-Single-Notice")
  assert.equal(quantity_0, "60")
  assert.equal(tokenId_0, "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")

  // mint notice
  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantities_1 = result.Messages[1].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_1 = result.Messages[1].Tags.find(t => t.name === 'TokenIds').value
  assert.equal(action_1, "Mint-Batch-Notice")
  assert.equal(JSON.parse(quantities_1)[0], "60")
  assert.equal(JSON.parse(quantities_1)[1], "60")
  assert.equal(JSON.parse(tokenIds_1)[0], "1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b")
  assert.equal(JSON.parse(tokenIds_1)[1], "0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1")

  //position-split notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Position-Split-Notice")
  assert.equal(stakeholder_2, "9876")
  assert.equal(collateralToken_2, collateralToken)
  assert.equal(parentCollectionId_2, parentCollectionId)
  assert.equal(conditionId_2, conditionId)
  assert.equal(JSON.stringify(partition_2), JSON.stringify(partition))
  assert.equal(quantity_2, quantity)
})

test('Split-Position: should return updated balances to prove commuicativity', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  // original: $ -> (A,B,C|D) ?
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '20')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
  // split: C|D -> (C,D) 
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new HI|LO ?
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '70')
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  // new split: LO -> (LO&A, LO&B, LO&C|D)
  assert.equal(balances["9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80"]["9876"], '30')
  assert.equal(balances["6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c"]["9876"], '30') 
  // Updated communicative position: A&LO (30+60=90)
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '90') 
  // new split position: A&HI
  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["9876"], '60')
})


// test('Split-Position: DEBUGING: should Get-Collection-Id for all options', async () => {
//   // non-random questionId
//   const questionId1 = 'NON-RANDOM';
//   const outcomeSlotCount1 = 9;
//   const resolutionAgent1 = "123";
//   const conditionId1 = keccak256(resolutionAgent1 + questionId1 + outcomeSlotCount1.toString()).toString('hex')
//   console.log("conditionId1: ", conditionId1)

//   const questionId2 = 'NEW-NON-RANDOM';
//   const outcomeSlotCount2 = 2;
//   const resolutionAgent2 = '456';
//   const conditionId2 = keccak256(resolutionAgent2 + questionId2 + outcomeSlotCount2.toString()).toString('hex')
//   console.log("conditionId2: ", conditionId2)

//   const result1A = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "",
//     ConditionId: conditionId1,
//     IndexSet: 0b111000000,
//     Data: ''
//   })

//   const result1B = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "",
//     ConditionId: conditionId1,
//     IndexSet: 0b000111000,
//     Data: ''
//   })

//   const result1C = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "",
//     ConditionId: conditionId1,
//     IndexSet: 0b000000111,
//     Data: ''
//   })

//   const result2LO = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "",
//     ConditionId: conditionId2,
//     IndexSet: 0b01,
//     Data: ''
//   })

//   const result2HI = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "",
//     ConditionId: conditionId2,
//     IndexSet: 0b10,
//     Data: ''
//   })


//   const result3ALO = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "e59bbfca7f21558e32ea865ecad1af2db6b756e950c832698d19aadd4e8613",
//     ConditionId: conditionId2,
//     IndexSet: 0b01,
//     Data: ''
//   })

//   const result3LOA = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c",
//     ConditionId: conditionId1,
//     IndexSet: 0b111000000,
//     Data: ''
//   })

//   const collectionId_1A = result1A.Messages[0].Tags.find(t => t.name === 'CollectionId').value
//   const collectionId_1B = result1B.Messages[0].Tags.find(t => t.name === 'CollectionId').value
//   const collectionId_1C = result1C.Messages[0].Tags.find(t => t.name === 'CollectionId').value

//   const collectionId_2LO = result2LO.Messages[0].Tags.find(t => t.name === 'CollectionId').value
//   const collectionId_2HI = result2HI.Messages[0].Tags.find(t => t.name === 'CollectionId').value

//   const collectionId_3ALO = result3ALO.Messages[0].Tags.find(t => t.name === 'CollectionId').value
//   const collectionId_3LOA = result3LOA.Messages[0].Tags.find(t => t.name === 'CollectionId').value

//   console.log("collectionId_1A:", collectionId_1A)
//   console.log("collectionId_1B:", collectionId_1B)
//   console.log("collectionId_1C:", collectionId_1C)

//   console.log("collectionId_2LO:", collectionId_2LO)
//   console.log("collectionId_2HI:", collectionId_2HI)

//   console.log("collectionId_3ALO:", collectionId_3ALO)
//   console.log("collectionId_3LOA:", collectionId_3LOA)
//   assert.equal(1,1)

//   // conditionId1:  c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e
//   // conditionId2:  39d12384576676750865a5858a66e2b6ca1fcdfd2654edda2df449d13a766668

//   // collectionId_1A: e59bbfca7f21558e32ea865ecad1af2db6b756e950c832698d19aadd4e8613
//   // collectionId_1B: b41336408b94c2733a4eddd742f4d10c41527420736cd89a886e3019fc3c26
//   // collectionId_1C: 8d59b8b8776d713d497228f1122692bed70be6c1fe8feb9031e43c51f273f94f

//   // collectionId_2LO: d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c
//   // collectionId_2HI: 4afcad2359f4198771e4e984d91b9634cacc0ec652961257bb7fd37654870ef

//   // collectionId_3ALO: f1b18e32af1732517810ab3b2b117fc29d122133b6e81b215910bbb13f7d142c8b0ee10e1768d87f1ae13ad312a83
//   // collectionId_3LOA: fe169e513cbc93ce9b19e44f1136104bdab18cf1b316677fe591b98f7cce8ac1fa11a122e4e31857711d9d13cb

//   // Params:
//   // A -> LO
//   // parent: e59bbfca7f21558e32ea865ecad1af2db6b756e950c832698d19aadd4e8613
//   // conditionId: 39d12384576676750865a5858a66e2b6ca1fcdfd2654edda2df449d13a766668
//   // indexSet: 0b01

//   // LO -> A
//   // parent: d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c
//   // conditionId: c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e
//   // indexSet: 0b111000000

//   const resultTestALO = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "e59bbfca7f21558e32ea865ecad1af2db6b756e950c832698d19aadd4e8613",
//     ConditionId: "39d12384576676750865a5858a66e2b6ca1fcdfd2654edda2df449d13a766668",
//     IndexSet: 0b01,
//     Data: ''
//   })

//   const resultTestLOA = await Send({
//     From: "1234",
//     Action: 'Get-Collection-Id',
//     ParentCollectionId: "d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c",
//     ConditionId: "c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e",
//     IndexSet: 0b111000000,
//     Data: ''
//   })

//   const collectionId_TestALO = resultTestALO.Messages[0].Tags.find(t => t.name === 'CollectionId').value
//   const collectionId_TestLOA = resultTestLOA.Messages[0].Tags.find(t => t.name === 'CollectionId').value

//   console.log("collectionId_TestALO:", collectionId_TestALO)
//   console.log("collectionId_TestLOA:", collectionId_TestLOA)
//   assert.equal(1,1)

//   const collectionIdA1 = keccak256("c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e" + 0b111000000).toString('hex')
//   console.log("collectionIdA1:", collectionIdA1)

//   const collectionIdA2 = keccak256("c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e" + 7).toString('hex')
//   console.log("collectionIdA2:", collectionIdA2)

//   const resultTest2ALO = await Send({
//     From: "1234",
//     Action: 'Get-Collection-H12',
//     ParentCollectionId: "e59bbfca7f021558e32ea865ecad1af2db6b7506e950c832698d19aadd4e8613",
//     ConditionId: "39d12384576676750865a5858a66e2b6ca1fcdfd2654edda2df449d13a766668",
//     IndexSet: 0b01,
//     Data: ''
//   })

//   const resultTest2LOA = await Send({
//     From: "1234",
//     Action: 'Get-Collection-H12',
//     ParentCollectionId: "d710212253c2207fd21f9b57be9d8cb16b9fa7e1a7efb58e52e9ad73c018984c",
//     ConditionId: "c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e",
//     IndexSet: 0b111000000,
//     Data: ''
//   })

//   // console.log("resultTest2ALO", resultTest2ALO)

//   const alo_h1 = resultTest2ALO.Messages[0].Tags.find(t => t.name === 'H1').value
//   const alo_h2 = resultTest2ALO.Messages[0].Tags.find(t => t.name === 'H2').value
  
//   const loa_h1 = resultTest2LOA.Messages[0].Tags.find(t => t.name === 'H1').value
//   const loa_h2 = resultTest2LOA.Messages[0].Tags.find(t => t.name === 'H2').value

//   const alo_res = resultTest2ALO.Messages[0].Tags.find(t => t.name === 'Result').value
//   const loa_res = resultTest2LOA.Messages[0].Tags.find(t => t.name === 'Result').value
  
//   console.log("alo_h1>e", alo_h1)
//   console.log("loa_h1", loa_h1)

//   console.log("alo_h2", alo_h2)
//   console.log("loa_h2", loa_h2)

//   console.log("alo_res", alo_res)
//   console.log("loa_res", loa_res)
// })


// /* 
//  * Merge Position
//  */
// test('Merge-Position: should not merge if amount exceeds balances in to-be-merged positions', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Merge-Position: should send a Positions-Merge-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Merge-Position: should transfer split collateral back to trader', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Merge-Position: should burn amounts in positions associated with partition', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Transferring: should not allow transferring more than split balance', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not allow reporting by incorrect resolution agent', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not allow report with wrong questionId', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not allow report with no slots', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not allow report with wrong number of slots', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not allow report with zero payouts in all slots', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should not merge if any amount is short', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should send Condition-Resolution-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Reporting: should make reported payout numerators available', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Redeeming: should send Payout-Redemption-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Redeeming: should zero out redeemed positions', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Redeeming: should not affect others positions', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Redeeming: should credit payout as collateral', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: combines collection IDs', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: sends Position-Split-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: burns value in the parent position', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: mints values in the child positions', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: should send Condition-Resolution-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: should reflect report via payoutNumerators', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: should not allow an update to the report', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: with valid redemption', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })

// test('Trader enters deeper position with another condition: should send Payout-Redemption-Notice', async () => {
//   const resolutionAgent = '123';
//     // randomize questionId
//   const questionId = genRanHex(64);
//   const outcomeSlotCount = 2;

//   const result = await Send({
//     From: "1234",
//     Action: 'Prepare-Condition',
//     Data: JSON.stringify({
//       resolutionAgent: resolutionAgent,
//       questionId: questionId,
//       outcomeSlotCount: outcomeSlotCount
//     })
//   })

//   console.log("result", result)
//   assert.equal(result.Output.data.output, "ok")
// })