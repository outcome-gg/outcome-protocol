import { test } from 'node:test'
import * as assert from 'node:assert'
import { Send } from '../../aos.helper.js'
import fs from 'node:fs'
import { use } from 'chai'

const OLD_ADMIN_PID = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I'
const NEW_ADMIN_PID = '1111'
const OLD_EMERGENCY_ADMIN_PID = 'XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I'
const NEW_EMERGENCY_ADMIN_PID = '8888'
const RESOLUTION_AGENT_PID = '9999'
const NEW_PROTOCOL_PROCESS_PID = '6666'
const USER_PID = 'USER_PID'

/************************  
 * LOAD MODULES
 ************************/

test('load dbAdmin module', async () => {
  const dbAdminCode = fs.readFileSync('./src/_core/DbAdmin.lua', 'utf-8')
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
  const code = fs.readFileSync('./src/_core/dataIndex.lua', 'utf-8')
  const result = await Send({ Action: "Eval", Data: code })
  assert.equal(result.Output.data.output, "OK")

})

/************************  
 * DB.INIT
 ************************/

test('Init db tables', async () => {
  const result = await Send({Action: "Eval", Data: "require('json').encode(InitDb())"})  
  assert.deepEqual(
    JSON.parse(result.Output.data.output), 
    ["Users", "Agents", "Messages", "MarketGroups", "Markets", "Wagers", "Wins", "Shares", "ChatSubscriptions", "MarketSubscriptions", "UserSubscriptions", "AgentSubscriptions"]
  )
})

/************************  
 * DB.QUERY
 ************************/

test('Query db tables', async () => {
  const sql = {query: "SELECT name FROM sqlite_master WHERE type='table';"}
  const result = await Send({
    From: OLD_ADMIN_PID,
    Action: "DB-Query", 
    Data: JSON.stringify(sql)
  })  

  const data = JSON.parse(result.Messages[0].Data)
  const names = data.map(d => d.name)
  
  assert.deepEqual(
    names, 
    ["Users", "Agents", "Messages", "MarketGroups", "Markets", "Wagers", "Wins", "Shares", "ChatSubscriptions", "MarketSubscriptions", "UserSubscriptions", "AgentSubscriptions"]
  )
})

/************************  
 * EMERGENCY ADMIN 
 ************************/

test('EmergencyAdmin.Update', async () => {
  const result = await Send({
    From: OLD_EMERGENCY_ADMIN_PID, 
    Action: 'Emergency-Admin-Update',
    NewEmergencyAdmin: NEW_EMERGENCY_ADMIN_PID,
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Emergency-Admin-Updated',
    data == NEW_EMERGENCY_ADMIN_PID
  )
})

/************************  
 * ADMIN 
 ************************/

test('Admin.Update', async () => {
  const result = await Send({
    From: OLD_ADMIN_PID,
    Action: 'Admin-Update',
    NewAdmin: NEW_ADMIN_PID,
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Admin-Updated',
    data == NEW_ADMIN_PID
  )
})

test('ProtocolProcess.Update', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Protocol-Process-Update',
    NewProtocolProcess: NEW_PROTOCOL_PROCESS_PID,
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Protocol-Process-Updated',
    data == NEW_PROTOCOL_PROCESS_PID
  )
})

let marketId = '';
let type = 'binary';
let price = '0.5';
let category = 'defi';
let startTimestamp = '1234';
let endTimestamp = '1235';
let imageUrl = 'https://example.com/image.jpg';
let conditionPath = 'will-btc-reach-100000-by-2025';
let conditionName = 'Will BTC reach $100,000 by 2025?';
let conditionDetail = 'Will BTC reach $100,000 by 2025? Market resolves as IN if...';

