local configuratorValidation = require("configuratorModules.configuratorValidation")

-- Mock the Configurator object
---@diagnostic disable-next-line: missing-fields
_G.Configurator = { admin = "test-this-is-valid-arweave-wallet-address-1" }

local msg = {}
local msgAdmin = {}
local msgDelay = {}

describe("#configurator #configuratorValidation", function()
  before_each(function()
		msg = {
      From = "test-this-is-valid-arweave-wallet-address-1",
      Tags = {
        UpdateProcess = "test-this-is-valid-arweave-wallet-address-2",
        UpdateAction = "action_name",
        UpdateTags = '{"key":"value"}',
        UpdateData = '{"key":"value"}'
      }
    }
    msgAdmin = {
      From = "test-this-is-valid-arweave-wallet-address-1",
      Tags = {
        UpdateAdmin = "test-this-is-valid-arweave-wallet-address-3"
      }
    }
    msgDelay = {
      From = "test-this-is-valid-arweave-wallet-address-1",
      Tags = {
        UpdateDelay = "123"
      }
    }
	end)

  it("should pass updateProcess validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should pass updateProcess validation when UpdateTags has whitespace", function()
    -- add whitespace to the JSON string
    msg.Tags.UpdateTags = '{" key ":" value "}'
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should fail updateProcess validation when UpdateTags doesn't start with `{`", function()
    -- remove the opening `{`
    msg.Tags.UpdateTags = '" key ":" value "}'
    -- should throw an error
		assert.has_error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
	end)

  it("should fail updateProcess validation when UpdateTags doesn't end with `}`", function()
    -- remove the closing `}`
    msg.Tags.UpdateTags = '{" key ":" value "'
    -- should throw an error
		assert.has._error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
	end)

  it("should pass updateProcess validation when UpdateTags JSON value is a string", function()
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should pass updateProcess validation when UpdateTags JSON value is a positive integer", function()
    -- value is a positive integer
    msg.Tags.UpdateTags = '{"key":123}'
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should pass updateProcess validation when UpdateTags JSON value is a negative integer", function()
    -- value is a negative integer
    msg.Tags.UpdateTags = '{"key":-123}'
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should pass updateProcess validation when UpdateTags JSON value is a decimal", function()
    -- value is a decimal
    msg.Tags.UpdateTags = '{"key":123.456}'
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should pass updateProcess validation when UpdateTags JSON value is a boolean", function()
    -- value is a boolean
    msg.Tags.UpdateTags = '{"key":false}'
    -- should not throw an error
		assert.has_no.errors(function()
      configuratorValidation.updateProcess(msg)
    end)
	end)

  it("should fail updateProcess validation when UpdateTags JSON value not matched", function()
    -- value is null
    msg.Tags.UpdateTags = '{"key":null}'
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
	end)

  it("should fail updateProcess validation when sender is not admin", function()
    -- change the sender from admin
    msg.From = "not-the-admin-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "Sender must be admin!")
	end)

  it("should fail updateProcess validation when UpdateProcess is missing", function()
    -- remove the UpdateProcess
    msg.Tags.UpdateProcess = nil
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateProcess is required!")
	end)

  it("should fail updateProcess validation when UpdateProcess is invalid", function()
    -- change the UpdateProcess to an invalid Arweave address
    msg.Tags.UpdateProcess = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateProcess must be a valid Arweave address!")
	end)

  it("should fail updateProcess validation  when UpdateAction is missing", function()
    -- remove the UpdateAction
    msg.Tags.UpdateAction = nil
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateAction is required!")
	end)

  it("should fail updateProcess validation when UpdateTags is invalid", function()
    -- change the UpdateTags to an invalid JSON
    msg.Tags.UpdateTags = ""
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
	end)

  it("should fail updateProcess validation when UpdateData is invalid", function()
    -- change the UpdateData to an invalid JSON
    msg.Tags.UpdateData = ""
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateData must be valid JSON!")
	end)

  it("should fail updateProcess validation when UpdateTags contains a key without value", function()
    -- Set UpdateTags to a string with an invalid key-value pair
    msg.Tags.UpdateTags = '{"key_without_value":}'
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
  end)

  it("should fail updateProcess validation when UpdateTags contains a value without key", function()
    -- Set UpdateTags to a string with an invalid key-value pair
    msg.Tags.UpdateTags = '{:"value_without_key"}'
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateProcess(msg)
    end, "UpdateTags must be valid JSON!")
  end)

  it("should pass updateAdmin validation", function()
		assert.has_no.errors(function()
      configuratorValidation.updateAdmin(msgAdmin)
    end)
	end)

  it("should fail updateAdmin validation when sender is not admin", function()
		-- change the sender from admin
    msgAdmin.From = "not-the-admin-arweave-wallet-address"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateAdmin(msgAdmin)
    end, "Sender must be admin!")
	end)

  it("should fail updateAdmin validation when UpdateAdmin is missing", function()
		-- remove the UpdateAdmin
    msgAdmin.Tags.UpdateAdmin = nil
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateAdmin(msgAdmin)
    end, "UpdateAdmin is required!")
	end)

  it("should fail updateAdmin validation when UpdateAdmin is invalid", function()
    -- change the UpdateProcess to an invalid Arweave address
    msgAdmin.Tags.UpdateAdmin = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      configuratorValidation.updateAdmin(msgAdmin)
    end, "UpdateAdmin must be a valid Arweave address!")
	end)

  it("should pass updateDelay validation", function()
		assert.has_no.errors(function()
      configuratorValidation.updateDelay(msgDelay)
    end)
	end)

  it("should fail updateDelay validation when sender is not admin", function()
		-- change the sender from admin
    msgDelay.From = "not-the-admin-arweave-wallet-address"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "Sender must be admin!")
	end)

  it("should fail updateDelay validation when UpdateDelay is missing", function()
		-- remove the UpdateDelay
    msgDelay.Tags.UpdateDelay = nil
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "UpdateDelay is required!")
	end)

  it("should fail updateDelay validation when UpdateDelay not a number", function()
		-- change the UpdateDelay to a string
    msgDelay.Tags.UpdateDelay = "not-a-number"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "UpdateDelay must be a number!")
	end)

  it("should fail updateDelay validation when UpdateDelay is zero", function()
		-- change the UpdateDelay to zero
    msgDelay.Tags.UpdateDelay = "0"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "UpdateDelay must be greater than zero!")
	end)

  it("should fail updateDelay validation when UpdateDelay is negative", function()
		-- change the UpdateDelay to a negative number
    msgDelay.Tags.UpdateDelay = "-123"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "UpdateDelay must be greater than zero!")
	end)

  it("should fail updateDelay validation when UpdateDelay is a decimal", function()
		-- change the UpdateDelay to a decimal number
    msgDelay.Tags.UpdateDelay = "123.456"
    -- should throw an error
    assert.has.error(function()
      configuratorValidation.updateDelay(msgDelay)
    end, "UpdateDelay must be an integer!")
	end)
end)