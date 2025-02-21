require("luacov")
local semiFungibleTokensValidation = require("marketModules.semiFungibleTokensValidation")
local json = require("json")

-- Mock the Market.cpmm object
---@diagnostic disable-next-line: missing-fields
_G.Market = { cpmm = {tokens = { positionIds = { "1", "2", "3" } } } }

local sender, recipient, positionId, quantity
local positionIds, quantities, recipients
local msg, msgBatch, msgBalance, msgBalances, msgBatchBalance, msgBatchBalances

describe("#market #semiFungibleTokens #semiFungibleTokensValidation", function()
  before_each(function()
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

    msg = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionId = positionId,
        Quantity = quantity,
      }
    }

    msgBatch = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionIds = json.encode(positionIds),
        Quantities = json.encode(quantities),
      }
    }

    msgBalance = {
      From = sender,
      Tags = { PositionId = positionId }
    }

    msgBalances = {
      From = sender,
      Tags = { PositionId = positionId }
    }

    msgBatchBalance = {
      From = sender,
      Tags = {
        Recipients = json.encode(recipients),
        PositionIds = json.encode(positionIds)
      }
    }

    msgBatchBalances = {
      From = sender,
      Tags = { PositionIds = json.encode(positionIds) }
    }
  end)

  it("should pass transfer-single validation", function()
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail transfer-single validation when recipient is missing", function()
    msg.Tags.Recipient = nil
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Recipient is required and must be a string!", err)
  end)

  it("should fail transfer-single validation when recipient is invalid", function()
    msg.Tags.Recipient = "invalid-arweave-wallet-address"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Recipient must be a valid Arweave address!", err)
  end)

  it("should fail transfer-single validation when positionId is missing", function()
    msg.Tags.PositionId = nil
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("PositionId is required and must be a string!", err)
  end)

  it("should fail transfer-single validation when positionId is invalid", function()
    msg.Tags.PositionId = "123"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should fail transfer-single validation when quantity is missing", function()
    msg.Tags.Quantity = nil
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity is required and must be a string!", err)
  end)

  it("should fail transfer-single validation when quantity is not a number", function()
    msg.Tags.Quantity = "not-a-number"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail transfer-single validation when quantity is zero", function()
    msg.Tags.Quantity = "0"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail transfer-single validation when quantity is negative", function()
    msg.Tags.Quantity = "-123"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail transfer-single validation when quantity is a decimal", function()
    msg.Tags.Quantity = "123.456"
    local success, err = semiFungibleTokensValidation.transferSingle(msg, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be an integer!", err)
  end)

  it("should pass transfer-batch validation", function()
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail transfer-batch validation when recipient is missing", function()
    msgBatch.Tags.Recipient = nil
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_false(success)
    assert.are.equal("Recipient is required and must be a string!", err)
  end)

  it("should fail transfer-batch validation when recipient is invalid", function()
    msgBatch.Tags.Recipient = "invalid-arweave-wallet-address"
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_false(success)
    assert.are.equal("Recipient must be a valid Arweave address!", err)
  end)

  it("should fail transfer-batch validation when positionIds is missing", function()
    msgBatch.Tags.PositionIds = nil
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_false(success)
    assert.are.equal("PositionIds is required!", err)
  end)

  it("should fail transfer-batch validation when quantities is missing", function()
    msgBatch.Tags.Quantities = nil
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_false(success)
    assert.are.equal("Quantities is required!", err)
  end)

  it("should fail transfer-batch validation when positionId is invalid", function()
    msgBatch.Tags.PositionIds = json.encode({ "1", "2", "123" })
    local success, err = semiFungibleTokensValidation.transferBatch(msgBatch, positionIds)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should pass balance-by-id validation", function()
    local success, err = semiFungibleTokensValidation.balanceById(msgBalance, positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail balance-by-id validation when positionId is invalid", function()
    msgBalance.Tags.PositionId = "123"
    local success, err = semiFungibleTokensValidation.balanceById(msgBalance, positionIds)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should pass batch-balances validation", function()
    local success, err = semiFungibleTokensValidation.batchBalances(msgBatchBalances, positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail batch-balances validation when positionIds is missing", function()
    msgBatchBalances.Tags.PositionIds = nil
    local success, err = semiFungibleTokensValidation.batchBalances(msgBatchBalances, positionIds)
    assert.is_false(success)
    assert.are.equal("PositionIds is required!", err)
  end)

end)
