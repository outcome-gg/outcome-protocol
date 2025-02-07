# Outcome v2 (WIP)

Outcome v2 is a new automated market maker and prediction market protocol that enables permissionless market creation and autonomous resolution, with all markets and their outcomes permanently stored on Arweave and AO.

## Quickstart

Get started with Outcome v2 by installing AOS, loading the package, and interacting with markets.

### 1. Install AOS
Ensure the AOS runtime is installed:

```bash
yarn global add https://get_ao.g8way.io
```

### 2. Load Outcome
Load the Outcome package into AOS:
```bash
aos --load src/outcome.lua
```

### 3. Choose your environment

#### **Mainnet**: Stake Tokens
Stake **1,000,000 $OCM tokens** to create markets on mainnet:
```lua
Outcome.tokenStake(1000000)
```

#### **Testnet**: Mint $Mock-DAI
Mint **$MockDAI tokens** to create markets on testnet:
```lua
Outcome.tokenMint(Outcome.testCollateral, 1000000) 
```

### 4. Create a Market
Once tokens are staked, spawn a new prediction market:
```lua
Outcome.marketFactorySpawnMarket(
    ao.id,                                              -- Resolution Agent (set to self for Quickstart)
    Outcome.mockDAI,                                    -- Collateral Token (Mock DAI for Quickstart)
    "$A0 surpasses $AR market cap by the end of 2025",  -- Question
    2,                                                  -- Outcome Slot Count (must be `2` for outcome.gg visibility)
    "Crypto",                                           -- Category
    "Prices",                                           -- Subcategory
    "Logo_TxID",                                        -- Arweave TxID of the logo image
    "Rules of the market",                              -- Rules
    250,                                                -- Creator Fee (basis points, `250` = 2.5%)
    ao.id                                               -- Creator Fee Target (set to self for Quickstart)
)
```

### 5. Init Market
Once a market has been spawned it must be initialized:
```lua
Outcome.marketFactoryInitMarket()
```

### 6. Get Market Process ID
Get the latest process ID for creator:
```lua
res = Outcome.marketFactoryMarketsByCreator()
markets = res.MarketsByCreator
market = markets[#markets]
```


### 5. Fund the Market and Set the Initial Probabilities
Provide liquidity and define the starting probability distribution:
```lua
Outcome.marketAddFunding(
    market,           -- Market Process ID
    Outcome.mockDAI,  -- Collateral Token (Mock DAI for Quickstart)
    1000000,          -- Funding Amount
    {60,40}          -- Initial Probability Distribution (60% IN, 40% OUT)
)
```

### 6. Buy an Outcome Share
Trade outcome shares:
```lua
Outcome.marketBuy(
  market,           -- Market Process ID
  Outcome.mockDAI,  -- Collateral Token (Mock DAI for Quickstart)
  1000,             -- Investment Amount (in Collateral Tokens)
  "1",              -- Outcome Position ID
  900               -- Minimum Shares to Receive
) 
```

### 7. Resolve Market
Finalize the market outcome by reporting payouts:
```lua
Outcome.marketReportPayouts(
    market, -- Market Process ID
    {1,0}  -- Payout Distribution (100% to IN, 0% to OUT)
)
```

### 8. Redeem Shares
Claim winnings in collateral by redeeming outcome shares:
```lua
Outcome.marketRedeemPositions(market)
```

## Architecture

Outcome v2 follows a transient-style architecture, where each market operates as an independent process, executed with `market.lua` and initialized with market-specific parameters.

Markets are created permissionlessly via `marketFactory.lua`, gated by `ocmToken.lua` staking.

Market resolution is autonomous via `resolutionAgent.lua`, with optional support for single-signer and perpetual (zero-resolution) markets.

Core processes are **ownerless**, with `configurator.lua` managing time-gated updates through token governance.

## Contracts

| Contract                | Purpose                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------- |
| configurator.lua        | Stages time-delayed protocol updates. |
| cronRunner.lua          | Manages cron jobs: adding, removing and executing scheduled tasks. |
| market.lua              | Handles all prediction market functionality in a single process. |
| marketFactory.lua       | Spawns prediction markets permissionlessly, gated by utility token staking. |
| ocmToken.lua            | Rewards activity, gates market creation, and governs protocol updates. |
| platformData.lua        | Stores protocol logs and enables complex frontend queries. |
| resolutionAgent.lua     | Autonomously resolves markets, supporting single-signer and zero-resolution (perpetual) markets. |

## Roles

| Role    | Name            | Purpose                                 |
| --------| --------------- | --------------------------------------- |
| **`C`** | **Configurator**   | Oversees and applies protocol updates   |
| **`G`** | **Governance**     | Executes **Configurator** actions based on on-chain votes. |
| **`M`** | **Moderator**      | Moderates non-critical content.         |
| **`V`** | **Viewer**         | Executes complex SQL queries.           |

