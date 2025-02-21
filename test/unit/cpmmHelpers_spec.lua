require("luacov")
local cpmmHelpers = require("marketModules.cpmmHelpers")
local json = require("json")

local x
local y
local sender
local outcomeSlotCount

describe("#market #conditionalTokens #cpmmHelpers", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    x = 10
    y = 3
    outcomeSlotCount = 3
    -- Mock cpmmHelpers object
    cpmmHelpers.token = { totalSupply = "0", balances = {} }
    cpmmHelpers.tokens = { positionIds = { "1", "2", "3" }, getBatchBalance = function() return { "100", "200", "300" } end  }
  end)

  it("should get position ids", function()
    local result = cpmmHelpers.getPositionIds(outcomeSlotCount)
    assert.are.same({"1", "2", "3"}, result)
  end)

  it("should calculate ceildiv when x > 0", function()
    local result = cpmmHelpers.ceildiv(x, y)
    assert.are.same(4, result) -- 3.3 rounds up to 4
	end)

  it("should calculate ceildiv when x == 0", function()
    x = 0
    local result = cpmmHelpers.ceildiv(x, y)
    assert.are.same(0, result)
	end)

  it("should calculate ceildiv when y == 0", function()
    y = 0
    local result = cpmmHelpers.ceildiv(x, y)
    assert.are.same("inf", tostring(result))
	end)

  it("should getPoolBalances", function()
    cpmmHelpers.conditionId = "the-condition-id"
    cpmmHelpers.payoutDenominator = {}
    cpmmHelpers.payoutDenominator[cpmmHelpers.conditionId] = 0
    cpmmHelpers.creatorFeeTarget = sender
    local result = cpmmHelpers:getPoolBalances()
    assert.is.same({ "100", "200", "300" }, result)
	end)
end)
