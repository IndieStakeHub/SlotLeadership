# Cardano Leadership Schedule Script

# Overview

This script automates the process of querying the Cardano node for leadership schedule information for a specified stake pool. It checks whether the node is fully synced, determines the appropriate time to run the leadership query, and formats the result into a Grafana CSV file for analysis.

# Features

Automated leadership schedule query for a specified stake pool.
Checks for node synchronization before running the query.
Grafana CSV formatting for easy integration with monitoring tools.

# Prerequisites

A running Cardano block producer node.
Installed Cardano binaries (cardano-cli, jq) in the system's PATH.
Properly configured NODE_HOME directory and stake pool settings.
Usage

Clone the repository:
```console
git clone https://github.com/your-username/cardano-leadership-script.git
cd cardano-leadership-script
```
Make the script executable:
```console
chmod +x leadership_schedule.sh
```
Edit the script (if needed) with your specific configurations.

Run the script:
```console
./leadership_schedule.sh
```

# Contributions

Contributions are welcome! Feel free to submit issues or pull requests.
