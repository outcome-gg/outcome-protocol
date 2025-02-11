require("luacov")
local semiFungibleTokensValidation = require("marketModules.semiFungibleTokensValidation")
local json = require("json")

-- Mock the Market.cpmm object
---@diagnostic disable-next-line: missing-fields
_G.Market = { cpmm = {tokens = { positionIds = { "1", "2", "3" } } } }

local sender = ""
local recipient = ""
local positionId = ""
local quantity = ""
local positionIds = {}
local quantities = {}
local recipients = {}
local msg = {}
local msgBatch = {}
local msgBalance = {}
local msgBalances = {}
local msgBatchBalance = {}
local msgBatchBalances = {}

describe("#market #semiFungibleTokens #semiFungibleTokensValidation", function()
  before_each(function()
    -- set variables
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
    -- create a message object
		msg = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionId = positionId,
        Quantity = quantity,
      }
    }
    -- create a message object
    msgBatch = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionIds = json.encode(positionIds),
        Quantities = json.encode(quantities),
      }
    }
    -- create a message object
    msgBalance = {
      From = sender,
      Tags = {
        PositionId = positionId
      }
    }
    -- create a message object
    msgBalances = {
      From = sender,
      Tags = {
        PositionId = positionId
      }
    }
    -- create a message object
    msgBatchBalance = {
      From = sender,
      Tags = {
        Recipients = json.encode(recipients),
        PositionIds = json.encode(positionIds)
      }
    }
    -- create a message object
    msgBatchBalances = {
      From = sender,
      Tags = {
        PositionIds = json.encode(positionIds)
      }
    }
	end)

  it("should pass transfer-single validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.transferSingle(msg, positionIds)
    end)
	end)

  it("should fail transfer-single validation when recipient is missing", function()
    -- remove the Recipient 
    msg.Tags.Recipient = nil
    -- should throw an error
		assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, positionIds)
    end, "Recipient is required!")
	end)

  it("should fail transfer-single validation when recipient is invalid", function()
    -- change the Recipient to an invalid Arweave address
    msg.Tags.Recipient = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, positionIds)
    end, "Recipient must be a valid Arweave address!")
	end)

  it("should fail transfer-single validation when positionId is missing", function()
		-- remove the pP
    msg.Tags.PositionId = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "PositionId is required!")
	end)

  it("should fail transfer-single validation when positionId is invalid", function()
		-- change PositionId to invalid positionId
    msg.Tags.PositionId = "123"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Invalid PositionId!")
	end)

  it("should fail transfer-single validation when quantity is missing", function()
		-- remove the Quantity
    msg.Tags.Quantity = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity is required!")
	end)

  it("should fail transfer-single validation when quantity not a number", function()
		-- change the Quantity to a string
    msg.Tags.Quantity = "not-a-number"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be a number!")
	end)

  it("should fail transfer-single validation when quantity is zero", function()
		-- change the Quantity to zero
    msg.Tags.Quantity = "0"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer-single validation when quantity is negative", function()
		-- change the Quantity to a negative number
    msg.Tags.Quantity = "-123"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer-single validation when quantity is a decimal", function()
		-- change the Quantity to a decimal number
    msg.Tags.Quantity = "123.456"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferSingle(msg, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be an integer!")
	end)

  it("should pass transfer-batch validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end)
	end)

  it("should fail transfer-batch validation when recipient is missing", function()
    -- remove the Recipient 
    msgBatch.Tags.Recipient = nil
    -- should throw an error
		assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Recipient is required!")
	end)

  it("should fail transfer-batch validation when recipient is invalid", function()
    -- change the Recipient to an invalid Arweave address
    msgBatch.Tags.Recipient = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Recipient must be a valid Arweave address!")
	end)

  it("should fail transfer-batch validation when positionIds is missing", function()
		-- remove the PositionIds
    msgBatch.Tags.PositionIds = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "PositionIds is required!")
	end)

  it("should fail transfer-batch validation when quantities is missing", function()
		-- remove the Quantities
    msgBatch.Tags.Quantities = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantities is required!")
	end)

  it("should fail transfer-batch validation when #quantities != #positionIds", function()
		-- remove the Quantities
    msgBatch.Tags.Quantities = json.encode({ "100", "200" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Input array lengths must match!")
	end)

  it("should fail transfer-batch validation when positionId is invalid", function()
		-- change PositionIds to include an invalid positionId
    msgBatch.Tags.PositionIds = json.encode({ "1", "2", "123" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Invalid PositionId!")
	end)

  it("should fail transfer-batch validation when quantity not passed as a string", function()
		-- change the Quantity to a string
    msgBatch.Tags.Quantities = json.encode({ "1", "2", 3 })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity is required!")
	end)

  it("should fail transfer-batch validation when quantity not a number", function()
		-- change a quantity to a non-numeric string
    msgBatch.Tags.Quantities = json.encode({ "1", "2", "not-a-number" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be a number!")
	end)

  it("should fail transfer-single validation when quantity is zero", function()
		-- change a quantity to zero
    msgBatch.Tags.Quantities = json.encode({ "1", "2", "0" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer-batch validation when quantity is negative", function()
		-- change a quantity to a negative number
    msgBatch.Tags.Quantities = json.encode({ "1", "2", "-123" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer-batch validation when quantity is a decimal", function()
		-- change a quantity to a decimal number
    msgBatch.Tags.Quantities = json.encode({ "1", "2", "123.456" })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Quantity must be an integer!")
	end)

  it("should fail transfer-batch validation wheninput array lengths are zero", function()
		-- set input array lengths to zero
    msgBatch.Tags.PositionIds = json.encode({})
    msgBatch.Tags.Quantities = json.encode({})
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.transferBatch(msgBatch, _G.Market.cpmm.tokens.positionIds)
    end, "Input array length must be greater than zero!")
	end)

  it("should pass balance-by-id validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.balanceById(msgBalance, positionIds)
    end)
	end)

  it("should fail balance-by-id validation when positionId is invalid", function()
		-- change PositionId to invalid positionId
    msgBalance.Tags.PositionId = "123"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.balanceById(msgBalance, _G.Market.cpmm.tokens.positionIds)
    end, "Invalid PositionId!")
	end)

  it("should pass balances-by-id validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.balancesById(msgBalances, _G.Market.cpmm.tokens.positionIds)
    end)
	end)

  it("should fail balances-by-id validation when positionId is invalid", function()
		-- change PositionId to invalid positionId
    msgBalances.Tags.PositionId = "123"
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.balancesById(msgBalances, _G.Market.cpmm.tokens.positionIds)
    end, "Invalid PositionId!")
	end)

  it("should pass batch-balance validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.batchBalance(msgBatchBalance, _G.Market.cpmm.tokens.positionIds)
    end)
	end)

  it("should fail batch-balance validation when recipients is missing", function()
		-- remove Recipients 
    msgBatchBalance.Tags.Recipients = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalance(msgBatchBalance, _G.Market.cpmm.tokens.positionIds)
    end, "Recipients is required!")
	end)

  it("should fail batch-balance validation when recipients is invalid", function()
		-- remove Recipients 
    msgBatchBalance.Tags.Recipients = json.encode({
      "test-this-is-valid-arweave-wallet-address-2",
      "test-this-is-valid-arweave-wallet-address-3",
      "invalid-arweave-wallet-address"
    })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalance(msgBatchBalance, _G.Market.cpmm.tokens.positionIds)
    end, "Recipient must be a valid Arweave address!")
	end)

  it("should fail batch-balance validation when input array lengths are zero", function()
		-- set input array lengths to zero
    msgBatchBalance.Tags.Recipients = json.encode({})
    msgBatchBalance.Tags.PositionIds = json.encode({})
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalance(msgBatchBalance, _G.Market.cpmm.tokens.positionIds)
    end, "Input array length must be greater than zero!")
	end)

  it("should pass batch-balances validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      semiFungibleTokensValidation.batchBalances(msgBatchBalances, _G.Market.cpmm.tokens.positionIds)
    end)
	end)

  it("should fail batch-balances validation when positionIds is missing", function()
		-- remove PositionIds 
    msgBatchBalances.Tags.PositionIds = nil
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalances(msgBatchBalances, _G.Market.cpmm.tokens.positionIds)
    end, "PositionIds is required!")
	end)

  it("should fail batch-balances validation when positionIds is invalid", function()
		-- invalid PositionIds 
    msgBatchBalances.Tags.PositionIds = json.encode({
      "1",
      "2",
      "123"
    })
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalances(msgBatchBalances, _G.Market.cpmm.tokens.positionIds)
    end, "Invalid PositionId!")
	end)

  it("should fail batch-balances validation when input array lengths are zero", function()
		-- set input array lengths to zero
    msgBatchBalances.Tags.PositionIds = json.encode({})
    -- should throw an error
    assert.has.error(function()
      semiFungibleTokensValidation.batchBalances(msgBatchBalances, _G.Market.cpmm.tokens.positionIds)
    end, "Input array length must be greater than zero!")
	end)
end)