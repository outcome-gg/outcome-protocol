require("luacov")
local market = require("marketModules.market")
local token = require("marketModules.token")
local tokens = require("marketModules.conditionalTokens")
local json = require("json")

local marketFactory = ""
local minter = ""
local sender = ""
local recipient = ""
local collateralToken = ""
local creator = ""
local question = ""
local rules = ""
local category = ""
local subcategory = ""
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
local dataIndex = ""
local newDataIndex = ""
local quantity = ""
local positionId = ""
local returnAmount = ""
local investmentAmount = ""
local maxPositionTokensToSell = ""
local resolutionAgent = ""
local positionIds = {}
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
local msgUpdateDataIndex = {}
local msgUpdateTakeFee = {}
local msgUpdateProtocolFeeTarget = {}
local msgUpdateLogo = {}
local msgUpdateLogos = {}
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
    rules = "This is a test market"
    category = "Test Category"
    subcategory = "Test Subcategory"
    name = "Test Market"
    ticker = "TST"
    logo = "https://test.com/logo.png"
    logos = {"https://test.com/1.png", "https://test.com/2.png"}
    newLogo = "https://test.com/new-logo.png"
    newLogos = {"https://test.com/new-1.png", "https://test.com/new-2.png"}
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
    dataIndex = "test-this-is-valid-arweave-wallet-address10"
    newDataIndex = "test-this-is-valid-arweave-wallet-address11"
    quantity = "100"
    positionId = "1"
    returnAmount = "90"
    investmentAmount = "100"
    maxPositionTokensToSell = "140"
    positionIds = {"1", "2"}
    distribution = {50, 50}
    resolutionAgent = "test-this-is-valid-arweave-wallet-address-10"
    payouts = { 1, 0 }
    positionIds = { "1", "2" }
    quantities = { "100", "200" }
    remainingBalances = { "0", "0" }
    -- Instantiate objects
    Market = market.new(
      configurator,
      dataIndex,
      collateralToken,
      resolutionAgent,
      creator,
      question,
      rules, 
      category,
      subcategory,
      positionIds,
      name,
      ticker,
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
      From = marketFactory,
      Tags = {
        CollateralToken = collateralToken,
        ResolutionAgent = resolutionAgent,
        Creator = creator,
        Question = question,
        Name = name,
        Ticker = ticker,
        Logo = logo,
        Logos = json.encode(logos),
        LpFee = lpFee,
        CreatorFee = creatorFee,
        CreatorFeeTarget = creatorFeeTarget,
        ProtocolFee = protocolFee,
        ProtocolFeeTarget = protocolFeeTarget,
        Configurator = configurator,
        DataIndex = dataIndex,
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
      FundingAdded = json.encode(distribution),
      MintAmount = quantity,
      Data = "Successfully added funding",
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
      Data = "Successfully removed funding",
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
      InvestmentAmount = investmentAmount,
      PositionId = "1",
      PositionTokensBought = quantity,
      Data = "Successful buy order",
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
      PositionId = "1",
      PositionTokensSold = quantity,
      Data = "Successful sell order"
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
		msgMintSingle = {
      From = minter,
      Tags = {
        Action = "Mint-Single",
        Recipient = sender,
        PositionId = positionId,
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
		msgMintBatch = {
      From = minter,
      Tags = {
        Action = "Mint-Batch",
        Recipient = sender,
        PositionIds = json.encode(positionIds),
        Quantities = json.encode(quantities),
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBalance = {
      From = sender,
      Tags = {
        Recipient = recipient,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgBalances = {
      From = sender,
      Tags = {
        Recipient = recipient,
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
		msgTransferSingle = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionId = positionId,
        Quantity = quantity,
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgTransferBatch = {
      From = sender,
      Tags = {
        Recipient = recipient,
        PositionIds = json.encode(positionIds),
        Quantities = json.encode(quantities),
      },
      Id = "test-message-id",
      ["X-Action"] = "FOO",
      reply = function(message) return message end,
      forward = function(target, message) return message end
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
      forward = function(target, message) return message end
    }
    -- create a message object
    msgMergePositions = {
      From = sender,
      Tags = {
        OnBehalfOf = recipient,
        Quantity = quantity,
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgReportPayouts = {
      From = resolutionAgent,
      Tags = {
        Payouts = json.encode(payouts),
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgRedeemPositions = {
      From = sender,
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateConfigurator = {
      From = configurator,
      Tags = {
        Configurator = newConfigurator
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateDataIndex = {
      From = configurator,
      Tags = {
        DataIndex = newDataIndex
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateTakeFee = {
      From = configurator,
      Tags = {
        CreatorFee = tostring(newCreatorFee),
        ProtocolFee = tostring(newProtocolFee)
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateProtocolFeeTarget = {
      From = configurator,
      Tags = {
        ProtocolFeeTarget = newProtocolFeeTarget
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateLogo = {
      From = configurator,
      Tags = {
        Logo = newLogo
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateLogos = {
      From = configurator,
      Tags = {
        Logos = json.encode(newLogos)
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a notice object
    noticeDebit = {
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You transferred 100 to test-this-is-valid-arweave-wallet-address-2"
    }
    -- create a notice object
    noticeCredit = {
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      ["X-Action"] = "FOO",
      Data = "You received 100 from test-this-is-valid-arweave-wallet-address-1"
    }
    -- create a notice object
    noticeCreditBatch = {
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      RemainingBalances = json.encode(remainingBalances),
      Action = 'Burn-Batch-Notice',
      Data = "Successfully burned batch"
    }
     -- create a notice object
     noticeDebitSingle = {
      Action = "Debit-Single-Notice",
      Recipient = recipient,
      PositionId = positionId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You transferred 100 of id 1 to " .. recipient
    }
    -- create a notice object
    noticeCreditSingle = {
      Action = "Credit-Single-Notice",
      Sender = sender,
      PositionId = positionId,
      Quantity = quantity,
      ["X-Action"] = "FOO",
      Data = "You received 100 of id 1 from " .. sender
    }
    -- create a notice object
    noticeDebitBatch = {
      Action = "Debit-Batch-Notice",
      Recipient = recipient,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You transferred batch to " .. recipient
    }
    -- create a notice object
    noticeCreditBatch = {
      Action = "Credit-Batch-Notice",
      Sender = sender,
      PositionIds = json.encode(positionIds),
      Quantities = json.encode(quantities),
      ["X-Action"] = "FOO",
      Data = "You received batch from " .. sender
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
      resolutionAgent,
      collateralToken,
      positionIds,
      creatorFee,
      creatorFeeTarget,
      protocolFee,
      protocolFeeTarget
    )
    -- assert initial state
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
    -- @dev update expected notice
    noticeAddFunding.FundingAdded = fundingAdded
    -- assert notice
    -- @dev update onBehalfOf
    noticeAddFunding.OnBehalfOf = msgAddFunding.Tags.Sender
    assert.are.same(noticeAddFunding, notice)
	end)

  it("should fail to addFunding and return funds if invalid", function()
    -- TODO
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
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
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
    -- @dev update expected notice
    noticeRemoveFunding.SendAmounts = json.encode({msgAddFunding.Tags.Quantity, msgAddFunding.Tags.Quantity})
    noticeRemoveFunding.SharesToBurn = msgAddFunding.Tags.Quantity
    noticeRemoveFunding.CollateralRemovedFromFeePool = "0"
    -- assert notice
    -- @dev update onBehalfOf
    noticeRemoveFunding.OnBehalfOf = msgRemoveFunding.From
    assert.are.same(noticeRemoveFunding, notice)
	end)

  it("should fail to removeFunding and return LP Tokens if invalid", function()
    -- TODO
  end)

  it("should calc buy amount", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
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
  -- @dev update expected notice
  noticeBuy.PositionTokensBought = buyAmount
  noticeBuy.FeeAmount = tostring(feeAmount)
  noticeBuy.OnBehalfOf = msgBuy.From
  -- assert notice
  assert.are.same(noticeBuy, notice)
 end)

 it("should fail to buy and return Collateral Tokens if invalid", function()
  -- TODO
  end)

  it("should sell", function()
    -- add funding
    Market.cpmm:addFunding(
      msgAddFunding.Tags.Sender,
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
    local feeAmount_ = math.ceil(tonumber(msgSell.Tags.ReturnAmount) * Market.cpmm.lpFee / 10000)
    noticeSell.FeeAmount = tostring(feeAmount_)
    -- sell
    local notice = {}
    assert.has.no.errors(function()
      notice = Market.cpmm:sell(
        msgSell.From,
        msgSell.From, -- onBehalfOf is the same as sender
        msgSell.Tags.ReturnAmount,
        msgSell.Tags.PositionId,
        msgSell.Tags.MaxPositionTokensToSell,
        msgSell
      )
    end)
    -- assert state
    -- LP Token balances
    assert.are.same(msgBuy.Tags.InvestmentAmount, Market.cpmm.token.balances[msgBuy.From])

    assert.are.same({
      ["1"] = {
        [_G.ao.id] = tostring(tonumber(balancesBefore["1"][_G.ao.id])),
        [msgSell.From] =  tostring(tonumber(balancesBefore["1"][msgSell.From]) - tonumber(msgSell.Tags.MaxPositionTokensToSell)),
      },
      ["2"] = {
        [_G.ao.id] = tostring(balancesBefore["2"][_G.ao.id] - tonumber(msgSell.Tags.MaxPositionTokensToSell)),
      },
    }, Market.cpmm.tokens.balancesById)
    -- Pool Balances
    local poolBalances = {
      tostring(tonumber(balancesBefore["1"][_G.ao.id])),
      tostring(balancesBefore["2"][_G.ao.id] - tonumber(msgSell.Tags.MaxPositionTokensToSell))
    }
    assert.are.same(poolBalances, Market.cpmm:getPoolBalances())
    -- assert notice
    -- @dev update onBehalfOf
    noticeSell.OnBehalfOf = msgSell.From
    assert.are.same(noticeSell, notice)
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
    local withdrawnFeesNotice = {}
    -- should not throw an error
		assert.has.no.error(function()
      withdrawnFeesNotice = Market.cpmm:withdrawFees(sender, sender, true, msgBuy) -- expectReply
    end)
    -- assert withdrawn fees
    assert.are.equal("1", feesWithdrawable)
    assert.are.equal(feesWithdrawable, withdrawnFeesNotice.FeeAmount)
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
        true, -- expectReply
        msgTransfer
      )
    end)
    -- assert updated balance
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.balances[recipient])
    -- assert update total supply
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.token.totalSupply)
    -- assert notices
    assert.are.same(noticeDebit, notices[1])
    assert.are.same(noticeCredit, notices[2])
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
        true, -- expectReply
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

  it("should get payout numerators", function()

    -- assert state
    assert.are.same({0,0}, Market.cpmm.tokens.payoutNumerators)
    -- get reply
    local reply = Market:getPayoutNumerators(
      msgInit -- msgBalance used to send a message with reply
    )
    -- assert reply
    assert.are.same(json.encode({0,0}), reply.Data)
  end)

  it("should get payout denominator", function()
    -- assert state
    assert.are.same(0, Market.cpmm.tokens.payoutDenominator)
    -- get reply
    local reply = Market:getPayoutDenominator(
      msgInit -- msgBalance used to send a message with reply
    )
    -- assert reply
    assert.are.same("0", reply.Data)
  end)

  it("should get balance", function()
    local balance = ''

    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.Tags.Recipient,
        msgMintSingle.Tags.PositionId,
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
    assert.are.same(msgMintSingle.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.PositionId][msgMintSingle.Tags.Recipient])
	end)

  it("should get balance from sender (no recipient)", function()
    local balance = ''

    -- mint to msgMint.From
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.From,
        msgMintSingle.Tags.PositionId,
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
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.PositionId][msgMintSingle.From])
	end)

  it("should get batch balance", function()
    local balances = {}
    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:batchMint(
        msgMintBatch.Tags.Recipient,
        json.decode(msgMintBatch.Tags.PositionIds),
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
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], json.decode(balances.Data)[1])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], json.decode(balances.Data)[2])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.PositionIds)[1]][sender])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.PositionIds)[2]][sender])
	end)

  it("should get balances", function()
    local balances = {}

    -- mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:mint(
        msgMintSingle.Tags.Recipient,
        msgMintSingle.Tags.PositionId,
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
    assert.are.same(msgMint.Tags.Quantity, json.decode(balances.Data)[msgMintSingle.Tags.Recipient])
    assert.are.same(msgMint.Tags.Quantity, Market.cpmm.tokens.balancesById[msgMintSingle.Tags.PositionId][msgMintSingle.Tags.Recipient])
	end)

  it("should get batch balances", function()
    local balances = {}

    -- batch mint
    -- should not throw an error
		assert.has_no.errors(function()
      Market.cpmm.tokens:batchMint(
        msgMintBatch.Tags.Recipient,
        json.decode(msgMintBatch.Tags.PositionIds),
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
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], json.decode(balances.Data)[json.decode(msgMintBatch.Tags.PositionIds)[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], json.decode(balances.Data)[json.decode(msgMintBatch.Tags.PositionIds)[2]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[1], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.PositionIds)[1]][msgMintBatch.Tags.Recipient])
    assert.are.same(json.decode(msgMintBatch.Tags.Quantities)[2], Market.cpmm.tokens.balancesById[json.decode(msgMintBatch.Tags.PositionIds)[2]][msgMintBatch.Tags.Recipient])
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
    assert.are.equal("Update-Configurator-Notice", notice.Action)
    assert.are.equal(msgUpdateConfigurator.Tags.Configurator, notice.Data)
	end)

  it("should update data index", function()
    local notice = {}
    -- should not throw an error
		assert.has.no.error(function()
      notice = Market:updateDataIndex(
        msgUpdateDataIndex
      )
    end)
    -- assert state
    assert.are.equal(msgUpdateDataIndex.Tags.DataIndex, Market.dataIndex)
    -- assert notice
    assert.are.equal("Update-Data-Index-Notice", notice.Action)
    assert.are.equal(msgUpdateDataIndex.Tags.DataIndex, notice.Data)
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
    assert.are.equal("Update-Take-Fee-Notice", notice.Action)
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
    assert.are.equal("Update-Protocol-Fee-Target-Notice", notice.Action)
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
    assert.are.equal(msgUpdateLogo.Tags.Logo, Market.cpmm.token.logo)
    -- assert notice
    assert.are.equal("Update-Logo-Notice", notice.Action)
    assert.are.equal(msgUpdateLogo.Tags.Logo, notice.Data)
  end)

  it("should update logos" , function()
    local notice = {}

    -- should not throw an error
    assert.has.no.error(function()
      notice = Market:updateLogos(
        msgUpdateLogos
      )
    end)
    -- assert state
    assert.are.equal(msgUpdateLogos.Tags.Logos, json.encode(Market.cpmm.tokens.logos))
    -- assert notice
    assert.are.equal("Update-Logos-Notice", notice.Action)
    assert.are.equal(msgUpdateLogos.Tags.Logos, notice.Data)
  end)
end)