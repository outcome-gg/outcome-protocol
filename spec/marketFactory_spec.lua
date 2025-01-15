require("luacov")
local marketFactory = require("marketFactory.modules.marketFactory")
local constants = require("modules.constants")
local json = require("json")

local sender = ""
local collateralToken = ""
local resolutionAgent = ""
local question = ""
local outcomeSlotCount = ""
local creatorFee = ""
local creatorFeeTarget = ""

local msg = {}
local msgInfo = {}
local noticeCredit = {}
local msgInitMarket = {}

local function getTagValue(tags, targetName)
  for _, tag in ipairs(tags) do
      if tag.name == targetName then
          return tag.value
      end
  end
  return nil -- Return nil if the name is not found
end

describe("#marketFactory", function()
  before_each(function()
    -- set variables
    sender = "test-this-is-valid-arweave-wallet-address-0"
    collateralToken = 'test-this-is-valid-arweave-wallet-address-1'
    resolutionAgent = 'test-this-is-valid-arweave-wallet-address-2'
    question = 'test question'
    outcomeSlotCount = "2"
    creatorFee = "100"
    creatorFeeTarget = 'test-this-is-valid-arweave-wallet-address-3'
    -- create a market factory object
    FACTORY = marketFactory:new(
      constants.marketFactory.configurator,
      constants.marketFactory.incentives,
      constants.marketFactory.namePrefix,
      constants.marketFactory.tickerPrefix,
      constants.marketFactory.logo,
      constants.marketFactory.lpFee,
      constants.marketFactory.protocolFee,
      constants.marketFactory.protocolFeeTarget,
      constants.marketFactory.maximumTakeFee,
      constants.marketFactory.utilityToken,
      constants.marketFactory.minimumPayment,
      constants.marketFactory.collateralTokens
    )
    -- create a message object
    msg = {
      From = sender,
      reply = function(message) return message end
    }
    -- create a message object
		msgInfo = {
      From = sender,
      reply = function(message) return message end
    }
    -- create a notice object
    noticeCredit = {
      Target = marketFactory,
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = "100",
      Tags = {
        ["X-Action"] = "Spawn-Market",
        ["X-CollateralToken"] = collateralToken,
        ["X-ResolutionAgent"] = resolutionAgent,
        ["X-Question"] = question,
        ["X-OutcomeSlotCount"] = outcomeSlotCount,
        ["X-CreatorFee"] = creatorFee,
        ["X-CreatorFeeTarget"] = creatorFeeTarget,
      },
      Id = "msg-id-123",
      reply = function(message) return message end
    }
    -- create a message object
    msgInitMarket = {
      From = sender,
      Tags = {
        Action = "Init-Market",
      },
      reply = function(message) return message end
    }
	end)

  it("should get info", function()
    -- get info
    local info = nil
    -- should not throw an error
    assert.has_no.errors(function()
      info = FACTORY:info(msgInfo)
    end)
    -- assert correct response
    assert.are.same({
      Configurator = constants.marketFactory.configurator,
      Incentives = constants.marketFactory.incentives,
      LpFee = constants.marketFactory.lpFee,
      ProtocolFee = constants.marketFactory.protocolFee,
      ProtocolFeeTarget = constants.marketFactory.protocolFeeTarget,
      MaximumTakeFee = constants.marketFactory.maximumTakeFee,
      UtilityToken = constants.marketFactory.utilityToken,
      MinimumPayment = constants.marketFactory.minimumPayment,
      CollateralTokens = json.encode(constants.marketFactory.collateralTokens)
    }, info)
  end)

  it("should spawn a market", function()
    -- spawn a market
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:spawnMarket(
        noticeCredit.Tags["X-CollateralToken"],
        noticeCredit.Tags["X-ResolutionAgent"],
        noticeCredit.Tags["X-Question"],
        noticeCredit.Tags["X-OutcomeSlotCount"],
        noticeCredit.Sender,
        noticeCredit.Tags["X-CreatorFee"],
        noticeCredit.Tags["X-CreatorFeeTarget"],
        noticeCredit
      )
    end)
    -- assert notice
    assert.are.same({
      Action = "Market-Spawned-Notice",
      ResolutionAgent = noticeCredit.Tags["X-ResolutionAgent"],
      CollateralToken = noticeCredit.Tags["X-CollateralToken"],
      Creator = noticeCredit.Sender,
      CreatorFee = noticeCredit.Tags["X-CreatorFee"],
      CreatorFeeTarget = noticeCredit.Tags["X-CreatorFeeTarget"],
      Question = noticeCredit.Tags["X-Question"],
      OutcomeSlotCount = noticeCredit.Tags["X-OutcomeSlotCount"],
      ["Original-Msg-Id"] = noticeCredit.Id
    }, notice)
  end)

  it("should init a market", function()
    local notice = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:initMarket(msgInitMarket)
    end)
    -- assert state change
    assert.are.same({}, FACTORY.marketsPendingInit)
    assert.are.same({mockProcessId}, FACTORY.marketsInit)
    assert.are.same({mockProcessId}, FACTORY.marketsSpawnedByCreator[noticeCredit.Sender])
    -- assert notice
    assert.are.same({
      Action = "Market-Init-Notice",
      MarketProcessIds = json.encode({mockProcessId})
    }, notice)
  end)

  it("should get markets pending", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- should not throw an error
    assert.has_no.errors(function()
      msgReply = FACTORY:marketsPending(msg)
    end)
    -- assert state change
    assert.are.same({mockProcessId}, FACTORY.marketsPendingInit)
    -- assert reply
    assert.are.same(json.encode({mockProcessId}), msgReply.Data)
  end)

  it("should clear process ID from markets pending after initialization", function()
  end)

  it("should get markets initialized", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- init market
    FACTORY:initMarket(msgInitMarket)
    -- should not throw an error
    assert.has_no.errors(function()
      msgReply = FACTORY:marketsInitialized(msg)
    end)
    -- assert state change
    assert.are.same({mockProcessId}, FACTORY.marketsInit)
    -- assert reply
    assert.are.same(json.encode({mockProcessId}), msgReply.Data)
  end)

  it("should get markets by creator", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags.Creator = noticeCredit.Sender
    assert.has_no.errors(function()
      msgReply = FACTORY:marketsByCreator(msg)
    end)
    -- assert state change
    assert.are.same({mockProcessId}, FACTORY.marketsSpawnedByCreator[noticeCredit.Sender])
    -- assert reply
    assert.are.same(json.encode({mockProcessId}), msgReply.Data)
  end)

  it("should get process ID using original msg ID", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags["Original-Msg-Id"] = noticeCredit.Id
    assert.has_no.errors(function()
      msgReply = FACTORY:getProcessId(msg)
    end)
    -- assert reply
    assert.are.same(mockProcessId, msgReply.Data)
  end)

  it("should get latest process ID for creator", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[noticeCredit.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[noticeCredit.Sender] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[noticeCredit.Sender], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags.Creator = noticeCredit.Sender
    assert.has_no.errors(function()
      msgReply = FACTORY:getLatestProcessIdForCreator(msg.Tags.Creator, msg)
    end)
    -- assert reply
    assert.are.same(mockProcessId, msgReply.Data)
  end)

  it("should update configurator", function()
    local notice = {}
    -- should not throw an error
    local newConfigurator = "test-this-is-valid-arweave-wallet-address-4"
    assert.has_no.errors(function()
      notice = FACTORY:updateConfigurator(
        newConfigurator,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newConfigurator, FACTORY.configurator)
    -- assert notice
    assert.are.same({
      Action = "Update-Configurator-Notice",
      UpdateConfigurator = newConfigurator
    }, notice)
  end)

  it("should update incentives", function()
    local notice = {}
    -- should not throw an error
    local newIncentives = "test-this-is-valid-arweave-wallet-address-5"
    assert.has_no.errors(function()
      notice = FACTORY:updateIncentives(
        newIncentives,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newIncentives, FACTORY.incentives)
    -- assert notice
    assert.are.same({
      Action = "Update-Incentives-Notice",
      UpdateIncentives = newIncentives
    }, notice)
  end)

  it("should update lp fee", function()
    local notice = {}
    -- should not throw an error
    local newLpFee = "123"
    assert.has_no.errors(function()
      notice = FACTORY:updateLpFee(
        newLpFee,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newLpFee, FACTORY.lpFee)
    -- assert notice
    assert.are.same({
      Action = "Update-LpFee-Notice",
      UpdateLpFee = newLpFee
    }, notice)
  end)

  it("should update protocol fee", function()
    local notice = {}
    -- should not throw an error
    local newProtocolFee = "123"
    assert.has_no.errors(function()
      notice = FACTORY:updateProtocolFee(
        newProtocolFee,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newProtocolFee, FACTORY.protocolFee)
    -- assert notice
    assert.are.same({
      Action = "Update-ProtocolFee-Notice",
      UpdateProtocolFee = newProtocolFee
    }, notice)
  end)

  it("should update protocol fee target", function()
    local notice = {}
    -- should not throw an error
    local newProtocolFeeTarget = "test-this-is-valid-arweave-wallet-address-6"
    assert.has_no.errors(function()
      notice = FACTORY:updateProtocolFeeTarget(
        newProtocolFeeTarget,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newProtocolFeeTarget, FACTORY.protocolFeeTarget)
    -- assert notice
    assert.are.same({
      Action = "Update-ProtocolFeeTarget-Notice",
      UpdateProtocolFeeTarget = newProtocolFeeTarget
    }, notice)
  end)

  it("should update maximum take fee", function()
    local notice = {}
    -- should not throw an error
    local newMaximumTakeFee = "123"
    assert.has_no.errors(function()
      notice = FACTORY:updateMaximumTakeFee(
        newMaximumTakeFee,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newMaximumTakeFee, FACTORY.maximumTakeFee)
    -- assert notice
    assert.are.same({
      Action = "Update-MaximumTakeFee-Notice",
      UpdateMaximumTakeFee = newMaximumTakeFee
    }, notice)
  end)

  it("should update utility token", function()
    local notice = {}
    -- should not throw an error
    local newUtilityToken = "test-this-is-valid-arweave-wallet-address-7"
    assert.has_no.errors(function()
      notice = FACTORY:updateUtilityToken(
        newUtilityToken,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newUtilityToken, FACTORY.utilityToken)
    -- assert notice
    assert.are.same({
      Action = "Update-UtilityToken-Notice",
      UpdateUtilityToken = newUtilityToken
    }, notice)
  end)

  it("should update minimum payment", function()
    local notice = {}
    -- should not throw an error
    local newMinimumPayment = "123"
    assert.has_no.errors(function()
      notice = FACTORY:updateMinimumPayment(
        newMinimumPayment,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newMinimumPayment, FACTORY.minimumPayment)
    -- assert notice
    assert.are.same({
      Action = "Update-MinimumPayment-Notice",
      UpdateMinimumPayment = newMinimumPayment
    }, notice)
  end)

  it("should approve collateral token", function()
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:approveCollateralToken(
        collateralToken,
        true, -- approve
        msg
      )
    end)
    -- assert state change
    local updatedCollateralTokens = constants.marketFactory.collateralTokens
    table.insert(updatedCollateralTokens, collateralToken)

    assert.are.same(updatedCollateralTokens, FACTORY.collateralTokens)
    -- assert notice
    assert.are.same({
      Action = "Approve-CollateralToken-Notice",
      IsApprove = "true",
      CollateralToken = collateralToken
    }, notice)
  end)

  it("should unapprove collateral token", function()
    local notice = {}
    -- should not throw an error
    FACTORY:approveCollateralToken(
      collateralToken,
      true, -- approve
      msg
    )
    assert.has_no.errors(function()
      notice = FACTORY:approveCollateralToken(
        collateralToken,
        false, -- unapprove
        msg
      )
    end)
    -- assert state change
    assert.are.same(constants.marketFactory.collateralTokens, FACTORY.collateralTokens)
    -- assert notice
    assert.are.same({
      Action = "Approve-CollateralToken-Notice",
      IsApprove = "false",
      CollateralToken = collateralToken
    }, notice)
  end)

  it("should transfer tokens sent in error", function()
    local notice = {}
    -- should not throw an error
    local recipient = "test-this-is-valid-arweave-wallet-address-8"
    local quantity = "100"
    assert.has_no.errors(function()
      notice = FACTORY:transfer(
        collateralToken,
        recipient,
        quantity,
        msg
      )
    end)
    -- assert notice
    assert.are.same({
      Action = "Transfer-Notice",
      Token = collateralToken,
      Recipient = recipient,
      Quantity = quantity
    }, notice)
  end)
end)