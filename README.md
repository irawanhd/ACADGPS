# Create AD Group and Add Computers Script

## Overview

This PowerShell script facilitates the creation of Active Directory (AD) groups and adds computers to these groups based on a hostname pattern. The hostname patterns and their corresponding Organizational Unit (OU) Distinguished Names are specified in a CSV file. The script allows users to select a hostname pattern, specify the group name, and optionally create additional groups in a single run.

## Prerequisites

- Windows operating system with PowerShell installed.
- Active Directory module for PowerShell.
- Necessary permissions to create AD groups and add members in the specified OUs.
- CSV file (`csvfile.csv`) containing the mapping of names, distinguished names, and hostname patterns.

## CSV File Format

The CSV file should be named `csvfile.csv` and located in the same directory as the script. The file should use a semicolon (`;`) as the delimiter and have the following columns:

- `Name`: A descriptive name for the hostname pattern.
- `DistinguishedName`: The distinguished name of the OU where the group will be created.
- `Hostname Contains`: The pattern used to match computer hostnames.

## Usage

1. **Ensure CSV File**: Make sure your CSV file is named `csvfile.csv` and located in the same directory as the script.

2. **Open PowerShell**: Open a PowerShell session with administrative privileges.

3. **Run the Script**: Execute the script by navigating to the directory containing the script and running the following command:

   ```powershell
   .\ACADGPS.ps1
