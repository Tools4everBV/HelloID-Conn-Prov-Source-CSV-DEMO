$connectionSettings = ConvertFrom-Json $configuration
$importSourcePath = $($connectionSettings.path)
$delimiter = $($connectionSettings.delimiter)
$dateFormat = $($connectionSettings.dateFormat)
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

        foreach ($record in $dataset) { $null = $data.Value.add($record) }
    }
    catch {
        $data.Value = $null
        Write-Verbose $_.Exception
    }
}
#endregion Functions

#region Script
Write-Information "Starting import"

$persons = [System.Collections.ArrayList]::new()
Get-SourceConnectorData -SourceFile "T4E_HelloID_Persons.csv" ([ref]$persons)

# Extend the persons with required fields
$persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force

$employments = [System.Collections.ArrayList]::new()
Get-SourceConnectorData -SourceFile "T4E_HelloID_Contracts.csv" ([ref]$employments)

# Extend the employments with required fields
$employments | Add-Member -MemberType NoteProperty -Name "FunctionDescription" -Value $null -Force

$professions = [System.Collections.ArrayList]::new()
Get-SourceConnectorData -SourceFile "T4E_HELLOID_OrganizationalFunctions.csv" ([ref]$professions)

# Group the professions
$professions = $professions | Group-Object FunctionCode -AsHashTable

# Join employment with profession description
$employments | ForEach-Object {
    $profession = $professions[$_.'FunctionCode']
    if ($null -ne $profession) {
        $_.'FunctionDescription' = $profession.'FunctionDescription'.trim()
    }
}

# Group the employments
$employments = $employments | Group-Object EmployeeCode -AsHashTable

#join Contracts with Persons
$persons | ForEach-Object {
    $_.ExternalId = $_.EmployeeCode
    
    #The following displayName concatenation will be used as default inside the RAW data 
    $_.DisplayName = $_.NickName + ' ' + $_.LastName

    $convertedResult = New-Object DateTime
    $converted = [DateTime]::TryParseExact($_.DateOfBirth, $dateFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$convertedResult)
    if ($converted) {
        $_.DateOfBirth = $convertedResult.ToString("MM/dd/yyyy")
    }

    #Get the corresponding contracts for the releated user
    $contracts = $employments[$_.EmployeeCode] 
    $contracts | ForEach-Object {
        
        $convertedStartDateResult = New-Object DateTime
        $converted = [DateTime]::TryParseExact($_.ContractStartDate, $dateFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$convertedStartDateResult)
        if ($converted) {
            $_.ContractStartDate = $convertedStartDateResult.ToString("MM/dd/yyyy")
        }

        $convertedEndDateResult = New-Object DateTime
        $converted = [DateTime]::TryParseExact($_.ContractEndDate, $dateFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$convertedEndDateResult)
        if ($converted) {
            $_.ContractEndDate = $convertedEndDateResult.ToString("MM/dd/yyyy")
        }
    }

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
    $persons = $persons | Select-Object *, @{name = 'UniqueKey'; expression = { "$($_.FirstName)$($_.LastName)$($_.Gender)$($_.DateOfBirth)" } }
    $identities = $persons | Select-Object -Property UniqueKey -Unique
    $personsGrouped = $persons | Group-Object -Property UniqueKey -AsHashTable -AsString

    #Define the property's used for sorting the persons priority based on one or more contract fields
    $prop1 = @{Expression = { $_.Volgnummer_contract }; Descending = $True }
    $prop2 = @{Expression = { $_.Aantal_FTE }; Descending = $True }
    $prop3 = @{Expression = { if (($_.Einddatum_contract -eq "") -or ($null -eq $_.Einddatum_contract) ) { (Get-Date -Year 2199 -Month 12 -Day 31) -as [datetime] } else { $_.Einddatum_contract -as [datetime] } }; Descending = $true }
    $prop4 = @{Expression = { $_.Begindatum_contract }; Ascending = $True }

    foreach ($identity in $identities ) {
        $latestContract = ($personsGrouped[$identity.UniqueKey] | Select-Object -ExpandProperty contracts | Sort-Object -Property $prop1, $prop2, $prop3, $prop4 | Select-Object -First 1)
        $personToUpdate = ($persons | Where-Object { $_.EmployeeCode -eq $latestContract.EmployeeCode })
   
        if ($null -eq $personToUpdate ) {
            "No contracts found for $identity"
            continue
        }
        $personToUpdate.ExcludedBySource = "false"
    }

}

#Test selection to identify if the sorted results are correct
#$persons | Select-Object -Property EmployeeCode, ExcludedBySource | Format-Table

# Make sure persons are unique
$persons = $persons | Sort-Object EmployeeCode -Unique

Write-Information "Import completed: $($persons.count) persons processed"

# Export and return the json
$json = $persons | ConvertTo-Json -Depth 10

Write-Output $json
#endregion Script