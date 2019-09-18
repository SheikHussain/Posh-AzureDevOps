<#

.SYNOPSIS
Get role definitions for a specific Azure DevOps libary

.DESCRIPTION
The  command will retreive the role definitions for the specificed library

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoVariableGroupRoleDefinitions -VariableGroupName <variable group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Set-AzDoVariableGroupPermissionInheritance()
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
        [string][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="Name")][Alias("name")]$VariableGroupName,
        [int][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="ID")][Alias("id")]$VariableGroupId,
        [bool]$InheritPermissions = $true
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.2-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.2-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
       
    }
    PROCESS
    {
        if ([string]::IsNullOrEmpty($VariableGroupName) -and [string]::IsNullOrEmpty($VariableGroupId))
        {
            throw "Specify either Variable Group Name or Variable Group Id"
        }

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName -or $_.id -eq $VariableGroupId }

        if ($variableGroup -eq $null)
        {
            throw "Variable Group could not be found"
        }

        # PATCH /_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/5d4ef62e-538a-42e9-a02e-e25bce16abee%245?inheritPermissions=false
        $apiParams = @()

        $apiParams += "inheritPermissions=$($InheritPermissions)"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/$($AzDoConnection.ProjectId)`$$($variableGroup.Id)" -QueryStringParams $apiParams

        Invoke-RestMethod -Method PATCH -Uri $apiUrl -Headers $AzDoConnection.HttpHeaders
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