### Configurator

| Action                | Required Role                    | Required Tags                          | Optional Tags                   | Result                 | 
| --------------------- | -------------------------------- |-------------------------------------- | ------------------------------- | ---------------------- | 
| `Info`  | | | | `Info-Response` |  
| `Stage-Update`        | `G` | `UpdateProcess`: Valid Arweave address<br>`UpdateAction`: String | `UpdateTags`: Valid stringified Key-Value JSON<br>`UpdateData`: Valid Key-Value JSON | `Stage-Update-Notice` |
| `Unstage-Update`      | `G` | `UpdateProcess`: Valid Arweave address<br>`UpdateAction`: String | `UpdateTags`: Valid stringified Key-Value JSON<br>`UpdateData`: Valid Key-Value JSON | `Unstage-Update-Notice` | 
| `Action-Update`       | `G` | `UpdateProcess`: Valid Arweave address<br>`UpdateAction`: String | `UpdateTags`: Valid stringified Key-Value JSON<br>`UpdateData`: Valid Key-Value JSON | `Action-Update-Notice` |
| `Stage-Update-Admin`  | `G` | `UpdateAdmin`: Valid Arweave address | | `Stage-Update-Admin-Notice` | 
| `Unstage-Update-Admin`| `G` | `UpdateAdmin`: Valid Arweave address | | `Unstage-Update-Admin-Notice` |  
| `Action-Update-Admin` | `G` | `UpdateAdmin`: Valid Arweave address | | `Action-Update-Admin-Notice` | 
| `Stage-Update-Delay`  | `G` | `UpdateDelay`: Integer greater than 0 | | `Stage-Update-Delay-Notice` |
| `Unstage-Update-Delay`| `G` | `UpdateDelay`: Integer greater than 0 | | `Unstage-Update-Delay-Notice` | 
| `Action-Update-Delay` | `G` | `UpdateDelay`: Integer greater than 0 | | `Action-Update-Delay-Notice` |

### Cron Runner

