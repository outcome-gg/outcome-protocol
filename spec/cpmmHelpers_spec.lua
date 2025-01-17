require("luacov")
local cpmmHelpers = require("marketModules.cpmmHelpers")
local json = require("json")

local x = 0
local y = 0
local sender = ""
local collateralToken = ""
local quantity = ""
local distribution = {}
local outcomeSlotCount = nil

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#market #conditionalTokens #cpmmHelpers", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    collateralToken = "test-this-is-valid-arweave-wallet-address-2"
    x = 10
    y = 3
    outcomeSlotCount = 3
    quantity = "100"
    distribution = {10, 40, 50}
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

  it("should validate addFunding when totalSupply == 0 and distribution valid", function()
    local result = cpmmHelpers:validateAddFunding(
      sender,
      quantity,
      distribution
    )
    assert.is_true(result)
	end)

  it("should not validate addFunding when totalSupply == 0 and distribution invalid", function()
    distribution = {10, 40}
    local result = cpmmHelpers:validateAddFunding(
      sender,
      quantity,
      distribution
    )
    assert.is_false(result)
	end)

  it("should validate addFunding when totalSupply ~= 0 and #distribution == 0", function()
    cpmmHelpers.token = { totalSupply = "100" }
    distribution = {}
    local result = cpmmHelpers:validateAddFunding(
      sender,
      quantity,
      distribution
    )
    assert.is_true(result)
	end)

  it("should not validate when addFunding when totalSupply ~= 0 and #distribution ~= 0", function()
    cpmmHelpers.token = { totalSupply = "100" }
    local result = cpmmHelpers:validateAddFunding(
      sender,
      quantity,
      distribution
    )
    assert.is_false(result)
	end)

  it("should not validate when distribution is nil", function()
    cpmmHelpers.token = { totalSupply = "100" }
    local result = cpmmHelpers:validateAddFunding(
      sender,
      quantity,
      nil
    )
    assert.is_false(result)
	end)

  it("should validate removeFunding when quanlity <= balance", function()
    cpmmHelpers.token.balances[sender] = "100"
    local result = cpmmHelpers:validateRemoveFunding(
      sender,
      quantity
    )
    assert.is_true(result)
	end)

  it("should not validate removeFunding when quantity > balance", function()
    local result = cpmmHelpers:validateRemoveFunding(
      sender,
      quantity
    )
    assert.is_false(result)
	end)

  it("should not validate removeFunding when sender == creator and market not resolved", function()
    cpmmHelpers.conditionId = "the-condition-id"
    cpmmHelpers.payoutDenominator = {}
    cpmmHelpers.payoutDenominator[cpmmHelpers.conditionId] = 0
    cpmmHelpers.creatorFeeTarget = sender
    local result = cpmmHelpers:validateRemoveFunding(
      sender,
      quantity
    )
    assert.is_false(result)
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
