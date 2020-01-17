# RansomwareSimulator
Powershell script to emulate the "blast radius" of a ransomware infection.


# Logic
- Powershell called via Office Macro simulating initial point of entry
- Discover Local Drives
- Discover Mapped Drives
- Loop through each drive
- Enumerate files with extensions matching whitelist/blacklist
- Test to see if current user has write permission to file (MUST NOT CHANGE METADATA OF ACTUAL FILE)
- Output Report simulating "C2 Callback"

# Report
- Count sum of files
- Count sum of data (IE. Sum of all Files Length)
- Report the top 10 File types (extensions) that were "encrypted"


# Todo
This script is not using threads or jobs so enumerating large network drives or local drives will take a significant amount of time.

- Find a way to implement Powershell Runspaces or PSJobs to complete this task
