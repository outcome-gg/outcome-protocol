require("luacov")
local crypto = require(".crypto")
local json = require("json")
-- @dev loads the configurator handlers
local _ = require("configurator")

local admin = ""
local updateAdmin = ""
local delay = nil
local updateDelay = nil
local msgInfo = {}
local msgUpdate = {}
local msgUpdateAdmin = {}
local msgUpdateDelay = {}
local hashUpdate = ""
local hashUpdateAdmin = ""
local hashUpdateDelay = ""
local timestamp = nil
local staged = {}

describe("#configurator", function()
  before_each(function()
    -- set admin
    admin = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"
    -- set delay
    delay = 3000
    -- create a message object
    msgInfo = {
      From = admin,
      Tags = {
        Action = "Info",
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdate = {
      From = admin,
      Tags = {
        UpdateProcess = "test-this-is-valid-arweave-wallet-address-1",
        UpdateAction = "action_name",
        UpdateTags = '{"key":"value"}',
        UpdateData = '{"key":"value"}'
      },
      reply = function(message) return message end
    }
    -- set updateAdmin
    updateAdmin = "test-this-is-valid-arweave-wallet-address-2"
    -- create a message object
    msgUpdateAdmin = {
      From = admin,
      Tags = {
        UpdateAdmin = updateAdmin,
      },
      reply = function(message) return message end
    }
    -- set updateDelay
    updateDelay = "123"
    -- create a message object
    msgUpdateDelay = {
      From = admin,
      Tags = {
        UpdateDelay = updateDelay,
      },
      reply = function(message) return message end
    }
    -- create hashes
    hashUpdate = tostring(crypto.digest.keccak256(msgUpdate.Tags.UpdateProcess .. msgUpdate.Tags.UpdateAction .. msgUpdate.Tags.UpdateTags .. msgUpdate.Tags.UpdateData).asHex())
    hashUpdateAdmin = tostring(crypto.digest.keccak256(msgUpdateAdmin.Tags.UpdateAdmin).asHex())
    hashUpdateDelay = tostring(crypto.digest.keccak256(msgUpdateDelay.Tags.UpdateDelay).asHex())
    -- set timestamp
    timestamp = os.time()
	end)

  it("should get info", function()
    -- get info
    local info = Handlers.process(msgInfo)
    -- assert correct response
    assert.are.same({
      Admin = admin,
      Delay = tostring(delay),
      Staged = json.encode(staged)
    }, info)
  end)

  it("should stage update", function()
    -- add action
    msgUpdate.Tags.Action = "Stage-Update"
    -- stage update
    local notice = Handlers.process(msgUpdate)
    -- assert correct response
    assert.are.same({
      Action = 'Stage-Update-Notice',
      UpdateProcess = msgUpdate.Tags.UpdateProcess,
      UpdateAction = msgUpdate.Tags.UpdateAction,
      UpdateTags = msgUpdate.Tags.UpdateTags,
      UpdateData = msgUpdate.Tags.UpdateData,
      Hash = "update" .. hashUpdate,
    }, notice)
  end)

  it("should unstage update", function()
    -- add action
    msgUpdate.Tags.Action = "Stage-Update"
    -- stage update
    Handlers.process(msgUpdate)
    -- update action
    msgUpdate.Tags.Action = "Unstage-Update"
    -- stage update
    local notice = Handlers.process(msgUpdate)
    -- assert correct response
    assert.are.same({
      Action = 'Unstage-Update-Notice',
      Hash = "update" ..hashUpdate,
    }, notice)
  end)

  it("should action update", function()
    -- add action
    msgUpdate.Tags.Action = "Stage-Update"
    -- stage update
    Handlers.process(msgUpdate)
    -- stub os.time to mock delay
    stub(os, "time", function() return timestamp + delay end)
    -- update action
    msgUpdate.Tags.Action = "Action-Update"
    -- action update
    local notice = Handlers.process(msgUpdate)
    -- assert correct response
    assert.are.same({
      Action = 'Action-Update-Notice',
      Hash = "update" ..hashUpdate,
    }, notice)
    -- restore the original os.time
    os.time:revert()
  end)

  it("should stage update delay", function()
    -- add action
    msgUpdateDelay.Tags.Action = "Stage-Update-Delay"
    -- stage update
    local notice = Handlers.process(msgUpdateDelay)
    -- assert correct response
    assert.are.same({
      Action = 'Stage-Update-Delay-Notice',
      UpdateDelay = msgUpdateDelay.Tags.UpdateDelay,
      Hash = "updateDelay" .. hashUpdateDelay,
    }, notice)
  end)

  it("should unstage update delay", function()
    -- add action
    msgUpdateDelay.Tags.Action = "Stage-Update-Delay"
    -- stage update
    Handlers.process(msgUpdateDelay)
    -- update action
    msgUpdateDelay.Tags.Action = "Unstage-Update-Delay"
    -- unstage update
    local notice = Handlers.process(msgUpdateDelay)
    -- assert correct response
    assert.are.same({
      Action = 'Unstage-Update-Delay-Notice',
      Hash = "updateDelay" .. hashUpdateDelay,
    }, notice)
  end)

  it("should action update delay", function()
    -- add action
    msgUpdateDelay.Tags.Action = "Stage-Update-Delay"
    -- stage update
    Handlers.process(msgUpdateDelay)
    -- stub os.time to mock delay
    stub(os, "time", function() return timestamp + delay end)
    -- update action
    msgUpdateDelay.Tags.Action = "Action-Update-Delay"
    -- action update
    local notice = Handlers.process(msgUpdateDelay)
    -- assert correct response
    assert.are.same({
      Action = 'Action-Update-Delay-Notice',
      Hash = "updateDelay" .. hashUpdateDelay,
    }, notice)
    -- restore the original os.time
    os.time:revert()
  end)

  it("should stage update admin", function()
    -- add action
    msgUpdateAdmin.Tags.Action = "Stage-Update-Admin"
    -- stage update
    local notice = Handlers.process(msgUpdateAdmin)
    -- assert correct response
    assert.are.same({
      Action = 'Stage-Update-Admin-Notice',
      UpdateAdmin = msgUpdateAdmin.Tags.UpdateAdmin,
      Hash = "updateAdmin" .. hashUpdateAdmin
    }, notice)
  end)

  it("should unstage update admin", function()
    -- add action
    msgUpdateAdmin.Tags.Action = "Stage-Update-Admin"
    -- stage update
    Handlers.process(msgUpdateAdmin)
    -- update action
    msgUpdateAdmin.Tags.Action = "Unstage-Update-Admin"
    -- unstage update
    local notice = Handlers.process(msgUpdateAdmin)
    -- assert correct response
    assert.are.same({
      Action = 'Unstage-Update-Admin-Notice',
      Hash = "updateAdmin" .. hashUpdateAdmin,
    }, notice)
  end)

  it("should action update admin", function()
    -- add action
    msgUpdateAdmin.Tags.Action = "Stage-Update-Admin"
    -- stage update
    Handlers.process(msgUpdateAdmin)
    -- stub os.time to mock delay 
    -- @dev delay updated by previous test
    stub(os, "time", function() return timestamp + updateDelay end)
    -- update action
    msgUpdateAdmin.Tags.Action = "Action-Update-Admin"
    -- action update
    local notice = Handlers.process(msgUpdateAdmin)
    -- assert correct response
    assert.are.same({
      Action = 'Action-Update-Admin-Notice',
      Hash = "updateAdmin" .. hashUpdateAdmin,
    }, notice)
    -- restore the original os.time
    os.time:revert()
  end)
end)