| Action                | Required Tags                          | Optional Tags                   | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Info`      | | | `Info-Response` |
| `Add-Job`   | `ProcessId`: Valid Arweave address | | `Add-Job-Notice` |
| `Add-Jobs`   | `ProcessId`: Valid JSON Array of Arweave addresses | | `Add-Jobs-Notice` |
| `Remove-Job`   | `ProcessId`: Valid Arweave address | | `Remove-Job-Notice` |
| `Remove-Jobs`   | `ProcessId`:  Valid JSON Array of Arweave addresses | | `Remove-Jobs-Notice` |
| `Run-Jobs`   | | | `Run-Jobs-Notice` |

### Market

- An action marked with a star `(*)` represents the `X-Action` tag included in a `Transfer` targetting the market's collateral token with the market as recipient.
- An action marked with two stars `(**)` represents the `X-Action` tag included in a `Transfer` targetting the market (the market's LP token) with the market as recipient.

| Action                | Required Tags                          | Optional Tags                   | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Info`      | | | `Info-Response` |
| `Add-Funding(*)`        | `Quantity`: Integer greater than 0<br>`Recipient`: Valid Arweave address<br>`X-Distribution`: Valid JSON Array of Integers greater than 0 (**exclude after initial funding or the transaction will fail**) | `X-OnBehalfOf`: Valid Arweave address | `Add-Funding-Notice` |
| `Remove-Funding(**)`      | `Quantity`: Integer greater than 0 | | `Remove-Funding-Notice` |
| `Buy(*)`       | `Quantity`: Integer greater than 0s<br>`X-PositionId`: Integer greater than 0<br>`X-MinPositionTokensToBuy`: Integer greater than 0 |  `X-OnBehalfOf`: Valid Arweave address | `Buy-Notice` |
| `Sell`  | `Quantity`: Integer greater than 0s<br>`PositionId`: Integer greater than 0<br>`ReturnAmount`: Integer greater than 0  |  | `Sell-Notice` |
| `Withdraw-Fees`| | | `Withdraw-Fees-Notice` |
| `Calc-Buy-Amount` | `InvestmentAmount`: Integer greater than 0s<br>`PositionId`: Integer greater than 0 | | `Calc-Buy-Amount-Response` |
| `Calc-Sell-Amount` | `ReturnAmount`: Integer greater than 0s<br>`PositionId`: Integer greater than 0 | | `Calc-Sell-Amount-Response` |
| `Collected-Fees`| | | `Collected-Fees-Response` |
| `Fees-Withdrawable` | | | `Fees-Withdrawable-Response` |
| `Transfer` | `Quantity`: Integer greater than 0<br>`Recipient`: Valid Arweave address | `X-*`: Tags beginning with "X-" | `Debit-Notice`, `Credit-Notice` |
| `Balance` | | `Recipient`: Valid Arweave address | `Balance-Response` |
| `Balances` | | | `Balances-Response` |
| `Total-Supply`  | | | `Total-Supply-Response` |
| `Merge-Positions` | `Quantity`: Integer greater than 0 | | `Merge-Positions-Notice` |
| `Report-Payouts` | `Payouts`: Valid JSON Array of Integers greater than 0 | | `Report-Payouts-Notice` |
| `Redeem-Positions` | | | `Redeem-Positions-Notice` |
| `Get-Payout-Numerators` | | | `Get-Payout-Numerators-Response` |
| `Get-Payout-Denominator` | | | `Get-Payout-Denominator-Response` |
| `Transfer-Single` | `Quantity`: Integer greater than 0<br>`PositionId`: Integer greater than 0<br>`Recipient`: Valid Arweave address | `X-*`: Tags beginning with "X-" | `Debit-Single-Notice`, `Credit-Single-Notice` |
| `Transfer-Batch` | `Quantities`: Valid JSON Array of Integers greater than 0<br>`PositionIds`: Valid JSON Array of Integers greater than 0<br>`Recipient`: Valid Arweave address | `X-*`: Tags beginning with "X-" | `Debit-Batch-Notice`, `Credit-Batch-Notice` |
| `Balance-By-Id` | `PositionId`: Integer greater than 0 | `Recipient`: Valid Arweave address | `Balance-By-Id-Response` |
| `Balances-By-Id` | `PositionId`: Integer greater than 0 | | `Balances-By-Id-Response` |
| `Batch-Balance` | `PositionIds`: Valid JSON Array of Integers greater than 0<br>`Recipients`: Valid JSON Array of Arweave addresses | | `Batch-Balance-Response` |
| `Batch-Balances` | `PositionIds`: Valid JSON Array of Integers greater than 0 | | `Batch-Balances-Response` |
| `Update-Configurator` | `Configurator`: Valid Arweave address | | `Update-Configurator-Notice` |
| `Update-Incentives` | `Incentives`: Valid Arweave address | | `Update-Incentives-Notice` |
| `Update-Take-Fee` | `CreatorFee`: Integer greater than 0<br> `ProtocolFee`: Integer greater than 0 | | `Update-Take-Fee-Notice` |
| `Update-Protocol-Fee-Target` | `ProtocolFeeTarget`: Valid Arweave address | | `Update-Protocol-Fee-Target-Notice` |
| `Update-Logo` | `Logo`: String | | `Update-Logo-Notice` |

### Market Factory

