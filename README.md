# Outcome Protocol

## Processes

| Process Name                     | SLOC | Purpose                                                                                                                                                                                               |
| --------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| src/agents/dataAgent.lua             | 330  | A process used to request, retrieve and subscribe to data feeds sources from Oracles.                                                                                                                                |
| src/agents/predictionAgent.lua       | 2  | A process that subscribes to a DataAgent to enter and exit prediction positions.                                                                                                                              |
| src/agents/resolutionAgent.lua                     | 154   | A process that can be polled and/or subscribes to receive data from a DataAgent to resolve a market. to .                                                                                                                             |
| src/agents/serviceAgent.lua               | 2  | An internal agent used to periodically fetch data and update the DataIndex.                                                                                      |
| src/core/configurator.lua                | 2  | The single point of Admin / Emergency Admin entry to update Core processes.                                                 |
| src/core/cronManager.lua           | 2  | A process used to schedule, trigger and pause periodic cron jobs.                         |
| src/core/dataIndex.lua         | 1472   | The protocol's DB. Non-critical data storage used to facilitate complex quieries made by the frontend.                                                                                                                                                                   |
| src/core/dbAdmin.lua             | 38  | An open-source AO SqLite process placed here to be accessed by the DataIndex.                    |
| src/core/marketFoundry.lua             | 9  | Used to spawn fully-autonomous markets: a collection of AMM, DataAgent and ResolutionAgent processes. |
| src/core/orderBook.lua               | 2   | Used to create limit orders. Sits on top of each market's AMM to offer hybrid market+limit order book.                                                                                                                                                                    |
| src/core/outcomeToken.lua             | 248   | Outcome's utility token.                                                                                                                                             |
| src/market/CPMM.lua      | 1307  | A Fixed Price Market Maker designed for binary tokens.                                                                                                                                                                     |
| src/market/conditionalTokens.lua            | 916  | Conditional Framework Tokens to enable combinatorial market positions, based on those developed by Gnosis.                                                                                                                                                         |
| src/oracles/dexi.lua    | 2   | Oracle process for Dexi integration.                                                                                                                                                                   |
| src/oracles/orbit.lua | 2   | Oracle process for 0rbit integration.                                                                                                                                                                    |
| src/oracles/tau.lua     | 2   | Oracle process for Tau integration.                                                                                                                                                                                           |                         |
| **Total**                         | 4488 |

```ml
src
└─ agents
  └─ dataAgent.lua
  └─ dbAdmin.lua
  └─ predictionAgent.lua
  └─ resolutionAgent.lua
  └─ serviceAgent.lua
└─ core
  └─ configurator.lua
  └─ cronManager.lua
  └─ dataIndex.lua
  └─ dbAdmin.lua
  └─ marketFoundry.lua
  └─ orderBook.lua
  └─ outcomeToken.lua
└─ market
  └─ CPMM.lua
  └─ conditionalTokens.lua
└─ oracles
  └─ dexi.lua
  └─ orbit.lua
  └─ tau.lua 
```
For more details on the Outcome protocol and its processes, please see the [docs](https://docs.outcome.gg). 

## Setup

Outcome is built on AOS 2.0 to include aoSqLite functionality. 

To install AOS 2.0, currently, run: 
```
npm i -g https://preview_ao.g8way.io
```

To setup locally add Arweave Wallet json file(s) to root, named:
- `./wallet.json` (for deployment and testing)
- `./wallet2.json` (for testing)

## Deploy

To deploy test processes, run:
```
yarn test:deploy
```

To deploy prod processes, run:
```
yarn prod:deploy
```

## Tests

Unit tests and integration tests are located in `/test/unit` and `/test/integration`, respectively.

To run unit tests, run:
```
yarn test:unit
```

To run a specific unit test, run:
```
yarn test:unit:{FOLDER}:{PROCESS}
```

To run integration tests, run: 
```
yarn test:integration   
```

To run a specific integration test, run: 
```
yarn test:integration:{PROCESS}
```

To redeploy and run a specific integration test, run: 
```
yarn test:integration:{PROCESS}:clean
```