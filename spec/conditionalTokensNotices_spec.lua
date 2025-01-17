require("luacov")
local conditionalTokensNotices = require("marketModules.conditionalTokensNotices")
local json = require("json")

local sender = ""
local collateralToken = ""
local resolutionAgent = ""
local quantity = ""
local payoutNumerators = {}
local payout = nil
local msgConditionResolution= {}
local msgPositionSplit = {}
local msgPositionsMerge = {}
local msgPayoutRedemption = {}

describe("#market #conditionalTokens #conditionalTokensNotices", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    collateralToken = "test-this-is-valid-arweave-wallet-address-2"
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-3"
    quantity = "100"
    payoutNumerators = {1, 0}
    payout = 50
    -- create a message object
    msgConditionResolution = {
      From = sender,
      Tags = {
        ResolutionAgent = resolutionAgent,
        PayoutNumerators = payoutNumerators,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgPositionSplit = {
      From = collateralToken,
      Tags = {
        Process = _G.ao.id,
        Stakeholder = sender,
        CollateralToken = collateralToken,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      forward = function(to, message) return {to, message} end
    }
    -- create a message object
    msgPositionsMerge = {
      From = collateralToken,
      Tags = {
        Quantity = quantity,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgPayoutRedemption = {
      From = collateralToken,
      Tags = {
        Process = _G.ao.id,
        CollateralToken = collateralToken,
        Payout = payout,
      },
      reply = function(message) return message end
    }
	end)

  it("should send condition resolution notice", function()
    local notice = conditionalTokensNotices.conditionResolutionNotice(
      msgConditionResolution.Tags.ResolutionAgent,
      msgConditionResolution.Tags.PayoutNumerators,
      msgConditionResolution
    )
    assert.are.same({
      Action = 'Condition-Resolution-Notice',
      ResolutionAgent = msgConditionResolution.Tags.ResolutionAgent,
      PayoutNumerators = json.encode(msgConditionResolution.Tags.PayoutNumerators)
    }, notice)
  end)

  it("should send position split notice", function()
    local result = conditionalTokensNotices.positionSplitNotice(
      msgPositionSplit.Tags.Stakeholder,
      msgPositionSplit.Tags.CollateralToken,
      msgPositionSplit.Tags.Quantity,
      msgPositionSplit
    )
    local to = result[1]
    local notice = result[2]
    assert.are.same(msgPositionSplit.Tags.Stakeholder, to)
    assert.are.same({
      Action = 'Split-Position-Notice',
      Process = _G.ao.id,
      Stakeholder = msgPositionSplit.Tags.Stakeholder,
      CollateralToken = msgPositionSplit.Tags.CollateralToken,
      Quantity = msgPositionSplit.Tags.Quantity,
      ["X-Action"] = "FOO"
    }, notice)
  end)

  it("should send positions merge notice", function()
    local notice = conditionalTokensNotices.positionsMergeNotice(
      msgPositionsMerge.Tags.Quantity,
      msgPositionsMerge
    )
    assert.are.same({
      Action = 'Merge-Positions-Notice',
      Quantity = msgPositionsMerge.Tags.Quantity
    }, notice)
  end)

  it("should send payout redemption notice", function()
    local notice = conditionalTokensNotices.payoutRedemptionNotice(
      msgPayoutRedemption.Tags.CollateralToken,
      msgPayoutRedemption.Tags.Payout,
      msgPayoutRedemption
    )
    assert.are.same({
      Action = 'Payout-Redemption-Notice',
      Process = _G.ao.id,
      CollateralToken = msgPayoutRedemption.Tags.CollateralToken,
      Payout = tostring(msgPayoutRedemption.Tags.Payout)
    }, notice)
  end)
end)