| Action                | Required Tags                          | Optional Tags                   | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Info`      | | | `Info-Response` |
| `Spawn-Market`        | `ResolutionAgent`: Valid Arweave address<br>`CollateralToken`: Valid Arweave address<br>`Question`: String<br>`OutcomeSlotCount`: Integer greater or equal to 2<br>`Category`: String<br>`Subcategory`: String<br>`Logo`: String<br>`Rules`: String<br>`CreatorFee`: Integer greater than or equal to 0<br>`CreatorFeeTarget`: Valid Arweave address<br> | | `Spawn-Market-Notice` |
| `Init-Market`      | | | `Init-Market-Notice` |
| `Markets-Pending`       | | | `Markets-Pending-Response` |
| `Markets-Init`  | | | `Markets-Init-Response` |
| `Markets-By-Creator`| `Creator`: Valid Arweave address | | `Markets-By-Creator-Response` |
| `Get-Process-Id` | `Original-Msg-Id`: Valid Arweave address | | `Get-Process-Id-Response` |
| `Get-Latest-Process-Id-For-Creator`  | `Creator`:  Valid Arweave address | | `Get-Latest-Process-Id-For-Creator-Response` |
| `Update-Configurator`| `Configurator`:  Valid Arweave address | | `Update-Configurator-Notice` |
| `Update-Incentives` | `Incentives`:  Valid Arweave address | | `Update-Incentives-Notice` |
| `Update-Lp-Fee` | `LpFee`: Integer greater than or equal to 0 | | `Update-Lp-Fee-Notice` |
| `Update-Protocol-Fee` | `ProtocolFee`: Integer greater than or equal to 0 | | `Update-Protocol-Fee-Notice` |
| `Update-Protocol-Fee-Target` | `ProtocolFeeTarget`:  Valid Arweave address | | `Update-Protocol-Fee-Target-Notice` |
| `Update-Maximum-Take-Fee` | `MaximumTakeFee`: Integer greater than or equal to 0 | | `Update-Maximum-Take-Fee-Notice` |
| `Approve-Collateral-Token` | `CollateralToken`:  Valid Arweave address<br>`Approved`: Boolean (true or false) | | `Approve-Collateral-Token-Notice` |
| `Transfer` | `Token`:  Valid Arweave address<br>`Quantity`: Integer greater than 0<br>`Recipient`: Valid Arweave address | `X-*`: Tags beginning with "X-" | `Transfer-Notice`, `Transfer-Success-Notice` |

### OCM Token

| Action                | Required Tags                          | Optional Tags                   | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Info`      | | | `Info-Response` |
| `Claim`        |  | `OnBehalfOf`: Valid Arweave address | `Claim-Notice` |
| `Transfer`      | `Quantity`: Integer greater than 0<br>`Recipient`: Valid Arweave address | `X-*`: Tags beginning with "X-"| `Debit-Notice`, `Credit-Notice` |
| `Burn`       | `Quantity`: Integer greater than 0 | | `Burn-Notice` |
| `Claim-Balance` | | `Recipient`: Valid Arweave address | `Claim-Balance-Response` |
| `Claim-Balances` | | | `Claim-Balances-Response` |
| `Balance` | | `Recipient`: Valid Arweave address | `Balance-Response` |
| `Balances` | | | `Balances-Response` |
| `Total-Supply` | | | `Total-Supply-Response` |
| `Update-Configurator` | `Configurator`: Valid Arweave address | | `Update-Configurator-Notice` |
| `Update-LP-Holder-Ratio`| `UpdateDelay`: Integer greater than 0 | | `Unstage-Update-Delay-Notice` |
| `Update-Collateral-Prices` | `UpdateDelay`: Integer greater than 0 | | `Action-Update-Delay-Notice` |
| `Update-Collateral-Factors` | `UpdateDelay`: Integer greater than 0 | | `Action-Update-Delay-Notice` |
| `Update-Collateral-Denominations` | `UpdateDelay`: Integer greater than 0 | | `Action-Update-Delay-Notice` |

### Platform Data

**Note**: actions in `platformData.lua` are restricted and require proper permissions to execute.

| Action                | Required Tags                          | Optional Tags                   | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Info`      | | | `Info-Response` |
| `Log-Market` | `Market`: Valid Arweave address<br>`Creator`: Valid Arweave address<br>`CreatorFee`: Integer greater than or equal to 0`CreatorFeeTarget`: Valid Arweave address<br>`Question`: String<br>`Rules`: String<br>`OutcomeSlotCount`: Integer greater than or equal to 2<br>`Collateral`: Valid Arweave address<br>`ResolutionAgent`: Valid Arweave address<br>`Category`: String<br>`Subcategory`: String<br>`Logo`: String | | `Log-Market-Notice` |
| `Log-Funding` | `User`: Valid Arweave address<br>`Operation`: String ("add" or "remove")<br>`Collateral`: Valid Arweave address<br>`Quantity`: Integer greater than 0 | | `Log-Funding-Notice` |
| `Log-Prediction`| `User`: Valid Arweave address<br>`Operation`: String ("buy" or "sell")<br>`Collateral`: Valid Arweave address<br>`Quantity`: Integer greater than 0<br>`Outcome`: Integer greater than 0<br>`Shares`: Integer greater than 0<br>`Price`: Decimal greater than 0 | | `Log-Prediction-Notice` |
| `Log-Probabilities`  | `Probabilities`: Valid JSON Array of decimals greater than or equal to 0 | | `Log-Probabilities-Notice` |
| `Broadcast`| `Market`: Valid Arweave address<br>`Data`: String | | `Broadcast-Notice` |
| `Query` | `Data`: Valid SQL Query | | `Query-Response` |
| `Get-Market` | `Market`: Valid Arweave address | | `Get-Market-Response` |
| `Get-Markets`| | `Status`: String ("open", "resolved" or "closed")<br>`Collateral`: Valid Arweave address<br>`MinFunding`: Integer greater than or equal to 0<br>`Creator`: Valid Arweave address<br>`Category`: String<br>`Subcategory`: String<br>`Keyword`: String<br>`OrderBy`: String ("timestamp" or "question", default: "timestamp")<br>`OrderDirections`: Valid Arweave address ("ASC" or "DESC")<br>`Limit`: Integer greater than 0 (default: 12)<br>`Offset`: Integer greater than or equal to 0 (default: 0) | `Get-Market-Response` |
| `Get-Broadcasts` | `Market`: Valid Arweave address | `OrderDirections`: Valid Arweave address ("ASC" or "DESC")<br>`Limit`: Integer greater than 0 (default: 50)<br>`Offset`: Integer greater than or equal to 0 (default: 0) | `Get-Broadcasts-Response` |
| `Set-User-Silence` | `User`: Valid Arweave address<br>`Silenced`: Boolean ("true" or "false") | | `Set-User-Silence-Notice` |
| `Set-Message-Visibility` | `Entity`: String ("message" or "user")<br>`EntityId`: Valid Arweave address<br>`Visible`: Boolean ("true" or "false") | | `Set-Message-Visibility-Notice` |
| `Delete-Messages` | `Entity`: String ("message" or "user")<br>`EntityId`: Valid Arweave address | | `Delete-Messages-Notice` |
| `Delete-Old-Messages` | `Days`: Integer greater than 0 | | `Delete-Old-Messages-Notice` |
| `Update-Configurator` | `Configurator`: Valid Arweave address | | `Update-Configurator-Notice` |
| `Update-Moderators` | `Moderators`: Valid JSON Array of Arweave addresses | | `Update-Moderators-Notice` |
| `Update-Readers` | `Readers`: Valid JSON Array of Arweave addresses | | `Update-Readers-Notice` |

### Resolution Agent

TODO

## Repository Structure

All contracts reside in `/src`. Each contract consists of:
1. A **top-level contract file** (e.g., `configurator.lua`), which acts as the main entry point, handling actions and instantiating processes.
2. A corresponding **module subfolder** (e.g., `/configuratorModules/`), which contains:
   - **Core Logic** – Defines contract behavior and execution.
   - **Output Notices** – Handles emitted events and responses.
   - **Input Validation** – Ensures valid data and transaction integrity.

Unit and integration tests are located in the `/test` folder.

```ml
src 
└─ configuratorModules 
  └─ configurator.lua
  └─ configuratorNotices.lua
  └─ configuratorValidation.lua
  └─ ...
