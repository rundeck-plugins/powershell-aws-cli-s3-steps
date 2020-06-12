#Requires -Version 4

<#
.SYNOPSIS
  Sync AWS bucket objects
.DESCRIPTION
  Sync AWS bucket objects
.PARAMETER source
    Source
.PARAMETER destination
    Destination
.PARAMETER include
    include
.PARAMETER exclude
    exclude
.PARAMETER quiet
    quiet
.PARAMETER recursive
    recursive
.PARAMETER dryrun
    dryrun
.PARAMETER endpoint_url
    endpoint_url
.PARAMETER access_key
    AWS Access Key
.PARAMETER secret_access_key
    AWS Secret Key
.PARAMETER default_region
    AWS Default Region
.PARAMETER options
    AWS options
.PARAMETER retries
    AWS retries
.PARAMETER checkexec
    checkexec
.PARAMETER fileexists
    fileexists
.NOTES
  Version:        1.0.0
  Author:         Rundeck
  Creation Date:  06/02/2018
  
#>

Param (
[string]$source,
[string]$destination,
[string]$include,
[string]$exclude,
[string]$quiet,
[string]$recursive,
[string]$dryrun,
[string]$endpoint_url,
[string]$access_key,
[string]$secret_access_key,
[string]$default_region,
[string]$options,
[int]$retries,
[string]$checkexec,
[string]$fileexists
)

Begin {
    if (-Not $access_key.contains('config.') -And -Not ([string]::IsNullOrEmpty($access_key)) ) {
        $env:AWS_ACCESS_KEY_ID=$access_key
    }

    if (-Not $secret_access_key.contains('config.') -And -Not ([string]::IsNullOrEmpty($secret_access_key)) ) {
         $env:AWS_SECRET_ACCESS_KEY=$secret_access_key
    }

    if (-Not $default_region.contains('config.') -And -Not ([string]::IsNullOrEmpty($default_region)) ) {
         $env:AWS_DEFAULT_REGION=$default_region
    }
}

Process {


    try{

        if($Env:RD_JOB_LOGLEVEL -ieq "DEBUG"){
            $VerbosePreference="Continue"
            $DebugPreference="Continue"
        }

        write-verbose "Source: $($source)"
        write-verbose "Destination: $($destination)"
        write-verbose "endpoint_url: $($endpoint_url)"
        write-verbose "recursive: $($recursive)"
        write-verbose "options: $($options)"
        write-verbose "retries: $($retries)"
        write-verbose "checkexec: $($checkexec)"
        write-verbose "fileexists: $($fileexists)"
        write-verbose "include: $($include)"
        write-verbose "exclude: $($exclude)"

        if($checkexec -eq "true"){
            if (Test-Path "$($fileexists)"){
                write-host "Filechecker: Found $($fileexists). Continuing execution."
            }else{
                Write-Warning "Filechecker: Did not find $($fileexists). Skipping execution."
                exit 0
            }
        }

        $source = $source.Trim()
        $destination = $destination.Trim()

        $cmd = "aws s3 sync ""$source"" ""$destination"" "
        
        if ($quiet -eq "true") {
            $cmd += " --quiet "
        }

        if($dryrun -eq "true"){
            $cmd += " --dryrun "
        }

        if($recursive -eq "true"){
            $cmd += " --recursive "
        }

        if (-Not ([string]::IsNullOrEmpty($endpoint_url)) -And  -Not $endpoint_url.contains('config.') ) {
            $cmd +=  " --endpoint-url $($endpoint_url) "
        }

        if (-Not ([string]::IsNullOrEmpty($exclude)) -And -Not $exclude.contains('config.') ) {
            $cmd +=  " --exclude $($exclude) "
        }

        if (-Not ([string]::IsNullOrEmpty($include)) -And  -Not $include.contains('config.')  ) {
            $cmd +=  " --include $($include) "
        }

        if (-Not ([string]::IsNullOrEmpty($options)) -And  -Not $options.contains('config.')  ) {
            $cmd +=  " $($options) "
        }

        $completed = $false
        $retrycount = 1
        $secondsDelay = 2

        while (-not $completed) {

            Try{
                Invoke-Expression $cmd
                if ($lastexitcode) {throw "Error running command"}

                Write-Verbose ("Command [{0}] succeeded." -f $cmd)
                $completed = $true
            }Catch{
                if ($retrycount -ge $retries) {
                    Write-Host ("Command [{0}] failed the maximum number of {1} times." -f $cmd, $retrycount)
                    throw
                } else {
                    Write-Host ("Command [{0}] failed. Retrying in {1} seconds." -f $cmd, $secondsDelay)
                    Start-Sleep $secondsDelay
                    $retrycount++
                }
            }
        }

        write-host "Done"

        

    }Catch{
        Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        exit 1
    }

}

