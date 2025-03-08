local Outcome = require("outcome")
local json = require("json")

local successCount = 0
local failCount = 0
local failedTests = {}
local coinBurner = "tPaIyq3VcpUdrYorOyH90aUbRo4x1Cv2S9DW-chowog"

--[[
=======
HELPERS
=======
]]

--- Retry helper function
local function retry(fn, retries, ...)
  local lastError = nil
  for attempt = 1, retries do
    local result, errorMsg = fn(...)
    if result then return result end
    lastError = errorMsg or "Unknown error"
    print("🔄 Attempt " .. tostring(attempt) .. "/" .. tostring(retries) .. " failed. Retrying...")
  end
  return nil, lastError
end

local function assertNotNil(value, message)
  if not value then
    error(message or "Assertion failed: value is nil")
  end
end

-- Tries to get process ID
--- @notice ProcessId is expected to be a non-empty string
local function tryGetProcessId(originalMsgId)
  local res = Outcome.marketFactoryGetProcessId(originalMsgId)
  -- Check if ProcessId is nil or an empty string
  if not res or not res.ProcessId or res.ProcessId:match("^%s*$") then
    return nil, "ProcessId is nil"
  end
  return res
end

--- Tries to init market
--- @notice tries to get process ID first, then initializes the market
local function tryInitMarket(originalMsgId)
  retry(tryGetProcessId, 20, originalMsgId)
  local res = Outcome.marketFactoryInitMarket()
  if not res or not res.MarketProcessIds or #res.MarketProcessIds == 0 then
    return nil, "MarketProcessIds is nil or empty"
  end
  return res
end

--- Tries to get expected balance
--- @notice Balance is expected to be a non-empty string
local function tryGetBalance(token, expectedBalance)
  local res = Outcome.tokenBalance(token)
  if not res or res.Balance ~= expectedBalance then
    print("res.Balance: " .. tostring(res.Balance))
    print("expectedBalance: " .. tostring(expectedBalance))
    return nil, "Balance is nil or does not match expected value"
  end
  return res
end

--- Tries to get expected position balance
--- @notice Balance is expected to be a non-empty string
local function tryGetPositionBalance(market, id, expectedBalance)
  local res = Outcome.marketPositionBalance(market, id)
  if not res or res.Balance ~= expectedBalance then
    return nil, "Balance is nil or does not match expected value"
  end
  return res
end

-- Logs test result
local function logTestResult(testName, isSuccess, msgId)
  local status = isSuccess and "✅ Success" or "❌ Failed"
  if isSuccess then
    successCount = successCount + 1
  else
    failCount = failCount + 1
    table.insert(failedTests, testName)
  end
  print(status .. " (msgId: " .. msgId .. ")\n")
end

--- Creates a market
local function createMarket(outcomeSlotCount)
  -- Create position token logos
  local logos = {}
  for i = 1, outcomeSlotCount do
    table.insert(logos, "Logo_TxID" .. tostring(i))
  end
  -- Spawn market
  local res1 = Outcome.marketFactorySpawnMarket(
    Outcome.testCollateral,
    ao.id, -- resolution agent
    ao.id, -- data index
    outcomeSlotCount,
    "What will happen?", -- question
    "How we will know", -- rules
    "Category",
    "Subcategory",
    "Logo_TxID", -- LP token logo
    logos, -- position token logos
    "", -- eventId (empty string to signify stand-alone market)
    250, -- creator fee (in basis points)
    coinBurner -- creator fee target (to use a valid Arweave address)
  )
  assertNotNil(res1["Original-Msg-Id"], "Market spawn failed: Original-Msg-Id is nil")

  local res2, error2 = tryInitMarket(res1["Original-Msg-Id"])
  assertNotNil(res2, "Market initialization failed: " .. (error2 or "Unknown error"))

  local res3, error3 = tryGetProcessId(res1["Original-Msg-Id"])
  assertNotNil(res3, "Market process ID retrieval failed: " .. (error3 or "Unknown error"))

  return res3 and res3 or nil
end

--- Checks if balance is updated
local function getBalance(token, expectedBalance)
  local res = retry(tryGetBalance, 20, token, expectedBalance)
  return res and res or nil
end

--- Checks if position balance is updated
local function getPositionBalance(market, id, expectedBalance)
  local res = retry(tryGetPositionBalance, 20, market, id, expectedBalance)
  return res and res or nil