└─ cronRunnerModules
  └─ ... 
└─ marketFactoryModules
  └─ ...
└─ marketModules
  └─ ... 
└─ ocmTokenModules 
  └─ ...
└─ platformData
  └─ ... 
└─ configurator.lua
└─ cronRunner.lua
└─ market.lua
└─ marketFactory.lua
└─ ocmToken.lua
└─ outcome.lua
└─ platformData.lua
└─ resolutionAgent.lua
└─ ...
test  
  └─ integration
    └─ configurator_test.js
    └─ ...
  └─ unit
    └─ configurator_spec.lua
    └─ ...
```

## Outcome Package

The `outcome.lua` package offers a streamlined interface for interacting with Outcome v2, an automated market maker and prediction market protocol built on AO.

Developers can load or require the package to execute actions efficiently across protocol processes.

### Installation

To install AOS, run:
```bash
yarn global add https://get_ao.g8way.io
```

### Loading the Outcome Package

To load the Outcome package into AOS, run:
```bash
aos --load src/outcome.lua
```

### Usage example

Run an action, such as retrieving **configurator information**:
```lua
Outcome.configuratorInfo()
```

### Available Methods

| Method                | Required Parameters                    | Optional Parameters             | Result                 |
| --------------------- | -------------------------------------- | ------------------------------- | ---------------------- |
| `Outcome.configuratorInfo()`        |  |  | `Configurator-Info-Response` |
| `Outcome.configuratorStageUpdate(updateProcess, updateAction, updateTags, updateData)` | `updateProcess`: Valid Arweave address<br>`updateAction`: String | `updateTags`: Valid stringified Key-Value JSON or `nil`<br>`updateData`: Valid stringified Key-Value JSON or `nil` | `Stage-Update-Notice` |
| `Outcome.configuratorUnstageUpdate(updateProcess, updateAction, updateTags, updateData)` | `updateProcess`: Valid Arweave address<br>`updateAction`: String | `updateTags`: Valid stringified Key-Value JSON or `nil`<br>`updateData`: Valid stringified Key-Value JSON or `nil` | `Unstage-Update-Notice` |
| `Outcome.configuratorActionUpdate(updateProcess, updateAction, updateTags, updateData)` | `updateProcess`: Valid Arweave address<br>`updateAction`: String | `updateTags`: Valid stringified Key-Value JSON or `nil`<br>`updateData`: Valid stringified Key-Value JSON or `nil` | `Action-Update-Notice` |
| `Outcome.configuratorStageUpdateAdmin(updateAdmin)` | `updateAdmin`: Valid Arweave address | | `Stage-Update-Admin-Notice` |
| `Outcome.configuratorUnstageUpdateAdmin(updateAdmin)` | `updateAdmin`: Valid Arweave address | | `Unstage-Update-Admin-Notice` |
| `Outcome.configuratorActionUpdateAdmin(updateAdmin)` | `updateAdmin`: Valid Arweave address | | `Action-Update-Admin-Notice` |
| `Outcome.configuratorStageUpdateDelay(updateDelay)` | `updateDelay`: Integer greater than or equal to 0 | | `Stage-Update-Delay-Notice` |
| `Outcome.configuratorUnstageUpdateDelay(updateDelay)` | `updateDelay`: Integer greater than or equal to 0 | | `Unstage-Update-Delay-Notice` |
| `Outcome.configuratorActionUpdateDelay(updateDelay)` | `updateDelay`: Integer greater than or equal to 0 | | `Action-Update-Delay-Notice` |
| `Outcome.marketInfo()`        |  |  | `Market-Info-Response` |
| `Outcome.marketAddFunding(market, collateral, quantity, distribution, onBehalfOf)` | `market`: Valid Arweave address<br>`collateral`: Valid Arweave address<br>`quantity`: Integer greater than 0<br>`distribution`: Table of integers greater than or equal to 0 | `onBehalfOf`: Valid Arweave address or `nil` | `Market-Add-Funding-Notice` |
| `Outcome.marketRemoveFunding(market, quantity)`  |  `market`: Valid Arweave address<br>`quantity`: Integer greater than 0 |  | `Market-Remove-Funding-Notice` |
| `Outcome.marketBuy(market, collateral, quantity, positionId, minPositionTokensToBuy, onBehalfOf)` | `market`: Valid Arweave address<br>`collateral`: Valid Arweave address<br>`quantity`: Integer greater than 0<br>`positionId`: Integer greater than 0<br>`minPositionTokensToBuy`: Integer greater than or equal to 0 | `onBehalfOf`: Valid Arweave address or `nil` | `Market-Buy-Notice` |
| `Outcome.marketSell(market, quantity, positionId, returnAmount)`  |  `market`: Valid Arweave address<br>`quantity`: Integer greater than 0<br>`positionId`: Integer greater than 0<br>`returnAmount`: Integer greater than 0 |  | `Market-Sell-Notice` |
| `Outcome.marketWithdrawFees(market)` | `market`: Valid Arweave address |  | `Market-Withdraw-Fees-Notice` |
| `Outcome.marketCalcBuyAmount(market, investmentAmount, positionId)`  | `market`: Valid Arweave address<br>`investmentAmount`: Integer greater than 0<br>`positionId`: Integer greater than 0 |  | `Market-Calc-Buy-Amount-Response` |
| `Outcome.marketCalcSellAmount(market, returnAmount, positionId)`| `market`: Valid Arweave address<br>`returnAmount`: Integer greater than 0<br>`positionId`: Integer greater than 0 |  | `Market-Calc-Sell-Amount-Response` |
| `Outcome.marketCollectedFees(market)` | `market`: Valid Arweave address |  | `Market-Collected-Fees-Response` |
| `Outcome.marketFeesWithdrawable(market, account)` |  `market`: Valid Arweave address<br>`account`: Valid Arweave address |  | `Market-Fees-Withdrawable-Response` |
| `Outcome.marketLpTokenTransfer(market, recipient, quantity)`  | `market`: Valid Arweave address<br>`recipient`: Valid Arweave address<br>`quantity`: Integer greater than 0 | `X-*`: Tags beginning with "X-" | `Market-LP-Token-Debit-Notice`, `Market-LP-Token-Credit-Notice`, `Market-Withdraw-Fees-Notice` |
| `Outcome.marketLpTokenBalance(market, recipient)` | `market`: Valid Arweave address | `recipient`: Valid Arweave address or `nil` | `Market-LP-Token-Balance-Response` |
| `Outcome.marketLpTokenBalances(market)`|  `market`: Valid Arweave address |  | `Market-LP-Token-Balances-Response` |
| `Outcome.marketLpTokenTotalSupply(market)`|  `market`: Valid Arweave address |  | `Market-LP-Token-Total-Supply-Response` |
| `Outcome.marketMergePositions(market, quantity, onBehalfOf)` | `market`: Valid Arweave address<br>`quantity`: Integer greater than 0  | `onBehalfOf`: Valid Arweave address or `nil` | `Market-Merge-Positions-Notice`, `Market-Positions-Batch-Burn-Notice`, `Market-Collateral-Credit-Notice`|
| `Outcome.marketReportPayouts(market, payouts)`  | `market`: Valid Arweave address<br>`payouts`: Valid table of integers greater than or equal to 0 |  | `Market-Report-Payouts-Notice` |
| `Outcome.marketRedeemPositions()` |  |  | `Market-Redeem-Positions-Notice`, `Market-Positions-Burn-Single-Notice`, `Market-Collateral-Credit-Notice`  |
| `Outcome.marketPositionTransfer(market, quantity, positionId, recipient)`  |  `market`: Valid Arweave address<br>`quantity`: Integer greater than 0<br>`positionId`: Integer greater than 0<br>`recipient`: Valid Arweave address<br> | `X-*`: Tags beginning with "X-" | `Market-Position-Debit-Single-Notice`, `Market-Position-Credit-Single-Notice`|
| `Outcome.marketPositionTransferBatch(market, quantities, positionIds, recipient)` | `market`: Valid Arweave address<br>`quantities`: Valid JSON Array of integers greater than 0<br>`positionId`: Valid JSON Array of integers greater than 0<br>`recipient`: Valid Arweave address<br> | `X-*`: Tags beginning with "X-" | `Market-Position-Debit-Batch-Notice`, `Market-Position-Credit-Batch-Notice`|
| `Outcome.marketGetPayoutNumerators(market)`  | `market`: Valid Arweave address |  | `Get-Numerators-Response` |
| `Outcome.marketGetPayoutDenominator(market)`  | `market`: Valid Arweave address |  | `Get-Denominator-Response` |
| `Outcome.marketPositionBalance(market, positionId, recipient)` |  `market`: Valid Arweave address<br>`positionId`: Integer greater than 0 |  `recipient`: Valid Arweave address or `nil` | `Market-Position-Balance-Response` |
| `Outcome.marketPositionBalances(market, positionId)`|  `market`: Valid Arweave address<br>`positionId`: Integer greater than 0 |  | `Market-Position-Balances-Response` |
| `Outcome.marketPositionBatchBalance(market, positionIds, recipients)` | `market`: Valid Arweave address<br>`positionIds`: Valid JSON Array of integers greater than 0<br>`recipient`: Valid JSON Array of Arweave addresses | | `Market-Position-Batch-Balance-Response` |
| `Outcome.marketPositionBatchBalances(market, positionIds)` | `market`: Valid Arweave address<br>`positionIds`: Valid JSON Array of integers greater than 0 | | `Market-Position-Batch-Balances-Response` |
| `Outcome.marketUpdateConfigurator(market, configurator)`  | `market`: Valid Arweave address<br>`configurator`: Valid Arweave address |  | `Market-Update-Configurator-Notice` |
| `Outcome.marketUpdateIncentives(market, incentives)`   | `market`: Valid Arweave address<br>`incentives`: Valid Arweave address |  | `Market-Update-Incentives-Notice` |
| `Outcome.marketUpdateTakeFee(market, creatorFee, protocolFee)`  | `market`: Valid Arweave address<br>`creatorFee`: Integer greater than or equal to 0<br>`protocolFee`: Integer greater than or equal to 0 |  | `Market-Update-Take-Fee-Notice` |
| `Outcome.marketUpdateProtocolFeeTarget(market, protocolFeeTarget)` | `market`: Valid Arweave address<br>`protocolFeeTarget`: Valid Arweave address |  | `Market-Update-Protocol-Fee-Target-Notice` |
| `Outcome.marketUpdateLogo(market, logo)`  | `market`: Valid Arweave address<br>`logo`: String |  | `Market-Update-Logo-Notice` |
| `Outcome.marketFactoryInfo()`        |  |  | `Market-Factory-Info-Response` |
| `Outcome.marketFactorySpawnMarket(resolutionAgent, collateralToken, question, outcomeSlotCount, category, subcategory, logo, rules, creatorFee, creatorFeeTarget)`  |  `resolutionAgent`: Valid Arweave address<br>`collateralToken`: Valid Arweave address<br>`question`: String<br>`outcomeSlotCount`: Integer greater than or equal to 2<br>`category`: String<br>`subcategory`: String<br>`logo`:String<br>`rules`: String<br>`creatorFee`: Integer greater than or equal to 0<br>`creatorFeeTarget`: Valid Arweave address  |  | `Market-Factory-Spawn-Market-Notice` |
| `Outcome.marketFactoryInitMarket()`        |  |  | `Market-Factory-Init-Market-Notice` |
| `Outcome.marketFactoryMarketsPending()`        |  |  | `Market-Factory-Markets-Pending-Response` |
| `Outcome.marketFactoryMarketsInit()`        |  |  | `Market-Factory-Markets-Init-Response` |
| `Outcome.marketFactoryMarketsByCreator()`        |  |  | `Market-Factory-Markets-By-Creator-Response` |
| `Outcome.marketFactoryGetProcessId()`        |  |  | `Market-Factory-Get-Process-Id-Response` |
| `Outcome.marketFactoryGetLatestProcessIdForCreator()`        |  |  | `Market-Factory-Get-Latest-Process-Id-For-Creator-Response` |
| `Outcome.marketFactoryUpdateConfigurator(configurator)` |  `configurator`: Valid Arweave address |  | `Market-Factory-Update-Configurator-Notice` |
| `Outcome.marketFactoryUpdateIncentives(incentives)` | `incentives`: Valid Arweave address |  | `Market-Factory-Update-Incentives-Notice` |
| `Outcome.marketFactoryUpdateLpFee(lpFee)`   |  `lpFee`: Integer greater than or equal to 0 |  | `Market-Factory-Update-LP-Fee-Notice` |
| `Outcome.marketFactoryUpdateProtocolFee(protocolFee)`  |  `protocolFee`: Integer greater than or equal to 0 |  | `Market-Factory-Update-Protocol-Fee-Notice` |
| `Outcome.marketFactoryUpdateProtocolFeeTarget(protocolFeeTarget)` | `protocolFeeTarget`: Valid Arweave address |  | `Market-Factory-Update-Protocol-Fee-Target-Notice` |
| `Outcome.marketFactoryUpdateMaximumTakeFee(maximumTakeFee)` |  `maximumTakeFee`: Integer greater than or equal to 0 |  | `Market-Factory-Update-Maximum-Take-Fee-Notice` |
| `Outcome.marketFactoryApproveCollateral(collateral, approved)` |  `collateral`: Valid Arweave address<br>`approved`: Boolean (`true` or `false`) |  | `Market-Factory-Approve-Collateral-Notice` |
| `Outcome.marketFactoryTransfer(token, quantity, recipient)`  | `token`: Valid Arweave address<br>`quantity`: Integer greater than 0<br>`recipient`: Valid Arweave address |  | `Market-Factory-Transfer-Notice`, `Market-Factory-Transfer-Success-Notice` |
| `Outcome.tokenInfo()` |  |  | `Token-Info-Response` |
| `Outcome.tokenClaim()` |  |  | `Token-Claim-Notice`, `Token-Credit-Notice` |
| `Outcome.tokenTransfer(quantity, recipient)` | `quantity`: Integer greater than 0<br>`recipient`: Valid Arweave address |  `X-*`: Tags beginning with "X-" | `Token-Debit-Notice`, `Token-Credit-Notice` |
| `Outcome.tokenBurn(quantity)` |  `quantity`: Integer greater than 0 |  | `Token-Burn-Notice` |
| `Outcome.tokenUpdateLpHolderRatio(ratio)` | `ratio`: Decimal greater than 0 |  | `Token-Info-Response` |
| `Outcome.tokenUpdateCollateralPrices(collateralPrices)` | `collateralPrices`: Valid table of <Arweave address, Integer greater than 0> mappings |  | `Token-Update-Collateral-Prices-Notice` |
| `Outcome.tokenUpdateCollateralFactors(collateralFactors)` |  `collateralFactors`: Valid table of <Arweave address, Decimal greater than 0> mappings |  | `Token-Update-Collateral-Factors-Notice` |
| `Outcome.tokenUpdateCollateralDenominations(collateralDenominations)` | `collateralDenominations`: Valid table of <Arweave address, Integer greater than 0> mappings |  | `Token-Update-Collateral-Denominations-Notice` |
| `Outcome.tokenUpdateConfigurator(configurator)` | `configurator`: Valid Arweave address |  | `Token-Update-Configurator-Notice` |
| `Outcome.tokenBalance(account)` |  | `account`: Valid Arweave address or `nil` | `Token-Balance-Response` |
| `Outcome.tokenBalances()` |  |  | `Token-Balances-Response` |
| `Outcome.tokenTotalSupply()` |  |  | `Token-Total-Supply-Response` |
| `Outcome.tokenClaimBalance(account)` |  | `account`: Valid Arweave address or `nil` | `Token-Claim-Balance-Response` |
| `Outcome.tokenClaimBalances()` |  |  | `Token-Claim-Balances-Response` |


## Testing

### Unit Tests

Run unit tests:
```bash
yarn test:unit
```

Check test coverage:
```bash
yarn test:unit
```

### Integration Tests

Before running integration tests, ensure your local Arweave wallet JSON files are in the project root:
- `./wallet.json` – Primary wallet for deploying and testing  
- `./wallet2.json` – Secondary wallet for additional tests  

Rn integration tests: 
```bash
yarn test:integration   
```

To run a specific integration test, run: 
```bash
yarn test:integration:{PROCESS}
```

To redeploy and run a specific integration test, run: 
```bash
yarn test:integration:{PROCESS}:clean
```