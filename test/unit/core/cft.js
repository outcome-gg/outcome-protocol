// @dev: commented out tests. failing because `module '.ao' not found` 
import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'
import keccak256 from 'keccak256'

const genRanHex = size => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

/* 
 * LOAD MODULE
 */
test('load conditionalTokens module', async () => {
  const code = fs.readFileSync('./src/core/conditionalTokens.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["conditionalTokens"] = _load()
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
      _G.package.loaded["token"] = _load()
      return "ok"
    `
  })

  assert.equal(result.Output.data.output, "ok")
})

test('mock collateral token balance', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)

  assert.equal(balances["9876"], '10000000000000000')
})

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

test('Split-Position: should transfer split collateral from trader with a Split-Position-Notice', async () => {
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
  assert.equal(action_, "Split-Position-Notice")
  assert.equal(stakeholder_, "9876")
  assert.equal(collateralToken_, collateralToken)
  assert.equal(parentCollectionId_, parentCollectionId)
  assert.equal(conditionId_, conditionId)
  assert.equal(partition_, JSON.stringify(partition))
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

test('Split-Position: should mint amounts in positions associated with partition verified with Balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    TokenId: "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532",
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  assert.equal(balances["9876"], '100')
})

test('Split-Position: should mint amounts in positions associated with partition verified with Balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '100')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '100')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '100')
})

test('Split-Position: collateralToken should have been transferred from trader', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)

  assert.equal(balances["9876"], '10000000000000000')
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

test('Split-Position: [balance] should have a balance of tokenId 4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532', async () => {
  const result = await Send({
    From: "9876",
    Action: 'Balance',
    TokenId: '4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532'
  })

  console.log("balance result", result.Messages[0].Tags)
})

test('Split-Position: should split from a parentCollection from the same condition and send a Split-Position-Notice', async () => {
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

  console.log("result", result)

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

  //split-position notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Split-Position-Notice")
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
    Action: 'Balances-All',
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

test('Split-Position: should transfer LO/HI split collateral from trader with a Split-Position-Notice', async () => {
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
  assert.equal(action_, "Split-Position-Notice")
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
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
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
test('Split-Position: should split from a parentCollection from a different condition and send a Split-Position-Notice', async () => {
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

  //split-position notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Split-Position-Notice")
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
    Action: 'Balances-All',
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

  //split-position notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Split-Position-Notice")
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
    Action: 'Balances-All',
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

/* 
 * Merge Position
 */
//@dev inputs to marge split from previous unit test
test('Merge-Position: should not merge if amount exceeds balances in to-be-merged positions', async () => {
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

  const result = await Send({
    From: "9876",
    Action: 'Merge-Positions',
    Data: JSON.stringify({
      collateralToken: collateralToken,
      parentCollectionId: parentCollectionId,
      conditionId: conditionId,
      partition: partition,
      quantity: 100  // balance 90
    })
  })

  assert.match(result, /User must have sufficient tokens!/)
})

//@dev inputs to marge split from previous "split" unit test
test('Merge-Position: should merge deeper-level positions and send a Merge-Positions-Notice', async () => {
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

  // within balance (90)
  const quantity = 30

  const result = await Send({
    From: "9876",
    Action: 'Merge-Positions',
    Data: JSON.stringify({
      collateralToken: collateralToken,
      parentCollectionId: parentCollectionId,
      conditionId: conditionId,
      partition: partition,
      quantity: quantity 
    })
  })
  
  // burn notice
  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantities_0 = result.Messages[0].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_0 = result.Messages[0].Tags.find(t => t.name === 'TokenIds').value
  assert.equal(action_0, "Burn-Batch-Notice")
  assert.equal(JSON.parse(quantities_0)[0], "30")
  assert.equal(JSON.parse(quantities_0)[1], "30")
  assert.equal(JSON.parse(tokenIds_0)[0], "1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b")
  assert.equal(JSON.parse(tokenIds_0)[1], "0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1")

  // mint notice
  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantity_1 = result.Messages[1].Tags.find(t => t.name === 'Quantity').value
  const tokenId_1 = result.Messages[1].Tags.find(t => t.name === 'TokenId').value
  assert.equal(action_1, "Mint-Single-Notice")
  assert.equal(quantity_1, "30")
  assert.equal(tokenId_1, "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")
  
  //position-merge notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Merge-Positions-Notice")
  assert.equal(stakeholder_2, "9876")
  assert.equal(collateralToken_2, collateralToken)
  assert.equal(parentCollectionId_2, parentCollectionId)
  assert.equal(conditionId_2, conditionId)
  assert.equal(JSON.stringify(partition_2), JSON.stringify(partition))
  assert.equal(quantity_2, quantity)
})

test('Merge-Position: should return lower-level position tokens to the trader', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  // original: $ -> (A,B,C|D) ?
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '50')
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
  // Updated communicative position: A&LO (90-30 = 60)
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '60') 
  // new split position: A&HI (60-30 = 30)
  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["9876"], '30')
})

//@dev inputs to marge split from first "split" unit test
test('Merge-Position: should merge first-level positions and send a Merge-Positions-Notice', async () => {
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const resolutionAgent = '123';
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  // collateralToken supplied even though splitting from parent
  const collateralToken = "9876"

  // parent is collateral token
  const parentCollectionId = ""

  // full partition
  const partition = [0b111000000, 0b000111000, 0b000000111]

  // within balance 
  const quantity = 10

  const result = await Send({
    From: "9876",
    Action: 'Merge-Positions',
    Data: JSON.stringify({
      collateralToken: collateralToken,
      parentCollectionId: parentCollectionId,
      conditionId: conditionId,
      partition: partition,
      quantity: quantity 
    })
  })
  
  // burn notice
  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantities_0 = result.Messages[0].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_0 = result.Messages[0].Tags.find(t => t.name === 'TokenIds').value
  assert.equal(action_0, "Burn-Batch-Notice")
  assert.equal(JSON.parse(quantities_0)[0], quantity.toString())
  assert.equal(JSON.parse(quantities_0)[1], quantity.toString())
  assert.equal(JSON.parse(quantities_0)[2], quantity.toString())
  assert.equal(JSON.parse(tokenIds_0)[0], "0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d")
  assert.equal(JSON.parse(tokenIds_0)[1], "7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863")
  assert.equal(JSON.parse(tokenIds_0)[2], "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")
  
  // transfer notice
  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantity_1 = result.Messages[1].Tags.find(t => t.name === 'Quantity').value
  const recipient_1 = result.Messages[1].Tags.find(t => t.name === 'Recipient').value
  const fromProcess_1 = result.Messages[1].Tags.find(t => t.name === 'From-Process').value
  assert.equal(action_1, "Transfer")
  assert.equal(quantity_1, quantity.toString())
  assert.equal(recipient_1, "9876")
  assert.equal(fromProcess_1, "9876")
  
  //position-merge notice
  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const stakeholder_2 = result.Messages[2].Tags.find(t => t.name === 'Stakeholder').value
  const collateralToken_2 = result.Messages[2].Tags.find(t => t.name === 'CollateralToken').value
  const parentCollectionId_2 = result.Messages[2].Tags.find(t => t.name === 'ParentCollectionId').value
  const conditionId_2 = result.Messages[2].Tags.find(t => t.name === 'ConditionId').value
  const partition_2 = result.Messages[2].Tags.find(t => t.name === 'Partition').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value
  assert.equal(action_2, "Merge-Positions-Notice")
  assert.equal(stakeholder_2, "9876")
  assert.equal(collateralToken_2, collateralToken)
  assert.equal(parentCollectionId_2, parentCollectionId)
  assert.equal(conditionId_2, conditionId)
  assert.equal(JSON.stringify(partition_2), JSON.stringify(partition))
  assert.equal(quantity_2, quantity)
})

//@dev TODO: check that collateralTokens have been returned to trader in integration tests
test('Merge-Position: should burn positions tokens from the trader', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // original: $ -> (A,B,C|D) !sub 10 from each!
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '40')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '90')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '90')
  // split: C|D -> (C,D) 
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new HI|LO ?
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '70')
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  // new split: LO -> (LO&A, LO&B, LO&C|D)
  assert.equal(balances["9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80"]["9876"], '30')
  assert.equal(balances["6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c"]["9876"], '30') 
  // Updated communicative position: A&LO 
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '60') 
  // new split position: A&HI 
  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["9876"], '30')
  // collateral balances
})

test('Transferring: check Balance', async () => {
  const result = await Send({
    From: "9876",
    Action: 'Balance',
    TokenId: '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1'
  })

  assert.equal(result.Messages[0].Data, "30")
})

test('Transferring: should not allow single transfer by more than split balance', async () => {
  const result = await Send({
    From: "9876",
    Action: 'Transfer-Single',
    Quantity: '31',
    Recipient: '1234',
    TokenId: '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1'
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const error_ = result.Messages[0].Tags.find(t => t.name === 'Error').value
  const tokenId_ = result.Messages[0].Tags.find(t => t.name === 'Token-Id').value

  assert.equal(action_, "Transfer-Error")
  assert.equal(error_, "Insufficient Balance!")
  assert.equal(tokenId_, '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1')
})

test('Transferring: should single transfer and send notices', async () => {
  const result = await Send({
    From: "9876",
    Action: 'Transfer-Single',
    Quantity: '10',
    Recipient: '1234',
    TokenId: '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1'
  })

  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantity_0 = result.Messages[0].Tags.find(t => t.name === 'Quantity').value
  const tokenId_0 = result.Messages[0].Tags.find(t => t.name === 'TokenId').value
  const recipient_0 = result.Messages[0].Tags.find(t => t.name === 'Recipient').value

  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantity_1 = result.Messages[1].Tags.find(t => t.name === 'Quantity').value
  const tokenId_1 = result.Messages[1].Tags.find(t => t.name === 'TokenId').value
  const sender_1 = result.Messages[1].Tags.find(t => t.name === 'Sender').value

  assert.equal(action_0, "Debit-Single-Notice")
  assert.equal(quantity_0, "10")
  assert.equal(tokenId_0, '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1')
  assert.equal(recipient_0, '1234')

  assert.equal(action_1, "Credit-Single-Notice")
  assert.equal(quantity_1, "10")
  assert.equal(tokenId_1, '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1')
  assert.equal(sender_1, '9876')
})

test('Transferring: should not allow batch transfer by more than split balance', async () => {
  const result = await Send({
    From: "9876",
    Action: 'Transfer-Batch',
    Quantities: JSON.stringify(['21']),
    Recipient: '1234',
    TokenIds: JSON.stringify(['0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1'])
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const error_ = result.Messages[0].Tags.find(t => t.name === 'Error').value
  const tokenId_ = result.Messages[0].Tags.find(t => t.name === 'Token-Id').value

  assert.equal(action_, "Transfer-Error")
  assert.equal(error_, "Insufficient Balance!")
  assert.equal(tokenId_, '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1')
})

test('Transferring: should batch transfer and send notices', async () => {
  const tokenIds = JSON.stringify(['0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1', '0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1'])
  const quantities = JSON.stringify(['5', '5'])
  const result = await Send({
    From: "9876",
    Action: 'Transfer-Batch',
    Quantities: quantities,
    Recipient: '1234',
    TokenIds: tokenIds
  })

  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const quantities_0 = result.Messages[0].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_0 = result.Messages[0].Tags.find(t => t.name === 'TokenIds').value
  const recipient_0 = result.Messages[0].Tags.find(t => t.name === 'Recipient').value

  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const quantities_1 = result.Messages[1].Tags.find(t => t.name === 'Quantities').value
  const tokenIds_1 = result.Messages[1].Tags.find(t => t.name === 'TokenIds').value
  const sender_1 = result.Messages[1].Tags.find(t => t.name === 'Sender').value

  assert.equal(action_0, "Debit-Batch-Notice")
  assert.equal(quantities_0, quantities)
  assert.equal(tokenIds_0, tokenIds)
  assert.equal(recipient_0, '1234')

  assert.equal(action_1, "Credit-Batch-Notice")
  assert.equal(quantities_1, quantities)
  assert.equal(tokenIds_1, tokenIds)
  assert.equal(sender_1, '9876')
})

test('Reporting: should not allow reporting by incorrect resolution agent', async () => {
  // const resolutionAgent = '123';
  const resolutionAgent = 'WRONG-RESOLUTION-AGENT';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  // const outcomeSlotCount = 9;
  const payouts = [1,0,0,0,0,0,0,0,0]

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })
  
  assert.match(result, /condition not prepared or found/)
})

test('Reporting: should not allow report with wrong questionId', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  // const questionId = 'NON-RANDOM';
  const questionId = 'INCORRECT-ID';
  // const outcomeSlotCount = 9;
  const payouts = [1,0,0,0,0,0,0,0,0]

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })
  
  assert.match(result, /condition not prepared or found/)
})

test('Reporting: should not allow report with no slots', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  // const outcomeSlotCount = 9;
  const payouts = []

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })
  
  assert.match(result, /there should be more than one outcome slot/)
})

test('Reporting: should not allow report with wrong number of slots', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  // const outcomeSlotCount = 9;
  const payouts = [1,0,0]

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })
  
  assert.match(result, /condition not prepared or found/)
})

test('Reporting: should not allow report with zero payouts in all slots', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  // const outcomeSlotCount = 9;
  const payouts = [0,0,0,0,0,0,0,0,0]

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })
  
  assert.match(result, /payout is all zeroes/)
})

test('Reporting: should send Condition-Resolution-Notice', async () => {
  const resolutionAgent = '123';
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  // const outcomeSlotCount = 9;
  const payouts = [1,0,0,0,0,0,0,0,0]
  const conditionId = keccak256(resolutionAgent + questionId + payouts.length.toString()).toString('hex')
  

  const result = await Send({
    From: resolutionAgent,
    Action: 'Report-Payouts',
    Data: JSON.stringify({
      questionId: questionId,
      payouts: payouts
    })
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const resolutionAgent_ = result.Messages[0].Tags.find(t => t.name === 'ResolutionAgent').value
  const outcomeSlotCount_ = result.Messages[0].Tags.find(t => t.name === 'OutcomeSlotCount').value
  const questionId_ = result.Messages[0].Tags.find(t => t.name === 'QuestionId').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const payoutNumerators_ = result.Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value

  assert.equal(action_, "Condition-Resolution-Notice")
  assert.equal(resolutionAgent_, resolutionAgent)
  assert.equal(outcomeSlotCount_, '9')
  assert.equal(questionId_, questionId)
  assert.equal(conditionId_, conditionId)
  assert.equal(JSON.stringify(payoutNumerators_), JSON.stringify(payouts))
})

test('Reporting: should make reported payout numerators available', async () => {
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const resolutionAgent = '123';
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Payout-Numerators',
    ConditionId: conditionId,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const payoutNumerators_ = result.Messages[0].Tags.find(t => t.name === 'PayoutNumerators').value

  assert.equal(action_, "Payout-Numerators")
  assert.equal(conditionId_, conditionId)
  assert.equal(payoutNumerators_, JSON.stringify([1,0,0,0,0,0,0,0,0]))
})

test('Reporting: should make reported payout denomniator available', async () => {
  // non-randomized questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const resolutionAgent = '123';
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')

  const result = await Send({
    From: "1234",
    Action: 'Get-Payout-Denominator',
    ConditionId: conditionId,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const payoutDenominator_ = result.Messages[0].Tags.find(t => t.name === 'PayoutDenominator').value

  assert.equal(action_, "Payout-Denominator")
  assert.equal(conditionId_, conditionId)
  assert.equal(payoutDenominator_, "1")
})

test('Redeeming: checking conditional token balances', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // console.log("balances", balances)
  // original: $ -> (A,B,C|D) ?
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '40')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '90')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '90')
  // split: C|D -> (C,D) 
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new HI|LO ?
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '70') 
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  // new split: LO -> (LO&A, LO&B, LO&C|D)
  assert.equal(balances["9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80"]["9876"], '30')
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '60')
  assert.equal(balances["6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c"]["9876"], '30') 

  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["9876"], '10') 
  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["1234"], '20') 
})

test('Redeeming: should send Payout-Redemption-Notice', async () => {
  // non-random questionId
  const questionId = 'NON-RANDOM';
  const outcomeSlotCount = 9;
  const resolutionAgent = "123";
  const conditionId = keccak256(resolutionAgent + questionId + outcomeSlotCount.toString()).toString('hex')
  const partition =  [0b000000111, 0b000111000, 0b111000000] 
  const collateralToken = "9876"

  const result = await Send({
    From: "9876",
    Action: 'Redeem-Positions',
    Data: JSON.stringify({
      collateralToken: collateralToken,
      parentCollectionId: "",
      conditionId: conditionId,
      indexSets: partition
    })
  })

  const action_0 = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const tokenId_0 = result.Messages[0].Tags.find(t => t.name === 'TokenId').value
  const quantity_0 = result.Messages[0].Tags.find(t => t.name === 'Quantity').value

  const action_1 = result.Messages[1].Tags.find(t => t.name === 'Action').value
  const tokenId_1 = result.Messages[1].Tags.find(t => t.name === 'TokenId').value
  const quantity_1 = result.Messages[1].Tags.find(t => t.name === 'Quantity').value

  const action_2 = result.Messages[2].Tags.find(t => t.name === 'Action').value
  const tokenId_2 = result.Messages[2].Tags.find(t => t.name === 'TokenId').value
  const quantity_2 = result.Messages[2].Tags.find(t => t.name === 'Quantity').value

  const action_3 = result.Messages[3].Tags.find(t => t.name === 'Action').value
  const recipient_3 = result.Messages[3].Tags.find(t => t.name === 'Recipient').value
  const quantity_3 = result.Messages[3].Tags.find(t => t.name === 'Quantity').value

  const action_4 = result.Messages[4].Tags.find(t => t.name === 'Action').value
  const redeemer_4 = result.Messages[4].Tags.find(t => t.name === 'Redeemer').value
  const payout_4 = result.Messages[4].Tags.find(t => t.name === 'Payout').value
  const collateralToken_4 = result.Messages[4].Tags.find(t => t.name === 'CollateralToken').value
  const indexSets_4 = result.Messages[4].Tags.find(t => t.name === 'IndexSets').value
  const conditionId_4 = result.Messages[4].Tags.find(t => t.name === 'ConditionId').value
  
  assert.equal(action_0, "Burn-Single-Notice")
  assert.equal(tokenId_0, "4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532")
  assert.equal(quantity_0, "40")

  assert.equal(action_1, "Burn-Single-Notice")
  assert.equal(tokenId_1, "7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863")
  assert.equal(quantity_1, "90")

  assert.equal(action_2, "Burn-Single-Notice")
  assert.equal(tokenId_2, "0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d")
  assert.equal(quantity_2, "90")

  assert.equal(action_3, "Transfer")
  assert.equal(recipient_3, "9876")
  assert.equal(quantity_3, "40.0")

  assert.equal(action_4, "Payout-Redemption-Notice")
  assert.equal(redeemer_4, "9876")
  assert.equal(payout_4, "40.0")
  assert.equal(collateralToken_4, "9876")
  assert.equal(indexSets_4, JSON.stringify([7,56,448]))
  assert.equal(conditionId_4, "c4973b6190194a30089838ed3cdd5db1867c5137c9178223c923163ff381936e")
})

test('Redeeming: should zero out redeemed positions && not affect other positions', async () => {
  const result = await Send({
    From: "1234",
    Action: 'Balances-All',
    Data: ''
  })

  const balances = JSON.parse(result.Messages[0].Data)
  // original: $ -> (A,B,C|D) - SHOULD BE BURNED
  assert.equal(balances["4e9dd43eec444cacd421965476abce6707d34301c49931cceca9d47de1526532"]["9876"], '0')
  assert.equal(balances["0a23b6f55f1ffa06bb9b6bb824dbcd672b6fcd06cc031b91d58f1acf34cf345d"]["9876"], '0')
  assert.equal(balances["7d8a76cac061acdb983bb2e43c93aa0b2cf959378e6e25a43cbadcb1afd0e863"]["9876"], '0')
  // split: C|D -> (C,D) 
  assert.equal(balances["b61eeb7f086dfe73683a4f5a9040adf112fa8bda1cf41bf995d3b890e9f15335"]["9876"], '20')
  assert.equal(balances["35d5963221eb06230aaeaa7085f67a8e9354855c4042e7785b22cd52eb2fae01"]["9876"], '20')
  // new HI|LO ?
  assert.equal(balances["9bab3ffd280420050d5a8be761ec828442de91d3a481dd5a938715331f87c4f5"]["9876"], '70') 
  assert.equal(balances["4c879561ced61976c1cab946b26ab08b04e58a9d0d24b895829dd79180cccbf0"]["9876"], '100')
  // new split: LO -> (LO&A, LO&B, LO&C|D)
  assert.equal(balances["9104d8bf3d7facc2d4addecdf2f91dcaebe34882bad3c8f4ba097099cbe10c80"]["9876"], '30')
  assert.equal(balances["1a5202803de9ab4467ea8d52abfa9da36ac433bdce3afd97930b11553ec53a0b"]["9876"], '60')
  assert.equal(balances["6c1be55b038998072fa6e6a98a1028ea66fe172cdd93010c0d21eca6c287d81c"]["9876"], '30') 

  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["9876"], '10') 
  assert.equal(balances["0010c76539475810599b1396709623a94f10d972a6d8231e9c98dc77c9efd7b1"]["1234"], '20') 
})

// @dev to be checked via integration tests
// test('Redeeming: should credit payout as collateral', async () => {
// })

// test('Trader enters deeper position with another condition: should send Condition-Resolution-Notice', async () => {
// })

// test('Trader enters deeper position with another condition: should reflect report via payoutNumerators', async () => {
// })

// test('Trader enters deeper position with another condition: should not allow an update to the report', async () => {
// })

// test('Trader enters deeper position with another condition: with valid redemption', async () => {
// })

// test('Trader enters deeper position with another condition: should send Payout-Redemption-Notice', async () => {
// })