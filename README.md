# RansomwareSimulator
Multithreaded Powershell script to emulate the "blast radius" of a ransomware infection. Does not actually encrypt anything!

Uses passive checks to test write priv to discovered files and reports on them.


# Logic
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


# Updates:

Implemented Runspaces and chunking to improve performance.
