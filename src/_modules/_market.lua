

local ao = require('ao')
local json = require('json')
local utils = require('.utils')
local crypto = require('.crypto')
local bint = require('.bint')(256)

Protocol = Protocol or {
-- Protocol = {
  _version = "1.0.0",
  process = "uUAK8YPT-kFexyYk56CKNlRJZWKBRjpUPQRUX6xk8_I",
  -- Change Owner on deployment
  Owner = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  -- Change Oracle on deployment
  Oracle = "XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I",
  Name = "Outcome Prediction Points",
  Ticker = "PRED",
  Denomination = 10,
  Logo = "TXID of logo image",
  Markets = {},
  Balances = {
    -- process:    0 tokens
    [ao.id] = "0",
    -- alice:   1000 tokens
    ["XkVOo16KMIHK-zqlR67cuNY0ayXIkPWODWw_HXAE20I"] = tostring(bint(10000000000000)),
    -- bob:     1000 tokens
    ["m6W6wreOSejTb2WRHoALM6M7mw3H8D2KmFVBYC1l0O0"] = tostring(bint(10000000000000))
  },
  Categories = {"ao", "games", "defi", "memes", "business", "technology"},
  WagerBalances = {
    ["ao"] = {},
    ["games"] = {},
    ["defi"] = {},
    ["memes"] = {},
    ["business"] = {},
    ["technology"] = {}
  },
  WinRatios = {
    ["ao"] = {},
    ["games"] = {},
    ["defi"] = {},
    ["memes"] = {},
    ["business"] = {},
    ["technology"] = {}
  },
  LastClaimDay = {},
}

-- LastNotice moved outside of protocol as unable to update Protocol variables safely while in production
if not LastNotice then LastNotice = {} end

--[[
    Outcome DB
  ]]
--
if not OutcomeDB then OutcomeDB = "GCpCoN1OIzyDHUr7xlqgBYgrqehmh8LGIMVYI6-s1kU" end

--[[
     Local variables and functions to limit daily Token Claims
   ]]
--

-- Constants for time calculations
local SECONDS_PER_DAY = 86400  -- Number of seconds in a day
local MS_PER_DAY = SECONDS_PER_DAY * 1000  -- Number of milliseconds in a day

-- Function to get day count from epoch
local function getDayCountFromTimestamp(timestamp_ms)
    return tostring(math.floor(timestamp_ms / MS_PER_DAY))
end

--[[
    Utils
  ]]
--
local function hash_url(url)
  local stream = crypto.utils.stream.fromString(url)
  return crypto.digest.sha2_256(stream).asHex()
end


--[[
     Methods for each of the core components of the Protocol Specificaiton
   ]]
--

--[[
     TOKEN
   ]]
--

--[[
     Info  
   ]]
--
-- @dev Returns the info about the token.
local function info(msg)
  ao.send({
    Target = msg.From,
    Name = Protocol.Name,
    Ticker = Protocol.Ticker,
    Denomination = tostring(Protocol.Denomination),
    Logo = Protocol.Logo,
    Owner = tostring(Protocol.Owner),
  })
end

--[[
     Total Supply
   ]]
--
-- @dev Returns the quantity of tokens in existence.
local function totalSupply(msg)
  local totalSupply_ = utils.reduce(
    function (acc, v) return acc + v end,
    0,
    bint(utils.values(Protocol.Balances))
  )

  ao.send({
    Target = msg.From,
    TotalSupply = string.format("%.i", totalSupply_),
    Data = totalSupply_
  })
end

--[[
     Balance  
   ]]
--
-- @dev Returns the quantity of tokens owned by `msg.From` or `msg.Target`, if provided.
local function balance(msg)
  local bal = '0'

  -- If not Target is provided, then return the Senders balance
  if (msg.Tags.Target and Protocol.Balances[msg.Tags.Target]) then
    bal = Protocol.Balances[msg.Tags.Target]
  elseif Protocol.Balances[msg.From] then
    bal = Protocol.Balances[msg.From]
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = Protocol.Ticker,
    Account = msg.Tags.Target or msg.From,
    Data = bal
  })
end

--[[
     Balances 
   ]]
--
-- @dev Returns the quantity of tokens owned by all participants.
local function balances(msg)
  ao.send({ Target = msg.From, Data = json.encode(Protocol.Balances) })
end

--[[
     WagerBalance  
   ]]
--
-- @dev Returns the quantity of tokens wagered by `msg.From` or `msg.Target`, if provided.
local function wagerBalance(msg)
  local bal = ''
  local bals = {}

  -- If not Target is provided, then return the Senders balance
  if (msg.Tags.Target) then
    for i = 1, #Protocol.Categories do
      local category = Protocol.Categories[i]
      local wagerBalance_ = Protocol.WagerBalances[category][msg.Tags.Target] or 0
      bals[category] = wagerBalance_
    end
  else
    for i = 1, #Protocol.Categories do
      local category = Protocol.Categories[i]
      local wagerBalance_ = Protocol.WagerBalances[category][msg.From] or 0
      bals[category] = wagerBalance_
    end
  end

  bal = utils.reduce(
    function (acc, v) return acc + v end,
    0,
    bint(utils.values(bals))
  )

  ao.send({
    Target = msg.From,
    Categories = json.encode(Protocol.Categories),
    Raw = json.encode(Protocol.WagerBalances),
    WagerBalance = tostring(bal),
    WagerBalances = json.encode(bals),
    Ticker = Protocol.Ticker,
    Account = msg.Tags.Target or msg.From,
    Data = tonumber(bal)
  })
end

--[[
     Wager Balances 
   ]]
--
-- @dev Returns the quantity of tokens wagered by all participants by category.
local function wagerBalances(msg)
  ao.send({ Target = msg.From, Data = json.encode(Protocol.WagerBalances) })
end

--[[
     WinRatio  
   ]]
