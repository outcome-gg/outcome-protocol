local configuratorNotices = require("configuratorModules.configuratorNotices")

-- Define variables
local admin
local delay
local msg
local hash
local timestamp

describe("#configurator #configuratorNotices", function()
  before_each(function()
    -- set admin
    admin = "test-this-is-valid-arweave-wallet-address-1"
    -- set delay
    delay = 100
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
    hash = "some-hash"
    timestamp = os.time()
	end)

  it("should send stageUpdateNotice", function()
    local notice = configuratorNotices.stageUpdateNotice(
      msg.Tags.UpdateProcess,
      msg.Tags.UpdateAction,
      msg.Tags.UpdateTags,
      msg.Tags.UpdateData,
      hash,
      msg
    )
		assert.are.same({
      Action = 'Stage-Update-Notice',
      UpdateProcess = msg.Tags.UpdateProcess,
      UpdateAction = msg.Tags.UpdateAction,
      UpdateTags = msg.Tags.UpdateTags,
      UpdateData = msg.Tags.UpdateData,
      Hash = hash,
    }, notice)
	end)

  it("should send unstageUpdateNotice", function()
    local notice = configuratorNotices.unstageUpdateNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Unstage-Update-Notice',
      Hash = hash
    }, notice)
	end)

  it("should send actionUpdateNotice", function()
    local notice = configuratorNotices.actionUpdateNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Action-Update-Notice',
      Hash = hash
    }, notice)
	end)

  it("should send stageUpdateAdminNotice", function()
    local notice = configuratorNotices.stageUpdateAdminNotice(
      admin,
      hash,
      msg
    )
		assert.are.same({
      Action = 'Stage-Update-Admin-Notice',
      UpdateAdmin = admin,
      Hash = hash,
    }, notice)
	end)

  it("should send unstageUpdateAdminNotice", function()
    local notice = configuratorNotices.unstageUpdateAdminNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Unstage-Update-Admin-Notice',
      Hash = hash,
    }, notice)
	end)

  it("should send actionUpdateAdminNotice", function()
    local notice = configuratorNotices.actionUpdateAdminNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Action-Update-Admin-Notice',
      Hash = hash,
    }, notice)
	end)

  it("should send stageUpdateDelayNotice", function()
    local notice = configuratorNotices.stageUpdateDelayNotice(
      delay,
      hash,
      msg
    )
		assert.are.same({
      Action = 'Stage-Update-Delay-Notice',
      UpdateDelay = delay,
      Hash = hash,
    }, notice)
	end)

  it("should send unstageUpdateDelayNotice", function()
    local notice = configuratorNotices.unstageUpdateDelayNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Unstage-Update-Delay-Notice',
      Hash = hash,
    }, notice)
	end)

  it("should send actionUpdateDelayNotice", function()
    local notice = configuratorNotices.actionUpdateDelayNotice(
      hash,
      msg
    )
		assert.are.same({
      Action = 'Action-Update-Delay-Notice',
      Hash = hash,
    }, notice)
	end)
end)