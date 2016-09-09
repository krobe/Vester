﻿#Requires -Version 3

function Invoke-Vester {
    <#
    .SYNOPSIS
    PowerCLI and Pester team up against your vSphere environment.

    .DESCRIPTION
    TODO: Write a full comment-based help section
    #>
    [CmdletBinding(SupportsShouldProcess = $true, 
                   ConfirmImpact = 'Medium')]
    param (
        # Define the file/folder of test file(s) to call
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        # Aliasing FullName enables easy pipe from Get-ChildItem
        [Alias('Path','FullName')]
        [object[]]$Script = '.',

        # Optionally define a different config file to use. Defaults to Vester\Configs\Config.ps1
        # Currently only supports one Config file at a time
        [object]$Config = "$(Split-Path -Parent $PSScriptRoot)\Configs\Config.ps1",

        # Optionally fix all config drift that is discovered. Defaults to false (off)
        [switch]$Remediate = $false,

        # Optionally run only tests that match the given tag(s)
        [ValidateSet('cluster','host','network','nfs','storage','vcenter','vds','vm')]
        # TODO: ^ That should be dynamic
        [string[]]$Tag = $null,

        # Optionally exclude tests with the given tag(s)
        [ValidateSet('cluster','host','network','nfs','storage','vcenter','vds','vm')]
        # TODO: ^ That should be dynamic
        [string[]]$ExcludeTag = $null
    )

    BEGIN {
        If ((Get-Module).Name -notcontains 'VMware.VimAutomation.Core') {
            Try {
                Write-Verbose 'Importing PowerCLI module "VMware.VimAutomation.Core"'
                Import-Module VMware.VimAutomation.Core -ErrorAction Stop
            } Catch {
                throw 'PowerCLI module "VMware.VimAutomation.Core" failed to import. Exiting'
            }
        }

        # Load the defined $cfg values to test
        . $Config

        If (-not $cfg) {
            throw "Valid config file not found at path '$Config'. Exiting"
        }

        # Check for already open session to desired vCenter server
        If ($cfg.vcenter.vc -notin $global:DefaultVIServers.Name) {
            Try {
                # Attempt connection to vCenter, prompting for credentials
                Write-Verbose "No active connection found to configured vCenter '$($cfg.vcenter.vc)'. Connecting"
                Connect-VIServer -Server $cfg.vcenter.vc -Credential (Get-Credential) -ErrorAction Stop
            } Catch {
                # If unable to connect, stop
                throw "Unable to connect to configured vCenter '$($cfg.vcenter.vc)'. Exiting"
            }
        }
        Write-Verbose "Processing against vCenter server '$($cfg.vcenter.vc)'"
    } # Begin

    PROCESS {
        # Need to ForEach if multiple -Script locations are not piped in
        ForEach ($Path in $Script) {
            # Pester accepts Tag/Exclude being null, but each test will need $Config/$Remediate params
            Invoke-Pester -Tag $Tag -ExcludeTag $ExcludeTag -Script @{
                Path = $Path
                Parameters = @{
                    Config = $Config
                    Remediate = $Remediate
                }
            } # Invoke-Pester
        } #ForEach Path
    } # Process

    END {
    }
} # function
