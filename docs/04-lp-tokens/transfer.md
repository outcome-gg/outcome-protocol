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

%% 🟢 Transfer Request
Sender ->> Market Handlers: Send "Transfer" message

alt Input validation fails
  %% ❌ Error Notice
  Market Handlers ->> Sender: "Transfer-Error" message
else Input validation succeeds
  Market Handlers ->> CPMM: Process Transfer

  alt There are fees withdrawable by the sender
    %% 💵 Withdrawable Fees Detected
    CPMM ->> Collateral Token: Send "Transfer" message to withdraw fees
    Collateral Token -->> Market Handlers: "Debit-Notice"
    Collateral Token -->> Sender: "Credit-Notice"
  end

  %% ✅ Fees Withdrawal Completed
  CPMM -->> Sender: "Withdraw-Fees-Notice" (with quantity = "0" for no fees)

  %% 🔄 Processing Asset Transfer
  CPMM ->> LP Token: Transfer Assets
  LP Token -->> Sender: "Debit-Notice"
  LP Token -->> Recipient: "Credit-Notice"
end

```