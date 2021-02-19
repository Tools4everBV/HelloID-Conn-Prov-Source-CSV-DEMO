$connectionSettings = ConvertFrom-Json $configuration
$importSourcePath = $($connectionSettings.path)
$delimiter = $($connectionSettings.delimiter)
$useCustomPrimaryPersonCalculation = $($connectionSettings.useCustomPrimaryPersonCalculation)

#region Functions
function Get-SourceConnectorData { 
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]$SourceFile,
        [parameter(Mandatory = $true)][ref]$data
    )
      
    try {

        $importSourcePath = $importSourcePath -replace '[\\/]?[\\/]$'
        $dataset = Import-Csv -Path "$importSourcePath\$SourceFile" -Delimiter $delimiter

        foreach ($record in $dataset) { 
           $null = $data.Value.add($record) 
        }
    }
    catch {
        $data.Value = $null
        Write-Verbose $_.Exception
    }
}
#endregion Functions

#region Script
$persons = New-Object System.Collections.Generic.list[object]
Get-SourceConnectorData -SourceFile "T4E_HelloID_Persons.csv" ([ref]$persons)

$employments = New-Object System.Collections.Generic.list[object]
Get-SourceConnectorData -SourceFile "T4E_HelloID_Contracts.csv" ([ref]$employments)

# Group the employments
$employments = $employments | Group-Object Medewerker -AsHashTable

# Extend the persons with positions and required fields
$persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force

#join Contracts with Persons
$persons | ForEach-Object {
    $_.ExternalId = $_.Medewerker
    $_.DisplayName = $_.Medewerker
    $contracts = $employments[$_.Medewerker]
    if ($null -ne $contracts) {
        [array]$_.Contracts = $contracts
    }
}

#Below is the configuration part as used to identify the primary person, all persons are grouped by the UniqueKey where only the person with the highest contract will be included for provisioning
if ($true -eq $useCustomPrimaryPersonCalculation) {

    #Extend the person model to automatically exclude persons by the source import
    $persons | Add-Member -MemberType NoteProperty -Name "ExcludedBySource" -Value "true" -Force

    #Define the logic used for ordering and grouping the person objects used to identify the primary person
    #Calculate identities base on your UniqueKey
    $persons = $persons | Select-Object *, @{name = 'UniqueKey'; expression = { "$($_.FirstName)$($_.LastName)$($_.Geslacht_Code)$($_.GeboorteDatum)" } }
    $identities = $persons | Select-Object -Property UniqueKey -Unique
    $personsGrouped = $persons | Group-Object -Property UniqueKey -AsHashTable -AsString

    #Define the property's used for sorting the persons priority based on one or more contract fields
    $prop1 = @{Expression = { $_.Volgnummer_contract }; Descending = $True }
    $prop2 = @{Expression = { $_.Aantal_FTE }; Descending = $True }
    $prop3 = @{Expression = { if (($_.Einddatum_contract -eq "") -or ($null -eq $_.Einddatum_contract) ) { (Get-Date -Year 2199 -Month 12 -Day 31) -as [datetime] } else { $_.Einddatum_contract -as [datetime] } }; Descending = $true }
    $prop4 = @{Expression = { $_.Begindatum_contract }; Ascending = $True }

    foreach ($identity in $identities ) {
        $latestContract = ($personsGrouped[$identity.UniqueKey] | Select-Object -ExpandProperty contracts | Sort-Object -Property $prop1, $prop2, $prop3, $prop4 | Select-Object -First 1)
        $personToUpdate = ($persons | Where-Object { $_.Medewerker -eq $latestContract.Medewerker })
   
        if ($null -eq $personToUpdate ) {
            "No contracts found for $identity"
            continue
        }
        $personToUpdate.ExcludedBySource = "false"
    }

}

#Test selection to identify if the sorted results are correct
#$persons | Select-Object -Property Medewerker, ExcludedBySource | Format-Table

# Make sure persons are unique
$persons = $persons | Sort-Object Medewerker -Unique

# Export and return the json
$json = $persons | ConvertTo-Json -Depth 10

Write-Output $json
#endregion Script