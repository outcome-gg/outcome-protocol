require("luacov")
local conditionalTokensNotices = require("modules.conditionalTokensNotices")
local json = require("json")

local sender = ""
local collateralToken = ""
local questionId = ""
local conditionId = ""
local outcomeSlotCount = nil
local resolutionAgent = ""
local process = ""
local quantity = ""
local payoutNumerators = {}
local payout = nil
local msgConditionPreparation = {}
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
    questionId = "this-is-a-valid-question-id"
    conditionId = "this-is-a-valid-condition-id"
    quantity = "100"
    outcomeSlotCount = 2
    payoutNumerators = {1, 0}
    payout = 50
    -- create a message object
		msgConditionPreparation = {
      From = sender,
      Tags = {
        ConditionId = conditionId,
        OutcomeSlotCount = outcomeSlotCount,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgConditionResolution = {
      From = sender,
      Tags = {
        ConditionId = conditionId,
        ResolutionAgent = resolutionAgent,
        QuestionId = questionId,
        OutcomeSlotCount = outcomeSlotCount,
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
        ConditionId = conditionId,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      forward = function(to, message) return {to, message} end
    }
    -- create a message object
    msgPositionsMerge = {
      From = collateralToken,
      Tags = {
        ConditionId = conditionId,
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
        ConditionId = conditionId,
        Payout = payout,
      },
      reply = function(message) return message end
    }
	end)

  it("should send condition preparation notice", function()
    local notice = conditionalTokensNotices.conditionPreparationNotice(
      msgConditionPreparation.Tags.ConditionId,
      msgConditionPreparation.Tags.OutcomeSlotCount,
      msgConditionPreparation
    )
    assert.are.same({
      Action = 'Condition-Preparation-Notice',
      ConditionId = msgConditionPreparation.Tags.ConditionId,
      OutcomeSlotCount = tostring(msgConditionPreparation.Tags.OutcomeSlotCount),
    }, notice)
	end)

  it("should send condition resolution notice", function()
    local notice = conditionalTokensNotices.conditionResolutionNotice(
      msgConditionResolution.Tags.ConditionId,
      msgConditionResolution.Tags.ResolutionAgent,
      msgConditionResolution.Tags.QuestionId,
      msgConditionResolution.Tags.OutcomeSlotCount,
      msgConditionResolution.Tags.PayoutNumerators,
      msgConditionResolution
    )
    assert.are.same({
      Action = 'Condition-Resolution-Notice',
      ConditionId = msgConditionResolution.Tags.ConditionId,
      ResolutionAgent = msgConditionResolution.Tags.ResolutionAgent,
      QuestionId = msgConditionResolution.Tags.QuestionId,
      OutcomeSlotCount = tostring(msgConditionResolution.Tags.OutcomeSlotCount),
      PayoutNumerators = json.encode(msgConditionResolution.Tags.PayoutNumerators)
    }, notice)
  end)

  it("should send position split notice", function()
    local result = conditionalTokensNotices.positionSplitNotice(
      msgPositionSplit.Tags.Stakeholder,
      msgPositionSplit.Tags.CollateralToken,
      msgPositionSplit.Tags.ConditionId,
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
      ConditionId = msgPositionSplit.Tags.ConditionId,
      Quantity = msgPositionSplit.Tags.Quantity,
      ["X-Action"] = "FOO"
    }, notice)
  end)

  it("should send positions merge notice", function()
    local notice = conditionalTokensNotices.positionsMergeNotice(
      msgPositionsMerge.Tags.ConditionId,
      msgPositionsMerge.Tags.Quantity,
      msgPositionsMerge
    )
    assert.are.same({
      Action = 'Merge-Positions-Notice',
      ConditionId = msgPositionsMerge.Tags.ConditionId,
      Quantity = msgPositionsMerge.Tags.Quantity
    }, notice)
  end)

  it("should send payout redemption notice", function()
    local notice = conditionalTokensNotices.payoutRedemptionNotice(
      msgPayoutRedemption.Tags.CollateralToken,
      msgPayoutRedemption.Tags.ConditionId,
      msgPayoutRedemption.Tags.Payout,
      msgPayoutRedemption
    )
    assert.are.same({
      Action = 'Payout-Redemption-Notice',
      Process = _G.ao.id,
      CollateralToken = msgPayoutRedemption.Tags.CollateralToken,
      ConditionId = msgPayoutRedemption.Tags.ConditionId,
      Payout = tostring(msgPayoutRedemption.Tags.Payout)
    }, notice)
  end)
end)