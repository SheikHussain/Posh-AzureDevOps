function Get-AzDoApiUrl()
{
    [CmdletBinding()]
    param
    (
        # Common Parameters
        [string]$ApiVersion = $global:AzDoApiVersion,

        [string][parameter(Mandatory = $true)]$RootPath,
        [string][parameter(Mandatory = $true)]$BaseApiPath,
        [string[]]$QueryStringParams = $null
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  

        # $errorPreference = 'Stop'
        # if ( $PSBoundParameters.ContainsKey('ErrorAction')) {
        #     $errorPreference = $PSBoundParameters['ErrorAction']
        # }

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0" }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $RootPath = $RootPath.TrimEnd("/")
        $BaseApiPath = $BaseApiPath.TrimStart("/")

        $apiUrl = "$($RootPath)/$($BaseApiPath)?api-version=$($ApiVersion)"
        
        if ($QueryStringParams) {
            foreach ($q in $QueryStringParams) {
                $apiUrl = "$($apiUrl)&$($q)"
            }
        }
        
        Write-Verbose "API Url: $apiUrl"

        return $apiUrl
    }
    END { }
}

