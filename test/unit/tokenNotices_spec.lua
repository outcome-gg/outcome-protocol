require("luacov")
local tokenNotices = require("marketModules.tokenNotices")
local json = require("json")

-- Define variables
local sender = ""
local recipient = ""
local msgMint = {}
local msgBurn = {}
local msgTransfer = {}
local noticeDebit = {}
local noticeCredit = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
    if tag.name == targetName then
      return tag.value
    end
  end
  return nil -- Return nil if the name is not found
end

describe("#market #token #tokenNotices", function()
  before_each(function()
    -- set sender
    sender = "test-this-is-valid-arweave-wallet-address-1"
    -- set recipient
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    -- create a message object
    msgMint = {
      From = sender,
      Tags = {
        Action = "Mint",
        Recipient = recipient,
        Quantity = "100",
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBurn = {
      From = sender,
      Tags = {
        Action = "Burn",
        Quantity = "100",
      },
      reply = function(message) return message end,
    }
    -- create a message object
    msgTransfer = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipient = recipient,
        Quantity = "100",
      },
      Id = "test-message-id",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a notice object
    noticeDebit = {
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to test-this-is-valid-arweave-wallet-address-2"
    }
    -- create a notice object
    noticeCredit = {
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from test-this-is-valid-arweave-wallet-address-1"
    }
	end)

  it("should send mintNotice", function()
    local notice = tokenNotices.mintNotice(
      msgMint.Tags.Recipient,
      msgMint.Tags.Quantity,
      true, -- expectReply
      msgMint
    )
    assert.are.same({
      Recipient = msgMint.Tags.Recipient,
      Quantity = msgMint.Tags.Quantity,
      Action = 'Mint-Notice',
      Data = "Successfully minted " .. msgMint.Tags.Quantity
    }, notice)
	end)

  it("should send burnNotice", function()
    local notice = tokenNotices.burnNotice(
      msgBurn.Tags.Quantity,
      true, -- expectReply
      msgBurn
    )

    assert.are.same({
      Target = msgBurn.From,
      Action = 'Burn-Notice',
      Quantity = msgBurn.Tags.Quantity,
      Data = "Successfully burned " .. msgBurn.Tags.Quantity
    }, notice)
	end)

  it("should send transferNotices", function()
    local notices = tokenNotices.transferNotices(
      noticeDebit,
      noticeCredit,
      recipient,
      true, -- expectReply
      msgTransfer
    )
    assert.are.same(noticeDebit, notices[1])
    assert.are.same(noticeCredit, notices[2])
	end)

  it("should send transferErrorNotice", function()
    local notice = tokenNotices.transferErrorNotice(
      msgTransfer
    )
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransfer.Id,
      Error = 'Insufficient Balance!'
    }, notice)
	end)
end)