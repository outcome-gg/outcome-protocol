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
    _G.CPMM = {
      initialized = initialized,
      tokens = {
        positionIds = { "1", "2", "3" }
      }
    }
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

  it("should pass init validation", function()
    -- should not throw an error
		assert.has_no.errors(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end)
	end)

  it("should fail init validation when already initialized", function()
    _G.CPMM.initialized = true
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Market already initialized!")
	end)

  it("should fail init validation when no marketId", function()
    msgInit.Tags.MarketId = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "MarketId is required!")
	end)

  it("should fail init validation when no conditionId", function()
    msgInit.Tags.ConditionId = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ConditionId is required!")
	end)

  it("should fail init validation when no collateralToken", function()
    msgInit.Tags.CollateralToken = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CollateralToken is required!")
	end)

  it("should fail init validation when invalid collateralToken", function()
    msgInit.Tags.CollateralToken = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CollateralToken must be a valid Arweave address!")
	end)

  it("should fail init validation when no outcomeSlotCount", function()
    msgInit.Tags.OutcomeSlotCount = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "OutcomeSlotCount is required!")
	end)

  it("should fail init validation when outcomeSlotCount not a number", function()
    msgInit.Tags.OutcomeSlotCount = "not-a-number"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "OutcomeSlotCount must be a number!")
	end)

  it("should fail init validation when outcomeSlotCount is zero", function()
    msgInit.Tags.OutcomeSlotCount = "0"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "OutcomeSlotCount must be greater than zero!")
	end)

  it("should fail init validation when outcomeSlotCount is negative", function()
    msgInit.Tags.OutcomeSlotCount = "-1"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "OutcomeSlotCount must be greater than zero!")
	end)

  it("should fail init validation when outcomeSlotCount is a decimal", function()
    msgInit.Tags.OutcomeSlotCount = "1.23"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "OutcomeSlotCount must be an integer!")
	end)

  it("should fail init validation when outcomeSlotCount is greater than 256", function()
    msgInit.Tags.OutcomeSlotCount = "257"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Too many outcome slots!")
	end)

  it("should fail init validation when outcomeSlotCount is one", function()
    msgInit.Tags.OutcomeSlotCount = "1"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "There should be more than one outcome slot!")
	end)

  it("should fail init validation when no name", function()
    msgInit.Tags.Name = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Name is required!")
	end)

  it("should fail init validation when no ticker", function()
    msgInit.Tags.Ticker = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Ticker is required!")
	end)

  it("should fail init validation when no logo", function()
    msgInit.Tags.Logo = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Logo is required!")
	end)

  it("should fail init validation when no lpFee", function()
    msgInit.Tags.LpFee = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "LpFee is required!")
	end)

  it("should fail init validation when LpFee not a number", function()
    msgInit.Tags.LpFee = "not-a-number"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "LpFee must be a number!")
	end)

  it("should fail init validation when LpFee is zero", function()
    msgInit.Tags.LpFee = "0"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "LpFee must be greater than zero!")
	end)

  it("should fail init validation when LpFee is negative", function()
    msgInit.Tags.LpFee = "-1"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "LpFee must be greater than zero!")
	end)

  it("should fail init validation when LpFee is a decimal", function()
    msgInit.Tags.LpFee = "1.23"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "LpFee must be an integer!")
	end)

  it("should fail init validation when no CreatorFee", function()
    msgInit.Tags.CreatorFee = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CreatorFee is required!")
	end)

  it("should fail init validation when CreatorFee not a number", function()
    msgInit.Tags.CreatorFee = "not-a-number"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CreatorFee must be a number!")
	end)

  it("should fail init validation when CreatorFee is zero", function()
    msgInit.Tags.CreatorFee = "0"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CreatorFee must be greater than zero!")
	end)

  it("should fail init validation when CreatorFee is negative", function()
    msgInit.Tags.CreatorFee = "-1"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CreatorFee must be greater than zero!")
	end)

  it("should fail init validation when CreatorFee is a decimal", function()
    msgInit.Tags.CreatorFee = "1.23"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "CreatorFee must be an integer!")
	end)

  it("should fail init validation when no ProtocolFee", function()
    msgInit.Tags.ProtocolFee = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ProtocolFee is required!")
	end)

  it("should fail init validation when ProtocolFee not a number", function()
    msgInit.Tags.ProtocolFee = "not-a-number"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ProtocolFee must be a number!")
	end)

  it("should fail init validation when ProtocolFee is zero", function()
    msgInit.Tags.ProtocolFee = "0"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ProtocolFee must be greater than zero!")
	end)

  it("should fail init validation when ProtocolFee is negative", function()
    msgInit.Tags.ProtocolFee = "-1"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ProtocolFee must be greater than zero!")
	end)

  it("should fail init validation when ProtocolFee is a decimal", function()
    msgInit.Tags.ProtocolFee = "1.23"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "ProtocolFee must be an integer!")
	end)

  it("should fail init validation when TakeFee >= 1000 (10%)", function()
    msgInit.Tags.CreatorFee = "500"
    msgInit.Tags.ProtocolFee = "501"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Take Fee capped at 10%!")
	end)

  it("should fail init validation when no configurator", function()
    msgInit.Tags.Configurator = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Configurator is required!")
	end)

  it("should fail init validation when invalid configurator", function()
    msgInit.Tags.Configurator = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Configurator must be a valid Arweave address!")
	end)

  it("should fail init validation when no incentives", function()
    msgInit.Tags.Incentives = nil
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Incentives is required!")
	end)

  it("should fail init validation when invalid incentives", function()
    msgInit.Tags.Incentives = "invalid-arweave-wallet-address"
    -- should throw an error
		assert.has.error(function()
      cpmmValidation.init(msgInit, _G.CPMM.initialized)
    end, "Incentives must be a valid Arweave address!")
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
      cpmmValidation.buy(msgBuy)
    end)
	end)

  it("should fail buy validation when missing positionId", function()
    msgBuy.Tags.PositionId = nil
    -- should not throw an error
		assert.has.error(function()
      cpmmValidation.buy(msgBuy)
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