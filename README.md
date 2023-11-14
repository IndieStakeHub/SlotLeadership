# Tutorial: Using Cardano Leadership Schedule Script

# Step 1: Prerequisites
Ensure that you have a running Cardano block producer node.
Confirm that the necessary Cardano binaries, such as cardano-cli and jq, are installed and available in your system's PATH.

# Step 2: Download the Script
Open your preferred text editor.
Copy and paste the provided script into the text editor.

# Step 3: Save the Script
Save the script with a meaningful name, for example, leadership_schedule.sh.

# Step 4: Make the Script Executable
Open a terminal window.
Navigate to the directory where you saved the script.
```console
cd /path/to/script/directory
```
Make the script executable.
```console
chmod +x leadership_schedule.sh
```

# Step 5: Edit the Script (Optional)
Open the script in your text editor if you want to customize any parameters (e.g., change the NODE_HOME directory or adjust network settings).

# Step 6: Run the Script
Execute the script.
```console
./leadership_schedule.sh
```

# Step 7: Review the Output
The script will display information about the current epoch, epoch start and end times, and the scheduled time for the leadership check.
If the script detects that it's too early to run or if the check has already been performed, appropriate messages will be displayed.
If the script proceeds with the leadership check, it will query Cardano for the leadership schedule, format the result into a Grafana CSV file, and display the result.

# Step 8: Troubleshooting
If you encounter issues, ensure that the necessary Cardano binaries (cardano-cli and jq) are in your PATH.
Check for any error messages displayed by the script.

# Step 9: Script Completion
Once the script has completed, it will display a message indicating the end of the script execution.

Note:
It's crucial to have accurate file paths and permissions for your Cardano node configuration files.
Ensure that the Cardano node is fully synced before running the script.
Regularly check for updates to the script based on any changes in Cardano node configurations.

That concludes the tutorial for using the Cardano Leadership Schedule script.
