import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'

test('load dbAdmin module', async () => {
  const dbAdminCode = fs.readFileSync('./src/core/DbAdmin.lua', 'utf-8')
  const result = await Send({
    Action: 'Eval',
    Data: `
      local function _load() 
        ${dbAdminCode}
      end
      _G.package.loaded["dbAdmin"] = _load()
      return "ok"
    `
  })
  assert.equal(result.Output.data.output, "ok")
})

test('Load source', async () => {
  const code = fs.readFileSync('./src/agents/resolutionAgent.lua', 'utf-8')
  const result = await Send({ Action: "Eval", Data: code })
  assert.equal(result.Output.data.output, "OK")

})

const testPID = '9876'

test('Load data agent', async () => {
  const code = fs.readFileSync('./src/agents/dataAgent.lua', 'utf-8')
  const result = await Send({ Action: "Eval", Data: code })
  assert.equal(result.Output.data.output, testPID)
})

test('Init db tables', async () => {
  const result = await Send({Action: "Eval", Data: "require('json').encode(InitDb())"})  
  assert.deepEqual(
    JSON.parse(result.Output.data.output), 
    ["Subscriptions"]
  )
})

test('DataAgent.Subscribe', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID (same as testPID)
    Target: testPID, 
    Action: 'Subscribe',
    Time: '86400',
  })

  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  const data = result.Messages[0].Data

  assert.ok(
    action == 'Subscribed',
    data == '96403'
  )
})

test('Resolution.Definition', async () => {
  const result = await Send({
    From: '1234', 
    Action: 'Resolution-Definition'
  })

  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data.CONDITION.ONE.condition_type == 'GREATER_THAN',
    data.CONDITION.ONE.value == 0,
    data.DATA_AGENT == '9876',
    data.CONTINUOUS == true,
    data.MARKET_CLOSE == 10000
  )
})

test('Resolution.State', async () => {
  const result = await Send({
    From: '1234', 
    Action: 'Resolution-State'
  })

  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data.ACTIVE == true,
    data.VALUE == false,
    data.OUTCOME == ''
  )
})

//@dev Mock data 0rbit process data response to data broadcast to subscribers
const mockResponse = '{"bitcoin":{"usd":67377},"ethereum":{"usd":3520.58},"solana":{"usd":151.38}}'
test('Oracle.Repsonse', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Oracle-Response',
    Data: mockResponse
  })
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  const type = result.Messages[0].Tags.find(t => t.name == "Type").value
  const assignments = result.Messages[0].Tags.find(t => t.name == "Assignments").value
  const data = result.Messages[0].Data

  assert.ok(
    result.Messages.length == 1,
    assignments.length == 1,
    assignments[0] == '9876',
    action == 'Data-Agent-Feed',
    type == 'json',
    data == mockResponse
  )
})

// @dev: mock data feed
test('DataAgent.Feed', async () => {
  await Send({
    From: '1234', 
    Action: 'Data-Agent-Feed',
    Data: mockResponse
  })
})

// @dev Testing the data agent broadcast updated resolution agent state
test('Resolution.State', async () => {
  const result = await Send({
    From: '1234', 
    Action: 'Resolution-State'
  })

  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data.ACTIVE == true,
    data.VALUE == true,
    data.OUTCOME == ''
  )
})

test('Resolve', async () => {
  const result = await Send({
    From: '1234', 
    Action: 'Resolve'
  })

  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data.ACTIVE == false,
    data.VALUE == true,
    data.OUTCOME == true
  )
})
