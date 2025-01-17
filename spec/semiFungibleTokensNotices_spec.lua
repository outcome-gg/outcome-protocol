require("luacov")
local semiFungibleTokensNotices = require("marketModules.semiFungibleTokensNotices")
local json = require("json")

-- Define variables
local sender = ""
local recipient = ""
local tokenId = ""
local quantity = ""
local tokenIds = {}
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
    tokenId = "1"
    quantity = "100"
    tokenIds = { "1", "2", "3" }
    quantities = { "100", "200", "300" }
    remainingBalances = { "0", "0", "0" }
    -- create a message object
    msgMintSingle = {
      From = sender,
      Tags = {
        Action = "Mint-Single",
        Recipient = recipient,
        TokenId = tokenId,
        Quantity = quantity,
      },
      reply = function(message) return message end
    }
    msgMintBatch = {
      From = sender,
      Tags = {
        Action = "Mint-Batch",
        Recipient = recipient,
        TokenIds = tokenIds,
        Quantities = quantities,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBurnSingle = {
      From = sender,
      Tags = {
        Action = "Burn-Single",
        TokenId = tokenId,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
    -- create a message object
    msgBurnBatch = {
      From = sender,
      Tags = {
        Action = "Burn-Single",
        TokenIds = tokenIds,
        Quantities = quantities,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
    -- create a message object
    msgTransferSingle = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipient = recipient,
        TokenId = tokenId,
        Quantity = quantity,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
    -- create a message object
    msgTransferBatch = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipient = recipient,
        TokenIds = tokenIds,
        Quantities = quantities,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
    -- create a notice object
    noticeBurnBatch = {
      Recipient = sender,
      TokenIds = json.encode(tokenIds),
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
      TokenId = tokenId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You transferred 100 of id 1 to " .. recipient
    }
    -- create a notice object
    noticeCreditSingle = {
      Target = recipient,
      Action = "Credit-Single-Notice",
      Sender = sender,
      TokenId = tokenId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You received 100 of id 1 from " .. sender
    }
    -- create a notice object
    noticeDebitBatch = {
      Action = "Debit-Batch-Notice",
      Recipient = recipient,
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You transferred batch to " .. recipient
    }
    -- create a notice object
    noticeCreditBatch = {
      Target = recipient,
      Action = "Credit-Batch-Notice",
      Sender = sender,
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You received batch from " .. sender
    }
	end)

  it("should send mintSingleNotice", function()
    local notice = semiFungibleTokensNotices.mintSingleNotice(
      msgMintSingle.Tags.Recipient,
      msgMintSingle.Tags.TokenId,
      msgMintSingle.Tags.Quantity,
      msgMintSingle
    )
    assert.are.same({
      Recipient = msgMintSingle.Tags.Recipient,
      TokenId = msgMintSingle.Tags.TokenId,
      Quantity = msgMintSingle.Tags.Quantity,
      Action = 'Mint-Single-Notice',
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(tokenId) .. Colors.reset
    }, notice)
	end)

  it("should send mintBatchNotice", function()
    local notice = semiFungibleTokensNotices.mintBatchNotice(
      msgMintBatch.Tags.Recipient,
      msgMintBatch.Tags.TokenIds,
      msgMintBatch.Tags.Quantities,
      msgMintBatch
    )
    assert.are.same({
      Recipient = recipient,
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      Action = 'Mint-Batch-Notice',
      Data = "Successfully minted batch"
    }, notice)
	end)

  it("should send burnSingleNotice", function()
    local notice = semiFungibleTokensNotices.burnSingleNotice(
      msgBurnSingle.From,
      msgBurnSingle.Tags.TokenId,
      msgBurnSingle.Tags.Quantity,
      msgBurnSingle
    )
    assert.are.same({
      Recipient = msgBurnSingle.From,
      TokenId = msgBurnSingle.Tags.TokenId,
      Quantity = msgBurnSingle.Tags.Quantity,
      Action = 'Burn-Single-Notice',
      ["X-Action"] = "FOO",
      Data = Colors.gray .. "Successfully burned " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(tokenId) .. Colors.reset
    }, notice)
	end)

  it("should send burnBatchNotice", function()
    local notice = semiFungibleTokensNotices.burnBatchNotice(
      noticeBurnBatch,
      msgBurnBatch
    )
    assert.are.same(noticeBurnBatch, notice)
	end)

  it("should send transferSingleNotices", function()
    local notices = semiFungibleTokensNotices.transferSingleNotices(
      msgTransferSingle.From,
      msgTransferSingle.Tags.Recipient,
      msgTransferSingle.Tags.TokenId,
      msgTransferSingle.Tags.Quantity,
      msgTransferSingle
    )
    assert.are.same(noticeDebitSingle, notices[1])
    assert.are.same(noticeCreditSingle.Target, notices[2].Target)
    assert.are.same(noticeCreditSingle.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCreditSingle.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCreditSingle.Quantity, getTagValue(notices[2].Tags, "Quantity"))
    assert.are.same(noticeCreditSingle["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should send transferBatchNotices", function()
    local notices = semiFungibleTokensNotices.transferBatchNotices(
      msgTransferBatch.From,
      msgTransferBatch.Tags.Recipient,
      msgTransferBatch.Tags.TokenIds,
      msgTransferBatch.Tags.Quantities,
      msgTransferBatch
    )
    assert.are.same(noticeDebitBatch, notices[1])
    assert.are.same(noticeCreditBatch.Target, notices[2].Target)
    assert.are.same(noticeCreditBatch.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCreditBatch.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCreditBatch.TokenIds, getTagValue(notices[2].Tags, "TokenIds"))
    assert.are.same(noticeCreditBatch.Quantities, getTagValue(notices[2].Tags, "Quantities"))
    assert.are.same(noticeCreditBatch["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should send transferErrorNotice", function()
    local notice = semiFungibleTokensNotices.transferErrorNotice(
      msgTransferSingle.Tags.TokenId,
      msgTransferSingle
    )
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransferSingle.Id,
      ['Token-Id'] = msgTransferSingle.Tags.TokenId,
      Error = 'Insufficient Balance!'
    }, notice)
	end)
end)