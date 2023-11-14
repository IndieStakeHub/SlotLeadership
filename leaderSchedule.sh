#!/bin/bash

# Set your own stake pool ID
STAKE_POOL_ID=""

# Check if cardano-cli is in the PATH
if ! command -v cardano-cli &> /dev/null; then
    echo "Error: cardano-cli not found. Make sure it is in your PATH."
    exit 1
fi

# cardano node directory
DIRECTORY="$NODE_HOME"

if [[ ! -d "$DIRECTORY/logs" ]]; then mkdir -p "$DIRECTORY/logs"; fi

# Create a pid, this way you can ps aux | grep leaderScheduleCheck.sh to see if the script is running
echo $$ > "$DIRECTORY/logs/leaderScheduleCheck.pid";

TESTNET="testnet"
MAINNET="mainnet"

# Set the network magic value as needed for the testnet environment that you want to use
# For details on available testnet environments, see https://book.world.dev.cardano.org/environments.html
MAGICNUMBER="1"

# Edit variable with $TESTNET for Testnet and $MAINNET for Mainnet
network=$MAINNET

# Check for vrf.skey presence
if [[ ! -f "$DIRECTORY/vrf.skey" ]]; then
    echo "vrf.skey not found";
    exit 1;
fi

CCLI=$(command -v cardano-cli)
JQ=$(command -v jq)

if [[ -z $CCLI || -z $JQ ]]; then
    echo "cardano-cli or jq command not found, exiting...";
    exit 1;
fi

BYRON_GENESIS=($(jq -r '[ .startTime, .protocolConsts.k, .blockVersionData.slotDuration ] |@tsv' < "$DIRECTORY/$network-byron-genesis.json"))

if [[ -z "${BYRON_GENESIS[*]}" ]]; then
    echo "BYRON GENESIS config file not loaded correctly";
    exit 1;
fi

network_magic="--mainnet"

# Check that the node is synced
function isSynced() {
    local sync_progress
    sync_progress=$($CCLI query tip $network_magic | jq -r ".syncProgress")
    [[ $sync_progress == "100.00" ]]
}

# Get current epoch
function getCurrentEpoch() {
    $CCLI query tip $network_magic | jq -r ".epoch"
}

# Get epoch start time based on the current one
function getEpochStartTime() {
    local byron_genesis_start_time=${BYRON_GENESIS[0]}
    local byron_k=${BYRON_GENESIS[1]}
    local byron_epoch_length=$((10 * byron_k))
    local byron_slot_length=${BYRON_GENESIS[2]}
    echo $((byron_genesis_start_time + (($(getCurrentEpoch) * byron_epoch_length * byron_slot_length) / 1000)))
}

# Get epoch end time based on the current one
function getEpochEndTime() {
    echo $(( $(getEpochStartTime) + (5 * 86400) - 600 ))
}

# Get current timestamp
function getCurrentTime() {
    printf '%(%s)T\n' -1
}

# Convert timestamps to UTC time
function timestampToUTC() {
    local timestamp=$1
    date +"%D %T" -ud @"$timestamp"
}

# Find the correct time to run the leaderslot check command
function getLeaderslotCheckTime() {
    local epochStartTime=$(getEpochStartTime)
    local epochEndTime=$(getEpochEndTime)
    local percentage=75
    echo $((epochStartTime + (percentage * (epochEndTime - epochStartTime) / 100)))
}

# Function to make the script sleep until the check needs to be executed
function sleepUntil() {
    local sleepSeconds=$1
    [[ $sleepSeconds -gt 0 ]] && sleep $sleepSeconds
}

# Check leaderschedule of the next epoch
function checkLeadershipSchedule() {
    local next_epoch=$(( $(getCurrentEpoch) + 1 ))
    local currentTime=$(getCurrentTime)
    local timestampCheckLeaders=$(getLeaderslotCheckTime)

    echo "Check is running at: $(timestampToUTC "$currentTime") for epoch: $next_epoch"

    # Cardano leadership query
    local leader_schedule_file="$DIRECTORY/logs/leaderSchedule_$next_epoch.txt"

    if [ ! -f "$leader_schedule_file" ]; then
        echo "Leadership Query Starting for POOL - $STAKE_POOL_ID"
        $CCLI query leadership-schedule $network_magic --genesis "$DIRECTORY/shelley-genesis.json" --stake-pool-id "$STAKE_POOL_ID" --vrf-signing-key-file "$DIRECTORY/vrf.skey" --next > "$leader_schedule_file"
        echo "Leadership Query - Finished"

        # Removing first two lines
        tail -n +3 "$leader_schedule_file" > "$leader_schedule_file.tmp" && mv "$leader_schedule_file.tmp" "$leader_schedule_file"

        # Writing in Grafana CSV format
        awk '{print $2,$3","$1","NR}' "$leader_schedule_file" > "$DIRECTORY/logs/slot.csv"
        sed -i '1 i\Time,Slot,No' "$DIRECTORY/logs/slot.csv"

        # Cleaning up
        rm "$leader_schedule_file"

        # Show Result
        cat "$DIRECTORY/logs/slot.csv"
    else
        echo "Leadership schedule file already exists: $leader_schedule_file"
    fi
}

if isSynced; then
    echo "Current epoch: $(getCurrentEpoch)"

    local epochStartTimestamp=$(getEpochStartTime)
    echo "Epoch start time: $(timestampToUTC "$epochStartTimestamp")"

    local epochEndTimestamp=$(getEpochEndTime)
    echo "Epoch end time: $(timestampToUTC "$epochEndTimestamp")"

    local currentTime=$(getCurrentTime)
    echo "Current cron execution time: $(timestampToUTC "$currentTime")"

    local timestampCheckLeaders=$(getLeaderslotCheckTime)
    echo "Next check time: $(timestampToUTC "$timestampCheckLeaders")"

    local timeDifference=$((timestampCheckLeaders - currentTime))
    if [ -f "$DIRECTORY/logs/leaderSchedule_$(( $(getCurrentEpoch) + 1 )).txt" ]; then
        echo "Check already done, check logs for results"
    elif [[ $timeDifference -gt 86400 ]]; then
        echo "Too early to run the script, wait for the next cron scheduled job"
    elif [[ $timeDifference -gt 0 ]] && [[ $timeDifference -le 86400 ]]; then
        sleepUntil "$timeDifference"
        echo "Check is starting on $(timestampToUTC "$currentTime")"
        checkLeadershipSchedule
        echo "Script ended, schedule logged inside file: leaderSchedule_$(( $(getCurrentEpoch) + 1 )).txt"
    elif [[ $timeDifference -lt 0 ]] && [ ! -f "$DIRECTORY/logs/leaderSchedule_$(( $(getCurrentEpoch) + 1 )).txt" ]; then
        echo "Check is starting on $(timestampToUTC "$currentTime")"
        checkLeadershipSchedule
        echo "Script ended, schedule logged inside file: leaderSchedule_$(( $(getCurrentEpoch) + 1 )).txt"
    else
        echo "There were problems running the script, check that everything is working fine"
    fi
else
    echo "Node not fully synced."
fi
