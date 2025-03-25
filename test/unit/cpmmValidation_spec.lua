require("luacov")
local cpmmValidation = require("marketModules.cpmmValidation")
local json = require("json")

local collateralToken, sender, initialized, positionIds, configurator, quantity, returnAmount
local investmentAmount, maxPositionTokensToSell, distribution
local msgConfigurator, msgAddFunding, msgRemoveFunding, msgBuy, msgSell, msgCalcBuyAmount, msgCalcSellAmount

describe("#market #conditionalTokens #cpmmValidation", function()
  before_each(function()
    -- Set variables
    collateralToken = "test-this-is-valid-arweave-wallet-address-0"
    sender = "test-this-is-valid-arweave-wallet-address-1"
    initialized = false
    configurator = "test-this-is-valid-arweave-wallet-address-5"
    quantity = "100"
    returnAmount = "100"
    investmentAmount = "100"
    maxPositionTokensToSell = "100"
    distribution = {50, 30, 20}
    positionIds = { "1", "2", "3" }

    -- Mock the CPMM object
    ---@diagnostic disable-next-line: missing-fields
    _G.CPMM = {
      initialized = initialized,
      tokens = {positionIds = positionIds},
      calcBuyAmount = function(self) return "100" end,
      calcSellAmount = function(self) return "100" end
    }

    -- Create messages
    msgConfigurator = { From = configurator, Tags = {} }
    msgAddFunding = { From = sender, Tags = { Quantity = quantity, ["X-Distribution"] = json.encode(distribution) } }
    msgRemoveFunding = { From = sender, Tags = { Quantity = quantity } }
    msgBuy = { From = collateralToken, Tags = { Sender = sender, ["X-PositionId"] = "1", Quantity = quantity, ["X-MinPositionTokensToBuy"] = "100" } }
    msgSell = { From = sender, Tags = { PositionId = "1", Quantity = quantity, ReturnAmount = returnAmount, MaxPositionTokensToSell = maxPositionTokensToSell } }
    msgCalcBuyAmount = { From = sender, Tags = { PositionId = "1", InvestmentAmount = investmentAmount } }
    msgCalcSellAmount = { From = sender, Tags = { PositionId = "1", ReturnAmount = returnAmount } }
  end)

  -- ✅ Add Funding
  it("should pass addFunding validation", function()
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail addFunding validation when missing quantity", function()
    msgAddFunding.Tags.Quantity = nil
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity is required and must be a string!", err)
  end)

  it("should fail addFunding validation when invalid quantity", function()
    msgAddFunding.Tags.Quantity = "not-a-number"
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail addFunding validation when invalid quantity", function()
    msgAddFunding.Tags.Quantity = "not-a-number"
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail addFunding validation when #distribution ~= #positionsIds", function()
    msgAddFunding.Tags["X-Distribution"] = json.encode({50, 50})
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Distribution length mismatch", err)
  end)

  it("should fail addFunding validation when distribution sum == 0", function()
    msgAddFunding.Tags["X-Distribution"] = json.encode({0, 0, 0})
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Distribution sum must be greater than zero", err)
  end)

  it("should fail addFunding validation when distribution item not a number", function()
    msgAddFunding.Tags["X-Distribution"] = json.encode({0, "foo", 0})
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Distribution item must be a number", err)
  end)

  it("should fail addFunding validation when distribution item is less than 0", function()
    msgAddFunding.Tags["X-Distribution"] = json.encode({0, -1, 0})
    local success, err = cpmmValidation.addFunding(msgAddFunding, "0", positionIds)
    assert.is_false(success)
    assert.are.equal("Distribution item must be greater than or equal to zero", err)
  end)

  it("should pass additional addFunding validation", function()
    msgAddFunding.Tags["X-Distribution"] = nil
    local success, err = cpmmValidation.addFunding(msgAddFunding, "100", positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail additional addFunding validation when distribution is provided", function()
    local success, err = cpmmValidation.addFunding(msgAddFunding, "100", positionIds)
    assert.is_false(success)
    assert.are.equal("Cannot specify distribution after initial funding", err)
  end)

  -- ✅ Remove Funding
  it("should pass removeFunding validation", function()
    local success, err = cpmmValidation.removeFunding(msgRemoveFunding, quantity)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail removeFunding validation when missing quantity", function()
    msgRemoveFunding.Tags.Quantity = nil
    local success, err = cpmmValidation.removeFunding(msgRemoveFunding, quantity)
    assert.is_false(success)
    assert.are.equal("Quantity is required and must be a string!", err)
  end)

  it("should fail removeFunding validation when invalid quantity", function()
    msgRemoveFunding.Tags.Quantity = "not-a-number"
    local success, err = cpmmValidation.removeFunding(msgRemoveFunding, quantity)
    assert.is_false(success)
    assert.are.equal("Quantity must be a valid number!", err)
  end)

  it("should fail removeFunding validation when balance < quantity", function()
    local balance = "0"
    local success, err = cpmmValidation.removeFunding(msgRemoveFunding, balance)
    assert.is_false(success)
    assert.are.equal("Quantity must be less than or equal to balance!", err)
  end)

  -- ✅ Buy
  it("should pass buy validation", function()
    local success, err = cpmmValidation.buy(msgBuy, _G.CPMM)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail buy validation when missing positionId", function()
    msgBuy.Tags["X-PositionId"] = nil
    local success, err = cpmmValidation.buy(msgBuy, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("X-PositionId is required and must be a string!", err)
  end)

  it("should fail buy validation when invalid positionId", function()
    msgBuy.Tags["X-PositionId"] = "0"
    local success, err = cpmmValidation.buy(msgBuy, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Invalid X-PositionId!", err)
  end)

  it("should fail buy validation when missing X-MinPositionTokensToBuy", function()
    msgBuy.Tags["X-MinPositionTokensToBuy"] = nil
    local success, err = cpmmValidation.buy(msgBuy, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("X-MinPositionTokensToBuy is required and must be a string!", err)
  end)

  it("should fail buy validation when X-MinPositionTokensToBuy is not a number", function()
    msgBuy.Tags["X-MinPositionTokensToBuy"] = "not-a-number"
    local success, err = cpmmValidation.buy(msgBuy, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("X-MinPositionTokensToBuy must be a valid number!", err)
  end)

  -- ✅ Sell
  it("should pass sell validation", function()
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail sell validation when missing positionId", function()
    msgSell.Tags.PositionId = nil
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("PositionId is required and must be a string!", err)
  end)

  it("should fail sell validation when invalid positionId", function()
    msgSell.Tags.PositionId = "0"
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should fail sell validation when missing MaxPositionTokensToSell", function()
    msgSell.Tags.MaxPositionTokensToSell = nil
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("MaxPositionTokensToSell is required and must be a string!", err)
  end)

  it("should fail sell validation when MaxPositionTokensToSell is not a number", function()
    msgSell.Tags.MaxPositionTokensToSell = "not-a-number"
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("MaxPositionTokensToSell must be a valid number!", err)
  end)

  it("should fail sell validation when missing ReturnAmount", function()
    msgSell.Tags.ReturnAmount = nil
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("ReturnAmount is required and must be a string!", err)
  end)
  
  it("should fail sell validation when ReturnAmount is not a number", function()
    msgSell.Tags.ReturnAmount = "not-a-number"
    local success, err = cpmmValidation.sell(msgSell, _G.CPMM)
    assert.is_false(success)
    assert.are.equal("ReturnAmount must be a valid number!", err)
  end)

  -- ✅ Calculate Buy Amount
  it("should pass calcBuyAmount validation", function()
    local success, err = cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail calcBuyAmount validation when missing positionId", function()
    msgCalcBuyAmount.Tags.PositionId = nil
    local success, err = cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("PositionId is required and must be a string!", err)
  end)

  it("should fail calcBuyAmount validation when invalid positionId", function()
    msgCalcBuyAmount.Tags.PositionId = "0"
    local success, err = cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should fail calcBuyAmount validation when missing InvestmentAmount", function()
    msgCalcBuyAmount.Tags.InvestmentAmount = nil
    local success, err = cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("InvestmentAmount is required and must be a string!", err)
  end)
  
  it("should fail calcBuyAmount validation when InvestmentAmount is not a number", function()
    msgCalcBuyAmount.Tags.InvestmentAmount = "not-a-number"
    local success, err = cpmmValidation.calcBuyAmount(msgCalcBuyAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("InvestmentAmount must be a valid number!", err)
  end)

  -- ✅ Calculate Sell Amount
  it("should pass calcSellAmount validation", function()
    local success, err = cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail calcSellAmount validation when missing positionId", function()
    msgCalcSellAmount.Tags.PositionId = nil
    local success, err = cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("PositionId is required and must be a string!", err)
  end)

  it("should fail calcSellAmount validation when invalid positionId", function()
    msgCalcSellAmount.Tags.PositionId = "0"
    local success, err = cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("Invalid PositionId!", err)
  end)

  it("should fail calcSellAmount validation when missing ReturnAmount", function()
    msgCalcSellAmount.Tags.ReturnAmount = nil
    local success, err = cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("ReturnAmount is required and must be a string!", err)
  end)

  it("should fail calcSellAmount validation when ReturnAmount is not a number", function()
    msgCalcSellAmount.Tags.ReturnAmount = "not-a-number"
    local success, err = cpmmValidation.calcSellAmount(msgCalcSellAmount, _G.CPMM.tokens.positionIds)
    assert.is_false(success)
    assert.are.equal("ReturnAmount must be a valid number!", err)
  end)

  it("should pass proposeConfigurator validation", function()
    msgConfigurator.Tags.Configurator = "test-this-is-valid-arweave-wallet-address-7"
    local success, err = cpmmValidation.proposeConfigurator(msgConfigurator, configurator)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should pass acceptConfigurator validation", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-7"
    local success, err = cpmmValidation.acceptConfigurator(msgConfigurator, "test-this-is-valid-arweave-wallet-address-7")
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail proposeConfigurator validation when sender is not configurator", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-8"
    local success, err = cpmmValidation.proposeConfigurator(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Sender must be configurator!", err)
  end)

  it("should faoñ acceptConfigurator validation when sender is not the proposedConfigurator", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-X"
    local success, err = cpmmValidation.acceptConfigurator(msgConfigurator, "test-this-is-valid-arweave-wallet-address-7")
    assert.is_false(success)
    assert.are.equal("Sender must be proposedConfigurator!", err)
  end)

  it("should fail proposeConfigurator validation when Configurator is missing", function()
    msgConfigurator.Tags.Configurator = nil
    local success, err = cpmmValidation.proposeConfigurator(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Configurator is required and must be a string!", err)
  end)

  it("should pass updateTakeFee validation", function()
    msgConfigurator.Tags.CreatorFee = "100"
    msgConfigurator.Tags.ProtocolFee = "100"
    local success, err = cpmmValidation.updateTakeFee(msgConfigurator, configurator)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateTakeFee validation when sender is not configurator", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-7"
    local success, err = cpmmValidation.updateTakeFee(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Sender must be configurator!", err)
  end)

  it("should fail updateTakeFee validation when sum of fees exceeds 1000 bps", function()
    msgConfigurator.Tags.CreatorFee = "9000"
    msgConfigurator.Tags.ProtocolFee = "2000"
    local success, err = cpmmValidation.updateTakeFee(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("TotalFee must be between 0 and 10000 (basis points)!", err)
  end)

  it("should pass updateProtocolFeeTarget validation", function()
    msgConfigurator.Tags.ProtocolFeeTarget = "test-this-is-valid-arweave-wallet-address-8"
    local success, err = cpmmValidation.updateProtocolFeeTarget(msgConfigurator, configurator)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateProtocolFeeTarget validation when sender is not configurator", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-8"
    local success, err = cpmmValidation.updateProtocolFeeTarget(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Sender must be configurator!", err)
  end)

  it("should fail updateProtocolFeeTarget validation when ProtocolFeeTarget is missing", function()
    msgConfigurator.Tags.ProtocolFeeTarget = nil
    local success, err = cpmmValidation.updateProtocolFeeTarget(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("ProtocolFeeTarget is required!", err)
  end)

  it("should pass updateLogo validation", function()
    msgConfigurator.Tags.Logo = "https://test.com/logo.png"
    local success, err = cpmmValidation.updateLogo(msgConfigurator, configurator)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it("should fail updateLogo validation when sender is not configurator", function()
    msgConfigurator.From = "test-this-is-valid-arweave-wallet-address-8"
    local success, err = cpmmValidation.updateLogo(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Sender must be configurator!", err)
  end)

  it("should fail updateLogo validation when Logo is missing", function()
    msgConfigurator.Tags.Logo = nil
    local success, err = cpmmValidation.updateLogo(msgConfigurator, configurator)
    assert.is_false(success)
    assert.are.equal("Logo is required!", err)
  end)
end)
