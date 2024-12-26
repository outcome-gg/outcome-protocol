require("luacov")
local conditionalTokens = require("modules.conditionalTokens")
local crypto = require(".crypto")
local json = require("json")

local name = ''
local ticker = ''
local logo = ''
local balancesById = {}
local totalSupplyById = {}
local denomination = nil
local sender = ""
local recipient = ""
local resolutionAgent = ""
local collateralToken = ""
local questionId = ""
local conditionId = ""
local positionIds = {}
local outcomeSlotCount = nil
local creatorFee = nil
local protocolFee = nil
local payout = nil
local payouts = {}
local totalPayout = nil
local protocolFeeTarget = ""
local creatorFeeTarget = ""
local quantity = ""
local payoutNumerators = {}
local payoutDenominator = nil
local msgPrepareCondition = {}
local msgSplitPosition = {}
local msgMergePositions = {}
local msgReportPayouts = {}
local msgRedeemPositions = {}
local msgOutcomeSlotCount = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#market #conditionalTokens", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-3"
    collateralToken = "test-this-is-valid-arweave-wallet-address-4"
    questionId = "this-is-a-valid-question-id"
    payout = 50 -- collateral tokens
    payouts = { 1, 0, 0 }
    totalPayout = 100 -- collateral tokens
    quantity = "100"
    -- set semi-fungible variables
    name = ''
    ticker = ''
    logo = ''
    balancesById = {}
    totalSupplyById = {}
    denomination = 12
    -- set conditional tokens variables
    conditionId = tostring(crypto.digest.keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount)).asHex())
    outcomeSlotCount = 3
    positionIds = { "1", "2", "3" }
    payoutNumerators = {0, 0, 0}
    payoutDenominator = 0
    creatorFee = 250 -- basis points
    creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
    protocolFee = 250 -- basis points
    protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-5"
    -- instantiate conditionalTokens
		ConditionalTokens = conditionalTokens:new(
      name,
      ticker,
      logo,
      balancesById,
      totalSupplyById,
      denomination,
      conditionId,
      collateralToken,
      positionIds,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    )

    -- create a message object
		msgPrepareCondition = {
      From = sender,
      Tags = {
        ConditionId = conditionId,
        OutcomeSlotCount = outcomeSlotCount,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgSplitPosition = {
      From = sender,
      Tags = {
        Process = _G.ao.id,
        Stakeholder = sender,
        CollateralToken = collateralToken,
        ConditionId = conditionId,
        Quantity = quantity,
      },
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(to, message) return {to, message} end
    }
    -- create a message object
    msgMergePositions = {
      From = sender,
      Tags = {
        OnBehalfOf = recipient,
        Quantity = quantity,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgReportPayouts = {
      From = resolutionAgent,
      Tags = {
        QuestionId = questionId,
        Payouts = payouts,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgRedeemPositions = {
      From = sender,
      reply = function(message) return message end
    }
    -- create a message object
    msgOutcomeSlotCount = {
      From = sender,
      Tags = {
        ConditionId = conditionId,
      },
      reply = function(message) return message end
    }
	end)

  it("should init conditional tokens", function()
    -- assert initial state
    assert.are.same(name, ConditionalTokens.name)
    assert.are.same(ticker, ConditionalTokens.ticker)
    assert.are.same(logo, ConditionalTokens.logo)
    assert.are.same(balancesById, ConditionalTokens.balancesById)
    assert.are.same(totalSupplyById, ConditionalTokens.totalSupplyById)
    assert.are.same(denomination, ConditionalTokens.denomination)
    assert.are.same(conditionId, ConditionalTokens.conditionId)
    assert.are.same(outcomeSlotCount, ConditionalTokens.outcomeSlotCount)
    assert.are.same(positionIds, ConditionalTokens.positionIds)
    assert.are.same(payoutNumerators, ConditionalTokens.payoutNumerators)
    assert.are.same(payoutDenominator, ConditionalTokens.payoutDenominator)
    assert.are.same(creatorFee, ConditionalTokens.creatorFee)
    assert.are.same(creatorFeeTarget, ConditionalTokens.creatorFeeTarget)
    assert.are.same(protocolFee, ConditionalTokens.protocolFee)
    assert.are.same(protocolFeeTarget, ConditionalTokens.protocolFeeTarget)
	end)

  -- it("should prepare condition", function()
  --   local notice = ConditionalTokens:prepareCondition(
  --     msgPrepareCondition.Tags.ConditionId,
  --     msgPrepareCondition.Tags.OutcomeSlotCount,
  --     msgPrepareCondition
  --   )
  --   -- asert state change
  --   assert.are.same({[conditionId] = {0,0,0}}, ConditionalTokens.payoutNumerators)
  --   assert.are.same({[conditionId] = 0}, ConditionalTokens.payoutDenominator)
  --   -- assert notice
  --   assert.are.equals("Condition-Preparation-Notice", notice.Action)
  --   assert.are.equals(msgPrepareCondition.Tags.ConditionId, notice.ConditionId)
  --   assert.are.equals(tostring(msgPrepareCondition.Tags.OutcomeSlotCount), notice.OutcomeSlotCount)
	-- end)

  it("should split position", function()
    local notice = ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- asert state change
    assert.are.same({
      [positionIds[1]] = {
        [ msgSplitPosition.From] = quantity
      },
      [positionIds[2]] = {
        [ msgSplitPosition.From] = quantity
      },
      [positionIds[3]] = {
        [ msgSplitPosition.From] = quantity
      },
    }, ConditionalTokens.balancesById)
    -- assert notice
    assert.are.equals("Split-Position-Notice", notice[2].Action)
    assert.are.equals(msgSplitPosition.Tags.Quantity, notice[2].Quantity)
    assert.are.equals(msgSplitPosition.Tags.CollateralToken, notice[2].CollateralToken)
    assert.are.equals(msgSplitPosition.Tags.ConditionId, notice[2].ConditionId)
    assert.are.equals(msgSplitPosition.Tags.Process, notice[2].Process)
    assert.are.equals(msgSplitPosition["X-Action"], notice[2]["X-Action"])
	end)

  it("should merge positions (isSell == true)", function()
    -- split position
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- merge positions
    local notice = ConditionalTokens:mergePositions(
      msgMergePositions.From,
      msgMergePositions.Tags.OnBehalfOf,
      msgMergePositions.Tags.Quantity,
      true, -- isSell
      msgMergePositions
    )
    -- asert state change
    assert.are.same({
      [positionIds[1]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[2]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[3]] = {
        [ msgSplitPosition.From] = '0'
      },
    }, ConditionalTokens.balancesById)
    -- assert notice
    assert.are.equals("Merge-Positions-Notice", notice.Action)
    assert.are.equals(msgSplitPosition.Tags.Quantity, notice.Quantity)
    assert.are.equals(msgSplitPosition.Tags.ConditionId, notice.ConditionId)
	end)

  it("should merge positions (isSell == false)", function()
    -- split position
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- merge positions
    local notice = ConditionalTokens:mergePositions(
      msgMergePositions.From,
      msgMergePositions.Tags.OnBehalfOf,
      msgMergePositions.Tags.Quantity,
      false, -- isSell
      msgMergePositions
    )
    -- asert state change
    assert.are.same({
      [positionIds[1]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[2]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[3]] = {
        [ msgSplitPosition.From] = '0'
      },
    }, ConditionalTokens.balancesById)
    -- assert notice
    assert.are.equals("Merge-Positions-Notice", notice.Action)
    assert.are.equals(msgSplitPosition.Tags.Quantity, notice.Quantity)
    assert.are.equals(msgSplitPosition.Tags.ConditionId, notice.ConditionId)
	end)

  it("should fail to merge positions (position not split)", function()
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:mergePositions(
        msgMergePositions.From,
        msgMergePositions.Tags.OnBehalfOf,
        msgMergePositions.Tags.Quantity,
        true, -- isSell
        msgMergePositions
      )
    end, "Id must exist! 1")
	end)

  it("should fail to merge positions (no account balance)", function()
    -- split position
    ConditionalTokens:splitPosition(
      recipient,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:mergePositions(
        msgMergePositions.From,
        msgMergePositions.Tags.OnBehalfOf,
        msgMergePositions.Tags.Quantity,
        true, -- isSell
        msgMergePositions
      )
    end, "Account must hold token! 1")
	end)

  it("should report payouts", function()
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    local notice = ConditionalTokens:reportPayouts(
      msgReportPayouts.Tags.QuestionId,
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- asert state change
    assert.are.same(payouts, ConditionalTokens.payoutNumerators)
    assert.are.same(1, ConditionalTokens.payoutDenominator)
    -- assert notice
    assert.are.equals("Condition-Resolution-Notice", notice.Action)
    assert.are.equals(json.encode(msgReportPayouts.Tags.Payouts), notice.PayoutNumerators)
    assert.are.equals(msgReportPayouts.Tags.QuestionId, notice.QuestionId)
    assert.are.equals(msgReportPayouts.From, notice.ResolutionAgent)
    assert.are.equals(conditionId, notice.ConditionId)
    assert.are.equals(tostring(outcomeSlotCount), notice.OutcomeSlotCount)
	end)

  it("should fail to report payouts (not resolution agent)", function()
    -- split position
    ConditionalTokens:splitPosition(
      recipient,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- call from non-resolution agent
    msgReportPayouts.From = sender
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:reportPayouts(
        msgReportPayouts.Tags.QuestionId,
        msgReportPayouts.Tags.Payouts,
        msgReportPayouts
      )
    end, "Sender not resolution agent!")
	end)

  it("should fail to report payouts (payout length != outcomeSlotCount)", function()
    -- split position
    ConditionalTokens:splitPosition(
      recipient,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- wrong outcome slot count
    msgReportPayouts.Tags.Payouts = {1}
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:reportPayouts(
        msgReportPayouts.Tags.QuestionId,
        msgReportPayouts.Tags.Payouts,
        msgReportPayouts
      )
    end, "Payouts must match outcome slot count!")
	end)

  it("should fail to report payouts (already reported)", function()
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    ConditionalTokens:reportPayouts(
      msgReportPayouts.Tags.QuestionId,
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:reportPayouts(
        msgReportPayouts.Tags.QuestionId,
        msgReportPayouts.Tags.Payouts,
        msgReportPayouts
      )
    end, "payout denominator already set")
	end)

  it("should fail to report payouts (payout all zeros)", function()
    -- split position
    ConditionalTokens:splitPosition(
      recipient,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- wrong outcome slot count
    msgReportPayouts.Tags.Payouts = {0, 0, 0}
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:reportPayouts(
        msgReportPayouts.Tags.QuestionId,
        msgReportPayouts.Tags.Payouts,
        msgReportPayouts
      )
    end, "payout is all zeroes")
	end)

  it("should redeem positions", function()
    -- split position
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    ConditionalTokens:reportPayouts(
      msgReportPayouts.Tags.QuestionId,
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- redeem positions
    local notice = ConditionalTokens:redeemPositions(
      msgRedeemPositions
    )
    -- asert state change
    assert.are.same({
      [positionIds[1]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[2]] = {
        [ msgSplitPosition.From] = '0'
      },
      [positionIds[3]] = {
        [ msgSplitPosition.From] = '0'
      },
    }, ConditionalTokens.balancesById)
    -- assert notice
    assert.are.equals("Payout-Redemption-Notice", notice.Action)
    assert.are.equals(conditionId, notice.ConditionId)
    assert.are.equals(quantity, notice.Payout)
    assert.are.equals(_G.ao.id, notice.Process)
	end)

  it("should fail to redeem positions (not reported)", function()
    -- split position
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- redeem positions
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:redeemPositions(
        msgRedeemPositions
      )
    end, "result for condition not received yet")
	end)

  it("should fail to redeem positions (no balance)", function()
    -- split position
    ConditionalTokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    ConditionalTokens:reportPayouts(
      msgReportPayouts.Tags.QuestionId,
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- redeem positions from different account
    msgRedeemPositions.From = recipient
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:redeemPositions(
        msgRedeemPositions
      )
    end, "no stake to redeem")
	end)

  it("should get outcomeSlotCount (when prepared)", function()
    -- get outcomeSlotCount
    local result = ConditionalTokens:getOutcomeSlotCount(
      msgOutcomeSlotCount
    )
    -- assert result
    assert.are.equals(outcomeSlotCount, result)
	end)

  it("should fail to get outcomeSlotCount (missing conditionId)", function()
    -- should throw an error
    assert.has.error(function()
      msgOutcomeSlotCount.Tags.ConditionId = nil
      ConditionalTokens:getOutcomeSlotCount(
        msgOutcomeSlotCount
      )
    end, "ConditionId is required!")
	end)

  it("should get condition id", function()
    local result = ConditionalTokens.getConditionId(
      resolutionAgent,
      questionId,
      outcomeSlotCount
    )
    assert.are.equals(conditionId, result)
	end)

  it("should return total payout minus take fee", function()
    local result = ConditionalTokens:returnTotalPayoutMinusTakeFee(
      collateralToken,
      sender,
      totalPayout
    )
    -- extract results
    local protocolFeeTransfer = result[1]
    local creatorFeeTransfer = result[2]
    local totalAmountMinusTakeFeeTransfer = result[3]
    -- assert protocol fee transfer
    assert.are.equals(collateralToken, protocolFeeTransfer.Target)
    assert.are.equals("Transfer", getTagValue(protocolFeeTransfer.Tags, "Action"))
    assert.are.equals(protocolFeeTarget, getTagValue(protocolFeeTransfer.Tags, "Recipient"))
    assert.are.equals(tostring(math.ceil(totalPayout * protocolFee / 1e4)), getTagValue(protocolFeeTransfer.Tags, "Quantity"))
    -- -- assert creator fee transfer
    assert.are.equals(collateralToken, creatorFeeTransfer.Target)
    assert.are.equals("Transfer", getTagValue(creatorFeeTransfer.Tags, "Action"))
    assert.are.equals(creatorFeeTarget, getTagValue(creatorFeeTransfer.Tags, "Recipient"))
    assert.are.equals(tostring(math.ceil(totalPayout * creatorFee / 1e4)), getTagValue(creatorFeeTransfer.Tags, "Quantity"))
    -- assert total amount minus take fee transfer
    assert.are.equals(collateralToken, totalAmountMinusTakeFeeTransfer.Target)
    assert.are.equals("Transfer", getTagValue(totalAmountMinusTakeFeeTransfer.Tags, "Action"))
    assert.are.equals(sender, getTagValue(totalAmountMinusTakeFeeTransfer.Tags, "Recipient"))
    assert.are.equals(tostring(totalPayout - math.ceil(totalPayout * protocolFee / 1e4) - math.ceil(totalPayout * creatorFee / 1e4)), getTagValue(totalAmountMinusTakeFeeTransfer.Tags, "Quantity"))
	end)
end)