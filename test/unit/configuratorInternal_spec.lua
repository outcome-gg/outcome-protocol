local crypto = require(".crypto")
local configurator = require("configuratorModules.configurator")

local admin = ""
local delay = nil
local updateDelay = nil
local msg = {}
local msgAdmin = {}
local msgDelay = {}
local hash = ""
local hashAdmin = ""
local hashDelay = ""
local timestamp = nil
local Configurator = {}

describe("#configurator #configuratorInternal", function()
  before_each(function()
    -- set admin
    admin = "test-this-is-valid-arweave-wallet-address-1"
    -- instantiate configurator
		Configurator = configurator.new(admin, "DEV") -- in dev mode with delay == 1 second
    -- create a message object
    msg = {
      From = admin,
      Tags = {
        UpdateProcess = "test-this-is-valid-arweave-wallet-address-2",
        UpdateAction = "action_name",
        UpdateTags = '{"key":"value"}',
        UpdateData = '{"key":"value"}'
      },
      reply = function(message) return message end
    }
    -- update admin
    admin = "test-this-is-valid-arweave-wallet-address-3"
    -- create a message object
    msgAdmin = {
      From = admin,
      Tags = {
        UpdateAdmin = admin
      },
      reply = function(message) return message end
    }
    -- update delay
    delay = 3000
    updateDelay = 123
    -- create a message object
    msgDelay = {
      From = admin,
      Tags = {
        UpdateDelay = tostring(delay)
      },
      reply = function(message) return message end
    }
    -- create hashes
    hash = tostring(crypto.digest.keccak256(msg.Tags.UpdateProcess .. msg.Tags.UpdateAction .. msg.Tags.UpdateTags .. msg.Tags.UpdateData).asHex())
    hashAdmin = tostring(crypto.digest.keccak256(msgAdmin.Tags.UpdateAdmin).asHex())
    hashDelay = tostring(crypto.digest.keccak256(msgDelay.Tags.UpdateDelay).asHex())
    -- set timestamp
    timestamp = os.time()
	end)

  it("should stage update", function()
    -- stage update
    local notice = Configurator:stageUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert staged
    assert.are.same({
      ["update" .. hash] = timestamp
    }, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Stage-Update-Notice',
      UpdateProcess = msg.Tags.UpdateProcess,
      UpdateAction = msg.Tags.UpdateAction,
      UpdateTags = msg.Tags.UpdateTags,
      UpdateData = msg.Tags.UpdateData,
      Hash = "update" .. hash,
    }, notice)
	end)

  it("should unstage update", function()
    -- stage update
    Configurator:stageUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert staged
    assert.are.same({
      ["update" .. hash] = timestamp
    }, Configurator.staged)
    -- unstage update
    local notice = Configurator:unstageUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Unstage-Update-Notice',
      Hash = "update" .. hash,
    }, notice)
	end)

  it("should fail to unstage update if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:unstageUpdate(
        msg.Tags.UpdateProcess,
        msg.Tags.UpdateAction,
        msg.Tags.UpdateTags,
        msg.Tags.UpdateData,
        msg
      )
    end, "Update not staged! Hash: " .. "update" .. hash)
    -- nothing should be staged
    assert.are.same({}, Configurator.staged)
	end)

  it("should action update", function()
    -- stage update
    Configurator:stageUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert staged
    assert.are.same({
      ["update" .. hash] = timestamp
    }, Configurator.staged)
    -- stub os.time to mock delay
    stub(os, "time", function() return timestamp + delay end)
    -- action update
    local notice = Configurator:actionUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Action-Update-Notice',
      Hash = "update" .. hash,
    }, notice)
    -- restore the original os.time
    os.time:revert()
	end)

  it("should fail to action update if not staged long enough", function()
    -- stage update
    Configurator:stageUpdate(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      msg
    )
    -- assert staged
    assert.are.same({
      ["update" .. hash] = timestamp
    }, Configurator.staged)
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdate(
        msg.Tags.UpdateProcess,
        msg.Tags.UpdateAction,
        msg.Tags.UpdateTags,
        msg.Tags.UpdateData,
        msg
      )
    end, "Update not staged long enough! Remaining: 3000s.")
    -- assert still staged
    assert.are.same({
      ["update" .. hash] = timestamp
    }, Configurator.staged)
	end)

  it("should fail to action update if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdate(
        msg.Tags.UpdateProcess,
        msg.Tags.UpdateAction,
        msg.Tags.UpdateTags,
        msg.Tags.UpdateData,
        msg
      )
    end, "Update not staged! Hash: " .. "update" .. hash)
    -- nothing should be staged
    assert.are.same({}, Configurator.staged)
	end)

  it("should stage update admin", function()
    -- stage update admin
    local notice = Configurator:stageUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert staged
    assert.are.same({
      ["updateAdmin" .. hashAdmin] = timestamp
    }, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Stage-Update-Admin-Notice',
      UpdateAdmin = admin,
      Hash = "updateAdmin" .. hashAdmin,
    }, notice)
	end)

  it("should unstage update admin", function()
    -- stage update admin
    Configurator:stageUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert staged
    assert.are.same({
      ["updateAdmin" .. hashAdmin] = timestamp
    }, Configurator.staged)
    -- unstage update admin
    local notice = Configurator:unstageUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Unstage-Update-Admin-Notice',
      Hash = "updateAdmin" .. hashAdmin,
    }, notice)
	end)

  it("should fail to unstage update admin if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:unstageUpdateAdmin(
        msgAdmin.Tags.UpdateAdmin,
        msgAdmin
      )
    end, "Update not staged! Hash: " .. "updateAdmin" .. hashAdmin)
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
	end)

  it("should action update admin", function()
    -- stage update admin
    Configurator:stageUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert staged
    assert.are.same({
      ["updateAdmin" .. hashAdmin] = timestamp
    }, Configurator.staged)
    -- stub os.time to mock delay
    stub(os, "time", function() return timestamp + delay end)
    -- action update admin
    local notice = Configurator:actionUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Action-Update-Admin-Notice',
      Hash = "updateAdmin" .. hashAdmin,
    }, notice)
    -- assert admin updated
    assert.are.same(admin, Configurator.admin)
    -- restore the original os.time
    os.time:revert()
	end)

  it("should fail to action update admin if not staged long enough", function()
    -- stage update admin
    Configurator:stageUpdateAdmin(
      msgAdmin.Tags.UpdateAdmin,
      msgAdmin
    )
    -- assert staged
    assert.are.same({
      ["updateAdmin" .. hashAdmin] = timestamp
    }, Configurator.staged)
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdateAdmin(
        msgAdmin.Tags.UpdateAdmin,
        msgAdmin
      )
    end, "Update not staged long enough! Remaining: 3000s.")
    -- assert still staged
    assert.are.same({
      ["updateAdmin" .. hashAdmin] = timestamp
    }, Configurator.staged)
	end)

  it("should fail to action update admin if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdateAdmin(
        msgAdmin.Tags.UpdateAdmin,
        msgAdmin
      )
    end, "Update not staged! Hash: " .. "updateAdmin" .. hashAdmin)
    -- nothing should be staged
    assert.are.same({}, Configurator.staged)
	end)

  it("should stage update delay", function()
    -- stage update admin
    local notice = Configurator:stageUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert staged
    assert.are.same({
      ["updateDelay" .. hashDelay] = timestamp
    }, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Stage-Update-Delay-Notice',
      UpdateDelay = tostring(delay),
      Hash = "updateDelay" .. hashDelay,
    }, notice)
	end)

  it("should unstage update delay", function()
    -- stage update admin
    Configurator:stageUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert staged
    assert.are.same({
      ["updateDelay" .. hashDelay] = timestamp
    }, Configurator.staged)
    -- unstage update admin
    local notice = Configurator:unstageUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Unstage-Update-Delay-Notice',
      Hash = "updateDelay" .. hashDelay,
    }, notice)
	end)

  it("should fail to unstage update delay if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:unstageUpdateDelay(
        msgDelay.Tags.UpdateDelay,
        msgDelay
      )
    end, "Update not staged! Hash: " .. "updateDelay" .. hashDelay)
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
	end)

  it("should action update delay", function()
    -- stage update admin
    Configurator:stageUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert staged
    assert.are.same({
      ["updateDelay" .. hashDelay] = timestamp
    }, Configurator.staged)
    -- stub os.time to mock delay
    stub(os, "time", function() return timestamp + delay end)
    -- action update admin
    local notice = Configurator:actionUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert unstaged
    assert.are.same({}, Configurator.staged)
    -- assert correct notice
    assert.are.same({
      Action = 'Action-Update-Delay-Notice',
      Hash = "updateDelay" .. hashDelay,
    }, notice)
    -- assert delay updated
    assert.are.same(delay, Configurator.delay)
    -- restore the original os.time
    os.time:revert()
	end)

  it("should fail to action update delay if not staged long enough", function()
    -- stage update admin
    Configurator:stageUpdateDelay(
      msgDelay.Tags.UpdateDelay,
      msgDelay
    )
    -- assert staged
    assert.are.same({
      ["updateDelay" .. hashDelay] = timestamp
    }, Configurator.staged)
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdateDelay(
        msgDelay.Tags.UpdateDelay,
        msgDelay
      )
    end, "Update not staged long enough! Remaining: 3000s.")
    -- assert still staged
    assert.are.same({
      ["updateDelay" .. hashDelay] = timestamp
    }, Configurator.staged)
	end)

  it("should fail to action update delay if unstaged", function()
    -- should throw an error
    assert.has.error(function()
      Configurator:actionUpdateDelay(
        msgDelay.Tags.UpdateDelay,
        msgDelay
      )
    end, "Update not staged! Hash: " .. "updateDelay" .. hashDelay)
    -- nothing should be staged
    assert.are.same({}, Configurator.staged)
	end)
end)