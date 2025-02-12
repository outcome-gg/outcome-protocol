require("luacov")
local cpmmNotices = require("marketModules.cpmmNotices")
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
local maxPositionTokensToSell = ""
local distribution = {}
local msgInit = {}
local msgAddFunding = {}
local msgRemoveFunding = {}
local msgBuy = {}
local msgSell = {}
local msgUpdateConfigurator = {}
local msgUpdateIncentives = {}
local msgUpdateTakeFee = {}
local msgUpdateProtocolFeeTarget = {}
local msgUpdateLogo = {}
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


describe("#market #conditionalTokens #cpmmNotices", function()
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
    maxPositionTokensToSell = "100"
    distribution = {50, 50}
    -- Mock the CPMM object
    ---@diagnostic disable-next-line: missing-fields
    _G.CPMM = {initialized = initialized, tokens = { positionIds = { "1", "2", "3" }}}
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
      From = sender,
      Tags = {
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
        Quantity = quantity,
        InvestmentAmount = investmentAmount,
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
      Data = "Successful sell order",
    }
    -- create a message object
    msgUpdateConfigurator = {
      From = sender,
      Tags = {
        Configurator = configurator
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateIncentives = {
      From = sender,
      Tags = {
        Incentives = incentives
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateTakeFee = {
      From = sender,
      Tags = {
        CreatorFee = "111",
        ProtocolFee = "222",
        TakeFee = "333"
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateProtocolFeeTarget = {
      From = sender,
      Tags = {
        ProtocolFeeTarget = "test-this-is-valid-arweave-wallet-address-7"
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgUpdateLogo = {
      From = sender,
      Tags = {
        Logo = "this-is-valid-url"
      },
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
	end)

  it("should send fundingAddedNotice", function()
    local fundingAdded = {10, 50}
    local notice = cpmmNotices.addFundingNotice(
      fundingAdded,
      msgAddFunding.Tags.Quantity,
      msgAddFunding
    )
    -- @dev update fundingAdded
    noticeAddFunding.FundingAdded = json.encode(fundingAdded)
    assert.are.same(noticeAddFunding, notice)
	end)

  it("should send fundingRemovedNotice", function()
    local sendAmounts = {10, 50}
    local collateralRemovedFromFeePool = 10
    local sharesToBurn = 50
    -- @dev update expected notice
    noticeRemoveFunding.SendAmounts = json.encode(sendAmounts)
    noticeRemoveFunding.SharesToBurn = tostring(sharesToBurn)
    noticeRemoveFunding.CollateralRemovedFromFeePool = tostring(collateralRemovedFromFeePool)
    local notice = cpmmNotices.removeFundingNotice(
      sendAmounts,
      collateralRemovedFromFeePool,
      sharesToBurn,
      msgRemoveFunding
    )
    assert.are.same(noticeRemoveFunding, notice)
	end)

  it("should send buyNotice", function()
    local feeAmount = 2
    -- @dev update expected notice
    noticeBuy.FeeAmount = tostring(feeAmount)
    noticeBuy.OnBehalfOf = msgBuy.From
    local notice = cpmmNotices.buyNotice(
      msgBuy.From,
      msgBuy.From, -- onBehalfOf
      msgBuy.Tags.InvestmentAmount,
      feeAmount,
      msgBuy.Tags.PositionId,
      msgBuy.Tags.Quantity,
      msgBuy
    )
    assert.are.same(noticeBuy, notice)
	end)

  it("should send sellNotice", function()
    local feeAmount = 2
    -- @dev update expected notice
    noticeSell.FeeAmount = tostring(feeAmount)
    noticeSell.PositionTokensSold = msgSell.Tags.Quantity
    local notice = cpmmNotices.sellNotice(
      msgSell.From,
      msgSell.Tags.ReturnAmount,
      feeAmount,
      msgSell.Tags.PositionId,
      msgSell.Tags.Quantity,
      msgSell
    )
    assert.are.same(noticeSell, notice)
	end)

  it("should send updateConfiguratorNotice", function()
    local notice = cpmmNotices.updateConfiguratorNotice(
      msgUpdateConfigurator.Tags.Configurator,
      msgUpdateConfigurator
    )
    assert.are.same({
      Action = "Update-Configurator-Notice",
      Data = msgUpdateConfigurator.Tags.Configurator
    }, notice)
	end)

  it("should send updateTakeFeeNotice", function()
    local notice = cpmmNotices.updateTakeFeeNotice(
      msgUpdateTakeFee.Tags.CreatorFee,
      msgUpdateTakeFee.Tags.ProtocolFee,
      msgUpdateTakeFee.Tags.TakeFee,
      msgUpdateTakeFee
    )
    assert.are.same({
      Action = "Update-Take-Fee-Notice",
      CreatorFee = msgUpdateTakeFee.Tags.CreatorFee,
      ProtocolFee = msgUpdateTakeFee.Tags.ProtocolFee,
      Data = msgUpdateTakeFee.Tags.TakeFee
    }, notice)
	end)

  it("should send updateProtocolFeeTargetNotice", function()
    local notice = cpmmNotices.updateProtocolFeeTargetNotice(
      msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget,
      msgUpdateProtocolFeeTarget
    )
    assert.are.same({
      Action = "Update-Protocol-Fee-Target-Notice",
      Data = msgUpdateProtocolFeeTarget.Tags.ProtocolFeeTarget
    }, notice)
	end)

  it("should send updateLogoNotice", function()
    local notice = cpmmNotices.updateLogoNotice(
      msgUpdateLogo.Tags.Logo,
      msgUpdateLogo
    )
    assert.are.same({
      Action = "Update-Logo-Notice",
      Data = msgUpdateLogo.Tags.Logo
    }, notice)
	end)
end)