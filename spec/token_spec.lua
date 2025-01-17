require("luacov")
local token = require("marketModules.token")
local json = require("json")
-- Define variables
local sender = ""
local recipient = ""
local quantity = nil
local burnQuantity = nil
local name = ''
local ticker = ''
local logo = ''
local balances = {}
local totalSupply = ''
local denomination = nil
local msgMint = {}
local msgBurn = {}
local msgTransfer = {}
local msgTransferError = {}
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

describe("#market #token #tokenInternal", function()
  before_each(function()
    -- set sender
    sender = "test-this-is-valid-arweave-wallet-address-1"
    -- set recipient
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    -- set quantity
    quantity = "100"
    -- set burnQuantity
    burnQuantity = "50"
    -- set name
    name = ''
    -- set ticker
    ticker = ''
    -- set logo
    logo = ''
    -- set balances
    balances = {}
    -- set totalSupply
    totalSupply = "0"
    -- set denomination
    denomination = 12
    -- instantiate token
		Token = token:new(
      name,
      ticker,
      logo,
      balances,
      totalSupply,
      denomination
    )
    -- create a message object
    msgMint = {
      From = sender,
      Tags = {
        Recipient = recipient,
        Quantity = quantity
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBurn = {
      From = sender,
      Tags = {
        Quantity = burnQuantity
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgTransfer = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipient = recipient,
        Quantity = "100",
        ["X-Action"] = "FOO"
      },
      Id = "test-message-id",
      reply = function(message) return message end
    }
    msgTransferError = {
      From = recipient,
      Tags = {
        Action = "Transfer",
        Recipient = sender,
        Quantity = "100"
      },
      Id = "test-message-id",
      reply = function(message) return message end
    }
    -- create a notice object
    noticeDebit = {
      Target = sender,
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to test-this-is-valid-arweave-wallet-address-2"
    }
    -- create a notice object
    noticeCredit = {
      Target = recipient,
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from test-this-is-valid-arweave-wallet-address-1"
    }
	end)

  it("should init tokens", function()
    -- assert initial state
    assert.are.same(Token.name, name)
    assert.are.same(Token.ticker, ticker)
    assert.are.same(Token.logo, logo)
    assert.are.same(Token.balances, balances)
    assert.are.same(Token.totalSupply, totalSupply)
    assert.are.same(Token.denomination, denomination)
	end)

  it("should mint tokens", function()
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = Token:mint(
        msgMint.Tags.Recipient,
        msgMint.Tags.Quantity,
        msgMint
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, Token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, Token.totalSupply)
    -- assert notice
    assert.are.same({
      Recipient = recipient,
      Quantity = msgMint.Tags.Quantity,
      Action = 'Mint-Notice',
      Data = "Successfully minted " .. msgMint.Tags.Quantity
    }, notice)
	end)

  it("should burn tokens", function()
    local notice = {}
    -- mint tokens
    Token:mint(
        msgMint.From,
        msgMint.Tags.Quantity,
        msgMint
      )
    -- should not throw an error
    assert.has_no.errors(function()
      notice = Token:burn(
        msgBurn.From,
        msgBurn.Tags.Quantity,
        msgBurn
      )
    end)
    -- calculate expected updated balance
    local updateBalance = tostring(tonumber(quantity) - tonumber(burnQuantity))
    -- assert updated balance
    assert.are.same(Token.balances[sender], updateBalance)
    -- assert update total supply
    assert.are.same(Token.totalSupply, updateBalance)
    -- assert notice
    assert.are.same({
      Quantity = msgBurn.Tags.Quantity,
      Action = 'Burn-Notice',
      Data = "Successfully burned " .. msgBurn.Tags.Quantity
    }, notice)
	end)

  it("should transfer tokens", function()
    local notices = {}
    -- mint tokens
    Token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- should not throw an error
    assert.has_no.errors(function()
      notices = Token:transfer(
        msgTransfer.From,
        msgTransfer.Tags.Recipient,
        msgTransfer.Tags.Quantity,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, Token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, Token.totalSupply)
    -- assert notices
    assert.are.same(noticeDebit, notices[1])
    assert.are.same(noticeCredit.Target, notices[2].Target)
    assert.are.same(noticeCredit.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCredit.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCredit.Quantity, getTagValue(notices[2].Tags, "Quantity"))
    assert.are.same(noticeCredit["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should fail to transfer tokens with insufficient balance", function()
    local notice = {}
    -- should not throw an error
    assert.has_no.error(function()
      notice = Token:transfer(
        msgTransferError.From,
        msgTransferError.Tags.Recipient,
        msgTransferError.Tags.Quantity,
        false, -- cast
        msgTransferError
      )
    end)
    -- assert no updated balance
    assert.are.same('0', Token.balances[recipient])
    -- assert no updated total supply
    assert.are.same('0', Token.totalSupply)
    -- assert error notice
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransferError.Id,
      Error = 'Insufficient Balance!'
    }, notice)
	end)
end)