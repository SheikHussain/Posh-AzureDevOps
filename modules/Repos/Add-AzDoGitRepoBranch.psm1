<#

.SYNOPSIS
Add a new branch to a git repostiory

.DESCRIPTION
The command will add a new branch to an existing git repositories

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER Name
Name of the git repository

.PARAMETER BaseOnBranchName
Name of the branch that the new branch is based on

.PARAMETER BranchName
Name of the branch 

.EXAMPLE
Add-AzDoGitRepoBranch -Name <git repo name> -BranchName <branch name> -BasedOnBranchName <based on branch name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Add-AzDoGitRepoBranch()
{
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$true)][string]$Name,
        [parameter(Mandatory=$true)][string]$BasedOnBranchName,
        [parameter(Mandatory=$true)][string]$NewBranchName
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

        if (-Not (Test-Path variable:ApiVersion) -or $ApiVersion -ne "4.1") { $ApiVersion = "4.1"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $repo = Get-AzDoGitRepos -AzDoConnection $AzDoConnection | ? { $_.name -eq $Name }
        
        if ($null -eq $repo)
        {
            Write-Error "Specified Repo '$Name' Not Found."

            return
        }

        $existingBranches = Get-AzDoGitRepoBranches -AzDoConnection $AzDoConnection -Name $Name
        $existingBasedOnBranch = $existingBranches | ? { $_.name -eq "refs/heads/$BasedOnBranchName"}

        if ($null -eq $existingBasedOnBranch)
        {
            Write-Error "Specified Source Branch not found: $BasedOnBranchName"

            return
        }

        $existingNewBranch = $existingBranches | ? { $_.name -eq "refs/heads/$BasedName"}
        if ($null -ne $existingNewBranch)
        {
            Write-Error "Specified Branch already exists: $BranchName"

            return
        }

        $apiParams = @()

        # POST https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/refs?api-version=4.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/git/repositories/$($repo.id)/refs" -QueryStringParams $apiParams

        # [{"name":"refs/heads/dev","newObjectId":"4aac2e2e07837b2c5e7e298c7167ca05cb5415e1","oldObjectId":"0000000000000000000000000000000000000000"}]
        $data = @(@{name="refs/heads/$($NewBranchName)";newObjectId="$($existingBasedOnBranch.objectid)";oldObjectId="0000000000000000000000000000000000000000"})
        $body = $data | ConvertTo-Json -Depth 50 -Compress
        $body = "[$($body)]"

        Write-Verbose "---------Request---------"
        Write-Verbose $body
        Write-Verbose "---------Reqest---------"

        if (-Not $WhatIfPreference)
        {
            $results = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)   
        }
        
        Write-Verbose "---------Repos---------"
        Write-Verbose ($results | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------Repos---------"

        return $results
    }
    END {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
     }
}

