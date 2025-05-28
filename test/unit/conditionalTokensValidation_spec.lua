require("luacov")
local conditionalTokensValidation = require("marketModules.conditionalTokensValidation")
local json = require("json")

-- Mock the CPMM object
---@diagnostic disable-next-line: missing-fields
_G.CPMM = { 
  tokens = { 
    positionIds = { "1", "2", "3" },
    balancesById = {
      ["1"] = { ["test-this-is-valid-arweave-wallet-address-1"] = "100" },
      ["2"] = { ["test-this-is-valid-arweave-wallet-address-1"] = "200" },
      ["3"] = { ["test-this-is-valid-arweave-wallet-address-1"] = "300" }
    }
  },
  resolutionAgent = "test-this-is-valid-arweave-wallet-address-0"
}

local resolutionAgent, sender, quantity, payouts
local msgMerge, msgPayouts, msgBatchRedeemPositions

describe("#market #conditionalTokens #conditionalTokensValidation", function()
  before_each(function()
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    quantity = "100"
    payouts = {1, 0}

    -- Create messages
    msgMerge = { From = sender, Tags = { Quantity = quantity } }
    msgPayouts = { From = resolutionAgent, Tags = { Payouts = json.encode(payouts) } }
    msgBatchRedeemPositions = { From = resolutionAgent }
  end)

  it("should pass merge validation", function()
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail merge validation when missing quantity", function()
    msgMerge.Tags.Quantity = nil
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Quantity is required and must be a string!", err)
  end)

  it("should fail merge validation when quantity is not numeric", function()
    msgMerge.Tags.Quantity = "not-a-number"
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail merge validation when quantity is zero", function()
    msgMerge.Tags.Quantity = "0"
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail merge validation when quantity is negative", function()
    msgMerge.Tags.Quantity = "-1"
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail merge validation when quantity is decimal", function()
    msgMerge.Tags.Quantity = "1.23"
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Quantity must be an integer!", err)
  end)


  it("should fail merge validation when onBehalfOf is invalid", function()
    msgMerge.Tags.OnBehalfOf = "foo"
    local success, err = conditionalTokensValidation.mergePositions(msgMerge, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("onBehalfOf must be a valid Arweave address!", err)
  end)

  it("should pass report payouts validation", function()
    local success, err = conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail report payouts validation when sender ~= resolutionAgent", function()
    msgPayouts.From = sender
    local success, err = conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    assert.is_false(success)
    assert.are.equal("Sender must be the resolution agent!", err)
  end)

  it("should fail report payouts validation when missing payouts", function()
    msgPayouts.Tags.Payouts = nil
    local success, err = conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    assert.is_false(success)
    assert.are.equal("Payouts is required!", err)
  end)

  it("should fail report payouts validation when payouts is not an array", function()
    msgPayouts.Tags.Payouts = "not-a-json-array"
    local success, err = conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    assert.is_false(success)
    assert.are.equal("Payouts must be a valid JSON Array!", err)
  end)

  it("should fail report payouts validation when payouts contains an invalid item", function()
    msgPayouts.Tags.Payouts = json.encode({1, 0, "invalid"})
    local success, err = conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    assert.is_false(success)
    assert.are.equal("Payouts item must be a valid number!", err)
  end)

  it("should pass batch payouts validation", function()
    local success, err = conditionalTokensValidation.batchRedeemPositions(msgBatchRedeemPositions, resolutionAgent, 1, {"1","2"})
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail batch payouts validation when sender is not resolution agent", function()
    local success, err = conditionalTokensValidation.batchRedeemPositions(msgBatchRedeemPositions, sender, 1, {"1","2"})
    assert.is_false(success)
    assert.are.equal("Sender must be the resolution agent!", err)
  end)

  it("should fail batch payouts validation when market is not resolved", function()
    local success, err = conditionalTokensValidation.batchRedeemPositions(msgBatchRedeemPositions, resolutionAgent, 0, {"1","2"})
    assert.is_false(success)
    assert.are.equal("Market must be resolved!", err)
  end)

  it("should fail batch payouts validation when market is not binary", function()
    local success, err = conditionalTokensValidation.batchRedeemPositions(msgBatchRedeemPositions, resolutionAgent, 1, {"1","2","3"})
    assert.is_false(success)
    assert.are.equal("Market must be binary!", err)
  end)
end)