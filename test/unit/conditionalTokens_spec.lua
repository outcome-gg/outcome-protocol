require("luacov")
local conditionalTokens = require("marketModules.conditionalTokens")
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
local positionIds = {}
local creatorFee = nil
local protocolFee = nil
local payouts = {}
local totalPayout = nil
local protocolFeeTarget = ""
local creatorFeeTarget = ""
local quantity = ""
local payoutNumerators = {}
local payoutDenominator = nil
local msgSplitPosition = {}
local msgMergePositions = {}
local msgReportPayouts = {}
local msgRedeemPositions = {}
local msg = {}

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
      resolutionAgent,
      collateralToken,
      positionIds,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    )
    -- create a message object
    msgSplitPosition = {
      From = sender,
      Tags = {
        Process = _G.ao.id,
        Stakeholder = sender,
        CollateralToken = collateralToken,
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
      reply = function(message) return message end,
      forward = function(to, message) return {to, message} end
    }
    -- create a message object
    msgReportPayouts = {
      From = resolutionAgent,
      Tags = {
        Payouts = payouts,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgRedeemPositions = {
      From = sender,
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msg = {
      From = sender,
      reply = function(message) return message end,
      forward = function(target, message) return message end
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
    assert.are.same(resolutionAgent, ConditionalTokens.resolutionAgent)
    assert.are.same(positionIds, ConditionalTokens.positionIds)
    assert.are.same(payoutNumerators, ConditionalTokens.payoutNumerators)
    assert.are.same(payoutDenominator, ConditionalTokens.payoutDenominator)
    assert.are.same(creatorFee, ConditionalTokens.creatorFee)
    assert.are.same(creatorFeeTarget, ConditionalTokens.creatorFeeTarget)
    assert.are.same(protocolFee, ConditionalTokens.protocolFee)
    assert.are.same(protocolFeeTarget, ConditionalTokens.protocolFeeTarget)
	end)

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
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- asert state change
    assert.are.same(payouts, ConditionalTokens.payoutNumerators)
    assert.are.same(1, ConditionalTokens.payoutDenominator)
    -- assert notice
    assert.are.equals("Report-Payouts-Notice", notice.Action)
    assert.are.equals(json.encode(msgReportPayouts.Tags.Payouts), notice.PayoutNumerators)
    assert.are.equals(msgReportPayouts.From, notice.ResolutionAgent)
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
      msgReportPayouts.Tags.Payouts,
      msgReportPayouts
    )
    -- should throw an error
    assert.has.error(function()
      ConditionalTokens:reportPayouts(
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
    assert.are.equals("Redeem-Positions-Notice", notice.Action)
    assert.are.equals(quantity, notice.Payout)
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
    end, "market not resolved")
	end)

  it("should return total payout minus take fee", function()
    local result = ConditionalTokens:returnTotalPayoutMinusTakeFee(
      collateralToken,
      sender,
      totalPayout,
      msg
    )
    -- extract results
    local protocolFeeTransfer = result[1]
    local creatorFeeTransfer = result[2]
    local totalAmountMinusTakeFeeTransfer = result[3]

    -- assert protocol fee transfer
    assert.are.equal("Transfer", protocolFeeTransfer.Action)
    assert.are.equal(protocolFeeTarget,  protocolFeeTransfer.Recipient)
    assert.are.equal(tostring(math.ceil(totalPayout * protocolFee / 1e4)), protocolFeeTransfer.Quantity)
    -- assert creator fee transfer
    assert.are.equal("Transfer", creatorFeeTransfer.Action)
    assert.are.equal(creatorFeeTarget, creatorFeeTransfer.Recipient)
    assert.are.equal(tostring(math.ceil(totalPayout * creatorFee / 1e4)), creatorFeeTransfer.Quantity)
    -- assert total amount minus take fee transfer
    assert.are.equal("Transfer", totalAmountMinusTakeFeeTransfer.Action)
    assert.are.equal(sender, totalAmountMinusTakeFeeTransfer.Recipient)
    assert.are.equals(tostring(totalPayout - math.ceil(totalPayout * protocolFee / 1e4) - math.ceil(totalPayout * creatorFee / 1e4)), totalAmountMinusTakeFeeTransfer.Quantity)
	end)
end)