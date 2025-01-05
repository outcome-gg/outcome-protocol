require("luacov")
local marketFactory = require("modules.factory")
local token = require("modules.token")
local tokens = require("modules.conditionalTokens")
local json = require("json")

local sender = ""
local configurator = ""
local incentives = ""
local lpFee = ""
local maximumTakeFee = ""
local minimumPayment = ""
local protocolFee = ""
local protocolFeeTarget = ""
local utilityToken = ""
local collateralTokens = {}

local msgInfo = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#marketFactory", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-0"
    configurator = 'test-this-is-valid-arweave-wallet-address-1'
    incentives = 'test-this-is-valid-arweave-wallet-address-2'
    lpFee = '100'
    maximumTakeFee = '500'
    minimumPayment = '1000'
    protocolFee = '250'
    protocolFeeTarget = 'test-this-is-valid-arweave-wallet-address-5'
    utilityToken = 'test-this-is-valid-arweave-wallet-address-6'
    collateralTokens = {
      'test-this-is-valid-arweave-wallet-address-7'
    }
    FACTORY = marketFactory:new()
    -- create a message object
		msgInfo = {
      From = sender,
      reply = function(message) return message end
    }
	end)

  it("should get info", function()
    -- get info
    local info = nil
    -- should not throw an error
    assert.has_no.errors(function()
      info = FACTORY:info(msgInfo)
    end)
    -- assert correct response
    assert.are.same({
      Configurator = configurator,
      Incentives = incentives,
      LpFee = lpFee,
      ProtocolFee = protocolFee,
      ProtocolFeeTarget = protocolFeeTarget,
      MaximumTakeFee = maximumTakeFee,
      UtilityToken = utilityToken,
      MinimumPayment = minimumPayment,
      CollateralTokens = json.encode(collateralTokens)
    }, info)
  end)

  it("should spawn a market", function()
  end)

  it("should init a market", function()
  end)
end)