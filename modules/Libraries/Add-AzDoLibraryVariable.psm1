<#

.SYNOPSIS
Add/Replace a new variable to a specific Azure DevOps libary

.DESCRIPTION
The command will add/replace a variable to the specificed library

.PARAMETER VariableGroupName
The name of the variable group to create/update

.PARAMETER VariableGroupDescription
A description for the variable group (only used if the group is created)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER VariableValue
The variable for the variable

.PARAMETER Secret
Indicates if the vaule should be stored as a "secret"

.PARAMETER Reset
Indicates if the ENTIRE library should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the library group should be created if it doesn't exist

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoLibraryVariable -VariableGroupName <variable group name> -VariableName <variable name> -VariableValue <some value>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Add-AzDoLibraryVariable()
{
    [CmdletBinding()]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, ParameterSetName="name")]$VariableGroupName,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, ParameterSetName="id")]$VariableGroupId,
        [string]$VariableGroupDescription,
        [string][parameter(Mandatory = $true,  ValueFromPipelineByPropertyName = $true)]$VariableName,
        [string][parameter(Mandatory = $true,  ValueFromPipelineByPropertyName = $true)]$VariableValue,
        [bool][parameter(ValueFromPipelineByPropertyName = $true)]$Secret,
        [switch]$Reset,
        [switch]$Force
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

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
        $method = "POST"

        if ([string]::IsNullOrEmpty($VariableGroupName) -and [string]::IsNullOrEmpty($VariableGroupId))
        {
            throw "Specify either Variable Group Name or Variable Group Id"
        }

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName -or $_.id -eq $VariableGroupId }

        if($variableGroup)
        {
            Write-Verbose "Variable group $VariableGroupName exists."

            if ($Reset)
            {
                Write-Verbose "Reset = $Reset : remove all variables."
                foreach($prop in $variableGroup.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
                {
                    $variableGroup.variables.PSObject.Properties.Remove($prop.Name)
                }
            }

            $id = $variableGroup.id
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($id)"
            $method = "Put"
        }
        else
        {
            Write-Verbose "Variable group $VariableGroupName not found."
            if ($Force)
            {
                Write-Verbose "Create variable group $VariableGroupName."
                $variableGroup = @{name=$VariableGroupName;description=$VariableGroupDescription;variables=New-Object PSObject;}
                $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"
            }
            else
            {
                throw "Cannot add variable to nonexisting variable group $VariableGroupName; use the -Force switch to create the variable group."
            }
        }

        Write-Verbose "Adding $VariableName with value $VariableValue..."
        $variableGroup.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value @{value=$VariableValue;isSecret=$Secret} -Force

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress
        
        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
        
        Write-Verbose "Response: $($response.id)"

        $response
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
