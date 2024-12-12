require("luacov")
local tokenValidation = require("modules.tokenValidation")

local msg = {}

describe("market.modules.tokenValidation", function()
  before_each(function()
		msg = {
      From = "test-this-is-valid-arweave-wallet-address-1",
      Tags = {
        Recipient = "test-this-is-valid-arweave-wallet-address-2",
        Quantity = "100",
      }
    }
	end)

  it("should pass transfer validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      tokenValidation.transfer(msg)
    end)
	end)

  it("should fail transfer validation when recipient is missing", function()
    -- remove the Recipient 
    msg.Tags.Recipient = nil
    -- should throw an error
		assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Recipient is required!")
	end)

  it("should fail transfer validation when recipient is invalid", function()
    -- change the Recipient to an invalid Arweave address
    msg.Tags.Recipient = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Recipient must be a valid Arweave address!")
	end)

  it("should fail transfer validation when quantity is missing", function()
		-- remove the Quantity
    msg.Tags.Quantity = nil
    -- should throw an error
    assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Quantity is required!")
	end)

  it("should fail transfer validation when quantity not a number", function()
		-- change the Quantity to a string
    msg.Tags.Quantity = "not-a-number"
    -- should throw an error
    assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Quantity must be a number!")
	end)

  it("should fail transfer validation when quantity is zero", function()
		-- change the Quantity to zero
    msg.Tags.Quantity = "0"
    -- should throw an error
    assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer validation when quantity is negative", function()
		-- change the Quantity to a negative number
    msg.Tags.Quantity = "-123"
    -- should throw an error
    assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Quantity must be greater than zero!")
	end)

  it("should fail transfer validation when quantity is a decimal", function()
		-- change the Quantity to a decimal number
    msg.Tags.Quantity = "123.456"
    -- should throw an error
    assert.has.error(function()
      tokenValidation.transfer(msg)
    end, "Quantity must be an integer!")
	end)
end)