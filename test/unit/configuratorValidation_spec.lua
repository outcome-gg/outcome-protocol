local configuratorValidation = require("configuratorModules.configuratorValidation")

-- Mock the Configurator object
---@diagnostic disable-next-line: missing-fields
_G.Configurator = { 
  admin = "test-this-is-valid-arweave-wallet-address-1",
  maxDelay = 365 * 24 * 60 * 60 * 1000
}

local msg, msgAdmin, msgDelay

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

  -- ✅ Update Process Validation
  it("should pass updateProcess validation", function()
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should pass updateProcess validation when UpdateTags has whitespace", function()
    msg.Tags.UpdateTags = '{" key ":" value "}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when UpdateTags JSON value is a positive integer", function()
    msg.Tags.UpdateTags = '{"key":123}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when UpdateTags JSON value is a negative integer", function()
    msg.Tags.UpdateTags = '{"key":-123}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when UpdateTags JSON value is a decimal", function()
    msg.Tags.UpdateTags = '{"key":123.456}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when UpdateTags JSON value is a boolean", function()
    msg.Tags.UpdateTags = '{"key":true}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when UpdateTags JSON value is not matched", function()
    msg.Tags.UpdateTags = '{"key":null}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateTags contains a key without value", function()
    msg.Tags.UpdateTags = '{"key_without_value":}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateTags doesn't start with `{`", function()
    msg.Tags.UpdateTags = '" key ":" value "}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateTags doesn't end with `}`", function()
    msg.Tags.UpdateTags = '{" key ":" value "'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should pass updateProcess validation when UpdateTags JSON value is a string", function()
    msg.Tags.UpdateTags = '{"key":"some_string"}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProcess validation when sender is not admin", function()
    msg.From = "not-the-admin-arweave-wallet-address"
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("Sender must be admin!", err)
  end)

  it("should fail updateProcess validation when UpdateProcess is missing", function()
    msg.Tags.UpdateProcess = nil
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateProcess is required and must be a string!", err)
  end)

  it("should fail updateProcess validation when UpdateAction is missing", function()
    msg.Tags.UpdateAction = nil
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateAction is required and must be a string!", err)
  end)

  it("should fail updateProcess validation when UpdateTags is invalid", function()
    msg.Tags.UpdateTags = "invalid-json"
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateData is invalid", function()
    msg.Tags.UpdateData = "invalid-json"
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateData must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateTags contains a key without value", function()
    msg.Tags.UpdateTags = '{"key_without_value":}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  it("should fail updateProcess validation when UpdateTags contains a value without key", function()
    msg.Tags.UpdateTags = '{:"value_without_key"}'
    local success, err = configuratorValidation.updateProcess(msg)
    assert.is_false(success)
    assert.are.equal("UpdateTags must be valid JSON!", err)
  end)

  -- ✅ Update Admin Validation
  it("should pass updateAdmin validation", function()
    local success, err = configuratorValidation.updateAdmin(msgAdmin)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateAdmin validation when sender is not admin", function()
    msgAdmin.From = "not-the-admin-arweave-wallet-address"
    local success, err = configuratorValidation.updateAdmin(msgAdmin)
    assert.is_false(success)
    assert.are.equal("Sender must be admin!", err)
  end)

  it("should fail updateAdmin validation when UpdateAdmin is missing", function()
    msgAdmin.Tags.UpdateAdmin = nil
    local success, err = configuratorValidation.updateAdmin(msgAdmin)
    assert.is_false(success)
    assert.are.equal("UpdateAdmin is required and must be a string!", err)
  end)

  it("should fail updateAdmin validation when UpdateAdmin is invalid", function()
    msgAdmin.Tags.UpdateAdmin = "invalid-arweave-wallet-address"
    local success, err = configuratorValidation.updateAdmin(msgAdmin)
    assert.is_false(success)
    assert.are.equal("UpdateAdmin must be a valid Arweave address!", err)
  end)

  -- ✅ Update Delay Validation
  it("should pass updateDelay validation", function()
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateDelay validation when sender is not admin", function()
    msgDelay.From = "not-the-admin-arweave-wallet-address"
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("Sender must be admin!", err)
  end)

  it("should fail updateDelay validation when UpdateDelay is missing", function()
    msgDelay.Tags.UpdateDelay = nil
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("UpdateDelay is required!", err)
  end)

  it("should fail updateDelay validation when UpdateDelay is not a number", function()
    msgDelay.Tags.UpdateDelay = "not-a-number"
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("UpdateDelay must be a valid number!", err)
  end)

  it("should fail updateDelay validation when UpdateDelay is zero", function()
    msgDelay.Tags.UpdateDelay = "0"
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("UpdateDelay must be greater than zero!", err)
  end)

  it("should fail updateDelay validation when UpdateDelay is negative", function()
    msgDelay.Tags.UpdateDelay = "-123"
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("UpdateDelay must be greater than zero!", err)
  end)

  it("should fail updateDelay validation when UpdateDelay is a decimal", function()
    msgDelay.Tags.UpdateDelay = "123.456"
    local success, err = configuratorValidation.updateDelay(msgDelay)
    assert.is_false(success)
    assert.are.equal("UpdateDelay must be an integer!", err)
  end)
end)
