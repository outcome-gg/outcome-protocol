```mermaid
sequenceDiagram
participant Sender
participant Recipient
box Purple Market Process
participant Market Handlers
participant CPMM
participant LP Token
end
participant Collateral Token

Sender ->> Market Handlers: Send "Transfer" message
alt Input validation fails
  Market Handlers ->> Sender: "Transfer-Error" message
else Input validation succeeds
  Market Handlers ->> CPMM: Transfer
  alt There are fees withdrawable by the sender
    CPMM ->> Collateral Token: Send "Transfer" message to withdraw fees
    Collateral Token -->> Market Handlers: "Debit-Notice"
    Collateral Token -->> Sender: "Credit-Notice"
  end
  CPMM -->> Sender: "Withdraw-Fees-Notice" (with quantity = "0" for no fees)
  CPMM ->> LP Token: Transfer
  LP Token -->> Sender: "Debit-Notice"
  LP Token -->> Recipient: "Credit-Notice"
end
```