--
-- @dev Returns the win ratio of `msg.From` or `msg.Target`, if provided.
local function winRatio(msg)
  local ratio = 0
  local ratios = {}
  local wins = {}
  local games = {}

  -- If not Target is provided, then return the Senders win ratio
  if (msg.Tags.Target) then
    for i = 1, #Protocol.Categories do
      local category = Protocol.Categories[i]
      local numWins = Protocol.WinRatios[category][msg.Tags.Target] and Protocol.WinRatios[category][msg.Tags.Target]["wins"] or 0
      local numGames = Protocol.WinRatios[category][msg.Tags.Target] and Protocol.WinRatios[category][msg.Tags.Target]["games"] or 0
      local winRatio_ = Protocol.WinRatios[category][msg.Tags.Target] and Protocol.WinRatios[category][msg.Tags.Target]["ratio"] or 0
      wins[category] = numWins
      games[category] = numGames
      ratios[category] = winRatio_
    end
  else
    for i = 1, #Protocol.Categories do
      local category = Protocol.Categories[i]
      local numWins = Protocol.WinRatios[category][msg.From] and Protocol.WinRatios[category][msg.From]["wins"] or 0
      local numGames = Protocol.WinRatios[category][msg.From] and Protocol.WinRatios[category][msg.From]["games"] or 0
      local winRatio_ = Protocol.WinRatios[category][msg.From] and Protocol.WinRatios[category][msg.From]["ratio"] or 0
      wins[category] = numWins
      games[category] = numGames
      ratios[category] = winRatio_
    end
  end

  local totalWins = utils.reduce(
    function (acc, v) return acc + v end,
    0,
    bint(utils.values(wins))
  )

  local totalGames = utils.reduce(
    function (acc, v) return acc + v end,
    0,
    bint(utils.values(games))
  )

  if (totalGames ~= 0) then
    ratio = bint.__div(tostring(totalWins), tostring(totalGames))
  end

  ao.send({
    Target = msg.From,
    WinRatio = tostring(ratio),
    WinRatios = json.encode(ratios),
    Account = msg.Tags.Target or msg.From,
    Data = tonumber(ratio)
  })
end

--[[
     WinRatios
   ]]
--
-- @dev Returns the win ratios of all participants by category.
local function winRatios(msg)
  ao.send({ Target = msg.From, Data = json.encode(Protocol.WinRatios) })
end

--[[
     Market 
   ]]
--
-- @dev Returns data for a given market.
local function market(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(Protocol.Markets[msg.Tags.Condition], 'Market not found!')

  ao.send({ Target = msg.From, Data = json.encode(Protocol.Markets[msg.Tags.Condition]) })
end

--[[
     Markets 
   ]]
--
-- @dev Returns data for all markets.
local function markets(msg)
  ao.send({ Target = msg.From, Data = json.encode(Protocol.Markets) })
end

--[[
     Claim 
   ]]
--
-- @dev Increases the balance of the sender. Callable once a day.
local function claim(msg)
  local claimAmount = 10000000000000 -- 1000 tokens
  local dayCount = getDayCountFromTimestamp(msg.Timestamp)

  if not Protocol.Balances[msg.From] then Protocol.Balances[msg.From] = "0" end
  if not Protocol.LastClaimDay[msg.From] then Protocol.LastClaimDay[msg.From] = "0" end

  -- Update DB Data
  local user = {}
  user['id'] = msg.From

  if (dayCount == Protocol.LastClaimDay[msg.From]) then
    user['updateType'] = "activity"
    ao.send({
      Target = msg.From,
      Data = "You have already claimed your tokens today."
    })
  else
    user['updateType'] = "claim"
    user['lastClaimDay'] = dayCount

    -- Update last day claimed
    Protocol.LastClaimDay[msg.From] = dayCount

    local balance_ = tostring(bint.__add(Protocol.Balances[msg.From], claimAmount))
    Protocol.Balances[msg.From] = balance_

    -- Send notice
    ao.send({
      Target = msg.From,
      Action = 'Claim-Notice',
      Process = ao.id,
      Balance = tostring(Protocol.Balances[msg.From]),
      Data = "Your balance has increased by " .. tostring(claimAmount) .. " tokens."
    })
  end

  -- Update DB
  ao.send({
    Target = OutcomeDB,
    Action = 'User-Ingest',
    Data = json.encode(user)
  })
end

--[[
     Last Claim 
   ]]
--
-- @dev Returns the last claim day of the msg.Sender or Target
local function lastClaim(msg)
  local dayCount = "0"

-- If not Target is provided, then return the Senders balance
  if (msg.Tags.Target and Protocol.LastClaimDay[msg.Tags.Target]) then
    dayCount = Protocol.LastClaimDay[msg.Tags.Target]
  elseif Protocol.LastClaimDay[msg.From] then
    dayCount = Protocol.LastClaimDay[msg.From]
  end

  ao.send({
    Target = msg.From,
    LastClaim = dayCount,
    Account = msg.Tags.Target or msg.From,
    Data = dayCount
  })
end

--[[
     Last Claims 
   ]]
--
-- @dev Returns the last claim days for all users
local function lastClaims(msg)
  ao.send({
    Target = msg.From,
    LastClaims = Protocol.LastClaimDay,
    Data = Protocol.LastClaimDay
  })
end

--[[
     Notice 
   ]]
--
-- @dev Set the notification timestamp of the sender. 
local function notice(msg)
  if not LastNotice[msg.From] then LastNotice[msg.From] = "0" end

  -- Update last notice cursor
  LastNotice[msg.From] = msg.Timestamp

  -- Send notice
  ao.send({
    Target = msg.From,
    Action = 'Notice-Notice',
    Process = ao.id,
    LastNotice = msg.Timestamp,
    Data = "Your last notice was at " .. tostring(msg.Timestamp)
  })
end

--[[
     Last Notice
   ]]
--
-- @dev Returns the last notice timestamp of the msg.Sender or Target
local function lastNotice(msg)
  local timestamp = ""

  -- If not Target is provided, then return the Senders last notice
  if (msg.Tags.Target) then
    if not LastNotice[msg.Tags.Target] then LastNotice[msg.Tags.Target] = "0" end
    timestamp = LastNotice[msg.Tags.Target]
  else
    if not LastNotice[msg.From] then LastNotice[msg.From] = "0" end
    timestamp = LastNotice[msg.From]
  end

  ao.send({
    Target = msg.From,
    LastNotice = timestamp,
    Account = msg.Tags.Target or msg.From,
    Data = timestamp
  })
end

--[[
     Last Notices 
   ]]
--
-- @dev Returns the last notice timestamps for all users
local function lastNotices(msg)
  ao.send({
    Target = msg.From,
    LastNotices = json.encode(LastNotice),
    Data = json.encode(LastNotice)
  })
end

--[[
     MARKET
   ]]
--

--[[
     Share Balances 
   ]]
--
local function marketShareBalances(condition)
  return Protocol.Markets[condition].ShareBalances
end

local function shareBalances(msg)
  assert(msg.Tags.Condition, 'Condition is required!')

  local shareBalances_ = marketShareBalances(msg.Tags.Condition)

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    ShareBalances = json.encode(shareBalances_),
    Data = json.encode(shareBalances_)
  })
