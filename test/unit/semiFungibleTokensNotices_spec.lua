require("luacov")
local semiFungibleTokensNotices = require("marketModules.semiFungibleTokensNotices")
local json = require("json")

-- Define variables
local sender = ""
local recipient = ""
local positionId = ""
local quantity = ""
local positionIds = {}
local quantities = {}
local remainingBalances = {}
local msgMintSingle = {}
local msgMintBatch = {}
local msgBurnSingle = {}
local msgBurnBatch = {}
local msgTransferSingle = {}
local msgTransferBatch = {}
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

describe("#market #semiFungibleTokens #semiFungibleTokensNotices", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    positionId = "1"
    quantity = "100"
    positionIds = { "1", "2", "3" }
    quantities = { "100", "200", "300" }
    remainingBalances = { "1", "0", "0" }
    -- create a message object
    msgMintSingle = {
      From = sender,
      Tags = {
        Action = "Mint-Single",
        Recipient = recipient,
        PositionId = positionId,
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    msgMintBatch = {
      From = sender,
      Tags = {
        Action = "Mint-Batch",
        Recipient = recipient,
        PositionIds = positionIds,
        Quantities = quantities,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBurnSingle = {
      From = sender,
      Tags = {
        Action = "Burn-Single",
        PositionId = positionId,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBurnBatch = {
      From = sender,
      Tags = {
        Action = "Burn-Single",
        PositionIds = positionIds,
        Quantities = quantities,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgTransferSingle = {
      From = sender,
      Tags = {
        Action = "Transfer",
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
        Action = "Transfer",
        Recipient = recipient,
        PositionIds = positionIds,
        Quantities = quantities,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a notice object
    noticeBurnBatch = {
      Recipient = sender,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      ["X-Action"] = "FOO",
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

  it("should send mintSingleNotice", function()
    local notice = semiFungibleTokensNotices.mintSingleNotice(
      msgMintSingle.Tags.Recipient,
      msgMintSingle.Tags.PositionId,
      msgMintSingle.Tags.Quantity,
      false, -- async
      msgMintSingle
    )
    assert.are.same({
      Recipient = msgMintSingle.Tags.Recipient,
      PositionId = msgMintSingle.Tags.PositionId,
      Quantity = msgMintSingle.Tags.Quantity,
      Action = 'Mint-Single-Notice',
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(positionId) .. Colors.reset
    }, notice)
	end)

  it("should send mintBatchNotice", function()
    local notice = semiFungibleTokensNotices.mintBatchNotice(
      msgMintBatch.Tags.Recipient,
      msgMintBatch.Tags.PositionIds,
      msgMintBatch.Tags.Quantities,
      false, -- async
      msgMintBatch
    )
    assert.are.same({
      Recipient = recipient,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      Action = 'Mint-Batch-Notice',
      Data = "Successfully minted batch"
    }, notice)
	end)

  it("should send burnSingleNotice", function()
    local notice = semiFungibleTokensNotices.burnSingleNotice(
      msgBurnSingle.From,
      msgBurnSingle.Tags.PositionId,
      msgBurnSingle.Tags.Quantity,
      false, -- async
      msgBurnSingle
    )
    assert.are.same({
      Recipient = msgBurnSingle.From,
      PositionId = msgBurnSingle.Tags.PositionId,
      Quantity = msgBurnSingle.Tags.Quantity,
      Action = 'Burn-Single-Notice',
      ["X-Action"] = "FOO",
      Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(positionId) .. Colors.reset
    }, notice)
	end)

  it("should send burnBatchNotice", function()
    local notice = semiFungibleTokensNotices.burnBatchNotice(
      sender,
      json.decode(noticeBurnBatch.PositionIds),
      json.decode(noticeBurnBatch.Quantities),
      json.decode(noticeBurnBatch.RemainingBalances),
      false, -- async
      msgBurnBatch
    )
    -- assert.are.same(remainingBalances, notice.RemainingBalances)
    assert.are.same(noticeBurnBatch, notice)
	end)

  it("should send transferSingleNotices", function()
    local notices = semiFungibleTokensNotices.transferSingleNotices(
      msgTransferSingle.From,
      msgTransferSingle.Tags.Recipient,
      msgTransferSingle.Tags.PositionId,
      msgTransferSingle.Tags.Quantity,
      false, -- async
      msgTransferSingle
    )
    assert.are.same(noticeDebitSingle, notices[1])
    assert.are.same(noticeCreditSingle, notices[2])
	end)

  it("should send transferBatchNotices", function()
    local notices = semiFungibleTokensNotices.transferBatchNotices(
      msgTransferBatch.From,
      msgTransferBatch.Tags.Recipient,
      msgTransferBatch.Tags.PositionIds,
      msgTransferBatch.Tags.Quantities,
      false, -- async
      msgTransferBatch
    )
    assert.are.same(noticeDebitBatch, notices[1])
    assert.are.same(noticeCreditBatch, notices[2])
	end)

  it("should send transferErrorNotice", function()
    local notice = semiFungibleTokensNotices.transferErrorNotice(
      msgTransferSingle.Tags.PositionId,
      msgTransferSingle
    )
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransferSingle.Id,
      ['PositionId'] = msgTransferSingle.Tags.PositionId,
      Error = 'Insufficient Balance!'
    }, notice)
	end)
end)