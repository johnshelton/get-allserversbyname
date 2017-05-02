#=======================================================================================
# Get-AllServersByName
# Created on: 2017-02-23
# Version 1.0
# Last Updated: 2017-05-02
# Last Updated by: John Shelton | c: 260-410-1200 | e: john.shelton@lucky13solutions.com
#
# Purpose: This script creates a txt file for each domain listed below containing all of
#          the Window servers in the environment.  This file can be used to import in to 
#          Remote Destop Manager.
#
# Notes: 
# 
# Change Log:
# 
#
#=======================================================================================
#
# Active Directory Environments that are to be examined
#
$ADEnvironments = "ad.domain.name", "another.ad.domain.name"
#
# Define Variables
#
$OutputDir = "c:\Temp\"
$GCServers = @()
#
# Find a Domain Controller for each environment
#
foreach ($ADDomain in $ADEnvironments){
    $GCServer = Get-ADDomainController -DomainName $ADDomain -Discover -Service GlobalCatalog | Select $_.Name
    $GCServers += $GCServer
}
#
# Get all AD Servers for Environments
#
foreach ($DomainController in $GCServers){
    #
    # Define Output File / One for each Environment
    #
    # Reformat Domain Name to replace . with _ for FileName
    $FileFormatedDomainName = $DomainController.Domain.replace('.','_')
    #
    # Define Output File Name and Path
    #
    $OutputFileName = "EnabledServers_"
    $OutputFileName += $FileFormatedDomainName
    $OutputFileName += ".txt"
    $OutputFullPath = Join-Path $OutputDir $OutputFileName.ToString()
    #
    # Find All Servers in Environment
    #
    $EnabledServers = Get-ADComputer -Filter * -Properties Name, OperatingSystem -Server $DomainController.name | where {$_.OperatingSystem -like "*Server*" -and $_.enabled -eq $True}
    #
    # Create output file
    #
    ForEach ($Server in $EnabledServers) {
        Add-Content -Path $OutputFullPath -Value $Server.Name
    }
}