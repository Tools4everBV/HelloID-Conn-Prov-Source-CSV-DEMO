$connectionSettings = ConvertFrom-Json $configuration
$importSourcePath = $($connectionSettings.path)
$delimiter = $($connectionSettings.delimiter)

function Get-SourceConnectorData { 
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]$SourceFile,
        [parameter(Mandatory = $true)][ref]$data
    )
    try {
        
        $importSourcePath = $importSourcePath -replace '[\\/]?[\\/]$'
        $dataset = Import-Csv -Path "$importSourcePath\$SourceFile" -Delimiter $delimiter

        foreach ($record in $dataset) { $null = $data.Value.add($record) }
    }
    catch {
        $data.Value = $null
        Write-Verbose $_.Exception
    }
}

Write-Information "Starting import"

$organizationalUnits = [System.Collections.ArrayList]::new()
Get-SourceConnectorData -SourceFile "T4E_HelloID_OrganizationalUnits.csv" ([ref]$organizationalUnits)

Write-Information "Import completed: $($organizationalUnits.count) departments processed"

$json = $organizationalUnits | ConvertTo-Json -Depth 3
Write-Output $json