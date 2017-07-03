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
#   2017-06-30  Converted param to allow an array (still need to work on output)
#               Added a line to add all members of the 
# 
#
#=======================================================================================
#
# Active Directory Environments that are to be examined
# Uncomment the line below to enable a pre set of domains.  Then comment out the param below.
# $ADEnvironments = "ad.domain.name", "another.ad.domain.name"
#
# Comment the below Param if you are providing a hard coded list above.
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string[]] $ADEnvironments = $(throw "-ADEnvironments is required.")
)
#
#
# Define Variables
#
$OutputDir = "c:\Temp\"
$ClusterSearchBaseIndex = @{
    "wfm.wegmans.com" = "OU=Clusters,OU=Member Servers,DC=wfm,DC=wegmans,DC=com"
    "test.wfm.local" = "OU=Clusters,OU=Member Servers,DC=test,DC=wfm,DC=local"
}
$ExecutionStamp = Get-Date -Format yyyyMMdd_HH-mm-ss
#
# Find a Domain Controller for each environment
#
foreach ($ADEnvironment in $ADEnvironments){
    $EnabledServers = @()
    $GCServer = Get-ADDomainController -DomainName $ADEnvironment -Discover -Service GlobalCatalog
    $SearchBase = ($ClusterSearchBaseIndex.Item($ADEnvironment))
    #
    # Get all Servers for Environments
    #
    #
    # Define Output File / One for each Environment
    #
    # Reformat Domain Name to replace . with _ for FileName
    $FileFormatedDomainName = $GCServer.Domain.replace('.','_')
    #
    # Define Output File Name and Path
    #
    $OutputFileName = "EnabledServers_" + $FileFormatedDomainName + "_" + $ExecutionStamp  + ".txt"
    $OutputFullPath = Join-Path $OutputDir $OutputFileName.ToString()
    #
    # Find All Servers in Environment
    #
    $EnabledServers = Get-ADComputer -Filter * -Properties Name, OperatingSystem -Server $GCServer.Name | Where-Object {$_.OperatingSystem -like "*Server*" -and $_.enabled -eq $True}
    #
    # Add Cluster Names to list of servers
    #
    IF ($SearchBase) {
        $EnabledServers += Get-ADComputer -Filter * -SearchBase $SearchBase -Server $GCServer.Name | Where-Object {$_.enabled -eq $True}
        Write-Host "Cluster Search Base found for" $ADEnvironment
    }
    Else {
        Write-Host "No Cluster Search Base found for" $ADEnvironment
    }
    #
    # Create output file
    #
    ForEach ($EnabledServer in $EnabledServers) {
        Add-Content -Path $OutputFullPath -Value $EnabledServer.Name
    }
}
