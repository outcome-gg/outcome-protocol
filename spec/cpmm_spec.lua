require("luacov")
local cpmm = require("modules.cpmm")
local token = require("modules.token")
local tokens = require("modules.conditionalTokens")
local json = require("json")

local marketFactory = ""
local sender = ""
local recipient = ""
local marketId = ""
local conditionId = ""
local collateralToken = ""
local outcomeSlotCount
local name = ""
local ticker = ""
local logo = ""
local newLogo = ""
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
local maxOutcomeTokensToSell = ""
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
local noticeDebit = {}
local noticeCredit = {}

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
    marketFactory = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    marketId = "this-is-valid-market-id"
    conditionId = "this-is-valid-condition-id"
    collateralToken = "test-this-is-valid-arweave-wallet-address-2"
    outcomeSlotCount = 2
    name = "Test Market"
    ticker = "TST"
    logo = "https://test.com/logo.png"
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
    maxOutcomeTokensToSell = "140"
    positionIds = {"1", "2"}
    distribution = {50, 50}
    -- Instantiate objects
    CPMM = cpmm:new(
      configurator,
      incentives,
      collateralToken,
      marketId,
      conditionId,
      positionIds,
      name,
      ticker,
      logo,
      lpFee,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    )
    -- create a message object
		msgInit = {
      From = marketFactory,
      Tags = {
        MarketId = marketId,
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
      forward = function(message) return message end
    }
    -- create a message object
    msgRemoveFunding = {
      From = sender,
      Tags = {
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(message) return message end
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
      forward = function(message) return message end
    }
    -- create a message object
    msgSell = {
      From = sender,
      Tags = {
        PositionId = "1",
        Quantity = quantity,
        ReturnAmount = returnAmount,
        MaxOutcomeTokensToSell = maxOutcomeTokensToSell
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgCalcBuyAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        InvestmentAmount = investmentAmount,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgCalcSellAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        ReturnAmount = returnAmount,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgMint = {
      From = sender,
      Tags = {
        Recipient = recipient,
        Quantity = quantity
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBurn = {
      From = sender,
      Tags = {
        Quantity = burnQuantity
      },
      reply = function(message) return message end
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
      reply = function(message) return message end
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
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateConfigurator = {
      From = sender,
      Tags = {
        Configurator = newConfigurator
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateIncentives = {
      From = sender,
      Tags = {
        Incentives = newIncentives
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateTakeFee = {
      From = sender,
      Tags = {
        CreatorFee = newCreatorFee,
        ProtocolFee = newProtocolFee
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateProtocolFeeTarget = {
      From = sender,
      Tags = {
        ProtocolFeeTarget = newProtocolFeeTarget
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateLogo = {
      From = sender,
      Tags = {
        Logo = newLogo
      },
      reply = function(message) return message end
    }
    -- create a notice object
    noticeDebit = {
      Target = sender,
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to test-this-is-valid-arweave-wallet-address-2"
    }
    -- create a notice object
    noticeCredit = {
      Target = recipient,
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from test-this-is-valid-arweave-wallet-address-1"
    }
	end)

  it("should have initial state", function()
    local token_ = token:new(
      name,
      ticker,
      logo,
      {},
      totalSupply,
      denomination
    )
    local tokens_ = tokens:new(
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
    -- assert initial state
		assert.is.same(marketId, CPMM.marketId)
    assert.is.same(incentives, CPMM.incentives)
    assert.is.same(configurator, CPMM.configurator)
    assert.is.same(true, CPMM.initialized)
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
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
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
    local fundingAdded = json.encode({tonumber(msgAddFunding.Tags.Quantity), tonumber(msgAddFunding.Tags.Quantity)})
    -- assert notice
    assert.are.same(msgAddFunding.Tags.Sender, notice.Target)
    assert.are.same("Successfully added funding", notice.Data)
    assert.are.same("Funding-Added-Notice", getTagValue(notice.Tags, "Action"))
    assert.are.same(msgAddFunding.Tags.Quantity,  getTagValue(notice.Tags, "MintAmount"))
    assert.are.same(fundingAdded, getTagValue(notice.Tags, "FundingAdded"))
	end)

  it("should addFunding with unbalanced distribution", function()
    -- unbalanced distribution
    local newDistribution = {80, 100}
    msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
    -- add funding
    local notice = CPMM:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
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
    local fundingAdded = json.encode({newDistribution[1], 100})
    -- assert notice
    assert.are.same(msgAddFunding.Tags.Sender, notice.Target)
    assert.are.same("Successfully added funding", notice.Data)
    assert.are.same("Funding-Added-Notice", getTagValue(notice.Tags, "Action"))
    assert.are.same(msgAddFunding.Tags.Quantity,  getTagValue(notice.Tags, "MintAmount"))
    assert.are.same(fundingAdded, getTagValue(notice.Tags, "FundingAdded"))
	end)

  -- it("should addFunding with highly unbalanced distribution", function()
  --   -- highly unbalanced distribution
  --   local newDistribution = {1, 100}
  --   msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
  --   -- add funding
  --   local notice = CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- assert state
  --   -- LP Token balances
  --   assert.are.same({
  --     [msgAddFunding.Tags.Sender] = msgAddFunding.Tags.Quantity
  --   }, CPMM.token.balances)
  --   -- Conditional Token Balances
  --   assert.are.same({
  --     ["1"] = {
  --       [_G.ao.id] = tostring(newDistribution[1]),
  --       [msgAddFunding.Tags.Sender] = tostring(newDistribution[2]-newDistribution[1]),
  --     },
  --     ["2"] = {
  --       [_G.ao.id] = msgAddFunding.Tags.Quantity,
  --     },
  --   }, CPMM.tokens.balancesById)
  --   -- Pool Balances
  --   local poolBalances = {tostring(newDistribution[1]), tostring(newDistribution[2])}
  --   assert.are.same(poolBalances, CPMM:getPoolBalances())
  --   local fundingAdded = json.encode({newDistribution[1], 100})
  --   -- assert notice
  --   assert.are.same(msgAddFunding.Tags.Sender, notice.Target)
  --   assert.are.same("Successfully added funding", notice.Data)
  --   assert.are.same("Funding-Added-Notice", getTagValue(notice.Tags, "Action"))
  --   assert.are.same(msgAddFunding.Tags.Quantity,  getTagValue(notice.Tags, "MintAmount"))
  --   assert.are.same(fundingAdded, getTagValue(notice.Tags, "FundingAdded"))
	-- end)

  -- it("should fail addFunding with binary distribution", function()
  --   -- unbalanced distribution
  --   local newDistribution = {0, 100}
  --   msgAddFunding.Tags["X-Distribution"] = json.encode(newDistribution)
  --   -- add funding
  --   assert.has.error(function()
  --     CPMM:addFunding(
  --       msgAddFunding.Tags.Sender,
  --       msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --       msgAddFunding.Tags.Quantity,
  --       json.decode(msgAddFunding.Tags["X-Distribution"]),
  --       msgAddFunding
  --     )
  --   end, "must hint a valid distribution")
	-- end)

  -- it("should removeFunding", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- override receive to return collateralToken balance
  --   ---@diagnostic disable-next-line: duplicate-set-field
  --   _G.Handlers.receive = function() return
  --     { Data = tonumber(msgAddFunding.Tags.Quantity) }
  --   end
  --   -- remove funding
  --   local notice = CPMM:removeFunding(
  --     msgRemoveFunding.From,
  --     msgRemoveFunding.Tags.Quantity,
  --     msgRemoveFunding
  --   )
  --   -- assert state
  --   -- LP Token balances
  --   assert.are.same("0", CPMM.token.balances[msgRemoveFunding.From])
  --   -- Conditional Token Balances
  --   -- Pool Balances
  --   assert.are.same({"0", "0"}, CPMM:getPoolBalances())
  --   -- assert notice
  --   assert.are.same(msgRemoveFunding.From, notice.Target)
  --   assert.are.same("Successfully removed funding", notice.Data)
  --   assert.are.same("Funding-Removed-Notice", getTagValue(notice.Tags, "Action"))
  --   local sendAmounts = json.encode({msgRemoveFunding.Tags.Quantity, msgRemoveFunding.Tags.Quantity})
  --   assert.are.same(sendAmounts,  getTagValue(notice.Tags, "SendAmounts"))
  --   assert.are.same(msgRemoveFunding.Tags.Quantity,  getTagValue(notice.Tags, "SharesToBurn"))
  --   local collateralRemovedFromFeePool = "0" -- no fees yet collected
  --   assert.are.same(collateralRemovedFromFeePool, getTagValue(notice.Tags, "CollateralRemovedFromFeePool"))
	-- end)

  -- it("should removeFunding with lpFees", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   local buyAmount = CPMM:calcBuyAmount(
  --     tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --     msgCalcBuyAmount.Tags.PositionId
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- override receive to return collateralToken balance
  --   ---@diagnostic disable-next-line: duplicate-set-field
  --   _G.Handlers.receive = function() return
  --     { Data = tonumber(msgAddFunding.Tags.Quantity) }
  --   end
  --   -- remove funding
  --   local poolBalancesBefore = CPMM:getPoolBalances()
  --   local notice = CPMM:removeFunding(
  --     msgRemoveFunding.From,
  --     msgRemoveFunding.Tags.Quantity,
  --     msgRemoveFunding
  --   )
  --   -- assert state
  --   -- LP Token balances
  --   assert.are.same("0", CPMM.token.balances[msgRemoveFunding.From])
  --   -- Conditional Token Balances
  --   -- Pool Balances
  --   assert.are.same({"0", "0"}, CPMM:getPoolBalances())
  --   -- assert notice
  --   assert.are.same(msgRemoveFunding.From, notice.Target)
  --   assert.are.same("Successfully removed funding", notice.Data)
  --   assert.are.same("Funding-Removed-Notice", getTagValue(notice.Tags, "Action"))
  --   local sendAmounts = json.encode({
  --     tostring(tonumber(msgRemoveFunding.Tags.Quantity) - buyAmount),
  --     msgRemoveFunding.Tags.Quantity
  --   })
  --   assert.are.same(json.encode(poolBalancesBefore),  getTagValue(notice.Tags, "SendAmounts"))
  --   assert.are.same(msgRemoveFunding.Tags.Quantity,  getTagValue(notice.Tags, "SharesToBurn"))
  --   local collateralRemovedFromFeePool = "0" -- no fees yet collected
  --   assert.are.same(collateralRemovedFromFeePool, getTagValue(notice.Tags, "CollateralRemovedFromFeePool"))
	-- end)

  -- it("should calc buy amount", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   local buyAmount = ''
  --   assert.has.no.errors(function()
  --     buyAmount = CPMM:calcBuyAmount(
  --       tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --       msgCalcBuyAmount.Tags.PositionId
  --     )
  --   end)
  --   -- assert buy amount
  --   assert.is_true(tonumber(buyAmount) > 0)
	-- end)

  -- it("should fail to calc buy amount when positionId invalid", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   msgCalcBuyAmount.Tags.PositionId = "0"
  --   assert.has.error(function()
  --     CPMM:calcBuyAmount(
  --       tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --       msgCalcBuyAmount.Tags.PositionId
  --     )
  --   end, "PositionId must be valid!")
	-- end)

  -- it("should fail to calc buy amount when investmentAmount == 0", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   msgCalcBuyAmount.Tags.InvestmentAmount = "0"
  --   assert.has.error(function()
  --     CPMM:calcBuyAmount(
  --       tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --       msgCalcBuyAmount.Tags.PositionId
  --     )
  --   end, "InvestmentAmount must be greater than zero!")
	-- end)

  -- it("should fail to calc buy amount when no funding", function()
  --   -- calc buy amount
  --   assert.has.error(function()
  --     CPMM:calcBuyAmount(
  --       tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --       msgCalcBuyAmount.Tags.PositionId
  --     )
  --   end, "must have non-zero balances")
	-- end)

  -- it("should calc sell amount", function()
  --   -- add funding 
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc sell amount
  --   local sellAmount = ''
  --   assert.has.no.errors(function()
  --     sellAmount = CPMM:calcSellAmount(
  --       tonumber(msgCalcSellAmount.Tags.ReturnAmount),
  --       msgCalcSellAmount.Tags.PositionId
  --     )
  --   end)
  --   -- assert sell amount
  --   assert.is_true(tonumber(sellAmount) > 0)
	-- end)

  -- it("should fail to calc sell amount when poolAmount <= returnAmountPlusFees", function()
  --   -- add funding 
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc sell amount
  --   msgCalcSellAmount.Tags.ReturnAmount = "99" -- returnAmount + fees > 100
  --   assert.has.error(function()
  --     CPMM:calcSellAmount(
  --       tonumber(msgCalcSellAmount.Tags.ReturnAmount),
  --       msgCalcSellAmount.Tags.PositionId
  --     )
  --   end, "PoolBalance must be greater than return amount plus fees!")
	-- end)

  -- it("should buy", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   local buyAmount = CPMM:calcBuyAmount(
  --     tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --     msgCalcBuyAmount.Tags.PositionId
  --   )
  --   -- buy
  --   local notice = {}
  --   assert.has.no.errors(function()
  --     notice = CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- assert state
  --   -- LP Token balances
  --   assert.are.same(msgBuy.Tags.InvestmentAmount, CPMM.token.balances[msgBuy.From])
  --   -- Conditional Token Balances
  --   local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
  --   local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * CPMM.lpFee / 10000)
  --   local quantityMinusFees = tonumber(msgBuy.Tags.Quantity) - tonumber(feeAmount)
  --   assert.are.same({
  --     ["1"] = {
  --       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
  --       [msgBuy.From] = buyAmount,
  --     },
  --     ["2"] = {
  --       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees),
  --     },
  --   }, CPMM.tokens.balancesById)
  --   -- Pool Balances
  --   local poolBalances = {
  --     tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
  --     tostring(fundingAmount + quantityMinusFees)
  --   }
  --   assert.are.same(poolBalances, CPMM:getPoolBalances())
  --   -- assert notice
  --   assert.are.same("Buy-Notice", getTagValue(notice.Tags, "Action"))
  --   assert.are.same(msgBuy.From, notice.Target)
  --   assert.are.same(msgBuy.Tags.InvestmentAmount, getTagValue(notice.Tags, "InvestmentAmount"))
  --   assert.are.same(tostring(feeAmount), getTagValue(notice.Tags, "FeeAmount"))
  --   assert.are.same(msgBuy.Tags.PositionId, getTagValue(notice.Tags, "PositionId"))
  --   assert.are.same(buyAmount, getTagValue(notice.Tags, "OutcomeTokensToBuy"))
  --   assert.are.same("Successful buy order", notice.Data)
	-- end)

  -- it("should not buy when minimumOutcomeTokens not reached", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   local buyAmount = CPMM:calcBuyAmount(
  --     tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --     msgCalcBuyAmount.Tags.PositionId
  --   )
  --   -- buy
  --   local notice = {}
  --   msgBuy.Tags.Quantity = "1000" -- minimumOutcomeTokens is 10000
  --   assert.has.error(function()
  --     notice = CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end, "Minimum outcome tokens not reached!")
  -- end)

  -- it("should sell", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- calc buy amount
  --   local buyAmount = CPMM:calcBuyAmount(
  --     tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
  --     msgCalcBuyAmount.Tags.PositionId
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- assert state before
  --   local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
  --   local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * CPMM.lpFee / 10000)
  --   local quantityMinusFees = tonumber(msgBuy.Tags.Quantity) - tonumber(feeAmount)
  --   local balancesBefore = {
  --     ["1"] = {
  --       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
  --       [msgBuy.From] = buyAmount,
  --     },
  --     ["2"] = {
  --       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees),
  --     },
  --   }
  --   assert.are.same(balancesBefore, CPMM.tokens.balancesById)
  --   -- calc sell amount
  --   local sellAmount = CPMM:calcSellAmount(
  --     tonumber(msgSell.Tags.ReturnAmount),
  --     msgSell.Tags.PositionId
  --   )
  --   -- sell
  --   local notice = {}
  --   assert.has.no.errors(function()
  --     notice = CPMM:sell(
  --     msgSell.From,
  --     msgSell.Tags.ReturnAmount,
  --     msgSell.Tags.PositionId,
  --     msgSell.Tags.Quantity,
  --     msgSell.Tags.MaxOutcomeTokensToSell,
  --     msgSell
  --     )
  --   end)
  --   -- assert state
  --   -- LP Token balances
  --   assert.are.same(msgBuy.Tags.InvestmentAmount, CPMM.token.balances[msgBuy.From])
  --   -- Conditional Token Balances
  --   local returnAmount_ = tonumber(msgSell.Tags.ReturnAmount)
  --   local feeAmount_ = math.ceil(returnAmount * CPMM.lpFee / 10000)
  --   local returnAmountPlusFees = returnAmount_ + feeAmount_
  --   local unburned = tonumber(msgSell.Tags.Quantity) - returnAmountPlusFees
  --   assert.are.same({
  --     ["1"] = {
  --       [_G.ao.id] = tostring(tonumber(balancesBefore["1"][_G.ao.id]) + tonumber(sellAmount) - returnAmountPlusFees - unburned),
  --       [msgSell.From] =  tostring(tonumber(balancesBefore["1"][msgSell.From]) - tonumber(sellAmount) + unburned),
  --     },
  --     ["2"] = {
  --       [_G.ao.id] = tostring(balancesBefore["2"][_G.ao.id] - returnAmountPlusFees),
  --     },
  --   }, CPMM.tokens.balancesById)
  --   -- Pool Balances
  --   local poolBalances = {
  --     tostring(tonumber(balancesBefore["1"][_G.ao.id]) + tonumber(sellAmount) - returnAmountPlusFees - unburned),
  --     tostring(balancesBefore["2"][_G.ao.id] - returnAmountPlusFees)
  --   }
  --   assert.are.same(poolBalances, CPMM:getPoolBalances())
  --   -- assert notice
  --   assert.are.same("Sell-Notice", getTagValue(notice.Tags, "Action"))
  --   assert.are.same(msgSell.From, notice.Target)
  --   assert.are.same(msgSell.Tags.ReturnAmount, getTagValue(notice.Tags, "ReturnAmount"))
  --   assert.are.same(tostring(feeAmount), getTagValue(notice.Tags, "FeeAmount"))
  --   assert.are.same(msgBuy.Tags.PositionId, getTagValue(notice.Tags, "PositionId"))
  --   assert.are.same(sellAmount, getTagValue(notice.Tags, "OutcomeTokensToSell"))
  --   assert.are.same("Successful sell order", notice.Data)
  -- end)

  -- it("should fail to sell when max sell amount is exceeded", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- sell
  --   msgSell.Tags.MaxOutcomeTokensToSell = "100"
  --   assert.has.error(function()
  --     CPMM:sell(
  --     msgSell.From,
  --     msgSell.Tags.ReturnAmount,
  --     msgSell.Tags.PositionId,
  --     msgSell.Tags.Quantity,
  --     msgSell.Tags.MaxOutcomeTokensToSell,
  --     msgSell
  --     )
  --   end, "Maximum sell amount exceeded!")
  -- end)

  -- it("should fail to sell when insufficient liquidity", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- stub
  --   stub(CPMM, "calcSellAmount", function()
  --     return "100"
  --   end)
  --   -- sell
  --   msgSell.Tags.ReturnAmount = "1000"
  --   msgSell.Tags.MaxOutcomeTokensToSell = "100"
  --   assert.has.error(function()
  --     CPMM:sell(
  --     msgSell.From,
  --     msgSell.Tags.ReturnAmount,
  --     msgSell.Tags.PositionId,
  --     msgSell.Tags.Quantity,
  --     msgSell.Tags.MaxOutcomeTokensToSell,
  --     msgSell
  --     )
  --   end, "Insufficient liquidity!")
  -- end)

  -- it("should fail to sell when insufficient balance", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- transfer to another account
  --   CPMM.tokens:transferSingle(
  --     msgSell.From,
  --     "test-this-is-valid-arweave-wallet-address-10",
  --     msgSell.Tags.PositionId,
  --     msgSell.Tags.Quantity,
  --     true,
  --     {}
  --   )
  --   -- sell
  --   assert.has.error(function()
  --     CPMM:sell(
  --     msgSell.From,
  --     msgSell.Tags.ReturnAmount,
  --     msgSell.Tags.PositionId,
  --     msgSell.Tags.Quantity,
  --     msgSell.Tags.MaxOutcomeTokensToSell,
  --     msgSell
  --     )
  --   end, "Insufficient balance!")
  -- end)

  -- it("should return collectedFees", function()
  --   local collectedFees = nil
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     collectedFees = CPMM:collectedFees()
  --   end)
  --   -- assert collected fees
  --   assert.are.equal("0", collectedFees)
	-- end)

  -- it("should return collectedFees after fee accrual", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- collected fees
  --   local collectedFees = nil
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     collectedFees = CPMM:collectedFees()
  --   end)
  --   -- assert collected fees
  --   assert.are.equal("1", collectedFees)
	-- end)

  -- it("should return feesWithdrawableBy sender", function()
  --   -- fees withdrawable
  --   local feesWithdrawable = nil
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     feesWithdrawable = CPMM:feesWithdrawableBy(sender)
  --   end)
  --   -- assert fees withdrawable
  --   assert.are.equal("0", feesWithdrawable)
	-- end)

  -- it("should return feesWithdrawableBy sender after fee accrual", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- fees withdrawable
  --   local feesWithdrawable = nil
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     feesWithdrawable = CPMM:feesWithdrawableBy(sender)
  --   end)
  --   -- assert fees withdrawable
  --   assert.are.equal("1", feesWithdrawable)
	-- end)

  -- it("should withdraw fees from sender", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- fees withdrawable
  --   local feesWithdrawable = CPMM:feesWithdrawableBy(sender)
  --   -- withdraw fees
  --   local withdrawnFees = nil
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     withdrawnFees = CPMM:withdrawFees(sender, msgBuy) -- msgBuy used to send a message with forward
  --   end)
  --   -- assert withdrawn fees
  --   assert.are.equal("1", feesWithdrawable)
  --   assert.are.equal(feesWithdrawable, withdrawnFees)
  --   -- assert state change
  --   assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
	-- end)

  -- it("should withdraw fees during _beforeTokenTransfer", function()
  --   -- add funding
  --   CPMM:addFunding(
  --     msgAddFunding.Tags.Sender,
  --     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
  --     msgAddFunding.Tags.Quantity,
  --     json.decode(msgAddFunding.Tags["X-Distribution"]),
  --     msgAddFunding
  --   )
  --   -- buy
  --   assert.has.no.errors(function()
  --     CPMM:buy(
  --     msgBuy.From,
  --     msgBuy.From, -- onBehalfOf is the same as sender
  --     msgBuy.Tags.InvestmentAmount,
  --     msgBuy.Tags.PositionId,
  --     msgBuy.Tags.Quantity,
  --     msgBuy
  --     )
  --   end)
  --   -- fees withdrawable
  --   local feesWithdrawable = CPMM:feesWithdrawableBy(sender)
  --   -- _beforeTokenTransfer
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     CPMM:_beforeTokenTransfer(sender, marketFactory, feesWithdrawable, msgBuy) -- msgBuy used to send a message with forward
  --   end)
  --   -- assert state change
  --   assert.are.equal("0", CPMM:feesWithdrawableBy(sender))
	-- end)

  -- it("should mint tokens", function()
  --   local notice = {}
  --   -- should not throw an error
  --   assert.has_no.errors(function()
  --     notice = CPMM:mint(
  --       msgMint.Tags.Recipient,
  --       msgMint.Tags.Quantity,
  --       msgMint
  --     )
  --   end)
  --   -- assert updated balance
  --   assert.are.same(msgMint.Tags.Quantity, CPMM.token.balances[recipient])
  --   -- assert update total supply
  --   assert.are.same(msgMint.Tags.Quantity, CPMM.token.totalSupply)
  --   -- assert notice
  --   assert.are.same({
  --     Recipient = recipient,
  --     Quantity = msgMint.Tags.Quantity,
  --     Action = 'Mint-Notice',
  --     Data = "Successfully minted " .. msgMint.Tags.Quantity
  --   }, notice)
	-- end)

  -- it("should burn tokens", function()
  --   local notice = {}
  --   -- mint tokens
  --   CPMM.token:mint(
  --       msgMint.From,
  --       msgMint.Tags.Quantity,
  --       msgMint
  --     )
  --   -- should not throw an error
  --   assert.has_no.errors(function()
  --     notice = CPMM.token:burn(
  --       msgBurn.From,
  --       msgBurn.Tags.Quantity,
  --       msgBurn
  --     )
  --   end)
  --   -- calculate expected updated balance
  --   local updateBalance = tostring(tonumber(quantity) - tonumber(burnQuantity))
  --   -- assert updated balance
  --   assert.are.same(CPMM.token.balances[sender], updateBalance)
  --   -- assert update total supply
  --   assert.are.same(CPMM.token.totalSupply, updateBalance)
  --   -- assert notice
  --   assert.are.same({
  --     Quantity = msgBurn.Tags.Quantity,
  --     Action = 'Burn-Notice',
  --     Data = "Successfully burned " .. msgBurn.Tags.Quantity
  --   }, notice)
	-- end)

  -- it("should transfer tokens", function()
  --   local notices = {}
  --   -- mint tokens
  --   CPMM.token:mint(
  --     msgMint.From,
  --     msgMint.Tags.Quantity,
  --     msgMint
  --   )
  --   -- should not throw an error
  --   assert.has_no.errors(function()
  --     notices = CPMM.token:transfer(
  --       msgTransfer.From,
  --       msgTransfer.Tags.Recipient,
  --       msgTransfer.Tags.Quantity,
  --       false, -- cast
  --       msgTransfer
  --     )
  --   end)
  --   -- assert updated balance
  --   assert.are.same(msgMint.Tags.Quantity, CPMM.token.balances[recipient])
  --   -- assert update total supply
  --   assert.are.same(msgMint.Tags.Quantity, CPMM.token.totalSupply)
  --   -- assert notices
  --   assert.are.same(noticeDebit, notices[1])
  --   assert.are.same(noticeCredit.Target, notices[2].Target)
  --   assert.are.same(noticeCredit.Action, getTagValue(notices[2].Tags, "Action"))
  --   assert.are.same(noticeCredit.Sender, getTagValue(notices[2].Tags, "Sender"))
  --   assert.are.same(noticeCredit.Quantity, getTagValue(notices[2].Tags, "Quantity"))
  --   assert.are.same(noticeCredit["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	-- end)

  -- it("should fail to transfer tokens with insufficient balance", function()
  --   local notice = {}
  --   -- should not throw an error
  --   assert.has_no.error(function()
  --     notice = CPMM.token:transfer(
  --       msgTransferError.From,
  --       msgTransferError.Tags.Recipient,
  --       msgTransferError.Tags.Quantity,
  --       false, -- cast
  --       msgTransferError
  --     )
  --   end)
  --   -- assert no updated balance
  --   assert.are.same('0', CPMM.token.balances[recipient])
  --   -- assert no updated total supply
  --   assert.are.same('0', CPMM.token.totalSupply)
  --   -- assert error notice
  --   assert.are.same({
  --     Action = 'Transfer-Error',
  --     ['Message-Id'] = msgTransferError.Id,
  --     Error = 'Insufficient Balance!'
  --   }, notice)
	-- end)

  -- it("should update configurator", function()
  --   local notice = {}
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     notice = CPMM:updateConfigurator(
  --     msgUpdateConfigurator.Tags.Configurator,
  --     msgUpdateConfigurator
  --   )
  --   end)
  --   -- assert state
  --   assert.are.equal(msgUpdateConfigurator.Tags.Configurator, CPMM.configurator)
  --   -- assert notice
  --   assert.are.equal("Configurator-Updated", notice.Action)
  --   assert.are.equal(msgUpdateConfigurator.Tags.Configurator, notice.Data)
	-- end)

  -- it("should update incentives", function()
  --   local notice = {}
  --   -- should not throw an error
	-- 	assert.has.no.error(function()
  --     notice = CPMM:updateIncentives(
  --     msgUpdateIncentives.Tags.Incentives,
  --     msgUpdateIncentives
  --   )
  --   end)
  --   -- assert state
  --   assert.are.equal(msgUpdateIncentives.Tags.Incentives, CPMM.incentives)
  --   -- assert notice
  --   assert.are.equal("Incentives-Updated", notice.Action)
  --   assert.are.equal(msgUpdateIncentives.Tags.Incentives, notice.Data)
	-- end)

  -- it("should update take fee" , function()
  --   local notice = {}
  --   -- should not throw an error
  --   assert.has.no.error(function()
  --     notice = CPMM:updateTakeFee(
  --     msgUpdateTakeFee.Tags.CreatorFee,
  --     msgUpdateTakeFee.Tags.ProtocolFee,
  --     msgUpdateTakeFee
  --   )
  --   end)
  --   -- assert state
  --   assert.are.equal(msgUpdateTakeFee.Tags.CreatorFee, CPMM.tokens.creatorFee)
  --   assert.are.equal(msgUpdateTakeFee.Tags.ProtocolFee, CPMM.tokens.protocolFee)
  --   -- assert notice
  --   local takeFee = tostring(tonumber(msgUpdateTakeFee.Tags.CreatorFee) + tonumber(msgUpdateTakeFee.Tags.ProtocolFee))
  --   assert.are.equal("Take-Fee-Updated", notice.Action)
  --   assert.are.equal(tostring(msgUpdateTakeFee.Tags.CreatorFee), notice.CreatorFee)
  --   assert.are.equal(tostring(msgUpdateTakeFee.Tags.ProtocolFee), notice.ProtocolFee)
  --   assert.are.equal(takeFee, notice.Data)
  -- end)

  -- it("should update protocol fee target" , function()
  --   local notice = {}
  --   -- should not throw an error
  --   assert.has.no.error(function()
  --     notice = CPMM:updateProtocolFeeTarget(
  --     msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget,
  --     msgUpdateProtocolFeeTarget
  --   )
  --   end)
  --   -- assert state
  --   assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, CPMM.tokens.protocolFeeTarget)
  --   -- assert notice
  --   assert.are.equal("Protocol-Fee-Target-Updated", notice.Action)
  --   assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, notice.Data)
  -- end)

  -- it("should update logo" , function()
  --   local notice = {}
  --   -- should not throw an error
  --   assert.has.no.error(function()
  --     notice = CPMM:updateLogo(
  --     msgUpdateLogo.Tags.Logo,
  --     msgUpdateLogo
  --   )
  --   end)
  --   -- assert state
  --   assert.are.equal(msgUpdateLogo.Tags.Logo, CPMM.tokens.logo)
  --   assert.are.equal(msgUpdateLogo.Tags.Logo, CPMM.token.logo)
  --   -- assert notice
  --   assert.are.equal("Logo-Updated", notice.Action)
  --   assert.are.equal(msgUpdateLogo.Tags.Logo, notice.Data)
  -- end)
end)