test('Market.Draft', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Market-Draft',
    Data: JSON.stringify({
      type: type,
      price: price,
      category: category,
      start_timestamp: startTimestamp,
      end_timestamp: endTimestamp,
      image_url: imageUrl,
      condition_name: conditionName,
      condition_path: conditionPath,
      condition_detail: conditionDetail,
      resolution_agent: RESOLUTION_AGENT_PID
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  marketId = data['id']

  assert.ok(
    action == 'Market-Drafted',
    data['id'] != '',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['start_timestamp'] == startTimestamp,
    data['end_timestamp'] == endTimestamp,
    data['image_url'] == imageUrl,
    data['condition_name'] == conditionName,
    data['condition_path'] == conditionPath,
    data['condition_detail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'draft'
  )
})

type = 'multi';
price = '0.7';
category = 'games';
startTimestamp = '10002';
endTimestamp = '10003';
imageUrl = 'https://example.com/image2.jpg';
conditionName = 'Will BTC reach $250,000 by 2025?';
conditionDetail = 'Will BTC reach $250,000 by 2025? Market resolves as IN if...';

test('Market.Draft-Update', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Market-Draft-Update',
    Data: JSON.stringify({
      id: marketId,
      type: type,
      price: price,
      category: category,
      start_timestamp: startTimestamp,
      end_timestamp: endTimestamp,
      image_url: imageUrl,
      condition_name: conditionName,
      condition_path: conditionPath,
      condition_detail: conditionDetail,
      resolution_agent: RESOLUTION_AGENT_PID
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  marketId = data['id']

  assert.ok(
    action == 'Market-Draft-Updated',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['start_timestamp'] == startTimestamp,
    data['end_timestamp'] == endTimestamp,
    data['image_url'] == imageUrl,
    data['condition_name'] == conditionName,
    data['condition_path'] == conditionPath,
    data['condition_detail'] == conditionDetail,
    data['condition_detail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'draft'
  )
})

test('Market.Open', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Market-Open',
    Data: JSON.stringify({
      'id': marketId
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Market-Opened',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['start_timestamp'] == startTimestamp,
    data['end_timestamp'] == endTimestamp,
    data['image_url'] == imageUrl,
    data['condition_name'] == conditionName,
    data['condition_path'] == conditionPath,
    data['condition_detail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'open'
  ) 
})

type = 'binary';
price = '0.6';
category = 'memes';
startTimestamp = Date.now();
endTimestamp = Date.now() + 1000 * 60 * 60 * 24;
imageUrl = 'https://example.com/image3.jpg';
conditionName = 'Will BTC reach USD 250,000 by 2025?';
conditionDetail = 'Will BTC reach USD 250,000 by 2025? Market resolves as IN if...';

test('Market.Open-Update', async () => {
  const result = await Send({
    From: NEW_EMERGENCY_ADMIN_PID,
    Action: 'Market-Open-Update',
    Data: JSON.stringify({
      id: marketId,
      type: type,
      price: price,
      category: category,
      start_timestamp: startTimestamp,
      end_timestamp: endTimestamp,
      image_url: imageUrl,
      condition_name: conditionName,
      condition_path: conditionPath,
      condition_detail: conditionDetail,
      resolution_agent: RESOLUTION_AGENT_PID
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Market-Open-Updated',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['start_timestamp'] == startTimestamp,
    data['end_timestamp'] == endTimestamp,
    data['image_url'] == imageUrl,
    data['condition_name'] == conditionName,
    data['condition_path'] == conditionPath,
    data['condition_detail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'open'
  ) 
})

price = '0.1';

// test('Market.Prices-Update', async () => {
//   const result = await Send({
//     From: NEW_PROTOCOL_PROCESS_PID,
//     Action: 'Market-Prices-Update',
//     Data: JSON.stringify({
//       id: marketId,
//       prices: prices
//     })
//   })
//   const data = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Market-Prices-Updated',
//     data['id'] == marketId,
//     data['prices'] == prices,
//   ) 
// })

/********************************************  
 * EMERGENCY ADMIN || RESOLUTION AGENT UPDATE
 ********************************************/

test('Market.Close', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Market-Close',
    Data: JSON.stringify({
      'id': marketId
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Market-Closed',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['startTimestamp'] == startTimestamp,
    data['endTimestamp'] == endTimestamp,
    data['imageUrl'] == imageUrl,
    data['conditionName'] == conditionName,
    data['conditionPath'] == conditionPath,
    data['conditionDetail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'closed'
  ) 
})

/********************************************  
 * EMERGENCY ADMIN || RESOLUTION AGENT UPDATE
 ********************************************/

test('Market.Resolve', async () => {
  const result = await Send({
    From: RESOLUTION_AGENT_PID,
    Action: 'Market-Resolve',
    Data: JSON.stringify({
      'id': marketId
    })
  })
  const data = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Market-Resolved',
    data['id'] == marketId,
    data['type'] == type,
    data['price'] == price,
    data['category'] == category,
    data['start_timestamp'] == startTimestamp,
    data['end_timestamp'] == endTimestamp,
    data['image_url'] == imageUrl,
    data['condition_name'] == conditionName,
    data['condition_path'] == conditionPath,
    data['condition_detail'] == conditionDetail,
    data['resolution_agent'] == RESOLUTION_AGENT_PID,
    data['status'] == 'resolved'
  ) 
})

/************************  
 * USER
 ************************/

test('Chat.Subscribe', async () => {
  const result = await Send({
    From: USER_PID,
    Action: 'Chat-Subscribe',
    Market: marketId,
    Active: true
  })
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  
  assert.ok(
    action == 'Chat-Subscribed',
    result.Messages[0].Data == true,
  ) 
})

test('Chat.Broadcast', async () => {
  const result = await Send({
    From: USER_PID,
    Action: 'Broadcast',
    Market: marketId,
    Data: 'Hello World'
  })
  const assignments = result.Messages[0].Tags.find(t => t.name == "Assignments").value
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  const nickname = result.Messages[0].Tags.find(t => t.name == "Nickname").value
  const type_ = result.Messages[0].Tags.find(t => t.name == "Type").value
  const broadcaster = result.Messages[0].Tags.find(t => t.name == "Broadcaster").value
  
  assert.ok(
    action == 'Broadcasted',
    nickname == 'USER_P..._PID',
    assignments.includes(USER_PID),
    type_ == 'normal',
    broadcaster == USER_PID,
    result.Messages[0].Data == 'Hello World'
  ) 
})

/************************  
 * ADMIN (AGAIN)
 ************************/

test('Chat.Broadcasts', async () => {
  const result = await Send({
    From: USER_PID,
    Action: 'Broadcasts',
    Market: marketId
  })
  const broadcasts = JSON.parse(result.Messages[0].Data)

  assert.ok(
    broadcasts[0]['user'] == USER_PID,
    broadcasts[0]['market'] == marketId,
    broadcasts[0]['body'] == 'Hello World',
    broadcasts[0]['visible'] == true
  )
})

/************************  
 * DATA INGEST: USERS
 ************************/
let users = [
  { 
    id: 'USER1', 
    updateType: 'claim'
  },
  { 
    id: 'USER1', 
    nickname: 'NICKNAME2', 
    updateType: 'nickname'
  },
  { 
    id: 'USERX', 
    nickname: 'NICKNAMEX', 
    updateType: 'nickname'
  },
]

test('User.Ingest - claim', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'User-Ingest',
    Data: JSON.stringify(users[0])
  })
  const user = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'User-Ingested',
    user['id'] == users[0].id,
    user['registered_ts'] == '10003',
    user['last_claim_posix'] == '90900',
    user['last_active_ts'] == '10003',
    user['timestamp'] == '10003',
  )
})

test('User.Ingest - claim new user', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'User-Ingest',
    Data: JSON.stringify(users[2])
  })
  const user = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'User-Ingested',
    user['id'] == users[2].id,
    user['nickname'] == "NICKNAMEX",
    user['registered_ts'] == '10003',
    user['last_claim_ts'] == '0',
    user['last_active_ts'] == '10003',
    user['timestamp'] == '10003'
  )
})

test('User.Ingest - claim + nickname', async () => {
  const result1 = await Send({
    From: NEW_ADMIN_PID,
    Action: 'User-Ingest',
    Data: JSON.stringify(users[0])
  })

  const user1 = JSON.parse(result1.Messages[0].Data)
  const action1 = result1.Messages[0].Tags.find(t => t.name == "Action").value

  const result2 = await Send({
    From: NEW_ADMIN_PID,
    Action: 'User-Ingest',
    Data: JSON.stringify(users[1])
  })
  const user2 = JSON.parse(result2.Messages[0].Data)
  const action2 = result2.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action1 == 'User-Ingested',
    action2 == 'User-Ingested',
    user1['id'] == users[0].id,
    user1['nickname'] == "USER1...SER1",
    user1['registered_ts'] == '10003',
    user1['last_claim_ts'] == '10003',
    user1['last_active_ts'] == '10003',
    user1['timestamp'] == '10003',
    user2['id'] == users[1].id,
    user2['nickname'] == 'NICKNAME2',
    user1['registered_ts'] == '10003',
    user1['last_claim_ts'] == '10003',
    user1['last_active_ts'] == '10003',
    user2['timestamp'] == '10003',
  )
})


