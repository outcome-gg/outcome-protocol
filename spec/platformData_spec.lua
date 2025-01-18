require("luacov")
local platformData = require("platformDataModules.platformData")
local db = require("platformDataModules.db")
local json = require("json")

local Db = {}
local PlatformData = {}
local admin = ""
local nonAdmin = ""
local configurator = ""
local moderators = {}
local msg = {}

describe("#configurator #configuratorInternal", function()
  before_each(function()
    -- set variables
    admin = "test-this-is-valid-arweave-wallet-address-1"
    nonAdmin = "test-this-is-valid-arweave-wallet-address-2"
    configurator = "test-this-is-valid-arweave-wallet-address-3"
    moderators = {
      "test-this-is-valid-arweave-wallet-address-4",
      "test-this-is-valid-arweave-wallet-address-5",
    }
    -- instantiate db
    Db = db:new()
    -- instantiate platformData
    PlatformData = platformData:new(Db, configurator, moderators)
    -- create a message object
    msg = {
      From = admin,
      Tags = {
      },
      reply = function(message) return message end
    }
	end)

  it("should get info", function()
    -- get info
    local notice = PlatformData:info(msg)
    -- assert correct notice
    assert.are.same({
      Configurator = configurator,
      Moderators = json.encode(moderators),
    }, notice)
	end)
end)