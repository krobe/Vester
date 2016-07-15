#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core


[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Remediation toggle')]
    [ValidateNotNullorEmpty()]
    [switch]$Remediate,
    [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Path to the configuration file')]
    [ValidateNotNullorEmpty()]
    [string]$Config
)

Process {
    # Variables
    Invoke-Expression -Command (Get-Item -Path $Config)
    [array]$esxsyslog = $global:config.host.esxsyslog

    # Tests
    Describe -Name 'Host Configuration: Syslog Server' -Fixture {
        foreach ($server in (Get-VMHost -Name $global:config.scope.host)) 
        {
            It -name "$($server.name) Host Syslog Service State" -test {
                [array]$value = Get-VMHostSysLogServer -VMHost $server
                try 
                {
                    Compare-Object -ReferenceObject $esxsyslog -DifferenceObject $value | Should Be $null
                }
                catch 
                {
                    if ($Remediate) 
                    {
                        Write-Warning -Message $_
                        Write-Warning -Message "Remediating $server"
                        Set-VMHostSysLogServer -VMHost $server -SysLogServer $esxsyslog -ErrorAction Stop
                        (Get-EsxCli -VMHost $server).system.syslog.reload()
                    }
                    else 
                    {
                        throw $_
                    }
                }
            }
        }
    }
}