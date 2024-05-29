# Ensure the Active Directory module is imported
Import-Module ActiveDirectory

# Function to create AD group and add computers
function Create-ADGroupAndAddComputers {
    param (
        [string]$csvPath
    )

    do {
        # Load the CSV file
        $csvData = Import-Csv -Path $csvPath -Delimiter ';'

        # Display the available hostname patterns for user selection with numbers
        Write-Output "Available hostname patterns:"
        $csvData | ForEach-Object {
            if (-not $_.PSObject.Properties["Number"]) {
                $_ | Add-Member -MemberType NoteProperty -Name Number -Value ($csvData.IndexOf($_))
            }
            $_
        } | Select-Object Number, Name, 'Hostname Contains' | Format-Table -AutoSize

        # Prompt the user to select the hostname pattern by number
        $selectedNumber = Read-Host "Enter the number corresponding to the hostname pattern"

        # Validate the selected number and get the corresponding entry
        if ($selectedNumber -match '^\d+$' -and [int]$selectedNumber -ge 0 -and [int]$selectedNumber -lt $csvData.Count) {
            $selectedEntry = $csvData[$selectedNumber]

            $hostnamePattern = $selectedEntry.'Hostname Contains'
            $ouPath = $selectedEntry.DistinguishedName

            # Prompt the user to input the group name
            $groupName = Read-Host "Enter the name of the group to be created"

            # Define the group description
            $groupDescription = "Group for specific computers based on hostname"

            # Find computers matching the hostname pattern
            $computers = Get-ADComputer -Filter "Name -like '$hostnamePattern*'" -Property DistinguishedName

            # Count the number of matching computers
            $computerCount = $computers.Count

            # List the matching computers
            Write-Output "Total $computerCount computers found matching the pattern '$hostnamePattern':"
            $computers | Select-Object Name, DistinguishedName | Format-Table -AutoSize

            # Check if any computers are found
            if ($computerCount -gt 0) {
                # Ask for confirmation to proceed with creating the group
                $confirmation = Read-Host "Do you want to proceed with creating the group '$groupName' in OU '$ouPath' and adding these $computerCount computers? (yes/no)"

                if ($confirmation -eq 'yes') {
                    # Create the group if it does not exist
                    if (-not (Get-ADGroup -Filter { Name -eq $groupName })) {
                        $newGroup = New-ADGroup -Name $groupName -GroupScope Global -Description $groupDescription -Path $ouPath
                        Write-Output "Group '$groupName' created successfully in OU '$ouPath'."
                        
                        # Set the "Protect object from accidental deletion" setting for the group
                        $newGroup | Set-ADObject -ProtectedFromAccidentalDeletion $true
                        Write-Output "Object protection enabled for group '$groupName'."
                    } else {
                        Write-Output "Group '$groupName' already exists in OU '$ouPath'."
                    }

                    # Get the DistinguishedName of the group
                    $groupDN = (Get-ADGroup -Filter { Name -eq $groupName }).DistinguishedName

                    # Initialize counters for skipped and added computers
                    $skippedCount = 0
                    $addedCount = 0

                    # Add the computers to the group
                    foreach ($computer in $computers) {
                        # Check if the computer is already a member of the group
                        if (-not (Get-ADGroupMember -Identity $groupDN -Recursive | Where-Object { $_.DistinguishedName -eq $computer.DistinguishedName })) {
                            if ($computer.DistinguishedName) {
                                try {
                                    Add-ADGroupMember -Identity $groupDN -Members $computer.DistinguishedName
                                    Write-Output "Added computer '$($computer.Name)' to group '$groupName'."
                                    $addedCount++
                                } catch {
                                    Write-Error "Failed to add computer '$($computer.Name)' to group '$groupName'. Error: $_"
                                }
                            } else {
                                Write-Error "Failed to add computer '$($computer.Name)'. DistinguishedName is null."
                            }
                        } else {
                            Write-Output "Skipped adding computer '$($computer.Name)' to group '$groupName'. It is already a member."
                            $skippedCount++
                        }
                    }

                    Write-Output "Script completed. Added $addedCount computers to the group. Skipped adding $skippedCount computers."
                } else {
                    Write-Output "Operation cancelled."
                }
            } else {
                Write-Output "No computers found matching the pattern '$hostnamePattern'."
            }
        } else {
            Write-Output "Invalid selection. Please enter a valid number corresponding to the hostname pattern."
        }

        # Ask the user if they want to create another group
        $createAnotherGroup = Read-Host "Do you want to create another group? (yes/no)"
    } while ($createAnotherGroup -eq 'yes')

    Write-Output "Script finished."
}

# Set the CSV path to the current working directory
$csvPath = (Get-Location).Path + "\csvfile.csv"  # Ensure the CSV file is named 'csvfile.csv' and located in the current directory

# Run the function to create AD group and add computers
Create-ADGroupAndAddComputers -csvPath $csvPath
