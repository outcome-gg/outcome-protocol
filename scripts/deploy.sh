#!/bin/bash

# Ensure the .env file exists
touch .env

# Function to start a server, load a script, capture the process ID, and terminate it
create_or_update_process() {
    PROCESS_NAME=$1
    SCRIPT_PATH=$2
    SCRIPT_TAG=$3
    PROCESS_ID_VAR="${PROCESS_NAME}"

    # Use expect to interact with the server, capture the process ID, load the script, and exit
    PROCESS_OUTPUT=$(expect -c "
    log_user 0
    spawn aos \"$PROCESS_NAME\" $SCRIPT_TAG
    log_user 1
    expect {
        -re {Your AOS process: ([a-zA-Z0-9_-]+)} {
            set process_id \$expect_out(1,string)
            send_user \"\$process_id\n\"
        }
        \">\" {
            send \".load $SCRIPT_PATH\r\"
        }
    }
    expect {
        \">\" {
            send \"exit\r\"
        }
    }
    expect eof
    ")

    # Extract and clean up the process ID from the output
    PROCESS_ID=$(echo "$PROCESS_OUTPUT" | sed -e 's/\x1B\[[0-9;]*[JKmsu]//g' | awk '/Your AOS process:/ {print $4}')

    # Save or update the Process ID in the .env file
    if grep -q "^${PROCESS_ID_VAR}=" .env; then
        # Update existing entry
        sed -i.bak "s/^${PROCESS_ID_VAR}=.*/${PROCESS_ID_VAR}=${PROCESS_ID}/" .env
    else
        # Add new entry
        echo "${PROCESS_ID_VAR}=${PROCESS_ID}" >> .env
    fi
}

# Check for command-line argument
if [ "$1" == "test" ]; then
    echo "Running in TEST mode..."
    # Deploy core contracts
    create_or_update_process TEST_DATA_INDEX4 src/core/dataIndex.lua --sqlite
    create_or_update_process TEST_MARKET_FOUNDRY4 src/core/marketFoundry.lua --sqlite
    # Deploy market contracts
    create_or_update_process TEST_CONDITIONAL_TOKENS2 src/conditionalTokens/conditionalTokens.lua
    create_or_update_process TEST_DLOB src/market/market.lua
    create_or_update_process TEST_AMM4 src/amm/amm.lua
    # Deploy mock contracts
    create_or_update_process TEST_COLLATERAL_TOKEN3 src/mock/token.lua
    # Deploy agents
    create_or_update_process TEST_DATA_AGENT src/agents/dataAgent0rbit.lua
    
elif [ "$1" == "prod" ]; then
    echo "Running in PROD mode..."
    # Deploy core contracts
    create_or_update_process PROD_DATA_INDEX4 src/core/dataIndex.lua --sqlite
    create_or_update_process PROD_MARKET_FOUNDRY4 src/core/marketFoundry.lua --sqlite
    # Deploy market contracts
    create_or_update_process PROD_CONDITIONAL_TOKENS src/conditionalTokens/conditionalTokens.lua
    create_or_update_process PROD_DLOB src/market/market.lua
else
    echo "Usage: $0 {test|prod}"
    exit 1
fi
