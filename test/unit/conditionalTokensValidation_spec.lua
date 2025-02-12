require("luacov")
local conditionalTokensValidation = require("marketModules.conditionalTokensValidation")
local json = require("json")

-- Mock the CPMM object
---@diagnostic disable-next-line: missing-fields
_G.CPMM = { tokens = { positionIds = { "1", "2", "3" }, resolutionAgent = "test-this-is-valid-arweave-wallet-address-0" } }

local resolutionAgent = ""
local sender = ""
local quantity = ""
local questionId = ""
local payouts = {}
local msgMerge = {}
local msgPayouts = {}

describe("#market #conditionalTokens #conditionalTokensValidation", function()
  before_each(function()
    -- set variables
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    quantity = "100"
    payouts = {1, 0}
    -- create a message object
		msgMerge = {
      From = sender,
      Tags = {
        Quantity = quantity,
      }
    }
    -- create a message object
    msgPayouts = {
      From = resolutionAgent,
      Tags = {
        QuestionId = questionId,
        Payouts = json.encode(payouts),
      }
    }
	end)

  it("should pass merge validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      conditionalTokensValidation.mergePositions(msgMerge)
    end)
	end)

  it("should fail merge validation when missing quantity", function()
    -- should throw an error
		assert.has.error(function()
      msgMerge.Tags.Quantity = nil
      conditionalTokensValidation.mergePositions(msgMerge)
    end, "Quantity is required!")
	end)

  it("should fail merge validation when quantity is not numeric", function()
    -- should throw an error
		assert.has.error(function()
      msgMerge.Tags.Quantity = "not-a-number"
      conditionalTokensValidation.mergePositions(msgMerge)
    end, "Quantity must be a number!")
	end)

  it("should fail merge validation when quantity is zero", function()
    -- should throw an error
		assert.has.error(function()
      msgMerge.Tags.Quantity = "0"
      conditionalTokensValidation.mergePositions(msgMerge)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail merge validation when quantity is negative", function()
    -- should throw an error
		assert.has.error(function()
      msgMerge.Tags.Quantity = "-1"
      conditionalTokensValidation.mergePositions(msgMerge)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail merge validation when quantity is decimal", function()
    -- should throw an error
		assert.has.error(function()
      msgMerge.Tags.Quantity = "1.23"
      conditionalTokensValidation.mergePositions(msgMerge)
    end, "Quantity must be an integer!")
	end)

  it("should pass report payouts validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    end)
	end)

  it("should fail report payouts validation when sender ~= resolutionAgent", function()
    msgPayouts.From = sender
    -- should throw an error
		assert.has.error(function()
      conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    end, "Sender must be resolution agent!")
	end)

  it("should fail report payouts validation when missing payouts", function()
    -- should throw an error
		assert.has.error(function()
      msgPayouts.Tags.Payouts = nil
      conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    end, "Payouts is required!")
	end)

  it("should fail report payouts validation when payouts not an array", function()
    -- should throw an error
		assert.has.error(function()
      msgPayouts.Tags.Payouts = "not-a-json-array"
      conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    end, "Payouts must be valid JSON Array!")
	end)

  it("should fail report payouts validation when payouts contains an invalid item", function()
    -- should throw an error
		assert.has.error(function()
      msgPayouts.Tags.Payouts = "[1, 0, 'invalid']"
      conditionalTokensValidation.reportPayouts(msgPayouts, resolutionAgent)
    end, "Payouts must be valid JSON Array!")
	end)
end)