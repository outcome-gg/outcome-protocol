require("luacov")
local semiFungibleTokens = require("marketModules.semiFungibleTokens")require("luacov")
local json = require("json")

-- Mock the Market.cpmm object
---@diagnostic disable-next-line: missing-fields
_G.Market = { cpmm = {tokens = { positionIds = { "1", "2", "3" } } } }

local name = ''
local ticker = ''
local logo = ''
local balancesById = {}
local totalSupplyById = {}
local denomination = nil
local minter = ""
local sender = ""
local recipient = ""
local positionId = ""
local quantity = ""
local positionIds = {}
local quantities = {}
local recipients = {}
local remainingBalances = {}
local msgMint = {}
local msgMintBatch = {}
local msgBurn = {}
local msgBurnBatch = {}
local msgTransfer = {}
local msgTransferBatch = {}
local msgBalance = {}
local msgBalances = {}
local msgBatchBalance = {}
local msgBatchBalances = {}
local noticeBurnBatch = {}
local noticeDebitSingle = {}
local noticeCreditSingle = {}
local noticeDebitBatch = {}
local noticeCreditBatch = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
    if tag.name == targetName then
      return tag.value
    end
  end
  return nil -- Return nil if the name is not found
end

describe("#market #semiFungibleTokens #semiFungibleTokensInternal", function()
  before_each(function()
    -- set variables
    -- set name
    name = ''
    -- set ticker
    ticker = ''
    -- set logo
    logo = ''
    -- set balances
    balancesById = {}
    -- set totalSupply
    totalSupplyById = {}
    -- set denomination
    denomination = 12
    -- instantiate semiFungibleTokens
		SemiFungibleTokens = semiFungibleTokens:new(
      name,
      ticker,
      logo,
      balancesById,
      totalSupplyById,
      denomination
    )
    minter = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    positionId = "1"
    quantity = "100"
    positionIds = { "1", "2", "3" }
    quantities = { "100", "200", "300" }
    recipients = {
      "test-this-is-valid-arweave-wallet-address-2",
      "test-this-is-valid-arweave-wallet-address-3",
      "test-this-is-valid-arweave-wallet-address-4"
    }
    remainingBalances = { "0", "0", "0" }
    -- create a message object
		msgMint = {
      From = minter,
      Tags = {
        Action = "Mint-Single",
        Recipient = sender,
        PositionId = positionId,
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
		msgMintBatch = {
      From = minter,
      Tags = {
        Action = "Mint-Batch",
        Recipient = sender,
        PositionIds = positionIds,
        Quantities = quantities,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
		msgBurn = {
      From = sender,
      Tags = {
        Action = "Burn-Single",
        PositionId = positionId,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      forward = function(target, message) return message end
    }
    -- create a message object
		msgBurnBatch = {
      From = sender,
      Tags = {
        Action = "Burn-Batch",
        PositionIds = positionIds,
        Quantities = quantities,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
		msgTransfer = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionId = positionId,
        Quantity = quantity,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgTransferBatch = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionIds = positionIds,
        Quantities = quantities,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBalance = {
      From = sender,
      Tags = {
        PositionId = positionId
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBalances = {
      From = sender,
      Tags = {
        PositionId = positionId
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBatchBalance = {
      From = sender,
      Tags = {
        Recipients = json.encode(recipients),
        PositionIds = json.encode(positionIds)
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBatchBalances = {
      From = sender,
      Tags = {
        PositionIds = json.encode(positionIds)
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a notice object
    noticeCreditBatch = {
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      Data = "Successfully burned batch"
    }
     -- create a notice object
     noticeDebitSingle = {
      Action = "Debit-Single-Notice",
      Recipient = recipient,
      PositionId = positionId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You transferred 100 of id 1 to " .. recipient
    }
    -- create a notice object
    noticeCreditSingle = {
      Action = "Credit-Single-Notice",
      Sender = sender,
      PositionId = positionId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You received 100 of id 1 from " .. sender
    }
    -- create a notice object
    noticeDebitBatch = {
      Action = "Debit-Batch-Notice",
      Recipient = recipient,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You transferred batch to " .. recipient
    }
    -- create a notice object
    noticeCreditBatch = {
      Action = "Credit-Batch-Notice",
      Sender = sender,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You received batch from " .. sender
    }
	end)

  it("should init semiFungibleTokens", function()
    -- assert initial state
    assert.are.same(SemiFungibleTokens.name, name)
    assert.are.same(SemiFungibleTokens.ticker, ticker)
    assert.are.same(SemiFungibleTokens.logo, logo)
    assert.are.same(SemiFungibleTokens.balancesById, balancesById)
    assert.are.same(SemiFungibleTokens.totalSupplyById, totalSupplyById)
    assert.are.same(SemiFungibleTokens.denomination, denomination)
	end)

  it("should mint", function()
    local notice = {}
    -- should not throw an error
		assert.has_no.errors(function()
      notice = SemiFungibleTokens:mint(
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, SemiFungibleTokens.balancesById[msgMint.Tags.PositionId][sender])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, SemiFungibleTokens.totalSupplyById[msgMint.Tags.PositionId])
    -- assert notice
    assert.are.same({
      Recipient = sender,
      PositionId = msgMint.Tags.PositionId,
      Quantity = msgMint.Tags.Quantity,
      Action = 'Mint-Single-Notice',
      Data = "Successfully minted " .. msgMint.Tags.Quantity .. " of id " .. msgMint.Tags.PositionId
    }, notice)
	end)

  it("should mint batch", function()
    local notice = {}
    -- should not throw an error
		assert.has_no.errors(function()
      notice = SemiFungibleTokens:batchMint(
        msgMintBatch.Tags.Recipient,
        msgMintBatch.Tags.PositionIds,
        msgMintBatch.Tags.Quantities,
        msgMintBatch
      )
    end)
    -- assert updated balance
    assert.are.same(msgMintBatch.Tags.Quantities[1], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[1]][sender])
    assert.are.same(msgMintBatch.Tags.Quantities[2], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[2]][sender])
    assert.are.same(msgMintBatch.Tags.Quantities[3], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[3]][sender])
    -- assert update total supply
    assert.are.same(msgMintBatch.Tags.Quantities[1], SemiFungibleTokens.totalSupplyById[msgMintBatch.Tags.PositionIds[1]])
    assert.are.same(msgMintBatch.Tags.Quantities[2], SemiFungibleTokens.totalSupplyById[msgMintBatch.Tags.PositionIds[2]])
    assert.are.same(msgMintBatch.Tags.Quantities[3], SemiFungibleTokens.totalSupplyById[msgMintBatch.Tags.PositionIds[3]])
    -- assert notice
    assert.are.same({
      Recipient = sender,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      Action = 'Mint-Batch-Notice',
      Data = "Successfully minted batch"
    }, notice)
	end)

  it("should burn", function()
    local notice = {}
    -- mint tokens
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:mint(
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- burn tokens
    -- should not throw an error
		assert.has_no.errors(function()
      notice = SemiFungibleTokens:burn(
        msgBurn.From,
        msgBurn.Tags.PositionId,
        msgBurn.Tags.Quantity,
        msgBurn
      )
    end)
    -- assert updated balance
    assert.are.same('0', SemiFungibleTokens.balancesById[msgBurn.Tags.PositionId][sender])
    -- assert update total supply
    assert.are.same('0', SemiFungibleTokens.totalSupplyById[msgBurn.Tags.PositionId])
    -- assert notice
    assert.are.same({
      Recipient = msgBurn.From,
      PositionId = msgBurn.Tags.PositionId,
      Quantity = msgBurn.Tags.Quantity,
      Action = 'Burn-Single-Notice',
      ["X-Action"] = "FOO",
      Data = "Successfully burned " .. msgBurn.Tags.Quantity .. " of id " .. msgBurn.Tags.PositionId
    }, notice)
	end)

  it("should burn batch", function()
    local notice = {}
    -- batch mint tokens
    -- should not throw an error
    assert.has_no.errors(function()
      SemiFungibleTokens:batchMint(
        msgMintBatch.Tags.Recipient,
        msgMintBatch.Tags.PositionIds,
        msgMintBatch.Tags.Quantities,
        msgMintBatch
      )
    end)
    -- burn tokens
    -- should not throw an error
		assert.has_no.errors(function()
      notice = SemiFungibleTokens:batchBurn(
      msgBurnBatch.From,
      msgBurnBatch.Tags.PositionIds,
      msgBurnBatch.Tags.Quantities,
      msgBurnBatch
    )
    end)
    -- assert updated balance
    assert.are.same('0', SemiFungibleTokens.balancesById[msgBurnBatch.Tags.PositionIds[1]][sender])
    assert.are.same('0', SemiFungibleTokens.balancesById[msgBurnBatch.Tags.PositionIds[2]][sender])
    assert.are.same('0', SemiFungibleTokens.balancesById[msgBurnBatch.Tags.PositionIds[3]][sender])
    -- assert update total supply
    assert.are.same('0', SemiFungibleTokens.totalSupplyById[msgBurnBatch.Tags.PositionIds[1]])
    assert.are.same('0', SemiFungibleTokens.totalSupplyById[msgBurnBatch.Tags.PositionIds[2]])
    assert.are.same('0', SemiFungibleTokens.totalSupplyById[msgBurnBatch.Tags.PositionIds[3]])
    -- assert notice
    assert.are.same({
      Recipient = msgBurnBatch.From,
      PositionIds = json.encode(msgBurnBatch.Tags.PositionIds),
      Quantities = json.encode(msgBurnBatch.Tags.Quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      ["X-Action"] = "FOO",
      Data = "Successfully burned batch"
    }, notice)
	end)

  it("should transfer tokens", function()
    local notices = {}
    -- mint tokens
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:mint(
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- should not throw an error
    assert.has_no.errors(function()
      notices = SemiFungibleTokens:transferSingle(
        msgTransfer.From,
        msgTransfer.Tags.Recipient,
        msgTransfer.Tags.PositionId,
        msgTransfer.Tags.Quantity,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgTransfer.Tags.Quantity, SemiFungibleTokens.balancesById[positionId][recipient])
    -- assert update total supply
    assert.are.same(msgTransfer.Tags.Quantity, SemiFungibleTokens.totalSupplyById[positionId])
    -- assert notices
    assert.are.same(noticeDebitSingle, notices[1])
    assert.are.same(noticeCreditSingle, notices[2])
	end)

  it("should fail to transfer tokens with insufficient balance", function()
    local notice = {}
    -- should throw an error
    assert.has_no.errors(function()
      notice = SemiFungibleTokens:transferSingle(
        msgTransfer.From,
        msgTransfer.Tags.Recipient,
        msgTransfer.Tags.PositionId,
        msgTransfer.Tags.Quantity,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert no updated balance
    assert.are.same('0', SemiFungibleTokens.balancesById[positionId][sender])
    -- assert no updated total supply
    assert.are.same(nil, SemiFungibleTokens.totalSupplyById[positionId])
    -- assert error notice
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransfer.Id,
      ['PositionId'] = msgTransfer.Tags.PositionId,
      Error = 'Insufficient Balance!'
    }, notice)
	end)

  it("should batch transfer tokens", function()
    local notices = {}
    -- mint tokens
    -- should not throw an error
    assert.has_no.errors(function()
      SemiFungibleTokens:batchMint(
        msgMintBatch.Tags.Recipient,
        msgMintBatch.Tags.PositionIds,
        msgMintBatch.Tags.Quantities,
        msgMintBatch
      )
    end)
    -- should not throw an error
    assert.has_no.errors(function()
      notices = SemiFungibleTokens:transferBatch(
        msgTransferBatch.From,
        msgTransferBatch.Tags.Recipient,
        msgTransferBatch.Tags.PositionIds,
        msgTransferBatch.Tags.Quantities,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgTransferBatch.Tags.Quantities[1], SemiFungibleTokens.balancesById[positionIds[1]][recipient])
    assert.are.same(msgTransferBatch.Tags.Quantities[2], SemiFungibleTokens.balancesById[positionIds[2]][recipient])
    assert.are.same(msgTransferBatch.Tags.Quantities[3], SemiFungibleTokens.balancesById[positionIds[3]][recipient])
    -- assert update total supply
    assert.are.same(msgTransferBatch.Tags.Quantities[1], SemiFungibleTokens.totalSupplyById[positionIds[1]])
    assert.are.same(msgTransferBatch.Tags.Quantities[2], SemiFungibleTokens.totalSupplyById[positionIds[2]])
    assert.are.same(msgTransferBatch.Tags.Quantities[3], SemiFungibleTokens.totalSupplyById[positionIds[3]])
    -- assert notices
    assert.are.same(noticeDebitBatch, notices[1])
    assert.are.same(noticeCreditBatch, notices[2])
	end)

  it("should fail to batch transfer tokens with insufficient balance", function()
    local notice = {}
    -- should throw an error
    assert.has_no.errors(function()
      notice = SemiFungibleTokens:transferBatch(
        msgTransferBatch.From,
        msgTransferBatch.Tags.Recipient,
        msgTransferBatch.Tags.PositionIds,
        msgTransferBatch.Tags.Quantities,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert no updated balance
    assert.are.same('0', SemiFungibleTokens.balancesById[positionId][sender])
    -- assert no updated total supply
    assert.are.same(nil, SemiFungibleTokens.totalSupplyById[positionId])
    -- assert error notice
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransfer.Id,
      ['PositionId'] = msgTransfer.Tags.PositionId,
      Error = 'Insufficient Balance!'
    }, notice)
	end)

  it("should get balance", function()
    local balance = ''
    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:mint(
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balance = SemiFungibleTokens:getBalance(
      msgMint.From,
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId
    )
    end)
    -- assert balance
    assert.are.same(msgMint.Tags.Quantity, balance)
    assert.are.same(msgMint.Tags.Quantity, SemiFungibleTokens.balancesById[msgMint.Tags.PositionId][msgMint.Tags.Recipient])
	end)

  it("should get balance from sender (no recipient)", function()
    local balance = ''
    -- mint to msgMint.From
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:mint(
      msgMint.From,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balance = SemiFungibleTokens:getBalance(
      msgMint.From,
      nil, -- no recipient
      msgMint.Tags.PositionId
    )
    end)
    -- assert balance
    assert.are.same(msgMint.Tags.Quantity, balance)
    assert.are.same(msgMint.Tags.Quantity, SemiFungibleTokens.balancesById[msgMint.Tags.PositionId][msgMint.From])
	end)

  it("should get batch balance", function()
    local balances = {}
    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:batchMint(
        msgMintBatch.Tags.Recipient,
        msgMintBatch.Tags.PositionIds,
        msgMintBatch.Tags.Quantities,
        msgMintBatch
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balances = SemiFungibleTokens:getBatchBalance(
        {
          msgMintBatch.Tags.Recipient,
          msgMintBatch.Tags.Recipient,
          msgMintBatch.Tags.Recipient
        },
        msgMintBatch.Tags.PositionIds
      )
    end)
    -- assert balances
    assert.are.same(msgMintBatch.Tags.Quantities[1], balances[1])
    assert.are.same(msgMintBatch.Tags.Quantities[2], balances[2])
    assert.are.same(msgMintBatch.Tags.Quantities[3], balances[3])
    assert.are.same(msgMintBatch.Tags.Quantities[1], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[1]][sender])
    assert.are.same(msgMintBatch.Tags.Quantities[2], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[2]][sender])
    assert.are.same(msgMintBatch.Tags.Quantities[3], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[3]][sender])
	end)

  it("should get balances", function()
    local balances = {}
    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:mint(
      msgMint.Tags.Recipient,
      msgMint.Tags.PositionId,
      msgMint.Tags.Quantity,
      msgMint
    )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balances = SemiFungibleTokens:getBalances(
      msgMint.Tags.PositionId
    )
    end)
    -- assert balance
    assert.are.same(msgMint.Tags.Quantity, balances[msgMint.Tags.Recipient])
    assert.are.same(msgMint.Tags.Quantity, SemiFungibleTokens.balancesById[msgMint.Tags.PositionId][msgMint.Tags.Recipient])
	end)

  it("should get batch balances", function()
    local balances = {}
    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      SemiFungibleTokens:batchMint(
        msgMintBatch.Tags.Recipient,
        msgMintBatch.Tags.PositionIds,
        msgMintBatch.Tags.Quantities,
        msgMintBatch
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balances = SemiFungibleTokens:getBatchBalances(
        msgMintBatch.Tags.PositionIds
      )
    end)
    -- assert balances
    assert.are.same(msgMintBatch.Tags.Quantities[1], balances[msgMintBatch.Tags.PositionIds[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(msgMintBatch.Tags.Quantities[2], balances[msgMintBatch.Tags.PositionIds[2]][msgMintBatch.Tags.Recipient])
    assert.are.same(msgMintBatch.Tags.Quantities[3], balances[msgMintBatch.Tags.PositionIds[3]][msgMintBatch.Tags.Recipient])
    assert.are.same(msgMintBatch.Tags.Quantities[1], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(msgMintBatch.Tags.Quantities[2], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[2]][msgMintBatch.Tags.Recipient])
    assert.are.same(msgMintBatch.Tags.Quantities[3], SemiFungibleTokens.balancesById[msgMintBatch.Tags.PositionIds[3]][msgMintBatch.Tags.Recipient])
	end)
end)