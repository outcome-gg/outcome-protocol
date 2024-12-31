require("luacov")
local cpmmValidation = require("modules.cpmmValidation")
local json = require("json")

local marketFactory = ""
local sender = ""
local initialized = nil
local marketId = ""
local conditionId = ""
local collateralToken = ""
local outcomeSlotCount = ""
local name = ""
local ticker = ""
local logo = ""
local lpFee = ""
local creatorFee = ""
local creatorFeeTarget = ""
local protocolFee = ""
local protocolFeeTarget = ""
local configurator = ""
local incentives = ""
local quantity = ""
local returnAmount = ""
local investmentAmount = ""
local maxOutcomeTokensToSell = ""
local distribution = {}
local msgInit = {}
local msgAddFunding = {}
local msgRemoveFunding = {}
local msgBuy = {}
local msgSell = {}
local msgCalcBuyAmount = {}
local msgCalcSellAmount = {}


describe("#market #conditionalTokens #cpmmValidation", function()
  before_each(function()
    -- set variables
    marketFactory = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    initialized = false
    marketId = "this-is-valid-market-id"
    conditionId = "this-is-valid-condition-id"
    collateralToken = "test-this-is-valid-arweave-wallet-address-2"
    outcomeSlotCount = "2"
    name = "Test Market"
    ticker = "TST"
    logo = "https://test.com/logo.png"
    lpFee = "100" -- basis points
    creatorFee = "100" -- basis points
    creatorFeeTarget = "test-this-is-valid-arweave-wallet-address-3"
    protocolFee = "100" -- basis points
    protocolFeeTarget = "test-this-is-valid-arweave-wallet-address-4"
    configurator = "test-this-is-valid-arweave-wallet-address-5"
    incentives = "test-this-is-valid-arweave-wallet-address-6"
    quantity = "100"
    returnAmount = "100"
    investmentAmount = "100"
    maxOutcomeTokensToSell = "100"
    distribution = {50, 50}
    -- Mock the CPMM object
    ---@diagnostic disable-next-line: missing-fields
    _G.CPMM = {initialized = initialized, tokens = {positionIds = { "1", "2", "3" }}}
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
      }
    }
    -- create a message object
    msgAddFunding = {
      From = sender,
      Tags = {
        Quantity = quantity,
        ["X-Distribution"] = json.encode(distribution)
      }
    }
    -- create a message object
    msgRemoveFunding = {
      From = sender,
      Tags = {
        Quantity = quantity,
      }
    }
    -- create a message object
    msgBuy = {
      From = sender,
      Tags = {
        PositionId = "1",
        Quantity = quantity,
      }
    }
    -- create a message object
    msgSell = {
      From = sender,
      Tags = {
        PositionId = "1",
        Quantity = quantity,
        ReturnAmount = returnAmount,
        MaxOutcomeTokensToSell = maxOutcomeTokensToSell
      }
    }
    -- create a message object
    msgCalcBuyAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        InvestmentAmount = investmentAmount,
      }
    }
    -- create a message object
    msgCalcSellAmount = {
      From = sender,
      Tags = {
        PositionId = "1",
        ReturnAmount = returnAmount,
      }
    }
	end)

  it("should pass addFunding validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.addFunding(msgAddFunding)
    end)
	end)

  it("should fail addFunding validation when missing quantity", function()
    msgAddFunding.Tags.Quantity = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.addFunding(msgAddFunding)
    end, "Quantity is required!")
	end)

  it("should fail addFunding validation when invalid quantity", function()
    msgAddFunding.Tags.Quantity = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.addFunding(msgAddFunding)
    end, "Quantity must be a number!")
	end)

  it("should fail addFunding validation when missing X-Distribution", function()
    msgAddFunding.Tags["X-Distribution"] = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.addFunding(msgAddFunding)
    end, "X-Distribution is required!")
	end)

  it("should fail addFunding validation when invalid X-Distribution", function()
    msgAddFunding.Tags["X-Distribution"] = "invalid-distribution"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.addFunding(msgAddFunding)
    end, "X-Distribution must be valid JSON Array!")
	end)

  it("should pass removeFunding validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.removeFunding(msgRemoveFunding)
    end)
	end)

  it("should fail removeFunding validation when missing quantity", function()
    msgRemoveFunding.Tags.Quantity = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.removeFunding(msgRemoveFunding)
    end, "Quantity is required!")
	end)

  it("should fail removeFunding validation when invalid quantity", function()
    msgRemoveFunding.Tags.Quantity = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.removeFunding(msgRemoveFunding)
    end, "Quantity must be a number!")
	end)

  it("should pass buy validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.buy(msgBuy, _G.CPMM.tokens.positionIds)
    end)
	end)

  it("should fail buy validation when missing positionId", function()
    msgBuy.Tags.PositionId = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.buy(msgBuy, _G.CPMM.tokens.positionIds)
    end, "PositionId is required!")
	end)

  it("should fail buy validation when invalid positionId", function()
    msgBuy.Tags.PositionId = "0"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.buy(msgBuy, _G.CPMM.tokens.positionIds)
    end, "Invalid positionId!")
	end)

  it("should fail buy validation when missing quantity", function()
    msgBuy.Tags.Quantity = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.buy(msgBuy, _G.CPMM.tokens.positionIds)
    end, "Quantity is required!")
	end)

  it("should fail buy validation when invalid quantity", function()
    msgBuy.Tags.Quantity = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.buy(msgBuy, _G.CPMM.tokens.positionIds)
    end, "Quantity must be a number!")
	end)

  it("should pass sell validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end)
	end)

  it("should fail sell validation when missing positionId", function()
    msgSell.Tags.PositionId = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "PositionId is required!")
	end)

  it("should fail sell validation when invalid positionId", function()
    msgSell.Tags.PositionId = "0"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "Invalid positionId!")
	end)

  it("should fail sell validation when missing quantity", function()
    msgSell.Tags.Quantity = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "Quantity is required!")
	end)

  it("should fail sell validation when invalid quantity", function()
    msgSell.Tags.Quantity = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "Quantity must be a number!")
	end)

  it("should fail sell validation when missing returnAmount", function()
    msgSell.Tags.ReturnAmount = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "ReturnAmount is required!")
	end)

  it("should fail sell validation when invalid returnAmount", function()
    msgSell.Tags.ReturnAmount = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "ReturnAmount must be a number!")
	end)

  it("should fail sell validation when missing maxOutcomeTokensToSell", function()
    msgSell.Tags.MaxOutcomeTokensToSell = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "MaxOutcomeTokensToSell is required!")
	end)

  it("should fail sell validation when invalid maxOutcomeTokensToSell", function()
    msgSell.Tags.MaxOutcomeTokensToSell = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.sell(msgSell, _G.CPMM.tokens.positionIds)
    end, "MaxOutcomeTokensToSell must be a number!")
	end)

  it("should pass calcBuyAmount validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    end)
	end)

  it("should fail calcBuyAmount validation when missing positionId", function()
    msgCalcBuyAmount.Tags.PositionId = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    end, "PositionId is required!")
	end)

  it("should fail calcBuyAmount validation when invalid positionId", function()
    msgCalcBuyAmount.Tags.PositionId = "0"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    end, "Invalid positionId!")
	end)

  it("should fail calcBuyAmount validation when missing investmentAmount", function()
    msgCalcBuyAmount.Tags.InvestmentAmount = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    end, "InvestmentAmount is required!")
	end)

  it("should fail calcBuyAmount validation when invalid investmentAmount", function()
    msgCalcBuyAmount.Tags.InvestmentAmount = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    end, "InvestmentAmount must be a number!")
	end)

  it("should pass calcSellAmount validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    end)
	end)

  it("should fail calcSellAmount validation when missing positionId", function()
    msgCalcSellAmount.Tags.PositionId = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    end, "PositionId is required!")
	end)

  it("should fail calcSellAmount validation when invalid positionId", function()
    msgCalcSellAmount.Tags.PositionId = "0"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    end, "Invalid positionId!")
	end)

  it("should fail calcSellAmount validation when missing returnAmount", function()
    msgCalcSellAmount.Tags.ReturnAmount = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    end, "ReturnAmount is required!")
	end)

  it("should fail calcSellAmount validation when invalid returnAmount", function()
    msgCalcSellAmount.Tags.ReturnAmount = "not-a-number"
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    end, "ReturnAmount must be a number!")
	end)
end)