end

--[[
     Outcomes 
   ]]
--
local function marketOutcomes(condition)
  return Protocol.Markets[condition].Outcomes
end

local function outcomes(msg)
  assert(msg.Tags.Condition, 'Condition is required!')

  local outcomes_ = marketOutcomes(msg.Tags.Condition)

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    Outcomes = json.encode(outcomes_),
    Data = json.encode(outcomes_)
  })
end

--[[
     Pool Balances 
   ]]
--
local function marketPoolBalances(condition)
  local poolBalances = {}
  local outcomes_ = marketOutcomes(condition)
  local shareBalances_ = marketShareBalances(condition)
  for i = 1, #outcomes_ do
    local outcome = outcomes_[i]
    local poolBalance = shareBalances_[outcome][ao.id]
    poolBalances[outcome] = poolBalance
  end
  return poolBalances
end

function Protocol.poolBalances(msg)
  assert(msg.Tags.Condition, 'Condition is required!')

  local poolBalances = marketPoolBalances(msg.Tags.Condition)

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    PoolBalances = json.encode(poolBalances),
    Data = json.encode(poolBalances)
  })
end

--[[
     Market Wager Balances
   ]]
--
local function marketWagerBalances(msg)
  assert(msg.Tags.Condition, 'Condition is required!')

  local marketWagerBalances_ = Protocol.Markets[msg.Tags.Condition].WagerBalances
  local marketCategory_ = Protocol.Markets[msg.Tags.Condition].Category

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    Category = marketCategory_,
    WagerBalances = json.encode(marketWagerBalances_),
    Data = json.encode(marketWagerBalances_)
  })
end

--[[
     Odds Weight
   ]]
--
local function marketOddsWeightForOutcome(condition, outcome)
  local shareBalances_ = marketShareBalances(condition)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local oddsWeight = 1
  for i = 1, #outcomes_ do
    if (outcomes_[i] ~= outcome) then
      local poolBalance = shareBalances_[outcomes_[i]][ao.id]
      oddsWeight = oddsWeight * poolBalance
    end
  end

  return oddsWeight
end

function Protocol.oddsWeight(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.Outcome, 'Outcome is required!')

  local oddsWeight = marketOddsWeightForOutcome(msg.Tags.Condition, msg.Tags.Outcome)

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    Outcome = msg.Tags.Outcome,
    OddsWeight = tostring(oddsWeight),
    Data = oddsWeight
  })
end

--[[
     Odds
   ]]
--
local function marketOddsForOutcome(condition, outcome)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local oddsWeight = marketOddsWeightForOutcome(condition, outcome)

  local sumOddsWeight = 0
  for i = 1, #outcomes_ do
    local otherOddsWeight = marketOddsWeightForOutcome(condition, outcomes_[i])
    sumOddsWeight = sumOddsWeight + otherOddsWeight
  end

  assert(sumOddsWeight ~= 0, 'SumOddsWeight is 0')

  return oddsWeight / sumOddsWeight
end

function Protocol.odds(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.Outcome, 'Outcome is required!')

  local odds = marketOddsForOutcome(msg.Tags.Condition, msg.Tags.Outcome)

  ao.send({
    Target = msg.From,
    Condition = msg.Tags.Condition,
    Outcome = msg.Tags.Outcome,
    Odds = tostring(odds),
    Data = odds
  })
end

--[[
     CalcBuyAmount  
   ]]
--
local function marketCalcBuyAmount(condition, investmentAmount, outcome)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local poolBalances = marketPoolBalances(condition)
  local buyTokenPoolBalance = poolBalances[outcome]

  local endingOutcomeBalance = buyTokenPoolBalance
  for i = 1, #outcomes_ do
    if (outcomes_[i] ~= outcome) then
      local poolBalance = poolBalances[outcomes_[i]]
      endingOutcomeBalance = endingOutcomeBalance * poolBalance / (poolBalance + investmentAmount)
    end
  end

  assert(endingOutcomeBalance > 0, 'Must have non-zero balances! ' .. tostring(endingOutcomeBalance))

  return math.floor(buyTokenPoolBalance + investmentAmount - endingOutcomeBalance)
end

