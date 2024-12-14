require("luacov")
local conditionalTokensHelpers = require("modules.conditionalTokensHelpers")
local json = require("json")
local crypto = require(".crypto")

local sender = ""
local resolutionAgent = ""
local collateralToken = ""
local questionId = ""
local conditionId = ""
local outcomeSlotCount = nil
local creatorFee = nil
local protocolFee = nil
local totalPayout = nil
local protocolFeeTarget = ""
local creatorFeeTarget = ""


describe("#market #conditionalTokens #conditionalTokensHelpers", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-1"
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-2"
    collateralToken = "test-this-is-valid-arweave-wallet-address-3"
    questionId = "this-is-a-valid-question-id"
    outcomeSlotCount = 2
    totalPayout = 100 -- collateral tokens
    protocolFee = 250 -- basis points
    creatorFee = 250 -- basis points
    conditionId = tostring(crypto.digest.keccak256(resolutionAgent .. questionId .. tostring(outcomeSlotCount)).asHex())
    -- Mock conditionalTokensHelpers.self
    local self = {
      protocolFee = protocolFee,
      creatorFee = creatorFee,
      protocolFeeTarget = protocolFeeTarget,
      creatorFeeTarget = creatorFeeTarget
    }
    setmetatable(conditionalTokensHelpers, { __index = self })
	end)

  it("should get condition id", function()
    local result = conditionalTokensHelpers.getConditionId(
      resolutionAgent,
      questionId,
      outcomeSlotCount
    )
    assert.are.equals(conditionId, result)
	end)

  it("should return total payout minus take fee", function()
    local result = conditionalTokensHelpers:returnTotalPayoutMinusTakeFee(
      collateralToken,
      sender,
      totalPayout
    )
    local protocolFeeTransfer = result[1]
    local creatorFeeTransfer = result[2]
    local totalAmountMinusTakeFeeTransfer = result[3]
    -- assert protocol fee transfer
    assert.are.equals(collateralToken, protocolFeeTransfer.Target)
    assert.are.equals("Transfer", protocolFeeTransfer.Action)
    assert.are.equals(protocolFeeTarget, protocolFeeTransfer.Recipient)
    assert.are.equals(tostring(math.ceil(totalPayout * 250 / 1e4)), protocolFeeTransfer.Quantity)
    -- assert creator fee transfer
    assert.are.equals(collateralToken, creatorFeeTransfer.Target)
    assert.are.equals("Transfer", creatorFeeTransfer.Action)
    assert.are.equals(creatorFeeTarget, creatorFeeTransfer.Recipient)
    assert.are.equals(tostring(math.ceil(totalPayout * 250 / 1e4)), creatorFeeTransfer.Quantity)
    -- assert total amount minus take fee transfer
    assert.are.equals(collateralToken, totalAmountMinusTakeFeeTransfer.Target)
    assert.are.equals("Transfer", totalAmountMinusTakeFeeTransfer.Action)
    assert.are.equals(sender, totalAmountMinusTakeFeeTransfer.Recipient)
    assert.are.equals(tostring(totalPayout - math.ceil(totalPayout * 250 / 1e4) - math.ceil(totalPayout * 250 / 1e4)), totalAmountMinusTakeFeeTransfer.Quantity)
	end)
end)