end

--[[
=====
TESTS
=====
]]

local function runTests()
  local testName, res, collateralBalance, lpBalance, positionBalance, binaryMarket

  print("🚀 STARTING TESTS\n")

  testName = "Mint Test Collateral"
  print("➤ " .. testName)
  local mintQuantity = "1000000000000000"
  res = Outcome.tokenMint(Outcome.testCollateral, mintQuantity)
  logTestResult(testName, res.Quantity~=nil, res.MessageId or "Unknown")

  testName = "Get Balance of Test Collateral"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(Outcome.testCollateral)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance~=nil,
    res and res.MessageId or "Unknown"
  )
  -- Save collateral balance
  collateralBalance = res.Balance

  testName = "Create Binary Market"
  print("➤ " .. testName)
  res = createMarket(2)
  logTestResult(
    testName,
    res ~= nil and res.ProcessId~=nil,
    res and res.MessageId or "Unknown"
  )
  binaryMarket = res and res.ProcessId or nil
  -- binaryMarket = "qr5PScIzm5deZ0RWyVO1lSO5SdNIodbDlTPSR7xJgqw"
  print("binaryMarket: " .. tostring(binaryMarket))

  -- testName = "Create Categorical Market"
  -- print("➤ " .. testName)
  -- res = createMarket(3)
  -- logTestResult(
  --   testName,
  --   res ~= nil and res.ProcessId~=nil,
  --   res and res.MessageId or "Unknown"
  -- )
  -- local categoricalMarket = res and res.ProcessId or nil

  -- testName = "Create Large Categorical Market"
  -- print("➤ " .. testName)
  -- res = createMarket(256)
  -- logTestResult(
  --   testName,
  --   res ~= nil and res.ProcessId~=nil,
  --   res and res.MessageId or "Unknown"
  -- )
  -- local largeCategoricalMarket = res and res.ProcessId or nil

  if not binaryMarket then
    error("Binary market creation failed")
  end

  testName = "Get Info from Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketInfo(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Question~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Binary Market Position Token Balance Initially Zero"
  print("➤ " .. testName)
  positionBalance = "0"
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )
  -- @dev This is to exit early if the position balance is not zero
  assert(res and res.Balance==positionBalance, "Position balance is not zero")

  testName = "Add Initial Funding to Binary Market"
  print("➤ " .. testName)
  local distribution = {70, 30}
  local fundingAmount = "100000000000000"
  res = Outcome.marketAddFunding(
    binaryMarket,
    Outcome.testCollateral,
    fundingAmount,
    distribution
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) - tonumber(fundingAmount))
  -- Update LP balance
  lpBalance = fundingAmount

  testName = "Collateral Balance Decreased After Adding Funding"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(Outcome.testCollateral)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "LP Balance Increased After Add Funding"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==lpBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Attempt to Add Additional Funding with Distribution"
  print("➤ " .. testName)
  res = Outcome.marketAddFunding(
    binaryMarket,
    Outcome.testCollateral,
    fundingAmount,
    distribution
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Notice",
    res and res.MessageId or "Unknown"
  )

  testName = "Collateral Balance Unchanged After Add Funding Error"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "LP Balance Unchanged After Adding Funding Error"
  print("➤ " .. testName)
  res = getBalance(binaryMarket, lpBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==lpBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Add Additional Funding to Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketAddFunding(
    binaryMarket,
    Outcome.testCollateral,
    fundingAmount,
    nil
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) - tonumber(fundingAmount))
  -- Update LP balance
  lpBalance = tostring(tonumber(lpBalance) + tonumber(fundingAmount))

  testName = "Collateral Balance Decreased After Additional Add Funding"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(Outcome.testCollateral)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "LP Balance Increased After Additional Add Funding"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==lpBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Remove Funding from Binary Market"
  print("➤ " .. testName)
  local sharesToBurn = "10000000000000"
  res = Outcome.marketRemoveFunding(
    binaryMarket,
    sharesToBurn
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Remove-Funding-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update LP balance
  lpBalance = tostring(tonumber(lpBalance) - tonumber(sharesToBurn))
  -- Update position balance
  positionBalance = tostring(tonumber(positionBalance) + tonumber(sharesToBurn))

  testName = "LP Balance Decreased After Remove Funding"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==lpBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Position Balance Increased After Remove Funding"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Collected Fees for Binary Market Zero Before Trading"
  print("➤ " .. testName)
  res = Outcome.marketCollectedFees(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.CollectedFees=="0",
    res and res.MessageId or "Unknown"
  )

  testName = "Fees Withdrawable for LP of Binary Market Zero Before Trading"
  print("➤ " .. testName)
  res = Outcome.marketFeesWithdrawable(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.FeesWithdrawable=="0",
    res and res.MessageId or "Unknown"
  )

  testName = "Calc buy amount from Binary Market"
  print("➤ " .. testName)
  local investmentAmount = "10000000000000"
  local positionId = "1"
  res = Outcome.marketCalcBuyAmount(
    binaryMarket,
    investmentAmount,
    positionId
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.InvestmentAmount==investmentAmount,
    res and res.MessageId or "Unknown"
  )
  local buyAmount = res.BuyAmount

  testName = "Buy from Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketBuy(
    binaryMarket,
    Outcome.testCollateral,
    investmentAmount,
    positionId,
    buyAmount
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance, accounting for 1% LP fee
  positionBalance = tostring(tonumber(positionBalance) + tonumber(buyAmount))
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) - tonumber(investmentAmount))

  testName = "Binary Market Position Token Balance Increased After Buy"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Collateral Balance Decreased After Buy"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Collected Fees for Binary Market Non-Zero After Trading"
  print("➤ " .. testName)
  res = Outcome.marketCollectedFees(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.CollectedFees~="0",
    res and res.MessageId or "Unknown"
  )

  testName = "Fees Withdrawable for LP of Binary Market Non-Zero After Trading"
  print("➤ " .. testName)
  res = Outcome.marketFeesWithdrawable(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.FeesWithdrawable~="0",
    res and res.MessageId or "Unknown"
  )

  testName = "Calc sell amount from Binary Market"
  print("➤ " .. testName)
  local returnAmount = "1000000000000"
  res = Outcome.marketCalcSellAmount(
    binaryMarket,
    returnAmount,
    positionId
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.ReturnAmount==returnAmount,
    res and res.MessageId or "Unknown"
  )
  local sellAmount = res.SellAmount

  testName =  "Sell from Binary Market"
  print("➤ " .. testName)
  local maxPositionTokensToSell = sellAmount
  res = Outcome.marketSell(
    binaryMarket,
    returnAmount,
    positionId,
    maxPositionTokensToSell
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Sell-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance
  positionBalance = tostring(tonumber(positionBalance) - tonumber(sellAmount))
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) + tonumber(returnAmount))

  testName = "Binary Market Position Token Balance Changed After Sell"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Collateral Balance Increased After Sell"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Withdraw fees from Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketWithdrawFees(
    binaryMarket
  )
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Withdraw-Fees-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) + tonumber(res.FeeAmount))

  testName = "Collateral Balance Increased After Withdraw Fees"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Info from Binary Market LP Token"
  print("➤ " .. testName)
  res = Outcome.tokenInfo(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Ticker~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Balance from Binary Market LP Token Holder"
  print("➤ " .. testName)
  res = Outcome.tokenBalance(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Balances from Binary Market LP Token"
  print("➤ " .. testName)
  res = Outcome.tokenBalances(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balances~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Total Supply from Binary Market LP Token"
  print("➤ " .. testName)
  res = Outcome.tokenTotalSupply(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.TotalSupply~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Transfer Binary Market LP Token"
  print("➤ " .. testName)
  local transferQuantity = "1000000000000"
  res = Outcome.tokenTransfer(transferQuantity, coinBurner, binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update balance
  lpBalance = tostring(tonumber(lpBalance) - tonumber(transferQuantity))

  testName = "Binary Market LP Token Balance Changed After Transfer"
  print("➤ " .. testName)
  res = getBalance(binaryMarket, lpBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==lpBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Postion Balance from Binary Market Holder"
  print("➤ " .. testName)
  res = Outcome.marketPositionBalance(binaryMarket, "1")
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Postion Balances from Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketPositionBalances(binaryMarket, "1")
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balances~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Postion Batch Balance from Binary Market Holders"
  print("➤ " .. testName)
  res = Outcome.marketPositionBatchBalance(binaryMarket, {"1"}, {ao.id})
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balances~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Postion Batch Balances from Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketPositionBatchBalances(binaryMarket, {"1"})
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balances~=nil,
    res and res.MessageId or "Unknown"
  )

  testName = "Transfer Position Tokens for Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketPositionTransfer(binaryMarket, transferQuantity, "1", coinBurner)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Single-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance
  positionBalance = tostring(tonumber(positionBalance) - tonumber(transferQuantity))

  testName = "Binary Market Position Token Balance Decreased After Transfer"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Transfer Batch Position Tokens for Binary Market"
  print("➤ " .. testName)
  res = Outcome.marketPositionTransferBatch(binaryMarket, {transferQuantity}, {"1"}, coinBurner)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Debit-Batch-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance
  positionBalance = tostring(tonumber(positionBalance) - tonumber(transferQuantity))

  testName = "Binary Market Batch Position Token Balance Decreased After Transfer Batch"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Merge Positions from Binary Market back to Collateral"
  print("➤ " .. testName)
  local mergeQuantity = "1000000000000"
  res = Outcome.marketMergePositions(binaryMarket, mergeQuantity)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Merge-Positions-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance
  positionBalance = tostring(tonumber(positionBalance) - tonumber(mergeQuantity))
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) + tonumber(mergeQuantity))

  testName = "Get Collateral Balance After Merge"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Binary Market Batch Position Token Balance Changed After Merge"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Get Payout Numerators of Unresolved Binary Market"
  print("➤ " .. testName)
  res =  Outcome.marketGetPayoutNumerators(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and json.encode(res.PayoutNumerators)==json.encode({0,0}),
    res and res.MessageId or "Unknown"
  )

  testName = "Get Payout Denominator of Unresolved Binary Market"
  print("➤ " .. testName)
  res =  Outcome.marketGetPayoutDenominator(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.PayoutDenominator==0,
    res and res.MessageId or "Unknown"
  )

  testName = "Report Payouts of Binary Market"
  print("➤ " .. testName)
  local payouts = {1,0}
  res = Outcome.marketReportPayouts(binaryMarket, payouts)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Report-Payouts-Notice",
    res and res.MessageId or "Unknown"
  )

  testName = "Get Payout Numerators of Resolved Binary Market"
  print("➤ " .. testName)
  res =  Outcome.marketGetPayoutNumerators(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and json.encode(res.PayoutNumerators)==json.encode(payouts),
    res and res.MessageId or "Unknown"
  )

  testName = "Get Payout Denominator of Resolved Binary Market"
  print("➤ " .. testName)
  res =  Outcome.marketGetPayoutDenominator(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.PayoutDenominator==1,
    res and res.MessageId or "Unknown"
  )

  testName = "Redeem Positions from Market"
  res =  Outcome.marketRedeemPositions(binaryMarket)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Action=="Redeem-Positions-Notice",
    res and res.MessageId or "Unknown"
  )
  -- Update position balance
  positionBalance = "0"
  -- Update collateral balance
  collateralBalance = tostring(tonumber(collateralBalance) + tonumber(res.NetPayout))

  testName = "Position Balance Zero After Redeem Positions"
  print("➤ " .. testName)
  res = getPositionBalance(binaryMarket, "1", positionBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==positionBalance,
    res and res.MessageId or "Unknown"
  )

  testName = "Collateral Balance Increased Redeem Positions"
  print("➤ " .. testName)
  res = getBalance(Outcome.testCollateral, collateralBalance)
  logTestResult(
    testName,
    res ~= nil and res.Error==nil and res.Balance==collateralBalance,
    res and res.MessageId or "Unknown"
  )

  -- testName = "Unable to Buy from Resolved Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Unable to Sell from Resolved Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Unable to Add Funding to Resolved Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Update Configurator for Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Update Incentives for Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Update Take Fee for Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Update Protocol Fee Target for Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  -- testName = "Update Logo for Binary Market"
  -- print("➤ " .. testName)
  -- print("🔧 TODO\n")

  print("🏁 TESTS COMPLETE")
  print("Total Success: " .. successCount .. " | Total Failed: " .. failCount)
  if failCount > 0 then
    print("\n❌ Failed Tests:")
    for _, failMessage in ipairs(failedTests) do
      print("- " .. failMessage)
    end
  end
end

runTests()
