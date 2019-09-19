<#

.SYNOPSIS
This command provides creates a new Team for Azure DevOps

.DESCRIPTION
The command will create a new Azure DevOps Team

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the group to create

.PARAMETER TeamDescription
The description of the group to create

.EXAMPLE
Create-AzDoTeam -TeamName <team name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoTeam()
{
    [CmdletBinding(
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$TeamName,
        [string]$TeamDescription
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  

        $errorPreference = 'Stop'
        if ( $PSBoundParameters.ContainsKey('ErrorAction')) {
            $errorPreference = $PSBoundParameters['ErrorAction']
        }

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # POST https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=5.0
        # {
        #    "name": "Team Name",
        # }
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams" -QueryStringParams $apiParams
        $teamDetails = @{name=$TeamName; description=$TeamDescription}
        $body = $teamDetails | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose $body

        $team = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        
        Write-Verbose "---------TEAM---------"
        Write-Verbose $team
        Write-Verbose "---------TEAM---------"

        $team
    }
    END { }
}

