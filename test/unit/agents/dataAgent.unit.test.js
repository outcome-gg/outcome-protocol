import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'

test('load DbAdmin module', async () => {
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

const testPID = '9876'

test('Load source', async () => {
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

test('Data.Fetch', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Data-Fetch'
  })

  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  const xAction = result.Messages[0].Tags.find(t => t.name == "X-Action").value
  const xUrl = result.Messages[0].Tags.find(t => t.name == "X-Url").value
  const recipient = result.Messages[0].Tags.find(t => t.name == "Recipient").value
  const quantity = result.Messages[0].Tags.find(t => t.name == "Quantity").value

  assert.ok(
    action == 'Transfer',
    xAction == 'Get-Real-Data',
    xUrl == 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana,&vs_currencies=usd',
    recipient == 'BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ',
    quantity == '1000000000000'
  )
})

test('Data', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Data',
    Token: 'BTC'
  })

  const data = result.Messages[0].Data

  assert.ok(
    data == 'Data not available!'
  )
})

test('Subscription.Details', async () => {
  const result = await Send({
    From: '1234', // USER_PID
    Action: 'Subscription-Details'
  })
  const data = result.Messages[0].Data

  assert.ok(
    data == '{"TOKEN":"Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc","FEE":"1000","TIME":"86400"}'
  )
})

const token = '123456'
const time = '86400'
const fee = '123'
test('Subscription.Update', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Subscription-Update',
    Token: token,
    Time: time,
    Fee: fee
  })
  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data["TOKEN"] == token,
    data["TIME"] == time,
    data["FEE"] == fee
  )
})

test('Subscribe', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Subscribe',
    Time: '86400'
  })
  const data = result.Messages[0].Data
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    data == '96403', 
    action == 'Subscribed'
  )
})

test('Subscriptions', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Subscriptions'
  })
  const data = JSON.parse(result.Messages[0].Data)

  assert.ok(
    data.length == 1,
    data[0]["id"] == "9876",
    data[0]["end_timestamp"] == "96403"
  )
})

const mockResponse = '{"bitcoin":{"usd":67377},"ethereum":{"usd":3520.58},"solana":{"usd":151.38}}'
//@dev Mock data 0rbit process data response with data response from above xUrl
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


test('Data', async () => {
  const result = await Send({
    From: '9876', // ADMIN_PID
    Action: 'Data',
    Token: 'BTC'
  })

  const data = result.Messages[0].Data

  assert.ok(
    data == '67377'
  )
})
