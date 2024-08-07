import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'
import keccak256 from 'keccak256'

const genRanHex = size => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

/* 
 * LOAD MODULE
 */
test('load conditionalToken module', async () => {
  const code = fs.readFileSync('./src/market/amm.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${code}
      end
      _G.package.loaded["amm"] = _load()
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
test('Spawn: a new market can be spawned', async () => {
  const conditionalToken = '123'
  const collateralToken = '1234'
  const conditionId = '12345'
  const fee = '100000000' // 1%
  const dataIndex = '123456'
  const xFrom = '4321'

  const result = await Send({
    From: "1234",
    Action: 'Spawn',
    ConditionalToken: conditionalToken,
    CollateralToken: collateralToken,
    ConditionId: conditionId,
    Fee: fee,
    DataIndex: dataIndex,
    ["X-From"]: xFrom,
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionalToken_ = result.Messages[0].Tags.find(t => t.name === 'ConditionalToken').value
  const collateralToken_ = result.Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const fee_ = result.Messages[0].Tags.find(t => t.name === 'Fee').value
  const creator_ = result.Messages[0].Tags.find(t => t.name === 'Creator').value

  assert.equal(action_, "New-Market-Notice")
  assert.equal(conditionalToken_, conditionalToken)
  assert.equal(collateralToken_, collateralToken)
  assert.equal(conditionId_, conditionId)
  assert.equal(fee_, fee)
  assert.equal(creator_, xFrom)
})

test('Info: market info updated', async () => {
  const conditionalToken = '123'
  const collateralToken = '1234'
  const conditionId = '12345'
  const fee = '100000000' // 1%
  const feePoolWeight = '0'

  const result = await Send({
    From: "1234",
    Action: 'Get-Market-Info',
    Data: ''
  })

  const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  const conditionalToken_ = result.Messages[0].Tags.find(t => t.name === 'ConditionalToken').value
  const collateralToken_ = result.Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  const feePoolWeight_ = result.Messages[0].Tags.find(t => t.name === 'FeePoolWeight').value
  const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  const fee_ = result.Messages[0].Tags.find(t => t.name === 'Fee').value

  assert.equal(action_, "Market-Info")
  assert.equal(conditionalToken_, conditionalToken)
  assert.equal(collateralToken_, collateralToken)
  assert.equal(conditionId_, conditionId)
  assert.equal(feePoolWeight_, feePoolWeight)
  assert.equal(fee_, fee)
})

test('Funding: can be funded', async () => {
  const conditionalToken = '123'
  const collateralToken = '1234'
  const conditionId = '12345'
  const fee = '100000000' // 1%
  const feePoolWeight = '0'
  const quantity = '100'

  // mocking response from the collateral token after transfer
  const result = await Send({
    From: collateralToken,
    Action: 'Credit-Notice',
    Sender: "9876",
    Recipient: "9876",
    Quantity: quantity,
    ['X-Action']: 'Add-Funding',
    ['X-From']: '9876',
    ['X-Quantity']: quantity,
    Data: ''
  })

  console.log("result", result)
  assert.equal(1,2)

  // const action_ = result.Messages[0].Tags.find(t => t.name === 'Action').value
  // const conditionalToken_ = result.Messages[0].Tags.find(t => t.name === 'ConditionalToken').value
  // const collateralToken_ = result.Messages[0].Tags.find(t => t.name === 'CollateralToken').value
  // const feePoolWeight_ = result.Messages[0].Tags.find(t => t.name === 'FeePoolWeight').value
  // const conditionId_ = result.Messages[0].Tags.find(t => t.name === 'ConditionId').value
  // const fee_ = result.Messages[0].Tags.find(t => t.name === 'Fee').value

  // assert.equal(action_, "Market-Info")
  // assert.equal(conditionalToken_, conditionalToken)
  // assert.equal(collateralToken_, collateralToken)
  // assert.equal(conditionId_, conditionId)
  // assert.equal(feePoolWeight_, feePoolWeight)
  // assert.equal(fee_, fee)
})

test('Trading: can buy tokens from it', async () => {})

test('Trading: can sell tokens to it', async () => {})

test('Trading: can make complex buy / sell orders', async () => {})

test('Funding: can continue being funded', async () => {})

test('Funding: can be defunded', async () => {})

test('Pricing: should move price of outcome to 0 after participants sell lots of outcome', async () => {})

test('Pricing: should move price of outcome to 1 after participants buy lots of outcome', async () => {})

test('Market: can be closed by resolutionAgent', async () => {})