function Protocol.calcBuyAmount(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required!')
  assert(bint.__lt(0, msg.Tags.InvestmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(msg.Tags.Outcome, 'Outcome is required!')

  local buyAmount = marketCalcBuyAmount(msg.Tags.Condition, msg.Tags.InvestmentAmount, msg.Tags.Outcome)

  ao.send({
    Target = msg.From,
    InvestmentAmount = msg.Tags.InvestmentAmount,
    BuyAmount = tostring(buyAmount),
    Outcome = msg.Tags.Outcome,
    Data = buyAmount
  })
end

--[[
     CalcSellAmount  
   ]]
--
local function marketCalcSellAmount(condition, returnAmount, outcome)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local poolBalances = marketPoolBalances(condition)
  local sellTokenPoolBalance = poolBalances[outcome]

  local endingOutcomeBalance = sellTokenPoolBalance
  for i = 1, #outcomes_ do
    if (outcomes_[i] ~= outcome) then
      local poolBalance = poolBalances[outcomes_[i]]
    endingOutcomeBalance = endingOutcomeBalance * poolBalance / (poolBalance - returnAmount)
    end
  end

  assert(endingOutcomeBalance > 0, 'Must have non-zero balances!')

  return math.ceil(returnAmount + endingOutcomeBalance - sellTokenPoolBalance)
end

function Protocol.calcSellAmount(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required!')
  assert(bint.__lt(0, msg.Tags.ReturnAmount), 'ReturnAmount must be greater than zero!')
  assert(msg.Tags.Outcome, 'Outcome is required!')

  local sellAmount = marketCalcSellAmount(msg.Tags.Condition, msg.Tags.ReturnAmount, msg.Tags.Outcome)

  ao.send({
    Target = msg.From,
    ReturnAmount = msg.Tags.ReturnAmount,
    SellAmount = tostring(sellAmount),
    Outcome = msg.Tags.Outcome,
    Data = sellAmount
  })
end

--[[
     Buy  
   ]]
--
local function marketBuy(sender, condition, investmentAmount, outcome, minOutcomeTokensToBuy)
  assert(Protocol.Markets[condition].Active, 'Market must be active!')

  local shareBalances_ = marketShareBalances(condition)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')
  local outcomeTokensToBuy = marketCalcBuyAmount(condition, investmentAmount, outcome)
  assert(bint.__le(minOutcomeTokensToBuy, outcomeTokensToBuy), 'Minimum buy amount not reached!')

  -- instantiate sender balance
  if not Protocol.Balances[sender] then Protocol.Balances[sender] = '0' end

  -- instantiate sender share balance
  if not Protocol.Markets[condition].ShareBalances[outcome][sender] then
    Protocol.Markets[condition].ShareBalances[outcome][sender] = '0'
  end

  -- transfer investment amount from sender to pool and allocate to market
  assert(bint.__le(investmentAmount, Protocol.Balances[sender]), 'Insufficient funds!')
  local senderBalance = tostring(bint.__sub(Protocol.Balances[sender], investmentAmount))
  Protocol.Balances[sender] = senderBalance
  local protocolBalance = tostring(bint.__add(Protocol.Balances[ao.id], investmentAmount))
  Protocol.Balances[ao.id] = protocolBalance
  local marketCollateralAmount = tostring(bint.__add(Protocol.Markets[condition].CollateralAmount, investmentAmount))
  Protocol.Markets[condition].CollateralAmount = marketCollateralAmount

  -- mint tokens for all outcomes
  for i = 1, #outcomes_ do
    local poolShareBalance = tostring(bint.__add(shareBalances_[outcomes_[i]][ao.id], outcomeTokensToBuy))
    shareBalances_[outcomes_[i]][ao.id] = poolShareBalance
  end

  -- transfer shares from process to sender 
  local newPoolShareBalance = tostring(bint.__sub(shareBalances_[outcome][ao.id], outcomeTokensToBuy))
  assert(bint.__le(outcomeTokensToBuy, shareBalances_[outcome][ao.id]), 'Insufficient shares in pool!')
  shareBalances_[outcome][ao.id] = newPoolShareBalance
  local newSenderShareBalance = tostring(bint.__add(shareBalances_[outcome][sender], outcomeTokensToBuy))
  shareBalances_[outcome][sender] = newSenderShareBalance

  -- instantiate sender wager balance for category
  if not Protocol.WagerBalances[Protocol.Markets[condition].Category][sender] then
    Protocol.WagerBalances[Protocol.Markets[condition].Category][sender] = '0'
  end

  -- instantiate sender wager balance for market
  if not Protocol.Markets[condition].WagerBalances[sender] then
    Protocol.Markets[condition].WagerBalances[sender] = '0'
  end

  -- update sender wager balance for category
  local senderCategoryWagerBalance = tostring(bint.__add(Protocol.WagerBalances[Protocol.Markets[condition].Category][sender], investmentAmount))
  Protocol.WagerBalances[Protocol.Markets[condition].Category][sender] = senderCategoryWagerBalance

  -- update sender wager balance for market
  local senderMarketWagerBalance = tostring(bint.__add(Protocol.Markets[condition].WagerBalances[sender], investmentAmount))
  Protocol.Markets[condition].WagerBalances[sender] = senderMarketWagerBalance

  -- update the odds 
  local odds = {}
  for i = 1, #outcomes_ do
    local outcomeOdds = marketOddsForOutcome(condition, outcomes_[i])
    odds[outcomes_[i]] = outcomeOdds
  end
  Protocol.Markets[condition].Odds = odds

  return outcomeTokensToBuy, newSenderShareBalance
end

function Protocol.buy(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.InvestmentAmount, 'InvestmentAmount is required')
  assert(bint.__lt(0, msg.Tags.InvestmentAmount), 'InvestmentAmount must be greater than zero!')
  assert(msg.Tags.Outcome, 'Outcome is required!')
  assert(msg.Tags.MinOutcomeTokensToBuy, 'MinOutcomeTokensToBuy is required!')
  assert(bint.__le(0, msg.Tags.MinOutcomeTokensToBuy), 'MinOutcomeTokensToBuy must be greater than or equal to zero!')

  local buyAmount, shareBalance_ = marketBuy(msg.From, msg.Tags.Condition, msg.Tags.InvestmentAmount, msg.Tags.Outcome, msg.Tags.MinOutcomeTokensToBuy)

  ao.send({
    Target = msg.From,
    Action = 'Buy-Notice',
    Process = ao.id,
    InvestmentAmount = msg.Tags.InvestmentAmount,
    BuyAmount = tostring(buyAmount),
    ShareBalance = tostring(shareBalance_),
    Condition = msg.Condition,
    Category = Protocol.Markets[msg.Condition].Category,
    Outcome = msg.Outcome,
    Data = "You bought " .. tostring(math.ceil(bint.__div(buyAmount, bint.__pow(10, Protocol.Denomination)))) .. " shares of outcome " .. msg.Tags.Outcome
  })

  -- Log Result
  ao.send({
    Target = ao.id,
    Action = 'Buy-Log',
    Process = ao.id,
    User = msg.From,
    InvestmentAmount = msg.Tags.InvestmentAmount,
    BuyAmount = tostring(buyAmount),
    ShareBalance = tostring(shareBalance_),
    Condition = msg.Condition,
    Category = Protocol.Markets[msg.Condition].Category,
    Outcome = msg.Outcome,
    Data = msg.From .. " bought " .. tostring(math.ceil(bint.__div(buyAmount, bint.__pow(10, Protocol.Denomination)))) .. " shares of outcome " .. msg.Tags.Outcome
  })

    -- Update DB
    local wager = {}

    wager['user'] = msg.From
    wager['position'] = msg.Tags.Outcome
    wager['action'] = 'credit'
    wager['amount'] = msg.Tags.InvestmentAmount

    local marketId = hash_url(msg.Condition)
    wager['market'] = marketId

    local average_price = bint.__div(buyAmount, msg.Tags.InvestmentAmount)
    wager['average_price'] = tostring(average_price)

    wager['odds'] = tostring(Protocol.Markets[msg.Condition].Odds['in'])

    ao.send({
      Target = OutcomeDB,
      Action = 'Wager-Ingest',
      Data = json.encode(wager)
    })
end

--[[
     Sell  
   ]]
--
local function marketSell(sender, condition, returnAmount, outcome, maxOutcomeTokensToSell)
  assert(Protocol.Markets[condition].Active, 'Market must be active!')

  local shareBalances_ = marketShareBalances(condition)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local outcomeTokenToSell = marketCalcSellAmount(condition, returnAmount, outcome)
  assert(bint.__le(outcomeTokenToSell, maxOutcomeTokensToSell), 'Maximum sell amount exceeded!')

  -- transfer returnAmount from sender to pool
  assert(bint.__le(outcomeTokenToSell, shareBalances_[outcome][sender]), 'Insufficient shares!')
  local senderShareBalance = tostring(bint.__sub(shareBalances_[outcome][sender], outcomeTokenToSell))
  shareBalances_[outcome][sender] = senderShareBalance
  local poolShareBalance = tostring(bint.__add(shareBalances_[outcome][ao.id], outcomeTokenToSell))
  shareBalances_[outcome][ao.id] = poolShareBalance

  -- burn tokens for all outcomes
  for i = 1, #outcomes_ do
    assert(bint.__le(outcomeTokenToSell, shareBalances_[outcomes_[i]][ao.id]), 'Insufficient shares in pool!')
    local poolShareBalance_ = tostring(bint.__sub(shareBalances_[outcomes_[i]][ao.id], outcomeTokenToSell))
    shareBalances_[outcomes_[i]][ao.id] = poolShareBalance_
  end

  -- transfer collateral from pool to sender and remove allocation from market
  local protocolBalance = tostring(bint.__sub(Protocol.Balances[ao.id], returnAmount))
  assert(bint.__le(returnAmount, Protocol.Balances[ao.id]), 'Insufficient funds in protocol!')
  Protocol.Balances[ao.id] = protocolBalance
  local marketCollateralAmount = tostring(bint.__sub(Protocol.Markets[condition].CollateralAmount, returnAmount))
  assert(bint.__le(returnAmount, Protocol.Markets[condition].CollateralAmount), 'Insufficient collateral in market!')
  Protocol.Markets[condition].CollateralAmount = marketCollateralAmount
  local senderBalance = tostring(bint.__add(Protocol.Balances[sender], returnAmount))
  Protocol.Balances[sender] = senderBalance

  -- update the odds 
  local odds = {}
  for i = 1, #outcomes_ do
    local outcomeOdds = marketOddsForOutcome(condition, outcomes_[i])
    odds[outcomes_[i]] = outcomeOdds
  end
  Protocol.Markets[condition].Odds = odds

  -- update wager balance for category
  local senderCategoryWagerBalance = tostring(bint.__sub(Protocol.WagerBalances[Protocol.Markets[condition].Category][sender], returnAmount))
  Protocol.WagerBalances[Protocol.Markets[condition].Category][sender] = senderCategoryWagerBalance

  -- update wager balance for market
  local senderMarketWagerBalance = tostring(bint.__sub(Protocol.Markets[condition].WagerBalances[sender], returnAmount))
  Protocol.Markets[condition].WagerBalances[sender] = senderMarketWagerBalance

  return outcomeTokenToSell, senderShareBalance
end

function Protocol.sell(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.ReturnAmount, 'ReturnAmount is required')
  assert(bint.__lt(0, msg.Tags.ReturnAmount), 'ReturnAmount must be greater than zero!')
  assert(msg.Tags.Outcome, 'Outcome is required!')
  assert(msg.Tags.MaxOutcomeTokensToSell, 'MaxOutcomeTokensToSell is required!')
  assert(bint.__lt(0, msg.Tags.MaxOutcomeTokensToSell), 'MaxOutcomeTokensToSell must be greater than zero!')

  local sellAmount, shareBalance = marketSell(msg.From, msg.Tags.Condition, msg.Tags.ReturnAmount, msg.Tags.Outcome, msg.Tags.MaxOutcomeTokensToSell)

  -- Notify Sender
  ao.send({
    Target = msg.From,
    Action = 'Sell-Notice',
    Process = ao.id,
    ReturnAmount = msg.Tags.ReturnAmount,
    SellAmount = tostring(sellAmount),
    ShareBalance = tostring(shareBalance),
    Condition = msg.Condition,
    Category = Protocol.Markets[msg.Condition].Category,
    Outcome = msg.Outcome,
    Data = "You sold " .. tostring(math.ceil(bint.__div(sellAmount, bint.__pow(10, Protocol.Denomination)))) .. " shares of outcome " .. msg.Tags.Outcome
  })

  -- Log Result
  ao.send({
    Target = ao.id,
    Action = 'Sell-Log',
    Process = ao.id,
    User = msg.From,
    ReturnAmount = msg.Tags.ReturnAmount,
    SellAmount = tostring(sellAmount),
    ShareBalance = tostring(shareBalance),
    Condition = msg.Condition,
    Category = Protocol.Markets[msg.Condition].Category,
    Outcome = msg.Outcome,
    Data = msg.From .. " sold " .. tostring(math.ceil(bint.__div(sellAmount, bint.__pow(10, Protocol.Denomination)))) .. " shares of outcome " .. msg.Tags.Outcome
  })

  -- Update DB
  local wager = {}

  wager['user'] = msg.From
  wager['position'] = msg.Tags.Outcome
  wager['action'] = 'debit'
  wager['amount'] = msg.Tags.ReturnAmount

  local marketId = hash_url(msg.Condition)
  wager['market'] = marketId

  local average_price = bint.__div(sellAmount, msg.Tags.ReturnAmount)
  wager['average_price'] = tostring(average_price)

  wager['odds'] = tostring(Protocol.Markets[msg.Condition].Odds['in'])

  ao.send({
    Target = OutcomeDB,
    Action = 'Wager-Ingest',
    Data = json.encode(wager)
  })
end

--[[
     Redeem  
   ]]
--
local function marketShareRedeem(sender, condition, outcome)
  assert(Protocol.Markets[condition].PayoutOutcome ~= '0', 'Payout outcome not reported!')
  assert(Protocol.Markets[condition].PayoutOutcome == outcome, 'Outcome must match payment outcome!')
  local shareBalances_ = marketShareBalances(condition)
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(outcome, outcomes_), 'Invalid outcome!')

  local senderOutcomeShares = shareBalances_[outcome][sender] and shareBalances_[outcome][sender] or 0
  assert(bint.__lt(0, senderOutcomeShares), 'No shares! share balances')

  -- check number of shares for the market payout outcome
  local totalOutcomeShares = utils.reduce(
    function (acc, v) return acc + v end,
    0,
    bint(utils.values(shareBalances_[outcome]))
  )

  -- check the market balance
  local marketCollateral = Protocol.Markets[condition].CollateralAmount

  -- calculate the sender payout
  local senderPayout = marketCollateral * senderOutcomeShares / totalOutcomeShares

  -- burn the sender shares
  shareBalances_[outcome][sender] = 0

  -- transfer payout from the protocol to the sender reducing the market collateral
  marketCollateral = tostring(bint.__sub(marketCollateral, senderPayout))
  assert(bint.__le(0, marketCollateral), 'Insufficient market collateral!')
  Protocol.Markets[condition].CollateralAmount = marketCollateral
  local protocolBalance = tostring(bint.__sub(Protocol.Balances[ao.id], senderPayout))
  assert(bint.__le(senderPayout, Protocol.Balances[ao.id]), 'Insufficient funds in protocol!')
  Protocol.Balances[ao.id] = protocolBalance
  local senderBalance = tostring(bint.__add(Protocol.Balances[sender], senderPayout))
  Protocol.Balances[sender] = senderBalance

  -- instantiate win ratio variables for sender
  if not Protocol.WinRatios[Protocol.Markets[condition].Category][sender] then
    for i = 1, #Protocol.Categories do
      local category = Protocol.Categories[i]
      -- ensure to not overwrite existing data
      if not Protocol.WinRatios[category][sender] then
        Protocol.WinRatios[category][sender] = {
          ["wins"] = "0",
          ["games"] = "0",
          ["ratio"] = "0"
        }
      end
    end
  end

  -- update win ratio
  local wins = Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["wins"]
  local games = Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["games"]
  local ratio = Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["ratio"]

  if (bint.__lt(Protocol.Markets[condition].WagerBalances[sender], senderPayout)) then
    wins = tostring(bint.__add(wins, 1))
    Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["wins"] = wins
  end

  games = tostring(bint.__add(games, 1))
  ratio = tostring(bint.__div(wins, games))

  Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["games"] = games
  Protocol.WinRatios[Protocol.Markets[condition].Category][sender]["ratio"] = ratio

  -- update wager Balances 
  local marketWagerBalance = Protocol.Markets[condition].WagerBalances[sender]
  local marketCategory = Protocol.Markets[condition].Category

  local updatedWagerBalance = tostring(bint.__sub(Protocol.WagerBalances[marketCategory][sender], marketWagerBalance))
  Protocol.WagerBalances[marketCategory][sender] = updatedWagerBalance

  return senderOutcomeShares, senderPayout, senderBalance
end

local function shareRedeem(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.Outcome, 'Outcome is required!')

  local redeemAmount, payout, balance_ = marketShareRedeem(msg.From, msg.Tags.Condition, msg.Tags.Outcome)

  ao.send({
    Target = msg.From,
    Action = 'Redeem-Notice',
    Process = ao.id,
    RedeemAmount = tostring(redeemAmount),
    Condition = msg.Condition,
    Outcome = msg.Outcome,
    Payout = tostring(payout),
    Balance = tostring(balance_),
    Data = "You redeemed " .. tostring(redeemAmount) .. " shares of outcome " .. msg.Tags.Outcome
  })
end

--[[
     ADMIN
   ]]
--

--[[
     Create Market
   ]]
--
local function createMarket(msg)
  assert(msg.From == Protocol.Owner, "Sender must be Owner!")
  assert(type(msg.Tags.Category) == 'string', 'Category is required!')
  assert(utils.includes(msg.Tags.Category, Protocol.Categories), 'Category must be valid!')
  assert(type(msg.Tags.Description) == 'string', 'Description is required!')
  assert(type(msg.Tags.Condition) == 'string', 'Condition is required!')
  assert(not Protocol.Markets[msg.Condition], 'Condition must be unique!')
  assert(type(msg.Tags.Outcomes) == 'string', 'Outcomes are required!')
  local outcomes_ = json.decode(msg.Tags.Outcomes)
  assert(type(outcomes_) == 'table', 'Outcomes must be a table!')

  local market_ = {
    Category = msg.Tags.Category,
    Description = msg.Tags.Description,
    Outcomes = outcomes_,
    WagerBalances = {},
    ShareBalances = {},
    CollateralAmount = 0,
    PayoutOutcome = 0,
    Active = true,
    Odds = {}
  }

  -- Instantiate wager balance category
  if not Protocol.WagerBalances[msg.Tags.Category] then
    Protocol.WagerBalances[msg.Tags.Category] = {}
  end

   -- Initialize share balances mapping & odds
  for i = 1, #outcomes_ do
    market_.ShareBalances[outcomes_[i]] = {}
    market_.ShareBalances[outcomes_[i]][ao.id] = "1000000000000" -- 100 tokens
    market_.Odds[outcomes_[i]] = 1 / #outcomes_
  end

  -- Mint token amount to pool and allocate to market
  local balance_ = tostring(bint.__add(Protocol.Balances[ao.id], "1000000000000"))
  Protocol.Balances[ao.id] = tostring(balance_)
  market_.CollateralAmount = "1000000000000"

  -- Create market
  Protocol.Markets[msg.Condition] = market_

  ao.send({
    Target = msg.From,
    Action = 'Market-Notice',
    Process = ao.id,
    Data = "Market created for condition " .. msg.Condition .. " with outcomes " .. msg.Outcomes
  })

  local marketId = hash_url(msg.Tags.Condition)
  print("marketid: " .. marketId)
end

--[[
     Close Market
   ]]
--
local function closeMarket(msg)
  assert(msg.From == Protocol.Owner, "Sender must be Owner!")
  assert(type(msg.Tags.Condition) == 'string', 'Condition is required!')

  Protocol.Markets[msg.Condition].Active = false

  ao.send({
    Target = msg.From,
    Action = 'Market-Close-Notice',
    Process = ao.id,
    Data = "Market closed for condition " .. msg.Condition
  })
end

--[[
     Close Market
   ]]
--
local function batchShareRedeem(msg)
  assert(msg.From == Protocol.Owner, "Sender must be Owner!")
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.Outcome, 'Outcome is required!')
  assert(not Protocol.Markets[msg.Tags.Condition].Active, 'Market must be closed!')
  assert(Protocol.Markets[msg.Tags.Condition].PayoutOutcome ~= 0, 'Payout outcome not reported!')
  assert(Protocol.Markets[msg.Tags.Condition].PayoutOutcome == msg.Tags.Outcome, 'Outcome must match payment outcome!')

  local shareBalances_ = marketShareBalances(msg.Tags.Condition)

  local shareOwners = utils.keys(shareBalances_[msg.Tags.Outcome])
  assert(#shareOwners > 0, 'No shares to redeem!')

  local redemptions = {}

  for i = 1, #shareOwners do
    local shareOwner = shareOwners[i]

    if (shareOwner ~= ao.id) then
      local redeemAmount_, payout_, balance_ =  marketShareRedeem(shareOwner, msg.Tags.Condition, msg.Tags.Outcome)
      local redemptionData = {
        ["RedeemAmount"] = redeemAmount_,
        ["Payout"] = payout_,
        ["Balance"] = balance_,
      }
      redemptions[shareOwner] = redemptionData

      -- Send notice to shareOwner
      ao.send({
        Target = shareOwner,
        Action = 'Redeem-Notice',
        Process = ao.id,
        RedeemAmount = tostring(redeemAmount_),
        Condition = msg.Condition,
        Outcome = msg.Outcome,
        Payout = tostring(payout_),
        Balance = tostring(balance_),
        Data = "You were redeemed " .. tostring(redeemAmount_) .. " shares of outcome " .. msg.Tags.Outcome
      })

      -- Update DB
      local win = {}
      win['user'] = shareOwner
      win['market'] = hash_url(msg.Tags.Condition)
      win['category'] = Protocol.Markets[msg.Tags.Condition].Category
      win['bet_amount'] = msg.Tags.Outcome
      win['won_amount'] = tostring(payout_)
    end

  end

  ao.send({
    Target = msg.From,
    Action = 'BatchRedeem-Notice',
    Process = ao.id,
    Condition = msg.Tags.Condition,
    Outcome = msg.Tags.Outcome,
    Redemptions = json.encode(redemptions),
    Data = json.encode(redemptions)
  })
end

--[[
     Resolve Competition
   ]]
--
local function resolveCompetition(msg)
  assert(msg.From == Protocol.Owner, "Sender must be Owner!")
  assert(msg.Tags.Category, 'Category is required!')
  assert(msg.Tags.Winners, 'Winners is required!')
  local winners = json.decode(msg.Tags.Winners)
  assert(type(winners) == 'table', 'Winners must be a table!')
  assert(msg.Tags.Prizes, 'Prizes is required!')
  local prizes = json.decode(msg.Tags.Prizes)
  assert(type(prizes) == 'table', 'Prizes must be a table!')
  assert(#winners == #prizes, 'Winners and Prizes must be of equal length!')

  for i = 1, #winners do
    local winner = winners[i]
    local prize = prizes[i]

    -- Update Balance
    local balance_ = tostring(bint.__add(Protocol.Balances[winner], prize))
    Protocol.Balances[winner] = balance_

    -- Send notice
    ao.send({
      Target = winner,
      Action = 'CompetitionPrize-Notice',
      Process = ao.id,
      Category = msg.Category,
      Prize = prize,
      Position = tostring(i),
      Balance = tostring(Protocol.Balances[winner]),
      Data = "Winner! Your balance has increased by " .. tostring(prize) .. " tokens."
    })
  end

  ao.send({
    Target = msg.From,
    Action = 'ResolveCompetition-Notice',
    Results = msg.Results,
    Data = msg.Results
  })
end

--[[
     ORACLE
   ]]
--

--[[
     Report Payouts
   ]]
--
local function marketReportPayouts(sender, condition, payoutOutcome)
  assert(not Protocol.Markets[condition].Active, 'Market must be closed!')
  assert(sender == Protocol.Oracle, 'Sender must be Oracle!')
  local outcomes_ = marketOutcomes(condition)
  assert(utils.includes(payoutOutcome, outcomes_), 'Invalid payoutOutcome!')
  assert(Protocol.Markets[condition].PayoutOutcome == 0, 'Payout outcome already reported!')

  -- Report the payout outcome
  Protocol.Markets[condition].PayoutOutcome = payoutOutcome

  -- Send notice
  ao.send({
    Target = sender,
    Action = 'Payout-Notice',
    Condition = condition,
    PayoutOutcome = payoutOutcome,
    Process = ao.id,
    Data = "Condition " .. condition .. " to payout outcome " .. payoutOutcome
  })
end

local function reportPayouts(msg)
  assert(msg.Tags.Condition, 'Condition is required!')
  assert(msg.Tags.PayoutOutcome, 'PayoutOutcome is required!')

  marketReportPayouts(msg.From, msg.Tags.Condition, msg.Tags.PayoutOutcome)
end


--[[
     Handlers for each incoming Action as defined by the Protocol Specification
   ]]
--

--[[
     TOKEN
   ]]
--

--[[
     Info  
   ]]
--
Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
  info(msg)
end)

--[[
     Total Supply
   ]]
--
Handlers.add('totalSupply', Handlers.utils.hasMatchingTag('Action', 'TotalSupply'), function(msg)
  totalSupply(msg)
end)

--[[
     Balance  
   ]]
--
Handlers.add('balance', Handlers.utils.hasMatchingTag('Action', 'Balance'), function(msg)
  balance(msg)
end)

--[[
     Balances 
   ]]
--
Handlers.add('balances', Handlers.utils.hasMatchingTag('Action', 'Balances'), function(msg)
  balances(msg)
end)

--[[
     Wager Balance  
   ]]
--
Handlers.add('wagerBalance', Handlers.utils.hasMatchingTag('Action', 'WagerBalance'), function(msg)
  wagerBalance(msg)
end)

--[[
     Wager Balances 
   ]]
--
Handlers.add('wagerBalances', Handlers.utils.hasMatchingTag('Action', 'WagerBalances'), function(msg)
  wagerBalances(msg)
end)

--[[
     Win Ratio  
   ]]
--
Handlers.add('winRatio', Handlers.utils.hasMatchingTag('Action', 'WinRatio'), function(msg)
  winRatio(msg)
end)

--[[
     Win Ratios 
   ]]
--
Handlers.add('winRatios', Handlers.utils.hasMatchingTag('Action', 'WinRatios'), function(msg)
  winRatios(msg)
end)

--[[
     Market 
   ]]
--
Handlers.add('market', Handlers.utils.hasMatchingTag('Action', 'Market'), function(msg)
  market(msg)
end)

--[[
     Markets 
   ]]
--
Handlers.add('markets', Handlers.utils.hasMatchingTag('Action', 'Markets'), function(msg)
  markets(msg)
end)

--[[
     Claim 
   ]]
--
Handlers.add('claim', Handlers.utils.hasMatchingTag('Action', 'Claim'), function(msg)
  claim(msg)
end)

--[[
     Last Claim 
   ]]
--
Handlers.add('lastClaim', Handlers.utils.hasMatchingTag('Action', 'LastClaim'), function(msg)
  lastClaim(msg)
end)

--[[
     Last Claims
   ]]
--
Handlers.add('lastClaims', Handlers.utils.hasMatchingTag('Action', 'LastClaims'), function(msg)
  lastClaims(msg)
end)

--[[
     Notice 
   ]]
--
Handlers.add('notice', Handlers.utils.hasMatchingTag('Action', 'Notice'), function(msg)
  notice(msg)
end)

--[[
     Last Notice 
   ]]
--
Handlers.add('lastNotice', Handlers.utils.hasMatchingTag('Action', 'LastNotice'), function(msg)
  lastNotice(msg)
end)

--[[
     Last Notices
   ]]
--
Handlers.add('lastNotices', Handlers.utils.hasMatchingTag('Action', 'LastNotices'), function(msg)
  lastNotices(msg)
end)

--[[
     MARKET
   ]]
--

--[[
     Share Balances 
   ]]
--
Handlers.add('shareBalances', Handlers.utils.hasMatchingTag('Action', 'ShareBalances'), function(msg)
  shareBalances(msg)
end)

--[[
     Outcomes 
   ]]
--
Handlers.add('outcomes', Handlers.utils.hasMatchingTag('Action', 'Outcomes'), function(msg)
  outcomes(msg)
end)

--[[
     Pool Balances 
   ]]
--
Handlers.add('poolBalances', Handlers.utils.hasMatchingTag('Action', 'PoolBalances'), function(msg)
  Protocol.poolBalances(msg)
end)

--[[
     Market Wager Balances 
   ]]
--
Handlers.add('marketWagerBalances', Handlers.utils.hasMatchingTag('Action', 'MarketWagerBalances'), function(msg)
  marketWagerBalances(msg)
end)

--[[
     Odds Weight
   ]]
--
Handlers.add('oddsWeight', Handlers.utils.hasMatchingTag('Action', 'OddsWeight'), function(msg)
  Protocol.oddsWeight(msg)
end)

--[[
     Odds  
   ]]
--
Handlers.add('odds', Handlers.utils.hasMatchingTag('Action', 'Odds'), function(msg)
  Protocol.odds(msg)
end)

--[[
     CalcBuyAmount  
   ]]
--
Handlers.add('calcBuyAmount', Handlers.utils.hasMatchingTag('Action', 'CalcBuyAmount'), function(msg)
  Protocol.calcBuyAmount(msg)
end)

--[[
     CalcSellAmount  
   ]]
--
Handlers.add('calcSellAmount', Handlers.utils.hasMatchingTag('Action', 'CalcSellAmount'), function(msg)
  Protocol.calcSellAmount(msg)
end)

--[[
     Buy  
   ]]
--
Handlers.add('buy', Handlers.utils.hasMatchingTag('Action', 'Buy'), function(msg)
  Protocol.buy(msg)
end)

--[[
     Sell  
   ]]
--
Handlers.add('sell', Handlers.utils.hasMatchingTag('Action', 'Sell'), function(msg)
  Protocol.sell(msg)
end)

--[[
     Redeem  
   ]]
--
Handlers.add('redeem', Handlers.utils.hasMatchingTag('Action', 'Redeem'), function(msg)
  shareRedeem(msg)
end)

--[[
     ADMIN
   ]]
--

--[[
     Create Market
   ]]
--
Handlers.add('createMarket', Handlers.utils.hasMatchingTag('Action', 'CreateMarket'), function(msg)
  createMarket(msg)
end)

--[[
     Close Market
   ]]
--
Handlers.add('closeMarket', Handlers.utils.hasMatchingTag('Action', 'CloseMarket'), function(msg)
  closeMarket(msg)
end)

--[[
     Batch Redeem
   ]]
--
Handlers.add('batchRedeem', Handlers.utils.hasMatchingTag('Action', 'BatchRedeem'), function(msg)
  batchShareRedeem(msg)
end)

--[[
     Resolve Competition
   ]]
--
Handlers.add('resolveCompetition', Handlers.utils.hasMatchingTag('Action', 'ResolveCompetition'), function(msg)
  resolveCompetition(msg)
end)

--[[
     ORACLE
   ]]
--

--[[
     Report Payouts
   ]]
--
Handlers.add('reportPayouts', Handlers.utils.hasMatchingTag('Action', 'ReportPayouts'), function(msg)
  reportPayouts(msg)
end)