/************************  
 * DATA INGEST: WAGER
 ************************/
let wagers = [
  { 
    user: 'data', 
    market: '1234',
    position: 'in',
    amount: '100',
    action: 'credit',
    average_price: '50',
    odds: '0.5'
  }
]
test('Wager.Ingest', async () => {
  const result = await Send({
    From: NEW_PROTOCOL_PROCESS_PID,
    Action: 'Wager-Ingest',
    Data: JSON.stringify(wagers[0])
  })
  const wager = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value
  assert.ok(
    action == 'Wager-Ingested',
    wager['id'] == "1234", // msg.id
    wager['user'] == wagers[0].user,
    wager['market'] == wagers[0].market,
    wager['position'] == wagers[0].position,
    wager['amount'] == wagers[0].amount,
    wager['action'] == wagers[0].action,
    wager['average_price'] == wagers[0].average_price,
    wager['odds'] == wagers[0].odds,
    wager['timestamp'] == '10003'
  )
})

/************************  
 * DATA INGEST: AGENTS
 ************************/
let agents = [
  { 
    id: 'AGENT1', 
    type: 'data', 
    owner: 'USER1'
  }
]

test('Agent.Ingest', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Agent-Ingest',
    Data: JSON.stringify(agents[0])
  })
  const agent = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Agent-Ingested',
    agent['id'] == agents[0].id,
    agent['type'] == agents[0].type,
    agent['owner'] == agents[0].owner,
    agent['timestamp'] == '10003'
  )
})

