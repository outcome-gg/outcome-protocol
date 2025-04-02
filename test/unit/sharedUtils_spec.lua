require("luacov")
local sharedUtils = require("marketModules.sharedUtils")

local MIN = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
local MAX = "57896044618658097711785492504343953926634992332820282019728792003956564819967"

describe("#market #sharedUtils", function()
  it("should safeAdd with a & b both +ve", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeAdd("1", "1")
    end)
    -- assert state
    assert.are.equal(result, "2")
  end)

  it("should safeAdd with a & b both -ve", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeAdd("-1", "-1")
    end)
    -- assert state
    assert.are.equal(result, "-2")
  end)

  it("should safeAdd with 10, -5", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeAdd("10", "-5")
    end)
    -- assert state
    assert.are.equal(result, "5")
  end)

  it("should safeAdd with -5, 10", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeAdd("-5", "10")
    end)
    -- assert state
    assert.are.equal(result, "5")
  end)

  it("should fail safeAdd to overflow with MAX, 1", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeAdd(MAX, "1")
    end, "Overflow detected in safeAdd")
  end)

  it("should fail safeAdd to overflow with 1, MAX", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeAdd("1", MAX)
    end, "Overflow detected in safeAdd")
  end)

  it("should fail safeAdd to underflow with MIN, -1", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeAdd(MIN, "-1")
    end, "Underflow detected in safeAdd")
  end)

  it("should fail safeAdd to underflow with -1, MIN", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeAdd("-1", MIN)
    end, "Underflow detected in safeAdd")
  end)

  it("should safeSub with both a & b +ve", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeSub("1", "1")
    end)
    -- assert state
    assert.are.equal(result, "0")
  end)

  it("should safeSub with both a & b -ve", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeSub("-1", "-1")
    end)
    -- assert state
    assert.are.equal(result, "0")
  end)

  it("should safeSub with -10, 5", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeSub("-10", "5")
    end)
    -- assert state
    assert.are.equal(result, "-15")
  end)

  it("should safeSub with 5, -10", function()
    local result
    -- should not throw an error
    assert.has.no.error(function()
      result = sharedUtils.safeSub("5", "-10")
    end)
    -- assert state
    assert.are.equal(result, "15")
  end)

  it("should fail safeSub to overflow with MAX, -2", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeSub(MAX, "-2")
    end, "Overflow detected in safeSub")
  end)

  it("should fail safeSub to underflow with -2, MAX", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeSub("-2", MAX)
    end, "Underflow detected in safeSub")
  end)

  it("should fail safeSub to underflow with MIN, 1", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeSub(MIN, "1")
    end, "Underflow detected in safeSub")
  end)

  it("should fail safeSub to overflow with 1, MIN", function()
    -- should throw error
    assert.error(function()
      sharedUtils.safeSub("1", MIN)
    end, "Overflow detected in safeSub")
  end)
end)