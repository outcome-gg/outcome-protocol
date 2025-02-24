```mermaid
sequenceDiagram
participant Trader
box Purple Market Process
participant Market Handlers
participant CPMM
participant Position Tokens
participant LP Token
end
participant Collateral Token


Trader ->> Market Handlers: Send "Sell" message
alt Input validation fails
  Market Handlers ->> Trader: "Sell-Error" message
else Input validation succeeds
  Market Handlers ->> CPMM: Sell
  CPMM ->> Position Tokens: Transfer single position from seller
  Position Tokens -->> Trader: "Debit-Single-Notice"
  Position Tokens -->> Market Handlers: "Credit-Single-Notice"
  CPMM ->> Position Tokens: Merge positions back to collateral
  Position Tokens ->> Position Tokens: Batch burn positions
  Position Tokens -->> Market Handlers: "Burn-Batch-Notice"
  Position Tokens -->> Market Handlers: "Positions-Merge-Notice"
  CPMM ->> Collateral Token: Send "Transfer" message to return collateral
  Collateral Token -->> Market Handlers: "Debit-Notice"
  Collateral Token -->> Trader: "Credit-Notice"
  alt There are remaining unburned positions
    Position Tokens -->> Market Handlers: "Debit-Single-Notice"
    Position Tokens -->> Trader: "Credit-Single-Notice"
  end
  CPMM -->> Trader: "Sell-Notice"
end
```