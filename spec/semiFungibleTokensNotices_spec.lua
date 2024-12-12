require("luacov")
local semiFungibleTokensNotices = require("modules.semiFungibleTokensNotices")
local json = require("json")

-- Define variables
local sender = ""
local recipient = ""
local tokenId = ""
local quantity = ""
local tokenIds = {}
local quantities = {}
local recipients = {}
local msgMintSingle = {}
local msgMintBatch = {}
local msgBurnSingle = {}
local msgBurnBatch = {}
local msgTransferSingle = {}
local msgTransferBatch = {}
local noticeDebitSingle = {}
local noticeCreditSingle = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("market.modules.semiFungibleTokensNotices", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    tokenId = "1"
    quantity = "100"
    tokenIds = { "1", "2", "3" }
    quantities = { "100", "200", "300" }
    recipients = {
      "test-this-is-valid-arweave-wallet-address-2",
      "test-this-is-valid-arweave-wallet-address-3",
      "test-this-is-valid-arweave-wallet-address-4"
    }
    -- create a message object
    msgMintSingle = {
      From = sender,
      Tags = {
        Action = "Mint",
        Recipient = recipient,
        TokenId = tokenId,
        Quantity = quantity,
      },
      reply = function(message) return message end
    }
    msgMintBatch = {
      From = sender,
      Tags = {
        Action = "Mint",
        Recipients = recipient,
        TokenIds = json.encode(tokenIds),
        Quantities = json.encode(quantities),
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBurnSingle = {
      From = sender,
      Tags = {
        Action = "Burn",
        Quantity = quantity,
      },
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
      reply = function(message) return message end
    }
    -- create a message object
    msgTransferBatch = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipients = json.encode(recipients),
        TokenIds = json.encode(tokenId),
        Quantitys = json.encode(quantity),
      },
      Id = "test-message-id",
      reply = function(message) return message end
    }
    -- create a notice object
    noticeDebitSingle = {
      Target = sender,
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to test-this-is-valid-arweave-wallet-address-2"
    }
    -- create a notice object
    noticeCreditSingle = {
      Target = recipient,
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from test-this-is-valid-arweave-wallet-address-1"
    }
	end)

  it("should send mintNotice", function()
    local notice = semiFungibleTokensNotices.mintSingleNotice(
      msgMintSingle.Tags.Recipient,
      msgMintSingle.Tags.TokenId,
      msgMintSingle.Tags.Quantity,
      msgMintSingle
    )
    assert.are.same({
      TokenId = msgMintSingle.Tags.TokenId,
      Quantity = msgMintSingle.Tags.Quantity,
      Action = 'Mint-Single-Notice',
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. tostring(quantity) .. Colors.gray .. " of id " .. Colors.blue .. tostring(tokenId) .. Colors.reset
    }, notice)
	end)

  -- it("should send burnNotice", function()
  --   local notice = semiFungibleTokensNotices.burnNotice(
  --     msgBurn.Tags.Quantity,
  --     msgBurn
  --   )
  --   assert.are.same({
  --     Action = 'Burn-Notice',
  --     Quantity = msgBurn.Tags.Quantity,
  --     Data = "Successfully burned " .. msgBurn.Tags.Quantity
  --   }, notice)
	-- end)

  -- it("should send transferNotices", function()
  --   local notices = semiFungibleTokensNotices.transferNotices(
  --     noticeDebit,
  --     noticeCredit,
  --     msgTransfer
  --   )
  --   assert.are.same(noticeDebit, notices[1])
  --   assert.are.same(noticeCredit.Target, notices[2].Target)
  --   assert.are.same(noticeCredit.Action, getTagValue(notices[2].Tags, "Action"))
  --   assert.are.same(noticeCredit.Sender, getTagValue(notices[2].Tags, "Sender"))
  --   assert.are.same(noticeCredit.Quantity, getTagValue(notices[2].Tags, "Quantity"))
  --   assert.are.same(noticeCredit["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	-- end)

  -- it("should send transferErrorNotice", function()
  --   local notice = semiFungibleTokensNotices.transferErrorNotice(
  --     msgTransfer
  --   )
  --   assert.are.same({
  --     Action = 'Transfer-Error',
  --     ['Message-Id'] = msgTransfer.Id,
  --     Error = 'Insufficient Balance!'
  --   }, notice)
	-- end)
end)