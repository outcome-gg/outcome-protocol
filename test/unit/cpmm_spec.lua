require("luacov")
local cpmm = require("marketModules.cpmm")
local token = require("marketModules.token")
local tokens = require("marketModules.conditionalTokens")
local json = require("json")

local market = ""
local sender = ""
local recipient = ""
local conditionId = ""
local collateralToken = ""
local outcomeSlotCount
local name = ""
local ticker = ""
local logo = ""
local logos = {}
local newLogo = ""
local newLogos = {}
local totalSupply = ""
local denomination = 0
local balancesById = {}
local totalSupplyById = {}
local lpFee
local creatorFee
local newCreatorFee
local creatorFeeTarget = ""
local protocolFee
local newProtocolFee
local protocolFeeTarget = ""
local newProtocolFeeTarget = ""
local configurator = ""
local newConfigurator = ""
local incentives = ""
local newIncentives = ""
local quantity = ""
local burnQuantity = ""
local returnAmount = ""
local investmentAmount = ""
local maxPositionTokensToSell = ""
local positionIds = {}
local distribution = {}
local msgInit = {}
local msgAddFunding = {}
local msgRemoveFunding = {}
local msgBuy = {}
local msgSell = {}
local msgCalcBuyAmount = {}
local msgCalcSellAmount = {}
local msgMint = {}
local msgBurn = {}
local msgTransfer = {}
local msgTransferError = {}
local msgUpdateConfigurator = {}
local msgUpdateIncentives = {}
local msgUpdateTakeFee = {}
local msgUpdateProtocolFeeTarget = {}
local msgUpdateLogo = {}
local msgUpdateLogos = {}
local noticeDebit = {}
local noticeCredit = {}
local noticeAddFunding = {}
local noticeRemoveFunding = {}
local noticeBuy = {}
local noticeSell = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#market #conditionalTokens #cpmmValidation", function()
  before_each(function()
    -- set variables
    market = "test-this-is-valid-arweave-wallet-address-1"
    sender = "test-this-is-valid-arweave-wallet-address-2"
    recipient = "test-this-is-valid-arweave-wallet-address-3"
    conditionId = "this-is-valid-condition-id"
    collateralToken = "test-this-is-valid-arweave-wallet-address-4"
    outcomeSlotCount = 2
    name = "Test Market"
    ticker = "TST"
    logo = "https://test.com/logo.png"
    logos = {"https://test.com/logo.png", "https://test.com/logo2.png"}
    newLogo = "https://test.com/new-logo.png"
    newLogos = {"https://test.com/new-logo.png", "https://test.com/new-logo2.png"}
    totalSupply = "0"
    denomination = 12
    lpFee = 100 -- basis points
    creatorFee = 100 -- basis points
    newCreatorFee = 200 -- basis points
    creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-3"
    protocolFee = 100 -- basis points
    newProtocolFee = 0 -- basis points
    protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
    newProtocolFeeTarget = "test-this-is-valid-arweave-wallet-address-5"
    configurator = "test-this-is-valid-arweave-wallet-address-6"
    newConfigurator = "test-this-is-valid-arweave-wallet-address-7"
    incentives = "test-this-is-valid-arweave-wallet-address-8"
    newIncentives = "test-this-is-valid-arweave-wallet-address-9"
    quantity = "100"
    burnQuantity = "50"
    returnAmount = "90"
    investmentAmount = "100"
    maxPositionTokensToSell = "140"
    positionIds = {"1", "2"}
    distribution = {50, 50}
    -- Instantiate objects
    CPMM = cpmm.new(
      configurator,
      collateralToken,
      conditionId,
      positionIds,
      name,
      ticker,
      denomination,
      logo,
      logos,
      lpFee,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    )
    -- create a message object
		msgInit = {
      From = market,
      Tags = {
        ConditionId = conditionId,
        CollateralToken = collateralToken,
        OutcomeSlotCount = outcomeSlotCount,
        Name = name,
        Ticker = ticker,
        Logo = logo,
        LpFee = lpFee,
        CreatorFee = creatorFee,
        CreatorFeeTarget = creatorFeeTarget,
        ProtocolFee = protocolFee,
        ProtocolFeeTarget = protocolFeeTarget,
        Configurator = configurator,
        Incentives = incentives
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgAddFunding = {
      From = collateralToken,
      Tags = {
        Sender = sender,
        Quantity = quantity,
        ["X-Distribution"] = json.encode(distribution)
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    noticeAddFunding = {
      Action = "Add-Funding-Notice",
      MintAmount = quantity,
      FundingAdded = json.encode({tonumber(quantity),tonumber(quantity)}),
      Data = "Successfully added funding"
    }
    -- create a message object
    msgRemoveFunding = {
      From = sender,
      Tags = {
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    noticeRemoveFunding = {
      Action = "Remove-Funding-Notice",
      SendAmounts = json.encode({quantity, quantity}),
      CollateralRemovedFromFeePool = "0", -- no fees yet collected
      SharesToBurn = quantity,
      Data = "Successfully removed funding"
    }
    -- create a message object
    msgBuy = {
      From = sender,
      Tags = {
        PositionId = "1",
        InvestmentAmount = investmentAmount,
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    noticeBuy = {
      Action = "Buy-Notice",
      OnBehalfOf = sender,
      InvestmentAmount = investmentAmount,
      FeeAmount = "0",
      PositionId = "1",
      PositionTokensBought = quantity,
      Data = "Successfully bought"
    }
    -- create a message object
    msgSell = {
      From = sender,
      Tags = {
        PositionId = "1",
        Quantity = quantity,
        ReturnAmount = returnAmount,
        MaxPositionTokensToSell = maxPositionTokensToSell
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    noticeSell = {
      Action = "Sell-Notice",
      ReturnAmount = returnAmount,
      FeeAmount = "0",
      PositionId = "1",
      PositionTokensSold = quantity,
      Data = "Successfully sold"
    }
    -- create a message object
    msgCalcBuyAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        InvestmentAmount = investmentAmount,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgCalcSellAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        ReturnAmount = returnAmount,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgMint = {
      From = sender,
      Tags = {
        Recipient = recipient,
        Quantity = quantity
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBurn = {
      From = sender,
      Tags = {
        Quantity = burnQuantity
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgTransfer = {
      From = sender,
      Tags = {
        Action = "Transfer",
        Recipient = recipient,
        Quantity = "100",
        ["X-Action"] = "FOO"
      },
      Id = "test-message-id",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgTransferError = {
      From = recipient,
      Tags = {
        Action = "Transfer",
        Recipient = sender,
        Quantity = "100"
      },
      Id = "test-message-id",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateConfigurator = {
      From = sender,
      Tags = {
        Configurator = newConfigurator
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateIncentives = {
      From = sender,
      Tags = {
        Incentives = newIncentives
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateTakeFee = {
      From = sender,
      Tags = {
        CreatorFee = newCreatorFee,
        ProtocolFee = newProtocolFee
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateProtocolFeeTarget = {
      From = sender,
      Tags = {
        ProtocolFeeTarget = newProtocolFeeTarget
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateLogo = {
      From = sender,
      Tags = {
        Logo = newLogo
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateLogos = {
      From = sender,
      Tags = {
        Logos = json.encode(newLogos)
      },
      reply = function(message) return message end
    }
    -- create a notice object
    noticeDebit = {
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to " .. recipient
    }
    -- create a notice object
    noticeCredit = {
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from " .. sender
    }
	end)

  it("should have initial state", function()
    local token_ = token.new(
      name .. " LP Token",
      ticker,
      logo,
      {},
      totalSupply,
      denomination
    )
    local tokens_ = tokens.new(
      name .. " Conditional Tokens",
      ticker,
      logos,
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
    -- assert initial state
    assert.is.same(configurator, CPMM.configurator)
    assert.is.same({}, CPMM.poolBalances)
    assert.is.same({}, CPMM.withdrawnFees)
    assert.is.same('0', CPMM.feePoolWeight)
    assert.is.same('0', CPMM.totalWithdrawnFees)
    assert.is.same(tokens_, CPMM.tokens)
    assert.is.same(token_, CPMM.token)
    assert.is.same(lpFee, CPMM.lpFee)
	end)

  it("should addFunding", function()
    -- add funding
    local notice = CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same({
      [msgAddFunding.Tags.Sender] = msgAddFunding.Tags.Quantity
    }, CPMM.token.balances)
    -- Conditional Token Balances
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
      ["2"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
    }, CPMM.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {msgAddFunding.Tags.Quantity, msgAddFunding.Tags.Quantity}
    assert.are.same(poolBalances, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated onBehalfOf
    noticeAddFunding.OnBehalfOf = msgAddFunding.Tags.Sender
    assert.are.same(noticeAddFunding, notice)
	end)

  it("should addFunding with unbalanced distribution", function()
    -- unbalanced distribution
    local newDistribution = {80, 100}
    msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
    -- calc and update new add funding distribution
    local newQuantity1 = newDistribution[1] * tostring(msgAddFunding.Tags.Quantity) / 100
    local newQuantity2 = newDistribution[2] * tostring(msgAddFunding.Tags.Quantity) / 100
    noticeAddFunding.FundingAdded = json.encode({newQuantity1, newQuantity2})
    -- add funding
    local notice = CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same({
      [msgAddFunding.Tags.Sender] = msgAddFunding.Tags.Quantity
    }, CPMM.token.balances)
    -- Conditional Token Balances
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(newDistribution[1]),
        [msgAddFunding.Tags.Sender] = tostring(newDistribution[2]-newDistribution[1]),
      },
      ["2"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
    }, CPMM.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {tostring(newDistribution[1]), tostring(newDistribution[2])}
    assert.are.same(poolBalances, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated onBehalfOf
    noticeAddFunding.OnBehalfOf = msgAddFunding.Tags.Sender
    assert.are.same(noticeAddFunding, notice)
	end)

  it("should addFunding with highly unbalanced distribution", function()
    -- highly unbalanced distribution
    local newDistribution = {1, 100}
    msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
    -- calc and update new add funding distribution
    local newQuantity1 = newDistribution[1] * tostring(msgAddFunding.Tags.Quantity) / 100
    local newQuantity2 = newDistribution[2] * tostring(msgAddFunding.Tags.Quantity) / 100
    noticeAddFunding.FundingAdded = json.encode({newQuantity1, newQuantity2})
    -- add funding
    local notice = CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same({
      [msgAddFunding.Tags.Sender] = msgAddFunding.Tags.Quantity
    }, CPMM.token.balances)
    -- Conditional Token Balances
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(newDistribution[1]),
        [msgAddFunding.Tags.Sender] = tostring(newDistribution[2]-newDistribution[1]),
      },
      ["2"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
    }, CPMM.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {tostring(newDistribution[1]), tostring(newDistribution[2])}
    assert.are.same(poolBalances, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated onBehalfOf
    noticeAddFunding.OnBehalfOf = msgAddFunding.Tags.Sender
    assert.are.same(noticeAddFunding, notice)
	end)

  it("should fail addFunding with binary distribution", function() -- @dev should not fail!
    -- unbalanced distribution
    local newDistribution = {0, 100}
    msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
    -- add funding
    assert.has.error(function()
      CPMM:addFunding(
        msgAddFunding.Tags.Sender,
        msgAddFunding.Tags.Quantity,
        json.decode(msgAddFunding.Tags["X-Distribution"]),
        msgAddFunding
      )
    end, "must hint a valid distribution")
	end)

  it("should removeFunding", function()
    -- backup send function override
    local backupAoSend = _G.ao.send
    -- Override ao.send to return a fixed balance
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.ao.send = function(val)
      local callCount = 0
      if val.Action == 'Balance' and callCount == 0 then
        callCount = callCount + 1
        return {
          receive = function()
            return { Data = msgAddFunding.Tags.Quantity } -- -- pool collateral balance before burn
          end
        }
      elseif val.Action == 'Balance' and callCount == 1 then
        callCount = callCount + 1
        return {
          receive = function()
            return { Data = "0" } -- pool collateral balance after burn
          end
        }
        end
      return {
        receive = function()
          return { Data = val }
        end
      }
    end
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- override receive to return collateralToken balance
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.Handlers.receive = function() return
      { Data = tonumber(msgAddFunding.Tags.Quantity) }
    end
    -- remove funding
    local notice = CPMM:removeFunding(
      msgRemoveFunding.From,
      msgRemoveFunding.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgRemoveFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same("0", CPMM.token.balances[msgRemoveFunding.From])
    -- Conditional Token Balances
    -- Pool Balances
    assert.are.same({"0", "0"}, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated onBehalfOf
    noticeRemoveFunding.OnBehalfOf = msgSell.From
    assert.are.same(noticeRemoveFunding, notice)
    -- restore ao.send
    _G.ao.send = backupAoSend
  end)

  it("should removeFunding with lpFees", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- backup send function override
    local backupAoSend = _G.ao.send
    -- Override ao.send to return a fixed balance
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.ao.send = function(val)
      local callCount = 0
      if val.Action == 'Balance' and callCount == 0 then
        callCount = callCount + 1
        return {
          receive = function()
            return { Data = msgAddFunding.Tags.Quantity } -- pool collateral balance before burn
          end
        }
      elseif val.Action == 'Balance' and callCount == 1 then
        callCount = callCount + 1
        return {
          receive = function()
            return { Data = "10" } -- pool collateral balance after burn
          end
        }
        end
      return {
        receive = function()
          return { Data = val }
        end
      }
    end
    -- remove funding
    local notice = CPMM:removeFunding(
      msgRemoveFunding.From,
      msgRemoveFunding.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgRemoveFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same("0", CPMM.token.balances[msgRemoveFunding.From])
    -- Conditional Token Balances
    -- Pool Balances
    assert.are.same({"0", "0"}, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated send amounts due to buy
    noticeRemoveFunding.SendAmounts = json.encode({"51", "199"})
    -- @dev: updated onBehalfOf
    noticeRemoveFunding.OnBehalfOf = msgRemoveFunding.From
    assert.are.same(noticeRemoveFunding, notice)
    -- restore ao.send
    _G.ao.send = backupAoSend
	end)

  it("should calc buy amount", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = ''
    assert.has.no.errors(function()
      buyAmount = CPMM:calcBuyAmount(
        tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
        msgCalcBuyAmount.Tags.PositionId
      )
    end)
    -- assert buy amount
    assert.is_true(tonumber(buyAmount) > 0)
	end)

  it("should fail to calc buy amount when positionId invalid", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    msgCalcBuyAmount.Tags.PositionId = "0"
    assert.has.error(function()
      CPMM:calcBuyAmount(
        tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
        msgCalcBuyAmount.Tags.PositionId
      )
    end, "PositionId must be valid!")
	end)

  it("should fail to calc buy amount when investmentAmount == 0", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    msgCalcBuyAmount.Tags.InvestmentAmount = "0"
    assert.has.error(function()
      CPMM:calcBuyAmount(
        tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
        msgCalcBuyAmount.Tags.PositionId
      )
    end, "InvestmentAmount must be greater than zero!")
	end)

  it("should fail to calc buy amount when no funding", function()
    -- calc buy amount
    assert.has.error(function()
      CPMM:calcBuyAmount(
        tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
        msgCalcBuyAmount.Tags.PositionId
      )
    end, "must have non-zero balances")
	end)

  it("should calc sell amount", function()
    -- add funding 
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc sell amount
    local sellAmount = ''
    assert.has.no.errors(function()
      sellAmount = CPMM:calcSellAmount(
        tonumber(msgCalcSellAmount.Tags.ReturnAmount),
        msgCalcSellAmount.Tags.PositionId
      )
    end)
    -- assert sell amount
    assert.is_true(tonumber(sellAmount) > 0)
	end)

  it("should fail to calc sell amount when poolAmount <= returnAmountPlusFees", function()
    -- add funding 
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc sell amount
    msgCalcSellAmount.Tags.ReturnAmount = "99" -- returnAmount + fees > 100
    assert.has.error(function()
      CPMM:calcSellAmount(
        tonumber(msgCalcSellAmount.Tags.ReturnAmount),
        msgCalcSellAmount.Tags.PositionId
      )
    end, "PoolBalance must be greater than return amount plus fees!")
	end)

  it("should buy", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = CPMM:calcBuyAmount(
      tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
      msgCalcBuyAmount.Tags.PositionId
    )
    -- buy
    local notice = {}
    assert.has.no.errors(function()
      notice = CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- assert state
    -- LP Token balances
    assert.are.same(msgBuy.Tags.InvestmentAmount, CPMM.token.balances[msgBuy.From])
    -- Conditional Token Balances
    local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
    local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * CPMM.lpFee / 10000)
    local quantityMinusFees = tonumber(msgBuy.Tags.Quantity) - tonumber(feeAmount)
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
        [msgBuy.From] = buyAmount,
      },
      ["2"] = {
        [_G.ao.id] = tostring(fundingAmount + quantityMinusFees),
      },
    }, CPMM.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {
      tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
      tostring(fundingAmount + quantityMinusFees)
    }
    assert.are.same(poolBalances, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated buy amount
    noticeBuy.PositionTokensBought = buyAmount
    noticeBuy.FeeAmount = tostring(math.floor(buyAmount * CPMM.lpFee / 10000))
    assert.are.same(noticeBuy, notice)
	end)

  it("should not buy when minimumPositionTokens not reached", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = CPMM:calcBuyAmount(
      tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
      msgCalcBuyAmount.Tags.PositionId
    )
    -- buy
    local notice = {}
    msgBuy.Tags.Quantity = "1000" -- minimumOutcomeTokens is 10000
    assert.has.error(function()
      notice = CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
      )
    end, "Minimum position tokens not reached!")
  end)

  it("should sell", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = CPMM:calcBuyAmount(
      tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
      msgCalcBuyAmount.Tags.PositionId
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- assert state before
    local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
    local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * CPMM.lpFee / 10000)
    local quantityMinusFees = tonumber(msgBuy.Tags.Quantity) - tonumber(feeAmount)
    local balancesBefore = {
      ["1"] = {
        [_G.ao.id] = tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
        [msgBuy.From] = buyAmount,
      },
      ["2"] = {
        [_G.ao.id] = tostring(fundingAmount + quantityMinusFees),
      },
    }
    assert.are.same(balancesBefore, CPMM.tokens.balancesById)
    -- calc sell amount
    local sellAmount = CPMM:calcSellAmount(
      tonumber(msgSell.Tags.ReturnAmount),
      msgSell.Tags.PositionId
    )
    -- Override ao.send to return a fixed balance
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.ao.send = function(val)
      if val.Action == 'Balance' then
        return {
          receive = function()
            return { Data = msgBuy.Tags.InvestmentAmount } -- pool collateral balance before transfers
          end
        }
      end
      return {
        receive = function()
          return { Data = val }
        end
      }
    end
    -- @dev increase max sell amount to sellAmount
    msgSell.Tags.MaxPositionTokensToSell = sellAmount
    -- @dev similarly prepare notice
    noticeSell.PositionTokensSold = sellAmount
    -- @dev set notice feeAmount 
    local feeAmount_ = math.ceil(tonumber(msgSell.Tags.ReturnAmount) * CPMM.lpFee / 10000)
    noticeSell.FeeAmount = tostring(feeAmount_)
    -- sell
    local notice = {}
    assert.has.no.errors(function()
      notice = CPMM:sell(
        msgSell.From,
        msgSell.From, -- onBehalfOf is the same as sender
        msgSell.Tags.ReturnAmount,
        msgSell.Tags.PositionId,
        msgSell.Tags.MaxPositionTokensToSell,
        false, -- cast
        false, -- castInterim
        msgSell
      )
    end)
    -- assert state
    -- LP Token balances
    assert.are.same(msgBuy.Tags.InvestmentAmount, CPMM.token.balances[msgBuy.From])
    -- Conditional Token Balances
    local returnAmount_ = tonumber(msgSell.Tags.ReturnAmount)
    local returnAmountPlusFees = returnAmount_ + feeAmount_

    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(tonumber(balancesBefore["1"][_G.ao.id])),
        [msgSell.From] =  tostring(tonumber(balancesBefore["1"][msgSell.From]) - msgSell.Tags.MaxPositionTokensToSell),
      },
      ["2"] = {
        [_G.ao.id] = tostring(balancesBefore["2"][_G.ao.id] - msgSell.Tags.MaxPositionTokensToSell),
      },
    }, CPMM.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {
      tostring(tonumber(balancesBefore["1"][_G.ao.id])),
      tostring(balancesBefore["2"][_G.ao.id] - msgSell.Tags.MaxPositionTokensToSell) -- merges from both positions to sell
    }
    assert.are.same(poolBalances, CPMM:getPoolBalances())
    -- assert notice
    -- @dev: updated onBehalfOf
    noticeSell.OnBehalfOf = msgSell.From
    assert.are.same(noticeSell, notice)
  end)

  it("should fail to sell when max sell amount is exceeded", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- sell
    msgSell.Tags.MaxPositionTokensToSell = "100"
    assert.has.error(function()
      CPMM:sell(
      msgSell.From,
      msgSell.From, -- onBehalfOf is the same as sender
      msgSell.Tags.ReturnAmount,
      msgSell.Tags.PositionId,
      msgSell.Tags.Quantity,
      msgSell.Tags.MaxPositionTokensToSell,
      msgSell
      )
    end, "Maximum sell amount exceeded!")
  end)

  it("should fail to sell when insufficient liquidity", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- stub
    stub(CPMM, "calcSellAmount", function()
      return "100"
    end)
    -- sell
    msgSell.Tags.ReturnAmount = "1000"
    msgSell.Tags.MaxPositionTokensToSell = "100"
    assert.has.error(function()
      CPMM:sell(
      msgSell.From,
      msgSell.From, -- onBehalfOf is the same as sender
      msgSell.Tags.ReturnAmount,
      msgSell.Tags.PositionId,
      msgSell.Tags.Quantity,
      msgSell.Tags.MaxPositionTokensToSell,
      msgSell
      )
    end, "Insufficient liquidity!")
  end)

  it("should fail to sell when insufficient balance", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- transfer to another account
    CPMM.tokens:transferSingle(
      msgSell.From,
      "test-this-is-valid-arweave-wallet-address-10",
      msgSell.Tags.PositionId,
      msgSell.Tags.Quantity,
      true,
      false,
      {}
    )
    -- sell
    assert.has.error(function()
      CPMM:sell(
      msgSell.From,
      msgSell.From, -- onBehalfOf is the same as sender
      msgSell.Tags.ReturnAmount,
      msgSell.Tags.PositionId,
      msgSell.Tags.MaxPositionTokensToSell,
      msgSell
      )
    end, "Insufficient balance!")
  end)

  it("should return collectedFees", function()
    local collectedFees = nil
    -- should not throw an error
		assert.has.no.error(function()
      collectedFees = CPMM:collectedFees()
    end)
    -- assert collected fees
    assert.are.equal("0", collectedFees)
	end)

  it("should return collectedFees after fee accrual", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- collected fees
    local collectedFees = nil
    -- should not throw an error
		assert.has.no.error(function()
      collectedFees = CPMM:collectedFees()
    end)
    -- assert collected fees
    assert.are.equal("1", collectedFees)
	end)

  it("should return feesWithdrawableBy sender", function()
    -- fees withdrawable
    local feesWithdrawable = nil
    -- should not throw an error
		assert.has.no.error(function()
      feesWithdrawable = CPMM:feesWithdrawableBy(sender)
    end)
    -- assert fees withdrawable
    assert.are.equal("0", feesWithdrawable)
	end)

  it("should return feesWithdrawableBy sender after fee accrual", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- fees withdrawable
    local feesWithdrawable = nil
    -- should not throw an error
		assert.has.no.error(function()
      feesWithdrawable = CPMM:feesWithdrawableBy(sender)
    end)
    -- assert fees withdrawable
    assert.are.equal("1", feesWithdrawable)
	end)

  it("should withdraw fees from sender", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- fees withdrawable
    local feesWithdrawable = CPMM:feesWithdrawableBy(sender)
    -- withdraw fees
    local withdrawnFeesNotice = {}
    -- should not throw an error
		assert.has.no.error(function()
      withdrawnFeesNotice = CPMM:withdrawFees(
        sender,
        sender,
        false, -- cast
        false, -- sendInterim
        false, -- detached
        msgBuy
      )
    end)
    -- assert withdrawn fees
    assert.are.equal("1", feesWithdrawable)
    assert.are.equal(feesWithdrawable, withdrawnFeesNotice.FeeAmount)
    -- assert state change
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
	end)

  -- The withdrawnFees[sender] function is overwritten when fees are collected. This should be accumulated instead.
  -- The user can withdraw as many tokens as they please.
  it("should fix FYEO-OUTCOME-01", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      "1000", -- updated due to rounding error msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- add funding from a different sender
    CPMM:addFunding(
      recipient, -- different sender
      "1000", -- updated due to rounding error msgAddFunding.Tags.Quantity,
      nil,
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- @dev withdrawnFees mapping updated to prevent user from withdrawing fees on any previous funding
    assert.are.equal("1000", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev no collected fees as no trading has occurred
    assert.are.equal("0", CPMM:collectedFees())
    -- @dev no fees withdrawable as no trading has occurred
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
    assert.are.equal("0", CPMM:feesWithdrawableBy(recipient))

    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      "1000", -- updated due to rounding error msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      "1000", -- updated due to rounding error msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)

    -- @dev withdrawnFees unchanged
    assert.are.equal("1000", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev 1% LP fees
    assert.are.equal("10", CPMM:collectedFees())
    -- @dev Sender and recipient receive 50% of the fees each
    assert.are.equal("5", CPMM:feesWithdrawableBy(sender))
    assert.are.equal("5", CPMM:feesWithdrawableBy(recipient))

    -- withdraw fees
    -- should not throw an error
		assert.has.no.error(function()
      CPMM:withdrawFees(
        sender,
        sender,
        false, -- cast
        false, -- sendInterim
        false, -- detached
        msgBuy
      )
    end)

    -- @dev sender withdrawnFees updated
    assert.are.equal("1005", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev 10 collected minus 5 withdrawn
    assert.are.equal("5", CPMM:collectedFees())
    -- @dev Sender has withdrawn their fees
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
    assert.are.equal("5", CPMM:feesWithdrawableBy(recipient))

    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      "1000", -- updated due to rounding error msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      "1000", -- updated due to rounding error msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)

    -- @dev withdrawnFees unchanged
    assert.are.equal("1005", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev 5 + 10 (1% LP fee)
    assert.are.equal("15", CPMM:collectedFees())
    -- @dev Sender and recipient receive 50% of the fees each of new fee
    assert.are.equal("5", CPMM:feesWithdrawableBy(sender))
    assert.are.equal("10", CPMM:feesWithdrawableBy(recipient))

    -- withdraw fees
    -- second all should not throw an error
		assert.has.no.error(function()
      CPMM:withdrawFees(
        sender,
        sender,
        false, -- cast
        false, -- sendInterim
        false, -- detached
        msgBuy
      )
    end)

    -- @dev sender withdrawnFees updated
    assert.are.equal("1010", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev 15 - 5 withdrawn
    assert.are.equal("10", CPMM:collectedFees())
    -- @dev Sender and recipient receive 50% of the fees each of new fee
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
    assert.are.equal("10", CPMM:feesWithdrawableBy(recipient))

    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      "1000", -- updated due to rounding error msgAddFunding.Tags.Quantity,
      nil,
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )

    -- @dev sender withdrawnFees updated to prevent user from withdrawing fees on any previous funding
    -- @dev updated amount not equal to funding amount due to update probabilities (the difference received as outcome tokens)
    assert.are.equal("1517", CPMM.withdrawnFees[sender])
    assert.are.equal("1000", CPMM.withdrawnFees[recipient])
    -- @dev 15 - 5 withdrawn
    assert.are.equal("10", CPMM:collectedFees())
    -- @dev Sender and recipient receive 50% of the fees each of new fee
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
    -- @dev number decreased due to small (yet necessary) rounding error (9.999 -> 9) to prevent underflow
    assert.are.equal("9", CPMM:feesWithdrawableBy(recipient))
	end)

  it("should withdraw fees during _beforeTokenTransfer", function()
    -- add funding
    CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      false, -- cast
      false, -- castInterim
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      CPMM:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      false, -- cast
      false, -- castInterim
      msgBuy
      )
    end)
    -- fees withdrawable
    local feesWithdrawable = CPMM:feesWithdrawableBy(sender)
    -- _beforeTokenTransfer
    -- should not throw an error
		assert.has.no.error(function()
      CPMM:_beforeTokenTransfer(
        sender,
        market,
        feesWithdrawable,
        false, -- cast
        false, -- sendInterim
        msgBuy
      ) -- msgBuy used to send a message with forward
    end)
    -- assert state change
    assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
	end)

  it("should mint tokens", function()
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = CPMM:mint(
        msgMint.Tags.Recipient,
        msgMint.Tags.Quantity,
        false, -- cast
        false, -- sendInterim
        false, -- detached
        msgMint
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, CPMM.token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, CPMM.token.totalSupply)
    -- assert notice
    assert.are.same({
      Recipient = recipient,
      Quantity = msgMint.Tags.Quantity,
      Action = 'Mint-Notice',
      Data = "Successfully minted " .. msgMint.Tags.Quantity
    }, notice)
	end)

  it("should burn tokens", function()
    local notice = {}
    -- mint tokens
    CPMM.token:mint(
        msgMint.From,
        msgMint.Tags.Quantity,
        msgMint
      )
    -- should not throw an error
    assert.has_no.errors(function()
      notice = CPMM.token:burn(
        msgBurn.From,
        msgBurn.Tags.Quantity,
        false, -- cast
        true, -- detached
        msgBurn
      ).receive().Data
    end)
    -- calculate expected updated balance
    local updateBalance = tostring(tonumber(quantity) - tonumber(burnQuantity))
    -- assert updated balance
    assert.are.same(CPMM.token.balances[sender], updateBalance)
    -- assert update total supply
    assert.are.same(CPMM.token.totalSupply, updateBalance)
    -- assert notice
    assert.are.same({
      Action = 'Burn-Notice',
      Target = msgBurn.From,
      Quantity = msgBurn.Tags.Quantity,
      Data = "Successfully burned " .. msgBurn.Tags.Quantity
    }, notice)
	end)

  it("should transfer tokens", function()
    local notices = {}
    -- mint tokens
    CPMM.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- should not throw an error
    assert.has_no.errors(function()
      notices = CPMM.token:transfer(
        msgTransfer.From,
        msgTransfer.Tags.Recipient,
        msgTransfer.Tags.Quantity,
        false, -- cast
        false, -- detached
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, CPMM.token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, CPMM.token.totalSupply)
    -- assert notices
    assert.are.same(noticeDebit, notices[1])
    assert.are.same(noticeCredit, notices[2])
	end)

  it("should fail to transfer tokens with insufficient balance", function()
    local notice = {}
    -- should not throw an error
    assert.has_no.error(function()
      notice = CPMM.token:transfer(
        msgTransferError.From,
        msgTransferError.Tags.Recipient,
        msgTransferError.Tags.Quantity,
        false, -- cast
        false, -- detached
        msgTransferError
      )
    end)
    -- assert no updated balance
    assert.are.same('0', CPMM.token.balances[recipient])
    -- assert no updated total supply
    assert.are.same('0', CPMM.token.totalSupply)
    -- assert error notice
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransferError.Id,
      Error = 'Insufficient Balance!'
    }, notice)
	end)

  it("should update configurator", function()
    local notice = {}
    -- should not throw an error
		assert.has.no.error(function()
      notice = CPMM:proposeConfigurator(
      msgUpdateConfigurator.Tags.Configurator,
      msgUpdateConfigurator
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, CPMM.proposedConfigurator)
    -- assert notice
    assert.are.equal("Propose-Configurator-Notice", notice.Action)
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, notice.Data)
	end)

  it("should accept configurator", function()
    local notice = {}
        -- should not throw an error
		assert.has.no.error(function()
      CPMM:proposeConfigurator(
      msgUpdateConfigurator.Tags.Configurator,
      msgUpdateConfigurator
    )
    end)
    -- should not throw an error
    msgUpdateConfigurator.From = msgUpdateConfigurator.Tags.Configurator
		assert.has.no.error(function()
      notice = CPMM:acceptConfigurator(
      msgUpdateConfigurator
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateConfigurator.From, CPMM.configurator)
    -- assert notice
    assert.are.equal("Accept-Configurator-Notice", notice.Action)
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, notice.Data)
	end)

  it("should update take fee" , function()
    local notice = {}
    -- should not throw an error
    assert.has.no.error(function()
      notice = CPMM:updateTakeFee(
      msgUpdateTakeFee.Tags.CreatorFee,
      msgUpdateTakeFee.Tags.ProtocolFee,
      msgUpdateTakeFee
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateTakeFee.Tags.CreatorFee, CPMM.tokens.creatorFee)
    assert.are.equal(msgUpdateTakeFee.Tags.ProtocolFee, CPMM.tokens.protocolFee)
    -- assert notice
    local takeFee = tostring(tonumber(msgUpdateTakeFee.Tags.CreatorFee) + tonumber(msgUpdateTakeFee.Tags.ProtocolFee))
    assert.are.equal("Update-Take-Fee-Notice", notice.Action)
    assert.are.equal(tostring(msgUpdateTakeFee.Tags.CreatorFee), notice.CreatorFee)
    assert.are.equal(tostring(msgUpdateTakeFee.Tags.ProtocolFee), notice.ProtocolFee)
    assert.are.equal(takeFee, notice.Data)
  end)

  it("should update protocol fee target" , function()
    local notice = {}
    -- should not throw an error
    assert.has.no.error(function()
      notice = CPMM:updateProtocolFeeTarget(
      msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget,
      msgUpdateProtocolFeeTarget
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, CPMM.tokens.protocolFeeTarget)
    -- assert notice
    assert.are.equal("Update-Protocol-Fee-Target-Notice", notice.Action)
    assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, notice.Data)
  end)

  it("should update logo" , function()
    local notice = {}
    -- should not throw an error
    assert.has.no.error(function()
      notice = CPMM:updateLogo(
      msgUpdateLogo.Tags.Logo,
      msgUpdateLogo
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateLogo.Tags.Logo, CPMM.token.logo)
    -- assert notice
    assert.are.equal("Update-Logo-Notice", notice.Action)
    assert.are.equal(msgUpdateLogo.Tags.Logo, notice.Data)
  end)

  it("should update logos" , function()
    local notice = {}
    -- should not throw an error
    assert.has.no.error(function()
      notice = CPMM:updateLogos(
      json.decode(msgUpdateLogos.Tags.Logos),
      msgUpdateLogos
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateLogos.Tags.Logos, json.encode(CPMM.tokens.logos))
    -- assert notice
    assert.are.equal("Update-Logos-Notice", notice.Action)
    assert.are.equal(msgUpdateLogos.Tags.Logos, notice.Data)
  end)
end)