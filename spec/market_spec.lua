require("luacov")
local market = require("modules.market")
local cpmm = require("modules.cpmm")
local token = require("modules.token")
local tokens = require("modules.conditionalTokens")
local json = require("json")
local crypto = require(".crypto")

local marketFactory = ""
local minter = ""
local sender = ""
local recipient = ""
local collateralToken = ""
local creator = ""
local question = ""
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
local tokenId = ""
local returnAmount = ""
local investmentAmount = ""
local maxOutcomeTokensToSell = ""
local resolutionAgent = ""
local tokenIds = {}
local quantities = {}
local remainingBalances = {}
local payouts = {}
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
local msgMintSingle = {}
local msgMintBatch = {}
local msgBalance = {}
local msgBalances = {}
local msgTransfer = {}
local msgTransferSingle = {}
local msgTransferBatch = {}
local msgTransferError = {}
local msgUpdateConfigurator = {}
local msgUpdateIncentives = {}
local msgUpdateTakeFee = {}
local msgUpdateProtocolFeeTarget = {}
local msgUpdateLogo = {}
local msgSplitPosition = {}
local msgMergePositions = {}
local msgReportPayouts = {}
local msgRedeemPositions = {}
local noticeDebit = {}
local noticeCredit = {}
local noticeDebitSingle = {}
local noticeCreditSingle = {}
local noticeDebitBatch = {}
local noticeCreditBatch = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#market", function()
  before_each(function()
    -- set variables
    marketFactory = "test-this-is-valid-arweave-wallet-address-0"
    minter = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    recipient = "test-this-is-valid-arweave-wallet-address-2"
    -- @dev mock init state for testing
    collateralToken = "test-this-is-valid-arweave-wallet-address-2"
    creator = "test-this-is-valid-arweave-wallet-address-3"
    question = "What is the meaning of life?"
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
    tokenId = "1"
    burnQuantity = "50"
    returnAmount = "90"
    investmentAmount = "100"
    maxOutcomeTokensToSell = "140"
    positionIds = {"1", "2"}
    distribution = {50, 50}
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-10"
    payouts = { 1, 0 }
    tokenIds = { "1", "2" }
    quantities = { "100", "200" }
    remainingBalances = { "0", "0" }
    -- Instantiate objects
    Market = market:new(
      configurator,
      incentives,
      collateralToken,
      resolutionAgent,
      creator,
      question,
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
        CollateralToken = collateralToken,
        ResolutionAgent = resolutionAgent,
        Creator = creator,
        Question = question,
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
		msgMintSingle = {
      From = minter,
      Tags = {
        Action = "Mint-Single",
        Recipient = sender,
        TokenId = tokenId,
        Quantity = quantity,
      },
      reply = function(message) return message end
    }
    -- create a message object
		msgMintBatch = {
      From = minter,
      Tags = {
        Action = "Mint-Batch",
        Recipient = sender,
        TokenIds = json.encode(tokenIds),
        Quantities = json.encode(quantities),
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBalance = {
      From = sender,
      Tags = {
        Recipient = recipient,
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgBalances = {
      From = sender,
      Tags = {
        Recipient = recipient,
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
		msgTransferSingle = {
      From = sender,
      Tags = {
        Recipient = recipient,
        TokenId = tokenId,
        Quantity = quantity,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
    -- create a message object
    msgTransferBatch = {
      From = sender,
      Tags = {
        Recipient = recipient,
        TokenIds = json.encode(tokenIds),
        Quantities = json.encode(quantities),
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end
    }
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
      reply = function(message) return message end
    }
    -- create a message object
    msgReportPayouts = {
      From = resolutionAgent,
      Tags = {
        Payouts = json.encode(payouts),
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgRedeemPositions = {
      From = sender,
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateConfigurator = {
      From = configurator,
      Tags = {
        Configurator = newConfigurator
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateIncentives = {
      From = configurator,
      Tags = {
        Incentives = newIncentives
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateTakeFee = {
      From = configurator,
      Tags = {
        CreatorFee = tostring(newCreatorFee),
        ProtocolFee = tostring(newProtocolFee)
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateProtocolFeeTarget = {
      From = configurator,
      Tags = {
        ProtocolFeeTarget = newProtocolFeeTarget
      },
      reply = function(message) return message end
    }
    -- create a message object
    msgUpdateLogo = {
      From = configurator,
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
    -- create a notice object
    noticeCreditBatch = {
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      Data = "Successfully burned batch"
    }
     -- create a notice object
     noticeDebitSingle = {
      Action = "Debit-Single-Notice",
      Recipient = recipient,
      TokenId = tokenId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You transferred 100 of id 1 to " .. recipient
    }
    -- create a notice object
    noticeCreditSingle = {
      Target = recipient,
      Action = "Credit-Single-Notice",
      Sender = sender,
      TokenId = tokenId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You received 100 of id 1 from " .. sender
    }
    -- create a notice object
    noticeDebitBatch = {
      Action = "Debit-Batch-Notice",
      Recipient = recipient,
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You transferred batch to " .. recipient
    }
    -- create a notice object
    noticeCreditBatch = {
      Target = recipient,
      Action = "Credit-Batch-Notice",
      Sender = sender,
      TokenIds = json.encode(tokenIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You received batch from " .. sender
    }
	end)

  it("should have initial state", function()
    local token_ = token:new(
      name .. " LP Token",
      ticker,
      logo,
      {},
      totalSupply,
      denomination
    )
    local tokens_ = tokens:new(
      name .. " Conditional Tokens",
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
    -- assert initial state
    assert.is.same(incentives, Market.cpmm.incentives)
    assert.is.same(configurator, Market.cpmm.configurator)
    assert.is.same({}, Market.cpmm.poolBalances)
    assert.is.same({}, Market.cpmm.withdrawnFees)
    assert.is.same('0', Market.cpmm.feePoolWeight)
    assert.is.same('0', Market.cpmm.totalWithdrawnFees)
    assert.is.same(tokens_, Market.cpmm.tokens)
    assert.is.same(token_, Market.cpmm.token)
    assert.is.same(lpFee, Market.cpmm.lpFee)
	end)

  it("should addFunding", function()
    -- add funding
    local notice = Market.cpmm:addFunding(
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
    }, Market.cpmm.token.balances)
    -- Conditional Token Balances
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
      ["2"] = {
        [_G.ao.id] = msgAddFunding.Tags.Quantity,
      },
    }, Market.cpmm.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {msgAddFunding.Tags.Quantity, msgAddFunding.Tags.Quantity}
    assert.are.same(poolBalances, Market.cpmm:getPoolBalances())
    local fundingAdded = json.encode({tonumber(msgAddFunding.Tags.Quantity), tonumber(msgAddFunding.Tags.Quantity)})
    -- assert notice
    assert.are.same(msgAddFunding.Tags.Sender, notice.Target)
    assert.are.same("Successfully added funding", notice.Data)
    assert.are.same("Funding-Added-Notice", getTagValue(notice.Tags, "Action"))
    assert.are.same(msgAddFunding.Tags.Quantity,  getTagValue(notice.Tags, "MintAmount"))
    assert.are.same(fundingAdded, getTagValue(notice.Tags, "FundingAdded"))
	end)

  it("should fail to addFunding and return funds if invalid", function()
    -- TODO
  end)

  it("should removeFunding", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- override receive to return collateralToken balance
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.Handlers.receive = function() return
      { Data = tonumber(msgAddFunding.Tags.Quantity) }
    end
    -- remove funding
    local notice = Market.cpmm:removeFunding(
      msgRemoveFunding.From,
      msgRemoveFunding.Tags.Quantity,
      msgRemoveFunding
    )
    -- assert state
    -- LP Token balances
    assert.are.same("0", Market.cpmm.token.balances[msgRemoveFunding.From])
    -- Conditional Token Balances
    -- Pool Balances
    assert.are.same({"0", "0"}, Market.cpmm:getPoolBalances())
    -- assert notice
    assert.are.same(msgRemoveFunding.From, notice.Target)
    assert.are.same("Successfully removed funding", notice.Data)
    assert.are.same("Funding-Removed-Notice", getTagValue(notice.Tags, "Action"))
    local sendAmounts = json.encode({msgRemoveFunding.Tags.Quantity, msgRemoveFunding.Tags.Quantity})
    assert.are.same(sendAmounts,  getTagValue(notice.Tags, "SendAmounts"))
    assert.are.same(msgRemoveFunding.Tags.Quantity,  getTagValue(notice.Tags, "SharesToBurn"))
    local collateralRemovedFromFeePool = "0" -- no fees yet collected
    assert.are.same(collateralRemovedFromFeePool, getTagValue(notice.Tags, "CollateralRemovedFromFeePool"))
	end)

  it("should fail to removeFunding and return LP Tokens if invalid", function()
    -- TODO
  end)

  it("should calc buy amount", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = ''
    assert.has.no.errors(function()
      buyAmount = Market.cpmm:calcBuyAmount(
        tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
        msgCalcBuyAmount.Tags.PositionId
      )
    end)
    -- assert buy amount
    assert.is_true(tonumber(buyAmount) > 0)
	end)

  it("should calc sell amount", function()
    -- add funding 
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- calc sell amount
    local sellAmount = ''
    assert.has.no.errors(function()
      sellAmount = Market.cpmm:calcSellAmount(
        tonumber(msgCalcSellAmount.Tags.ReturnAmount),
        msgCalcSellAmount.Tags.PositionId
      )
    end)
    -- assert sell amount
    assert.is_true(tonumber(sellAmount) > 0)
	end)

  it("should buy", function()
   -- add funding
   Market.cpmm:addFunding(
     msgAddFunding.Tags.Sender,
     msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
     msgAddFunding.Tags.Quantity,
     json.decode(msgAddFunding.Tags["X-Distribution"]),
     msgAddFunding
   )
   -- calc buy amount
   local buyAmount = Market.cpmm:calcBuyAmount(
     tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
     msgCalcBuyAmount.Tags.PositionId
   )
   -- buy
   local notice = {}
   assert.has.no.errors(function()
     notice = Market.cpmm:buy(
     msgBuy.From,
     msgBuy.From, -- onBehalfOf is the same as sender
     msgBuy.Tags.InvestmentAmount,
     msgBuy.Tags.PositionId,
     msgBuy.Tags.Quantity,
     msgBuy
     )
   end)
   -- assert state
   -- LP Token balances
   assert.are.same(msgBuy.Tags.InvestmentAmount, Market.cpmm.token.balances[msgBuy.From])
   -- Conditional Token Balances
   local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
   local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * Market.cpmm.lpFee / 10000)
   local quantityMinusFees = tonumber(msgBuy.Tags.Quantity) - tonumber(feeAmount)
   assert.are.same({
     ["1"] = {
       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
       [msgBuy.From] = buyAmount,
     },
     ["2"] = {
       [_G.ao.id] = tostring(fundingAmount + quantityMinusFees),
     },
   }, Market.cpmm.tokens.balancesById)
   -- Pool Balances
   local poolBalances = {
     tostring(fundingAmount + quantityMinusFees - tonumber(buyAmount)),
     tostring(fundingAmount + quantityMinusFees)
   }
   assert.are.same(poolBalances, Market.cpmm:getPoolBalances())
   -- assert notice
   assert.are.same("Buy-Notice", getTagValue(notice.Tags, "Action"))
   assert.are.same(msgBuy.From, notice.Target)
   assert.are.same(msgBuy.Tags.InvestmentAmount, getTagValue(notice.Tags, "InvestmentAmount"))
   assert.are.same(tostring(feeAmount), getTagValue(notice.Tags, "FeeAmount"))
   assert.are.same(msgBuy.Tags.PositionId, getTagValue(notice.Tags, "PositionId"))
   assert.are.same(buyAmount, getTagValue(notice.Tags, "OutcomeTokensToBuy"))
   assert.are.same("Successful buy order", notice.Data)
 end)

 it("should fail to buy and return Collateral Tokens if invalid", function()
  -- TODO
  end)

  it("should sell", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- calc buy amount
    local buyAmount = Market.cpmm:calcBuyAmount(
      tonumber(msgCalcBuyAmount.Tags.InvestmentAmount),
      msgCalcBuyAmount.Tags.PositionId
    )
    -- buy
    assert.has.no.errors(function()
      Market.cpmm:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
      )
    end)
    -- assert state before
    local fundingAmount = tonumber(msgAddFunding.Tags.Quantity)
    local feeAmount = math.ceil(tonumber(msgBuy.Tags.InvestmentAmount) * Market.cpmm.lpFee / 10000)
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
    assert.are.same(balancesBefore, Market.cpmm.tokens.balancesById)
    -- calc sell amount
    local sellAmount = Market.cpmm:calcSellAmount(
      tonumber(msgSell.Tags.ReturnAmount),
      msgSell.Tags.PositionId
    )
    -- sell
    local notice = {}
    assert.has.no.errors(function()
      notice = Market.cpmm:sell(
      msgSell.From,
      msgSell.Tags.ReturnAmount,
      msgSell.Tags.PositionId,
      msgSell.Tags.Quantity,
      msgSell.Tags.MaxOutcomeTokensToSell,
      msgSell
      )
    end)
    -- assert state
    -- LP Token balances
    assert.are.same(msgBuy.Tags.InvestmentAmount, Market.cpmm.token.balances[msgBuy.From])
    -- Conditional Token Balances
    local returnAmount_ = tonumber(msgSell.Tags.ReturnAmount)
    local feeAmount_ = math.ceil(returnAmount * Market.cpmm.lpFee / 10000)
    local returnAmountPlusFees = returnAmount_ + feeAmount_
    local unburned = tonumber(msgSell.Tags.Quantity) - returnAmountPlusFees
    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(tonumber(balancesBefore["1"][_G.ao.id]) + tonumber(sellAmount) - returnAmountPlusFees - unburned),
        [msgSell.From] =  tostring(tonumber(balancesBefore["1"][msgSell.From]) - tonumber(sellAmount) + unburned),
      },
      ["2"] = {
        [_G.ao.id] = tostring(balancesBefore["2"][_G.ao.id] - returnAmountPlusFees),
      },
    }, Market.cpmm.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {
      tostring(tonumber(balancesBefore["1"][_G.ao.id]) + tonumber(sellAmount) - returnAmountPlusFees - unburned),
      tostring(balancesBefore["2"][_G.ao.id] - returnAmountPlusFees)
    }
    assert.are.same(poolBalances, Market.cpmm:getPoolBalances())
    -- assert notice
    assert.are.same("Sell-Notice", getTagValue(notice.Tags, "Action"))
    assert.are.same(msgSell.From, notice.Target)
    assert.are.same(msgSell.Tags.ReturnAmount, getTagValue(notice.Tags, "ReturnAmount"))
    assert.are.same(tostring(feeAmount), getTagValue(notice.Tags, "FeeAmount"))
    assert.are.same(msgBuy.Tags.PositionId, getTagValue(notice.Tags, "PositionId"))
    assert.are.same(sellAmount, getTagValue(notice.Tags, "OutcomeTokensToSell"))
    assert.are.same("Successful sell order", notice.Data)
  end)

  it("should return collectedFees", function()
    local collectedFees = nil
    -- should not throw an error
		assert.has.no.error(function()
      collectedFees = Market.cpmm:collectedFees()
    end)
    -- assert collected fees
    assert.are.equal("0", collectedFees)
	end)

  it("should return collectedFees after fee accrual", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      Market.cpmm:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
      )
    end)
    -- collected fees
    local collectedFees = nil
    -- should not throw an error
		assert.has.no.error(function()
      collectedFees = Market.cpmm:collectedFees()
    end)
    -- assert collected fees
    assert.are.equal("1", collectedFees)
	end)

  it("should return feesWithdrawableBy sender", function()
    local feesWithdrawable = nil
    -- should not throw an error
		assert.has.no.error(function()
      feesWithdrawable = Market.cpmm:feesWithdrawableBy(sender)
    end)
    -- assert fees withdrawable
    assert.are.equal("0", feesWithdrawable)
	end)

  it("should return feesWithdrawableBy sender after fee accrual", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      Market.cpmm:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
      )
    end)
    -- fees withdrawable
    local feesWithdrawable = nil
    -- should not throw an error
		assert.has.no.error(function()
      feesWithdrawable = Market.cpmm:feesWithdrawableBy(sender)
    end)
    -- assert fees withdrawable
    assert.are.equal("1", feesWithdrawable)
	end)

  it("should withdraw fees from sender", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
      msgAddFunding.Tags.Sender, -- onBehalfOf is the same as sender
      msgAddFunding.Tags.Quantity,
      json.decode(msgAddFunding.Tags["X-Distribution"]),
      msgAddFunding
    )
    -- buy
    assert.has.no.errors(function()
      Market.cpmm:buy(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf is the same as sender
      msgBuy.Tags.InvestmentAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
      )
    end)
    -- fees withdrawable
    local feesWithdrawable = Market.cpmm:feesWithdrawableBy(sender)
    -- withdraw fees
    local withdrawnFees = nil
    -- should not throw an error
		assert.has.no.error(function()
      withdrawnFees = Market.cpmm:withdrawFees(sender, msgBuy) -- msgBuy used to send a message with forward
    end)
    -- assert withdrawn fees
    assert.are.equal("1", feesWithdrawable)
    assert.are.equal(feesWithdrawable, withdrawnFees)
    -- assert state change
    assert.are.equal("0", Market.cpmm:feesWithdrawableBy(sender))
	end)

  it("should transfer tokens", function()
    local notices = {}

    -- mint tokens
    Market.cpmm.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- should not throw an error
    assert.has_no.errors(function()
      notices = Market.cpmm.token:transfer(
        msgTransfer.From,
        msgTransfer.Tags.Recipient,
        msgTransfer.Tags.Quantity,
        false, -- cast
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.totalSupply)
    -- assert notices
    assert.are.same(noticeDebit, notices[1])
    assert.are.same(noticeCredit.Target, notices[2].Target)
    assert.are.same(noticeCredit.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCredit.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCredit.Quantity, getTagValue(notices[2].Tags, "Quantity"))
    assert.are.same(noticeCredit["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should fail to transfer tokens with insufficient balance", function()
    local notice = {}

    -- should not throw an error
    assert.has_no.error(function()
      notice = Market.cpmm.token:transfer(
        msgTransferError.From,
        msgTransferError.Tags.Recipient,
        msgTransferError.Tags.Quantity,
        false, -- cast
        msgTransferError
      )
    end)
    -- assert no updated balance
    assert.are.same('0', Market.cpmm.token.balances[recipient])
    -- assert no updated total supply
    assert.are.same('0', Market.cpmm.token.totalSupply)
    -- assert error notice
    assert.are.same({
      Action = 'Transfer-Error',
      ['Message-Id'] = msgTransferError.Id,
      Error = 'Insufficient Balance!'
    }, notice)
	end)

  it("should get LP Token balance (sender)", function()

    -- mint tokens
    Market.cpmm.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- assert state
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.balances[sender])
    -- get reply
    msgBalance.Tags.Recipient = nil
    local reply = Market:balance(msgBalance)
    -- assert reply
    assert.are.same(msgMint.Tags.Quantity, reply.Data)
    assert.are.same(msgMint.Tags.Quantity, reply.Balance)
    assert.are.same(sender, reply.Account)
  end)

  it("should get LP Token balance (recipient)", function()

    -- mint tokens
    Market.cpmm.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- assert state
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.balances[sender])
    -- get reply
    local reply = Market:balance(msgBalance)
    -- assert reply
    assert.are.same("0", reply.Data)
    assert.are.same("0", reply.Balance)
    assert.are.same(recipient, reply.Account)
  end)

  it("should get LP Token balances", function()

    -- mint tokens
    Market.cpmm.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- assert state
    local expectedBalances = {
      [sender] = msgMint.Tags.Quantity
    }
    assert.are.same(expectedBalances, Market.cpmm.token.balances)
    -- get reply
    local reply = Market:balances(msgBalances)
    -- assert reply
    assert.are.same(json.encode(expectedBalances), reply.Data)
  end)

  it("should get LP Token total supply", function()

    -- mint tokens
    Market.cpmm.token:mint(
      msgMint.From,
      msgMint.Tags.Quantity,
      msgMint
    )
    -- assert state
    local expectedTotalSupply = msgMint.Tags.Quantity
    assert.are.same(expectedTotalSupply, Market.cpmm.token.totalSupply)
    -- get reply
    local reply = Market:totalSupply(msgBalances) -- msgBalances used to send a message with reply
    -- assert reply
    assert.are.same(json.encode(expectedTotalSupply), reply.Data)
  end)

  it("should merge positions (isSell == true)", function()

    -- split position
    Market.cpmm.tokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- merge positions
    local notice = Market:mergePositions(
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
    }, Market.cpmm.tokens.balancesById)
    -- assert notice
    assert.are.equals("Merge-Positions-Notice", notice.Action)
    assert.are.equals(msgSplitPosition.Tags.Quantity, notice.Quantity)
    assert.are.equals(msgSplitPosition.Tags.ConditionId, notice.ConditionId)
	end)

  it("should merge positions (isSell == false)", function()

    -- split position
    Market.cpmm.tokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- merge positions
    local notice = Market:mergePositions(
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
    }, Market.cpmm.tokens.balancesById)
    -- assert notice
    assert.are.equals("Merge-Positions-Notice", notice.Action)
    assert.are.equals(msgSplitPosition.Tags.Quantity, notice.Quantity)
    assert.are.equals(msgSplitPosition.Tags.ConditionId, notice.ConditionId)
	end)

  it("should report payouts", function()

    -- split position
    Market.cpmm.tokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    local notice = Market:reportPayouts(
      msgReportPayouts
    )
    -- asert state change
    assert.are.same(payouts, Market.cpmm.tokens.payoutNumerators)
    assert.are.same(1, Market.cpmm.tokens.payoutDenominator)
    -- assert notice
    assert.are.equals("Condition-Resolution-Notice", notice.Action)
    assert.are.equals(msgReportPayouts.Tags.Payouts, notice.PayoutNumerators)
    assert.are.equals(msgReportPayouts.From, notice.ResolutionAgent)
	end)

  it("should redeem positions", function()

    -- split position
    Market.cpmm.tokens:splitPosition(
      msgSplitPosition.From,
      msgSplitPosition.Tags.CollateralToken,
      msgSplitPosition.Tags.Quantity,
      msgSplitPosition
    )
    -- report payouts
    Market:reportPayouts(
      msgReportPayouts
    )
    -- redeem positions
    local notice = Market:redeemPositions(
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
    }, Market.cpmm.tokens.balancesById)
    -- assert notice
    assert.are.equals("Payout-Redemption-Notice", notice.Action)
    assert.are.equals(conditionId, notice.ConditionId)
    assert.are.equals(quantity, notice.Payout)
    assert.are.equals(_G.ao.id, notice.Process)
	end)

  it("should get payout numerators", function()

    -- assert state
    assert.are.same({0,0}, Market.cpmm.tokens.payoutNumerators)
    -- get reply
    local reply = Market:getPayoutNumerators(
      msgInit -- msgBalance used to send a message with reply
    )
    -- assert reply
    assert.are.same(json.encode({0,0}), reply.Data)
    assert.are.same(msgInit.Tags.ConditionId, reply.ConditionId)
    assert.are.same("Payout-Numerators", reply.Action)
  end)

  it("should get payout denominator", function()
    -- assert state
    assert.are.same(0, Market.cpmm.tokens.payoutDenominator)
    -- get reply
    local reply = Market:getPayoutDenominator(
      msgInit -- msgBalance used to send a message with reply
    )
    -- assert reply
    assert.are.same(0, reply.Data)
    assert.are.same(msgInit.Tags.ConditionId, reply.ConditionId)
    assert.are.same("Payout-Denominator", reply.Action)
  end)

  it("should transfer conditional tokens", function()
    local notices = {}

    -- mint tokens
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.Tags.Recipient,
        msgMintSingle.Tags.TokenId,
        msgMintSingle.Tags.Quantity,
        msgMintSingle
      )
    end)
    -- should not throw an error
    assert.has_no.errors(function()
      notices = Market:transferSingle(
        msgTransferSingle
      )
    end)
    -- assert updated balance
    assert.are.same(msgTransfer.Tags.Quantity, Market.cpmm.tokens.balancesById[tokenId][recipient])
    -- assert update total supply
    assert.are.same(msgTransfer.Tags.Quantity, Market.cpmm.tokens.totalSupplyById[tokenId])
    -- assert notices
    assert.are.same(noticeDebitSingle, notices[1])
    assert.are.same(noticeCreditSingle.Target, notices[2].Target)
    assert.are.same(noticeCreditSingle.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCreditSingle.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCreditSingle.TokenId, getTagValue(notices[2].Tags, "TokenId"))
    assert.are.same(noticeCreditSingle.Quantity, getTagValue(notices[2].Tags, "Quantity"))
    assert.are.same(noticeCreditSingle["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should batch transfer conditional tokens", function()
    local notices = {}

    -- mint tokens
    -- should not throw an error
    assert.has_no.errors(function()
      Market.cpmm.tokens:batchMint(
        msgMintBatch.Tags.Recipient,
        json.decode(msgMintBatch.Tags.TokenIds),
        json.decode(msgMintBatch.Tags.Quantities),
        msgMintBatch
      )
    end)
    -- should not throw an error
    assert.has_no.errors(function()
      notices = Market:transferBatch(
        msgTransferBatch
      )
    end)
    -- assert updated balance
    assert.are.same(json.decode(msgTransferBatch.Tags.Quantities)[1], Market.cpmm.tokens.balancesById[tokenIds[1]][recipient])
    assert.are.same(json.decode(msgTransferBatch.Tags.Quantities)[2], Market.cpmm.tokens.balancesById[tokenIds[2]][recipient])
    -- assert update total supply
    assert.are.same(json.decode(msgTransferBatch.Tags.Quantities)[1], Market.cpmm.tokens.totalSupplyById[tokenIds[1]])
    assert.are.same(json.decode(msgTransferBatch.Tags.Quantities)[2], Market.cpmm.tokens.totalSupplyById[tokenIds[2]])
    -- assert notices
    assert.are.same(noticeDebitBatch, notices[1])
    assert.are.same(noticeCreditBatch.Target, notices[2].Target)
    assert.are.same(noticeCreditBatch.Action, getTagValue(notices[2].Tags, "Action"))
    assert.are.same(noticeCreditBatch.Sender, getTagValue(notices[2].Tags, "Sender"))
    assert.are.same(noticeCreditBatch.TokenIds, getTagValue(notices[2].Tags, "TokenIds"))
    assert.are.same(noticeCreditBatch.Quantities, getTagValue(notices[2].Tags, "Quantities"))
    assert.are.same(noticeCreditBatch["X-Action"], getTagValue(notices[2].Tags, "X-Action"))
	end)

  it("should get balance", function()
    local balance = ''

    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.Tags.Recipient,
        msgMintSingle.Tags.TokenId,
        msgMintSingle.Tags.Quantity,
        msgMintSingle
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balance = Market:balanceById(
        msgMintSingle
      )
    end)
    -- assert reply
    assert.are.same(msgMintSingle.Tags.Quantity, balance.Data)
    -- assert state
    assert.are.same(msgMintSingle.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.TokenId][msgMintSingle.Tags.Recipient])
	end)

  it("should get balance from sender (no recipient)", function()
    local balance = ''

    -- mint to msgMint.From
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.From,
        msgMintSingle.Tags.TokenId,
        msgMintSingle.Tags.Quantity,
        msgMintSingle
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balance = Market:balanceById(
        msgMintSingle
      )
    end)
    -- assert balance
    assert.are.same(msgMint.Tags.Quantity, balance.Data)
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.TokenId][msgMintSingle.From])
	end)

  it("should get batch balance", function()
    local balances = {}
    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:batchMint(
        msgMintBatch.Tags.Recipient,
        json.decode(msgMintBatch.Tags.TokenIds),
        json.decode(msgMintBatch.Tags.Quantities),
        msgMintBatch
      )
    end)
    -- get balance
    -- create recipients
    msgMintBatch.Tags.Recipients = json.encode({
      msgMintBatch.Tags.Recipient,
      msgMintBatch.Tags.Recipient
    })
    -- remove recipient
    msgMintBatch.Tags.Recipient = nil
    -- should not throw an error
		assert.has_no.errors(function()
      balances = Market:batchBalance(
        msgMintBatch
      )
    end)
    -- assert balances
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], balances.Data[1])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], balances.Data[2])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.TokenIds)[1]][sender])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.TokenIds)[2]][sender])
	end)

  it("should get balances", function()
    local balances = {}

    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.Tags.Recipient,
        msgMintSingle.Tags.TokenId,
        msgMintSingle.Tags.Quantity,
        msgMintSingle
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balances = Market:balancesById(
        msgMintSingle
      )
    end)
    -- assert balance
    assert.are.same(msgMint.Tags.Quantity, balances.Data[msgMintSingle.Tags.Recipient])
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.TokenId][msgMintSingle.Tags.Recipient])
	end)

  it("should get batch balances", function()
    local balances = {}

    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:batchMint(
        msgMintBatch.Tags.Recipient,
        json.decode(msgMintBatch.Tags.TokenIds),
        json.decode(msgMintBatch.Tags.Quantities),
        msgMintBatch
      )
    end)
    -- get balance
    -- should not throw an error
		assert.has_no.errors(function()
      balances = Market:batchBalances(
        msgMintBatch
      )
    end)
    -- assert balances
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], balances.Data[json.decode(msgMintBatch.Tags.TokenIds)[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], balances.Data[json.decode(msgMintBatch.Tags.TokenIds)[2]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.TokenIds)[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.TokenIds)[2]][msgMintBatch.Tags.Recipient])
	end)

  it("should update configurator", function()
    local notice = {}
    -- should not throw an error
		assert.has.no.error(function()
      notice = Market:updateConfigurator(
        msgUpdateConfigurator
      )
    end)
    -- assert state
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, Market.cpmm.configurator)
    -- assert notice
    assert.are.equal("Configurator-Updated", notice.Action)
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, notice.Data)
	end)

  it("should update incentives", function()
    local notice = {}
    -- should not throw an error
		assert.has.no.error(function()
      notice = Market:updateIncentives(
        msgUpdateIncentives
      )
    end)
    -- assert state
    assert.are.equal(msgUpdateIncentives.Tags.Incentives, Market.cpmm.incentives)
    -- assert notice
    assert.are.equal("Incentives-Updated", notice.Action)
    assert.are.equal(msgUpdateIncentives.Tags.Incentives, notice.Data)
	end)

  it("should update take fee" , function()
    local notice = {}

    -- should not throw an error
    assert.has.no.error(function()
      notice = Market:updateTakeFee(
        msgUpdateTakeFee
      )
    end)
    -- assert state
    assert.are.equal(tonumber(msgUpdateTakeFee.Tags.CreatorFee), Market.cpmm.tokens.creatorFee)
    assert.are.equal(tonumber(msgUpdateTakeFee.Tags.ProtocolFee), Market.cpmm.tokens.protocolFee)
    -- assert notice
    local takeFee = tostring(tonumber(msgUpdateTakeFee.Tags.CreatorFee) + tonumber(msgUpdateTakeFee.Tags.ProtocolFee))
    assert.are.equal("Take-Fee-Updated", notice.Action)
    assert.are.equal(tostring(msgUpdateTakeFee.Tags.CreatorFee), notice.CreatorFee)
    assert.are.equal(tostring(msgUpdateTakeFee.Tags.ProtocolFee), notice.ProtocolFee)
    assert.are.equal(takeFee, notice.Data)
  end)

  it("should update protocol fee target" , function()
    local notice = {}

    -- should not throw an error
    assert.has.no.error(function()
      notice = Market:updateProtocolFeeTarget(
      msgUpdateProtocolFeeTarget
    )
    end)
    -- assert state
    assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, Market.cpmm.tokens.protocolFeeTarget)
    -- assert notice
    assert.are.equal("Protocol-Fee-Target-Updated", notice.Action)
    assert.are.equal(msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget, notice.Data)
  end)

  it("should update logo" , function()
    local notice = {}

    -- should not throw an error
    assert.has.no.error(function()
      notice = Market:updateLogo(
        msgUpdateLogo
      )
    end)
    -- assert state
    assert.are.equal(msgUpdateLogo.Tags.Logo, Market.cpmm.tokens.logo)
    assert.are.equal(msgUpdateLogo.Tags.Logo, Market.cpmm.token.logo)
    -- assert notice
    assert.are.equal("Logo-Updated", notice.Action)
    assert.are.equal(msgUpdateLogo.Tags.Logo, notice.Data)
  end)
end)