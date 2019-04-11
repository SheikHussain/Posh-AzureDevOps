    <#

.SYNOPSIS
This commend provides accesss Build Defintiions from Azure DevOps

.DESCRIPTION
The command will retrieve a full build definition (if it exists) 

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER BuildDefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER BuildDefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER ExpandFields
A common seperated list of fields to expand

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildDefinition -ProjectUrl https://dev.azure.com/<organizztion>/<project> -BuildDefinitionName <build defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildDefinition()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ParameterSetName='Name', ValueFromPipelinebyPropertyName = $true)]$BuildDefinitionName,
        [int][parameter(ParameterSetName='ID', ValueFromPipelinebyPropertyName = $true)]$BuildDefinitionId,
        [string]$ExpandFields
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -or $AzDoConnection -eq $null)
        {
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
            }
            else 
            {
                $AzDoConnection = Connect-AzDo -ProjectUrl $ProjectUrl -PAT $PAT -LocalOnly
            }
        }

        if ($BuildDefinitionId -eq $null -and [string]::IsNullOrEmpty($BuildDefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions"

        $apiParams = @()

        if (-Not [string]::IsNullOrEmpty($ExpandFields)) 
        {
            $apiParams += "Expand=$($ExpandFields)"
        }

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($BuildDefinitionId)" -QueryStringParams $apiParams
        }
        else 
        {
            $apiParams += "searchText=$($BuildDefinitionName)"

            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions" -QueryStringParams $apiParams
        }

        $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------BUILD DEFINITION---------"
        Write-Verbose $buildDefinitions
        Write-Verbose "---------BUILD DEFINITION---------"

        if ($buildDefinitions.count -ne $null)
        {   
            foreach($bd in $buildDefinitions.value)
            {
                if ($bd.name -like $BuildDefinitionName){
                    Write-Verbose "Release Defintion Found $($bd.name) found."

                    $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($bd.id)" -QueryStringParams $apiParams
                    $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

                    return $buildDefinitions
                }
            }
            Write-Verbose "Build definition $BuildDefinitionName not found."

            return $null
        } 
        elseif ($buildDefinitions -ne $null) {
            return $buildDefinitions
        }

        Write-Verbose "Build definition $BuildDefinitionId not found."
        
        return $null
    }
    END { }
}
