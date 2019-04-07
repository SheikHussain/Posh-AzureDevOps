<#

.SYNOPSIS
Retrieve the work items related to  the specified build 

.DESCRIPTION
The command will retrieve the work items associated with the specified build 

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER Id
The id of the build to retrieve (use on this OR the name parameter)

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildWorkItems -ProjectUrl https://dev.azure.com/<organizztion>/<project> -Id <build id> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildWorkItems()
{
    [CmdletBinding(
        DefaultParameterSetName='ID'
    )]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='ID')]$Id,
        [int]$Count = 1,
        [string][parameter(Mandatory = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ($Id -eq $null -and $build -eq $null) { throw "Build ID or Build object must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion
    }
    PROCESS
    {
        $apiParams = @()

        $apiParams += "`$top=$($Count)"

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -BaseApiPath "/_apis/build/builds/$($Id)/workitems" -QueryStringParams $apiParams -ApiVersion $ApiVersion

        $buildWorkItems = Invoke-RestMethod $apiUrl -Headers $headers

        Write-Verbose "---------BUILD WORKITEMS---------"
        Write-Verbose $buildWorkItems
        Write-Verbose "---------BUILD WORKITEMS---------"

        #Write-Verbose "Build status $($build.id) not found."
        if (-Not $buildWorkItems -or $buildWorkItems.count -eq 0) {
            Write-Verbose "No Workitems Found Related to build $Id"

            return $null
        }

        foreach ($wit in $buildWorkItems.value) {
            Write-Verbose "`t$($wit.id) => $($wit.url)"

            $witDetails = Invoke-RestMethod $wit.url -Headers $headers | Select-Object -ExpandProperty fields

            $witCustom = [pscustomobject]@{
                Id = $wit.id;
                Url = $wit.url;
                Details = $witDetails;
            }

            $witCustom | Select-Object Id, Url -ExpandProperty Details
        }

    }
    END { }
}
