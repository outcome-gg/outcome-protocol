require("luacov")
local tokenValidation = require("marketModules.tokenValidation")

local msg = {}

describe("#market #token #tokenValidation", function()
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
    local success, err = tokenValidation.transfer(msg)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail transfer validation when recipient is missing", function()
    msg.Tags.Recipient = nil
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Recipient is required and must be a string!", err)
  end)

  it("should fail transfer validation when recipient is invalid", function()
    msg.Tags.Recipient = "invalid-arweave-wallet-address"
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Recipient must be a valid Arweave address!", err)
  end)

  it("should fail transfer validation when quantity is missing", function()
    msg.Tags.Quantity = nil
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Quantity is required and must be a string!", err)
  end)

  it("should fail transfer validation when quantity is not a number", function()
    msg.Tags.Quantity = "not-a-number"
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail transfer validation when quantity is zero", function()
    msg.Tags.Quantity = "0"
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail transfer validation when quantity is negative", function()
    msg.Tags.Quantity = "-123"
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Quantity must be greater than zero!", err)
  end)

  it("should fail transfer validation when quantity is a decimal", function()
    msg.Tags.Quantity = "123.456"
    local success, err = tokenValidation.transfer(msg)
    assert.is_false(success)
    assert.are.equal("Quantity must be an integer!", err)
  end)
end)