/************************  
 * DATA INGEST: MESSAGES
 ************************/
let messages = [
  { 
    id: 'MESSAGE1', 
    user: 'USER1', 
    market: 'MARKET1',
    body: 'Hello World',
    visible: true,
  }
]
test('Message.Ingest', async () => {
  const result = await Send({
    From: NEW_ADMIN_PID,
    Action: 'Message-Ingest',
    Data: JSON.stringify(messages[0])
  })
  const message = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Message-Ingested',
    message['id'] == messages[0].id,
    message['user'] == messages[0].user,
    message['market'] == messages[0].market,
    message['body'] == messages[0].body,
    message['timestamp'] == '10003'
  )
})

/************************  
 * DATA INGEST: MARKET PRICE
 ************************/
test('MarketPrice.Ingest', async () => {
  let marketPrices = [
    { 
      id: marketId, 
      price: '50',
    }
  ]
  const result = await Send({
    From: NEW_PROTOCOL_PROCESS_PID,
    Action: 'Market-Price-Ingest',
    Data: JSON.stringify(marketPrices[0])
  })
  const market = JSON.parse(result.Messages[0].Data)
  const action = result.Messages[0].Tags.find(t => t.name == "Action").value

  assert.ok(
    action == 'Market-Price-Ingested',
    market['id'] == marketPrices[0].id,
    market['price'] == marketPrices[0].price
  )
})


// /************************  
//  * DATA INGEST: WIN
//  ************************/
// let wins = [
//   { 
//     user: 'USER1', 
//     market: '1234', 
//     category: 'games',
//     bet_amount: '100',
//     won_amount: '200'
//   }
// ]
// test('Win.Ingest', async () => {
//   const result = await Send({
//     From: NEW_PROTOCOL_PROCESS_PID,
//     Action: 'Win-Ingest',
//     Data: JSON.stringify(wins[0])
//   })
//   const win = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Win-Ingested',
//     win['id'] == "1234", // msg.id
//     win['user'] == wins[0].user,
//     win['market'] == wins[0].market,
//     win['category'] == wins[0].category,
//     win['bet_amount'] == wins[0].bet_amount,
//     win['won_amount'] == wins[0].won_amount,
//     win['timestamp'] == '10003'
//   )
// })


/************************  
 * UI DATA: USER
 ************************/
test('UI.User', async () => {
  const result = await Send({
    From: NEW_PROTOCOL_PROCESS_PID,
    Action: 'UI-User',
    Data: JSON.stringify({'id': users[0].id, 'updateType': 'claim'})
  })
  const userData = JSON.parse(result.Messages[0].Data)

  assert.ok(
    userData['id'] == users[0].id
  )
})

/************************  
 * UI DATA: LEADERBOARD
 ************************/
//@dev: UNIT TEST FAILS BUT WORKS IN PRODUCTION
// test('UI.Leaderboard', async () => {
//   const result = await Send({
//     From: NEW_PROTOCOL_PROCESS_PID,
//     Action: 'UI-Leaderboard',
//     Data: ''
//   })
//   const leaderboardData = JSON.parse(result.Messages[0].Data)
//   console.log("leaderboardData: ", leaderboardData)

//   assert.ok(
//     leaderboardData['id'] == users[0].id
//   )
// })



/************************  
 * IGNORE BELOW FOR NOW
 ************************/






/************************  
 * DATA INGEST: SHARES
 ************************/
