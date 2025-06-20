require("luacov")
local marketFactory = require("marketFactoryModules.marketFactory")
local constants = require("marketFactoryModules.constants")
local json = require("json")

local sender = ""
local collateralToken = ""
local resolutionAgent = ""
local dataIndex = ""
local chatroom = ""
local question = ""
local outcomeSlotCount = ""
local creatorFee = ""
local creatorFeeTarget = ""

local msg = {}
local msgInfo = {}
local msgCreateMarketGroup = {}
local msgSpawnMarket = {}
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
    dataIndex = 'test-this-is-valid-arweave-wallet-address-3'
    chatroom = 'test-this-is-valid-arweave-wallet-address-4'
    question = 'test question'
    outcomeSlotCount = "2"
    creatorFee = "100"
    creatorFeeTarget = 'test-this-is-valid-arweave-wallet-address-5'
    -- create a market factory object
    FACTORY = marketFactory.new(
      constants.dev.configurator,
      constants.dev.veToken,
      constants.namePrefix,
      constants.tickerPrefix,
      constants.logo,
      constants.lpFee,
      constants.protocolFee,
      constants.dev.protocolFeeTarget,
      constants.maximumTakeFee,
      constants.dev.allowedCreators,
      constants.dev.listedCollateralTokens,
      constants.testCollateral,
      constants.maximumIterations
    )
    -- create a message object
    msg = {
      From = sender,
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
		msgInfo = {
      From = sender,
      reply = function(message) return message end
    }
    -- create a notice object
    msgCreateMarketGroup = {
      Target = marketFactory,
      From = sender,
      Tags = {
        ["Action"] = "Create-Market-Group",
        ["Collateral"] = collateralToken,
        ["DataIndex"] = dataIndex,
        ["Chatroom"] = chatroom,
        ["Question"] = question,
        ["Rules"] = "test rules",
        ["OutcomeSlotCount"] = outcomeSlotCount,
        ["CreatorFee"] = creatorFee,
        ["CreatorFeeTarget"] = creatorFeeTarget,
        ["Category"] = "test category",
        ["Subcategory"] = "test subcategory",
        ["Logo"] = "test logo"
      },
      Id =  "test-this-is-valid-arweave-wallet-address-6",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a notice object
    msgSpawnMarket = {
      Target = marketFactory,
      From = sender,
      Tags = {
        ["Action"] = "Spawn-Market",
        ["CollateralToken"] = collateralToken,
        ["ResolutionAgent"] = resolutionAgent,
        ["DataIndex"] = dataIndex,
        ["Chatroom"] = chatroom,
        ["Question"] = question,
        ["Rules"] = "test rules",
        ["OutcomeSlotCount"] = outcomeSlotCount,
        ["CreatorFee"] = creatorFee,
        ["CreatorFeeTarget"] = creatorFeeTarget,
        ["Category"] = "test category",
        ["Subcategory"] = "test subcategory",
        ["Logo"] = "test logo",
        ["Logos"] = {"test logo1", "test logo2"},
        ["EventId"] = ""
      },
      Id =  "test-this-is-valid-arweave-wallet-address-3",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- create a message object
    msgInitMarket = {
      From = sender,
      Tags = {
        Action = "Init-Market",
      },
      Id =  "test-this-is-valid-arweave-wallet-address-4",
      reply = function(message) return message end,
      forward = function(target, message) return message end
    }
    -- add collateral to listed collateral tokens
    FACTORY.listedCollateralTokens[collateralToken] = {
      name = "test",
      ticker = "TEST",
      denomination = 9
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
      Configurator = constants.dev.configurator,
      VeToken = constants.dev.veToken,
      LpFee = tostring(constants.lpFee),
      ProtocolFee = tostring(constants.protocolFee),
      ProtocolFeeTarget = constants.dev.protocolFeeTarget,
      MaximumTakeFee = tostring(constants.maximumTakeFee),
      AllowedCreators = json.encode(constants.dev.allowedCreators),
      ListedCollateralTokens = json.encode(constants.dev.listedCollateralTokens),
      TestCollateral = constants.testCollateral,
    }, info)
  end)

  it("should create an event", function()
    -- create a market group
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:createEvent(
        msgCreateMarketGroup.Tags["Collateral"],
        msgCreateMarketGroup.Tags["DataIndex"],
        msgCreateMarketGroup.Tags["Chatroom"],
        msgCreateMarketGroup.Tags["OutcomeSlotCount"],
        msgCreateMarketGroup.Tags["Question"],
        msgCreateMarketGroup.Tags["Rules"],
        msgCreateMarketGroup.Tags["Category"],
        msgCreateMarketGroup.Tags["Subcategory"],
        msgCreateMarketGroup.Tags["Logo"],
        "1741542323381", -- startTime
        "1741552323381", -- endTime
        msgCreateMarketGroup
      )
    end)
    -- assert notice
    assert.are.same({
      Action = "Create-Event-Notice",
      EventId = msgCreateMarketGroup.Id,
      Collateral = msgCreateMarketGroup.Tags["Collateral"],
      DataIndex = msgCreateMarketGroup.Tags["DataIndex"],
      Chatroom = msgCreateMarketGroup.Tags["Chatroom"],
      Creator = msgCreateMarketGroup.From,
      Question = msgCreateMarketGroup.Tags["Question"],
      Denomination = "9",
      OutcomeSlotCount = msgCreateMarketGroup.Tags["OutcomeSlotCount"],
      Rules = msgCreateMarketGroup.Tags["Rules"],
      Category = msgCreateMarketGroup.Tags["Category"],
      Subcategory = msgCreateMarketGroup.Tags["Subcategory"],
      Logo = msgCreateMarketGroup.Tags["Logo"],
      StartTime = "1741542323381",
      EndTime = "1741552323381"
    }, notice)
  end)

  it("should spawn a market", function()
    -- spawn a market
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:spawnMarket(
        msgSpawnMarket.Tags["CollateralToken"],
        msgSpawnMarket.Tags["ResolutionAgent"],
        msgSpawnMarket.Tags["DataIndex"],
        msgSpawnMarket.Tags["Chatroom"],
        msgSpawnMarket.Tags["OutcomeSlotCount"],
        msgSpawnMarket.Tags["Question"],
        msgSpawnMarket.Tags["Rules"],
        msgSpawnMarket.Tags["Category"],
        msgSpawnMarket.Tags["Subcategory"],
        msgSpawnMarket.Tags["Logo"],
        msgSpawnMarket.Tags["Logos"],
        msgSpawnMarket.Tags["EventId"],
        "1741542323381", -- startTime
        "1741552323381", -- endTime
        msgSpawnMarket.From,
        msgSpawnMarket.Tags["CreatorFee"],
        msgSpawnMarket.Tags["CreatorFeeTarget"],
        msgSpawnMarket
      )
    end)
    -- assert notice
    assert.are.same({
      Action = "Spawn-Market-Notice",
      ResolutionAgent = msgSpawnMarket.Tags["ResolutionAgent"],
      CollateralToken = msgSpawnMarket.Tags["CollateralToken"],
      DataIndex = msgSpawnMarket.Tags["DataIndex"],
      Chatroom = msgSpawnMarket.Tags["Chatroom"],
      Denomination = "9",
      OutcomeSlotCount = msgSpawnMarket.Tags["OutcomeSlotCount"],
      Question = msgSpawnMarket.Tags["Question"],
      Rules = msgSpawnMarket.Tags["Rules"],
      Category = msgSpawnMarket.Tags["Category"],
      Subcategory = msgSpawnMarket.Tags["Subcategory"],
      Logo = msgSpawnMarket.Tags["Logo"],
      Logos = json.encode(msgSpawnMarket.Tags["Logos"]),
      EventId = msgSpawnMarket.Tags["EventId"],
      StartTime = "1741542323381",
      EndTime = "1741552323381",
      Creator = msgSpawnMarket.From,
      CreatorFee = msgSpawnMarket.Tags["CreatorFee"],
      CreatorFeeTarget = msgSpawnMarket.Tags["CreatorFeeTarget"],
      ["Original-Msg-Id"] = msgSpawnMarket.Id
    }, notice)
  end)

  it("should init a market", function()
    local notice = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-5"
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    FACTORY.processToMessageMapping[mockProcessId] = msgSpawnMarket.Id
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
    local marketConfig = {
      creator = msgSpawnMarket.From,
      creatorFee = creatorFee,
      creatorFeeTarget = creatorFeeTarget,
      question = question,
      rules = "",
      outcomeSlotCount = outcomeSlotCount,
      collateralToken = collateralToken,
      resolutionAgent = resolutionAgent,
      dataIndex = dataIndex,
      chatroom = chatroom,
      category = "",
      subcategory = "",
      logo = "",
      eventId = ""
    }
    FACTORY.messageToMarketConfigMapping[msgSpawnMarket.Id] = marketConfig
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:initMarket(msgInitMarket)
    end)
    -- assert state change
    assert.are.same({}, FACTORY.marketsPendingInit)
    assert.are.same({mockProcessId}, FACTORY.marketsInit)
    assert.are.same({mockProcessId}, FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From])
    -- assert notice
    assert.are.same({
      Action = "Init-Market-Notice",
      Data = json.encode({mockProcessId})
    }, notice)
  end)

  it("should get markets pending", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
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
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    FACTORY.processToMessageMapping[mockProcessId] = msgSpawnMarket.Id
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
    local marketConfig = {
      creator = msgSpawnMarket.From,
      creatorFee = creatorFee,
      creatorFeeTarget = creatorFeeTarget,
      question = question,
      rules = "",
      outcomeSlotCount = outcomeSlotCount,
      collateralToken = collateralToken,
      resolutionAgent = resolutionAgent,
      dataIndex = dataIndex,
      category = "",
      subcategory = "",
      logo = "",
      eventId = ""
    }
    FACTORY.messageToMarketConfigMapping[msgSpawnMarket.Id] = marketConfig
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

  it("should get events by creator", function()
    FACTORY:createEvent(
      msgCreateMarketGroup.Tags["Collateral"],
      msgCreateMarketGroup.Tags["DataIndex"],
      msgCreateMarketGroup.Tags["Chatroom"],
      msgCreateMarketGroup.Tags["OutcomeSlotCount"],
      msgCreateMarketGroup.Tags["Question"],
      msgCreateMarketGroup.Tags["Rules"],
      msgCreateMarketGroup.Tags["Category"],
      msgCreateMarketGroup.Tags["Subcategory"],
      msgCreateMarketGroup.Tags["Logo"],
      "1741542323381", -- startTime
      "1741552323381", -- endTime
      msgCreateMarketGroup
    )
    local msgReply = {}
    -- should not throw an error
    msg.Tags = {}
    msg.Tags.Creator = msgCreateMarketGroup.From
    assert.has_no.errors(function()
      msgReply = FACTORY:eventsByCreator(msg)
    end)
    -- assert reply
    local expectedResponse = {}
    expectedResponse[msgCreateMarketGroup.Id] = {}
    expectedResponse[msgCreateMarketGroup.Id].collateral = msgCreateMarketGroup.Tags.Collateral
    expectedResponse[msgCreateMarketGroup.Id].outcomeSlotCount = msgCreateMarketGroup.Tags.OutcomeSlotCount
    assert.are.same(json.encode(expectedResponse), msgReply.Data)
  end)

  it("should get markets by creator", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags.Creator = msgSpawnMarket.From
    assert.has_no.errors(function()
      msgReply = FACTORY:marketsByCreator(msg)
    end)
    -- assert state change
    assert.are.same({mockProcessId}, FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From])
    -- assert reply
    assert.are.same(mockProcessId, json.decode(msgReply.Data)[1])
  end)

  it("should get process ID using original msg ID", function()
    local msgReply = {}
    -- should mock the state change of a spawned market
    local mockProcessId = "test-this-is-valid-arweave-wallet-address-3"
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags["Original-Msg-Id"] = msgSpawnMarket.Id
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
    FACTORY.messageToProcessMapping[msgSpawnMarket.Id] = mockProcessId
    table.insert(FACTORY.marketsPendingInit, mockProcessId)
    FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From] = {}
    table.insert(FACTORY.marketsSpawnedByCreator[msgSpawnMarket.From], mockProcessId)
    -- should not throw an error
    msg.Tags = {}
    msg.Tags.Creator = msgSpawnMarket.From
    assert.has_no.errors(function()
      msgReply = FACTORY:getLatestProcessIdForCreator(msg)
    end)
    -- assert reply
    assert.are.same(mockProcessId, msgReply.Data)
  end)

  it("should allow creator", function()
    FACTORY.allowedCreators = {}
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:allowCreator(
        msgSpawnMarket.From,
        msg
      )
    end)
    -- assert state change
    local updatedCreators = {}
    updatedCreators[msgSpawnMarket.From] = true

    assert.are.same(updatedCreators, FACTORY.allowedCreators)
    -- assert notice
    assert.are.same({
      Action = "Allow-Creator-Notice",
      Data = msgSpawnMarket.From
    }, notice)
  end)

  it("should unapprove creator", function()
    FACTORY.allowedCreators = {}
    local notice = {}
    -- should not throw an error
    FACTORY:allowCreator(
      msgSpawnMarket.From,
      msg
    )
    assert.has_no.errors(function()
      notice = FACTORY:disallowCreator(
        msgSpawnMarket.From,
        msg
      )
    end)
    -- assert state change
    assert.are.same(constants.collateralTokens, FACTORY.collateralTokens)
    -- assert notice
    assert.are.same({
      Action = "Disallow-Creator-Notice",
      Data = msgSpawnMarket.From
    }, notice)
  end)

  it("should propose configurator", function()
    local notice = {}
    -- should not throw an error
    local newConfigurator = "test-this-is-valid-arweave-wallet-address-4"
    assert.has_no.errors(function()
      notice = FACTORY:proposeConfigurator(
        newConfigurator,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newConfigurator, FACTORY.proposedConfigurator)
    -- assert notice
    assert.are.same({
      Action = "Propose-Configurator-Notice",
      Data = newConfigurator
    }, notice)
  end)

  it("should accept configurator", function()
    local notice = {}
    -- should not throw an error
    local proposedConfigurator = "test-this-is-valid-arweave-wallet-address-4"
    assert.has_no.errors(function()
      notice = FACTORY:proposeConfigurator(
        proposedConfigurator,
        msg
      )
    end)
    -- assert state change
    assert.are.same(proposedConfigurator, FACTORY.proposedConfigurator)
    -- assert notice
    assert.are.same({
      Action = "Propose-Configurator-Notice",
      Data = proposedConfigurator
    }, notice)
    -- should not throw an error from proposed configurator
    msg.From = proposedConfigurator
    assert.has_no.errors(function()
      notice = FACTORY:acceptConfigurator(
        msg
      )
    end)
    -- assert state change
    assert.are.same(proposedConfigurator, FACTORY.configurator)
    assert.are.same(nil, FACTORY.proposedConfigurator)
    -- assert notice
    assert.are.same({
      Action = "Accept-Configurator-Notice",
      Data = proposedConfigurator
    }, notice)
  end)

  -- it("should update configurator", function()
  --   local notice = {}
  --   -- should not throw an error
  --   local newConfigurator = "test-this-is-valid-arweave-wallet-address-4"
  --   assert.has_no.errors(function()
  --     notice = FACTORY:updateConfigurator(
  --       newConfigurator,
  --       msg
  --     )
  --   end)
  --   -- assert state change
  --   assert.are.same(newConfigurator, FACTORY.configurator)
  --   -- assert notice
  --   assert.are.same({
  --     Action = "Update-Configurator-Notice",
  --     Data = newConfigurator
  --   }, notice)
  -- end)

  it("should update veToken", function()
    local notice = {}
    -- should not throw an error
    local newVeToken = "test-this-is-valid-arweave-wallet-address-4"
    assert.has_no.errors(function()
      notice = FACTORY:updateVeToken(
        newVeToken,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newVeToken, FACTORY.veToken)
    -- assert notice
    assert.are.same({
      Action = "Update-Ve-Token-Notice",
      Data = newVeToken
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
      Action = "Update-Lp-Fee-Notice",
      Data = newLpFee
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
      Action = "Update-Protocol-Fee-Notice",
      Data = newProtocolFee
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
      Action = "Update-Protocol-Fee-Target-Notice",
      Data = newProtocolFeeTarget
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
      Action = "Update-Maximum-Take-Fee-Notice",
      Data = newMaximumTakeFee
    }, notice)
  end)

  it("should update maximumIterations", function()
    local notice = {}
    -- should not throw an error
    local newMaximumIterations = 101
    assert.has_no.errors(function()
      notice = FACTORY:updateMaximumIterations(
        newMaximumIterations,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newMaximumIterations, FACTORY.maximumIterations)
    -- assert notice
    assert.are.same({
      Action = "Update-Maximum-Iterations-Notice",
      Data = tostring(newMaximumIterations)
    }, notice)
  end)

  it("should update market process code", function()
    local notice = {}
    -- should not throw an error
    local newMarketProcessCode = "print('hello world')"
    assert.has_no.errors(function()
      notice = FACTORY:updateMarketProcessCode(
        newMarketProcessCode,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newMarketProcessCode, FACTORY.marketProcessCode)
    -- assert notice
    assert.are.same({
      Action = "Update-Market-Process-Code-Notice",
      Data = "Successfully updated market process code"
    }, notice)
  end)

  it("should list collateral token", function()
    -- reset collateralToken registerd state to nil
    FACTORY.listedCollateralTokens[collateralToken] = nil
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:listCollateralToken(
        collateralToken,
        "Test",
        "TEST",
        12,
        msg
      )
    end)
    -- assert state change
    assert.are.same("Test", FACTORY.listedCollateralTokens[collateralToken].name)
    assert.are.same("TEST", FACTORY.listedCollateralTokens[collateralToken].ticker)
    assert.are.same(12, FACTORY.listedCollateralTokens[collateralToken].denomination)
    -- assert notice
    assert.are.same({
      Action = "List-Collateral-Token-Notice",
      Name = "Test",
      Ticker = "TEST",
      Denomination = "12",
      CollateralToken = collateralToken
    }, notice)
  end)

  it("should delist collateral token", function()
    -- reset collateralToken registerd state to nil
    FACTORY.listedCollateralTokens[collateralToken] = {
      name = "test",
      ticker = "TEST",
      denomination = 9
    }
    local notice = {}
    -- should not throw an error
    assert.has_no.errors(function()
      notice = FACTORY:delistCollateralToken(
        collateralToken,
        msg
      )
    end)
    -- assert state change
    assert.are.same(nil, FACTORY.listedCollateralTokens[collateralToken])
    -- assert notice
    assert.are.same({
      Action = "Delist-Collateral-Token-Notice",
      CollateralToken = collateralToken
    }, notice)
  end)

  it("should update market process code", function()
    local notice = {}
    -- should not throw an error
    local newMarketProcessCode = "print('hello world')"
    assert.has_no.errors(function()
      notice = FACTORY:updateMarketProcessCode(
        newMarketProcessCode,
        msg
      )
    end)
    -- assert state change
    assert.are.same(newMarketProcessCode, FACTORY.marketProcessCode)
    -- assert notice
    assert.are.same({
      Action = "Update-Market-Process-Code-Notice",
      Data = "Successfully updated market process code"
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