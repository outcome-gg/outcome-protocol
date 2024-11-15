import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { getMessageData, getNoticeData, getNoticeAction, getErrorMessage, parseAmount, parseBalances, delay } from "./utils.js";
import { expect } from "chai";
import { readFileSync } from "fs";
import { fileURLToPath } from 'url';
import path from "path";
import { error } from "console";
import dotenv from 'dotenv';

dotenv.config();

const dataIndex = process.env.TEST_DATA_INDEX4;

console.log("DATA_INDEX: ", dataIndex)

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
describe("db.integration.test", function () {
  before(async () => ( 
    processId = dataIndex,
    wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet.json')).toString(),
    ),
    wallet2 = JSON.parse(
      readFileSync(path.join(__dirname, '../../wallet2.json')).toString(),
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
  * DB: INIT
  ************************************************************************/

  /* 
  * DB.Init
  */
  describe("db.Init", function () {
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
      expect(Messages[0].Data).to.eql('["Users","Agents","Messages","MarketGroups","Markets","Wagers","Wins","Shares","ChatSubscriptions","MarketSubscriptions","UserSubscriptions","AgentSubscriptions"]')
    })
  })

  /***********************************************************************
  * DB: QUERY
  ************************************************************************/

  /* 
  * DB.Query
  */
  describe("db.Query", function () {
    it("+ve should query db", async () => {
      const sql = {query: "SELECT name FROM sqlite_master WHERE type='table';"}
      const data = JSON.stringify(sql)
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "DB-Query" }
        ],
        signer: createDataItemSigner(admin1),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const names = data_.map(d => d.name)

      expect(names).to.eql(["Users","Agents","Messages","MarketGroups","Markets","Wagers","Wins","Shares","ChatSubscriptions","MarketSubscriptions","UserSubscriptions","AgentSubscriptions"])
    })
  })

  /***********************************************************************
  * EMERGENCY ADMIN
  ************************************************************************/

  /* 
  * EmergencyAdmin.Update
  */
  describe("EmergencyAdmin.Update", function () {
    it("+ve should update emergency admin", async () => {
      // update emergency admin target      
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Emergency-Admin-Update" },
          { name: "NewEmergencyAdmin", value: emergencyAdminAddress2 }
        ],
        signer: createDataItemSigner(emergencyAdmin1),
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

      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Emergency-Admin-Updated')
      expect(Messages[0].Data).to.eql(emergencyAdminAddress2)
    })
  })

  /***********************************************************************
  * ADMIN: PROCESSES
  ************************************************************************/

  /* 
  * Admin.Update
  */
  describe("Admin.Update", function () {
    it("+ve should update admin", async () => {
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Admin-Update" },
          { name: "NewAdmin", value: adminAddress2 }
        ],
        signer: createDataItemSigner(admin1),
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

      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Admin-Updated')
      expect(Messages[0].Data).to.eql(adminAddress2)
    })
  })

  /* 
  * ProtocolProcess.Update
  */
  describe("ProtocolProcess.Update", function () {
    it("+ve should update protocol process", async () => {
      // update protocolProcess target

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Protocol-Process-Update" },
          { name: "NewProtocolProcess", value: protocolProcessAddress2 }
        ],
        signer: createDataItemSigner(admin2),
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

      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Protocol-Process-Updated')
      expect(Messages[0].Data).to.eql(protocolProcessAddress2)
    })
  })

  /***********************************************************************
  * ADMIN: MARKETS
  ************************************************************************/
  
  /* 
  * Market Draft
  */
  describe("Market.Draft", function () {
    it("+ve should draft a market", async () => {
      let type = 'binary';
      let price = '0.5';
      let category = 'defi';
      let startTimestamp = '131231';
      let endTimestamp = '131233';
      let imageUrl = 'https://example.com/image.jpg';
      let conditionPath = 'will-btc-reach-100000-by-2025';
      let conditionName = 'Will BTC reach $100,000 by 2025?';
      let conditionDetail = 'Will BTC reach $100,000 by 2025? Market resolves as IN if...';

      let data = JSON.stringify({
        'type': type,
        'price': price,
        'category': category,
        'start_timestamp': startTimestamp,
        'end_timestamp': endTimestamp,
        'image_url': imageUrl,
        'condition_path': conditionPath,
        'condition_name': conditionName,
        'condition_detail': conditionDetail,
        'resolution_agent': resolutionAgent
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Market-Draft" }
        ],
        signer: createDataItemSigner(admin2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      marketId = data_['id']
      
      expect(action).to.eql('Market-Drafted')
      expect(data_['type']).to.eql(type)
      expect(data_['price']).to.eql(price)
      expect(data_['category']).to.eql(category)
      expect(data_['start_timestamp']).to.eql(startTimestamp)
      expect(data_['end_timestamp']).to.eql(endTimestamp)
      expect(data_['image_url']).to.eql(imageUrl)
      expect(data_['condition_path']).to.eql(conditionPath)
      expect(data_['condition_name']).to.eql(conditionName)
      expect(data_['condition_detail']).to.eql(conditionDetail)
      expect(data_['resolution_agent']).to.eql(resolutionAgent)
      expect(data_['status']).to.eql('draft')
    })
  })

  /* 
  * Market Draft Update
  */
  describe("Market.Draft-Update", function () {
    it("+ve should update a market draft", async () => {
      let type = 'binary';
      let price = '0.5';
      let category = 'defi';
      let startTimestamp = '131231';
      let endTimestamp = '131233';
      let imageUrl = 'https://example.com/image.jpg';
      let conditionPath = 'will-btc-reach-100000-by-2025';
      let conditionName = 'Will BTC reach $100,000 by 2025?';
      let conditionDetail = 'Will BTC reach $100,000 by 2025? Market resolves as IN if...';

      let data = JSON.stringify({
        'id': marketId,
        'type': type,
        'price': price,
        'category': category,
        'start_timestamp': startTimestamp,
        'end_timestamp': endTimestamp,
        'image_url': imageUrl,
        'condition_path': conditionPath,
        'condition_name': conditionName,
        'condition_detail': conditionDetail,
        'resolution_agent': resolutionAgent
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Market-Draft-Update" }
        ],
        signer: createDataItemSigner(admin2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Market-Draft-Updated')
      expect(data_['type']).to.eql(type)
      expect(data_['price']).to.eql(price)
      expect(data_['category']).to.eql(category)
      expect(data_['start_timestamp']).to.eql(startTimestamp)
      expect(data_['end_timestamp']).to.eql(endTimestamp)
      expect(data_['image_url']).to.eql(imageUrl)
      expect(data_['condition_path']).to.eql(conditionPath)
      expect(data_['condition_name']).to.eql(conditionName)
      expect(data_['condition_detail']).to.eql(conditionDetail)
      expect(data_['resolution_agent']).to.eql(resolutionAgent)
      expect(data_['status']).to.eql('draft')
    })
  })

  /* 
  * Market Open
  */
  describe("Market.Open", function () {
    it("+ve should open a market", async () => {
      let type = 'binary';
      let price = '0.5';
      let category = 'defi';
      let startTimestamp = '131231';
      let endTimestamp = '131233';
      let imageUrl = 'https://example.com/image.jpg';
      let conditionPath = 'will-btc-reach-100000-by-2025';
      let conditionName = 'Will BTC reach $100,000 by 2025?';
      let conditionDetail = 'Will BTC reach $100,000 by 2025? Market resolves as IN if...';

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Market-Open" }
        ],
        signer: createDataItemSigner(admin2),
        data: JSON.stringify({
          'id': marketId
        }),
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Market-Opened')
      expect(data_['type']).to.eql(type)
      expect(data_['price']).to.eql(price)
      expect(data_['category']).to.eql(category)
      expect(data_['start_timestamp']).to.eql(startTimestamp)
      expect(data_['end_timestamp']).to.eql(endTimestamp)
      expect(data_['image_url']).to.eql(imageUrl)
      expect(data_['condition_path']).to.eql(conditionPath)
      expect(data_['condition_name']).to.eql(conditionName)
      expect(data_['condition_detail']).to.eql(conditionDetail)
      expect(data_['resolution_agent']).to.eql(resolutionAgent)
      expect(data_['status']).to.eql('open')
    })
  })

  /* 
  * Market Open Update
  */
  describe("Market.Open-Update", function () {
    it("+ve should update an open market", async () => {
      let type = 'binary';
      let price = '0.5';
      let category = 'defi';
      let startTimestamp = '131235';
      let endTimestamp = '131239';
      let imageUrl = 'https://example.com/image.jpg';
      let conditionPath = 'will-btc-reach-100000-by-2025';
      let conditionName = 'Will BTC reach $100,000 by 2025?';
      let conditionDetail = 'Will BTC reach $100,000 by 2025? Market resolves as IN if...';

      let data = JSON.stringify({
        'id': marketId,
        'type': type,
        'price': price,
        'category': category,
        'start_timestamp': startTimestamp,
        'end_timestamp': endTimestamp,
        'image_url': imageUrl,
        'condition_path': conditionPath,
        'condition_name': conditionName,
        'condition_detail': conditionDetail,
        'resolution_agent': resolutionAgent
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Market-Open-Update" }
        ],
        signer: createDataItemSigner(emergencyAdmin2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value
      
      expect(action).to.eql('Market-Open-Updated')
      expect(data_['type']).to.eql(type)
      expect(data_['price']).to.eql(price)
      expect(data_['category']).to.eql(category)
      expect(data_['start_timestamp']).to.eql(startTimestamp)
      expect(data_['end_timestamp']).to.eql(endTimestamp)
      expect(data_['image_url']).to.eql(imageUrl)
      expect(data_['condition_path']).to.eql(conditionPath)
      expect(data_['condition_name']).to.eql(conditionName)
      expect(data_['condition_detail']).to.eql(conditionDetail)
      expect(data_['resolution_agent']).to.eql(resolutionAgent)
      expect(data_['status']).to.eql('open')
    })
  })

  /***********************************************************************
  * DATA INGEST: USERS
  ************************************************************************/
  let users = [
    { 
      id: 'USER1', 
      nickname: 'NICKNAME1', 
      registered_ts: "123", 
      last_claim_posix: "456", 
      last_active_ts: "789", 
      banned: false 
    }
  ]

  /* 
  * User Ingest
  */
  describe("User.Ingest", function () {
    it("+ve should update users table", async () => {
      let price = '0.5';

      let data = JSON.stringify({
        'id': users[0].id,
        'nickname': users[0].nickname,
        'registered_ts': users[0].registered_ts,
        'last_claim_posix': users[0].last_claim_posix,
        'last_active_ts': users[0].last_active_ts,
        'banned': users[0].banned,
        'updateType': 'activity'
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "User-Ingest" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      expect(action).to.eql('User-Ingested')
      expect(data_.id).to.eql(users[0].id)
      expect(data_['nickname']).to.eql(users[0].nickname)
      // expect(data_['registered_ts']).to.eql(users[0].registered_ts)
      // expect(data_['last_claim_posix']).to.eql(users[0].last_claim_posix)
      // expect(data_['last_active_ts']).to.eql(users[0].last_active_ts)
      expect(data_['banned']).to.eql(0)
    })
  })

  /***********************************************************************
  * DATA INGEST: AGENTS
  ************************************************************************/
  let agents = [
    { 
      id: 'AGENT1', 
      type: 'data', 
      owner: 'USER1', 
      active: true
    }
  ]

  /* 
  * Agent Ingest
  */
  describe("Agent.Ingest", function () {
    it("+ve should update agents table", async () => {


      let data = JSON.stringify({
        'id': agents[0].id,
        'type': agents[0].type,
        'owner': agents[0].owner,
        'active': agents[0].active
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Agent-Ingest" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      expect(action).to.eql('Agent-Ingested')
      expect(data_['id']).to.eql(agents[0].id)
      expect(data_['type']).to.eql(agents[0].type)
      expect(data_['owner']).to.eql(agents[0].owner)
      expect(data_['active']).to.eql(1)
    })
  })

  /***********************************************************************
  * DATA INGEST: MESSAGES
  ************************************************************************/
  let messages = [
    { 
      id: 'MESSAGE1',
      user: 'USER1',   
      market: 'MARKET1', 
      body: 'Hello World',
      visible: true,
    }
  ]

  /* 
  * Message Ingest
  */
  describe("Message.Ingest", function () {
    it("+ve should update messages table", async () => {


      let data = JSON.stringify({
        'id': messages[0].id,
        'user': messages[0].user,
        'market': messages[0].market,
        'body': messages[0].body,
        'visible': messages[0].visible
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Message-Ingest" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      expect(action).to.eql('Message-Ingested')
      expect(data_['id']).to.eql(messages[0].id)
      expect(data_['user']).to.eql(messages[0].user)
      expect(data_['market']).to.eql(messages[0].market)
      expect(data_['body']).to.eql(messages[0].body)
      expect(data_['visible']).to.eql(messages[0].visible.toString())
    })
  })

  /***********************************************************************
  * DATA INGEST: MARKET PRICES
  ************************************************************************/

  /* 
  * Market Price Ingest
  */
  describe("MarketPrice.Ingest", function () {
    it("+ve should update market table with prices", async () => {
      let prices = [
        { 
          id: marketId,
          price: '70'
        }
      ]

      let data = JSON.stringify({
        'id': prices[0].id,
        'price': prices[0].price
      });

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Market-Price-Ingest" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      expect(action).to.eql('Market-Price-Ingested')
      expect(data_['id']).to.eql(prices[0].id)
      expect(data_['price']).to.eql(prices[0].price)
    })
  })

  /***********************************************************************
  * DATA INGEST: WAGERS
  ************************************************************************/

  /* 
  * Wager Ingest
  */
  describe("Wager.Ingest", function () {
    it("+ve should update wager table", async () => {
      let wagers = [
        { 
          'user': 'USER1',
          'market': marketId,
          'position': 'in',
          'action': 'credit',
          'amount': '500',
          'average_price': '0.5',
          'odds': '0.5'
        }
      ]

      let data = JSON.stringify(wagers[0]);

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "Wager-Ingest" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)
      const action = Messages[0].Tags.find(t => t.name == "Action").value

      expect(action).to.eql('Wager-Ingested')
      expect(data_['user']).to.eql(wagers[0].user)
      expect(data_['market']).to.eql(wagers[0].market)
      expect(data_['position']).to.eql(wagers[0].position)
      expect(data_['action']).to.eql(wagers[0].action)
      expect(data_['amount']).to.eql(wagers[0].amount)
      expect(data_['average_price']).to.eql(wagers[0].average_price)
    })
  })

  // /***********************************************************************
  // * DATA INGEST: WINS
  // ************************************************************************/

  // /* 
  // * WIN Ingest
  // */
  // describe("Win.Ingest", function () {
  //   it("+ve should update win table", async () => {
  //     let wins = [
  //       { 
  //         'user': 'USER1',
  //         'market': marketId,
  //         'category': 'defi',
  //         'bet_amount': '100',
  //         'won_amount': '500'
  //       }
  //     ]

  //     let data = JSON.stringify(wins[0]);

  //     await message({
  //       process: processId,
  //       tags: [
  //         { name: "Action", value: "Win-Ingest" }
  //       ],
  //       signer: createDataItemSigner(protocolProcess2),
  //       data: data,
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

  //     expect(Messages.length).to.be.greaterThanOrEqual(1)

  //     const data_ = JSON.parse(Messages[0].Data)
  //     const action = Messages[0].Tags.find(t => t.name == "Action").value

  //     expect(action).to.eql('Win-Ingested')
  //     expect(data_['user']).to.eql(wins[0].user)
  //     expect(data_['market']).to.eql(wins[0].market)
  //     expect(data_['category']).to.eql(wins[0].category)
  //     expect(data_['bet_amount']).to.eql(wins[0].bet_amount)
  //     expect(data_['won_amount']).to.eql(wins[0].won_amount)
  //   })
  // })

  /***********************************************************************
  * UI DATA: USER
  ************************************************************************/

  /* 
   * User data
   */
  describe("UI.User", function () {
    it("+ve should return user data", async () => {
      
      let data = JSON.stringify({'id': users[0].id});

      await message({
        process: processId,
        tags: [
          { name: "Action", value: "UI-User" }
        ],
        signer: createDataItemSigner(protocolProcess2),
        data: data,
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

      const data_ = JSON.parse(Messages[0].Data)

      expect(data_['id']).to.eql(users[0].id)
    })
  })

  /***********************************************************************
  * UI DATA: LEADERBOARD
  ************************************************************************/

  /* 
   * Total Leaderboard data
   */
  describe("UI.Leaderboard", function () {
    it("+ve should return leaderboard data", async () => {
    
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "UI-Leaderboard" }
        ],
        signer: createDataItemSigner(admin1),
        data: '',
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

      const data = JSON.parse(Messages[0].Data)

      expect(data.length).to.eql(0)
    })
  })

  /* 
   * Category Leaderboard data
   */
  describe("UI.Leaderboard", function () {
    it("+ve should return category leaderboard data", async () => {
    
      await message({
        process: processId,
        tags: [
          { name: "Action", value: "UI-Leaderboard" },
          { name: "Category", value: "ao" }
        ],
        signer: createDataItemSigner(admin1),
        data: '',
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

      const data = JSON.parse(Messages[0].Data)

      expect(data.length).to.eql(0)
    })
  })
})