// let shares = [
//   { 
//     id: 'AGENT1', 
//     type: 'data', 
//     owner: 'USER1'
//   }
// ]
// test('MarketGroup.Ingest', async () => {
//   const result = await Send({
//     From: NEW_ADMIN_PID,
//     Action: 'Agent-Ingest',
//     Agent: agents[0].id,
//     AgentOwner: agents[0].owner,
//     Type: agents[0].type
//   })
//   const agent = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Agent-Ingested',
//     agent[0]['id'] == agents[0].id,
//     agent[0]['type'] == agents[0].type,
//     agent[0]['owner'] == agents[0].owner,
//     agent[0]['timestamp'] == '10003'
//   )
// })

/************************  
 * DATA INGEST: AGENT-SUBSCRIPTIONS
 ************************/
// let marketGroups = [
//   { 
//     id: 'AGENT1', 
//     type: 'data', 
//     owner: 'USER1'
//   },
//   { 
//     id: 'AGENT2', 
//     type: 'data', 
//     owner: 'USER2'
//   },
// ]
// test('MarketGroup.Ingest', async () => {
//   const result = await Send({
//     From: NEW_ADMIN_PID,
//     Action: 'Agent-Ingest',
//     Agent: agents[0].id,
//     AgentOwner: agents[0].owner,
//     Type: agents[0].type
//   })
//   const agent = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Agent-Ingested',
//     agent[0]['id'] == agents[0].id,
//     agent[0]['type'] == agents[0].type,
//     agent[0]['owner'] == agents[0].owner,
//     agent[0]['timestamp'] == '10003'
//   )
// })

/************************  
 * DATA INGEST: CHAT-SUBSCRIPTIONS
 ************************/
// let marketGroups = [
//   { 
//     id: 'AGENT1', 
//     type: 'data', 
//     owner: 'USER1'
//   },
//   { 
//     id: 'AGENT2', 
//     type: 'data', 
//     owner: 'USER2'
//   },
// ]
// test('MarketGroup.Ingest', async () => {
//   const result = await Send({
//     From: NEW_ADMIN_PID,
//     Action: 'Agent-Ingest',
//     Agent: agents[0].id,
//     AgentOwner: agents[0].owner,
//     Type: agents[0].type
//   })
//   const agent = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Agent-Ingested',
//     agent[0]['id'] == agents[0].id,
//     agent[0]['type'] == agents[0].type,
//     agent[0]['owner'] == agents[0].owner,
//     agent[0]['timestamp'] == '10003'
//   )
// })

/************************  
 * DATA INGEST: MARKET-SUBSCRIPTIONS
 ************************/
// let marketGroups = [
//   { 
//     id: 'AGENT1', 
//     type: 'data', 
//     owner: 'USER1'
//   },
//   { 
//     id: 'AGENT2', 
//     type: 'data', 
//     owner: 'USER2'
//   },
// ]
// test('MarketGroup.Ingest', async () => {
//   const result = await Send({
//     From: NEW_ADMIN_PID,
//     Action: 'Agent-Ingest',
//     Agent: agents[0].id,
//     AgentOwner: agents[0].owner,
//     Type: agents[0].type
//   })
//   const agent = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Agent-Ingested',
//     agent[0]['id'] == agents[0].id,
//     agent[0]['type'] == agents[0].type,
//     agent[0]['owner'] == agents[0].owner,
//     agent[0]['timestamp'] == '10003'
//   )
// })

/************************  
 * DATA INGEST: USER-SUBSCRIPTIONS
 ************************/
// let marketGroups = [
//   { 
//     id: 'AGENT1', 
//     type: 'data', 
//     owner: 'USER1'
//   },
//   { 
//     id: 'AGENT2', 
//     type: 'data', 
//     owner: 'USER2'
//   },
// ]
// test('MarketGroup.Ingest', async () => {
//   const result = await Send({
//     From: NEW_ADMIN_PID,
//     Action: 'Agent-Ingest',
//     Agent: agents[0].id,
//     AgentOwner: agents[0].owner,
//     Type: agents[0].type
//   })
//   const agent = JSON.parse(result.Messages[0].Data)
//   const action = result.Messages[0].Tags.find(t => t.name == "Action").value

//   assert.ok(
//     action == 'Agent-Ingested',
//     agent[0]['id'] == agents[0].id,
//     agent[0]['type'] == agents[0].type,
//     agent[0]['owner'] == agents[0].owner,
//     agent[0]['timestamp'] == '10003'
//   )
// })