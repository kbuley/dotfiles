# AGENTS.md - PowerShell

# APPLIES-TO: powershell, ps1

This document provides guidance for AI assistants working with PowerShell code in this repository.

## Project Context

This repository contains PowerShell scripts for Azure resource management, Windows automation, system administration, and infrastructure automation. Code should follow PowerShell best practices, be cross-platform compatible when possible, maintainable, and production-ready.

## Core Principles

### 1. Modern PowerShell (7+)

- **Target PowerShell 7+** (cross-platform) unless Windows-specific features are required
- Use approved verbs (Get-, Set-, New-, Remove-, etc.)
- Follow PSScriptAnalyzer rules
- Use explicit parameter types
- Implement proper error handling

### 2. Cross-Platform Compatibility

- Write scripts that work on Windows, Linux, and macOS when possible
- Use `Join-Path` instead of hardcoded path separators
- Check `$IsWindows`, `$IsLinux`, `$IsMacOS` for platform-specific code
- Avoid Windows-specific cmdlets unless explicitly required
- Use `Get-ChildItem` instead of `dir` or `ls`

### 3. Azure Focus

- Use Azure PowerShell modules (`Az.*`)
- Implement proper authentication patterns
- Handle Azure API throttling and retries
- Use proper resource tagging
- Follow Azure naming conventions

### 4. Code Quality

- Use PSScriptAnalyzer for linting
- Write Pester tests
- Include comment-based help
- Use meaningful variable names
- Implement proper logging

## Project Structure

### Standard Layout

```
.
├── Modules/
│   └── AzureResourceManager/
│       ├── AzureResourceManager.psd1    # Module manifest
│       ├── AzureResourceManager.psm1    # Module script
│       ├── Public/                       # Exported functions
│       │   ├── Get-AzResourceGroupEx.ps1
│       │   └── New-AzResourceGroupEx.ps1
│       ├── Private/                      # Internal functions
│       │   ├── Connect-AzureContext.ps1
│       │   └── Write-Log.ps1
│       └── Tests/                        # Pester tests
│           └── AzureResourceManager.Tests.ps1
├── Scripts/
│   ├── Deploy-Resources.ps1
│   ├── Audit-Permissions.ps1
│   └── Cleanup-Resources.ps1
├── Config/
│   ├── settings.psd1
│   └── environments/
│       ├── dev.psd1
│       └── prod.psd1
├── Logs/
├── .github/
│   └── workflows/
│       └── test.yml
├── Tests/
│   └── Integration/
│       └── Deploy.Tests.ps1
├── PSScriptAnalyzerSettings.psd1
└── README.md
```

## Installation and Setup

### PowerShell 7+ Installation

```powershell
# Windows (winget)
winget install Microsoft.PowerShell

# Windows (MSI)
# Download from: https://github.com/PowerShell/PowerShell/releases

# macOS (Homebrew)
brew install --cask powershell

# Linux (Ubuntu)
sudo apt-get update
sudo apt-get install -y powershell

# Verify installation
$PSVersionTable
```

### Azure PowerShell Module

```powershell
# Install Azure PowerShell
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Install specific modules
Install-Module -Name Az.Accounts -Force
Install-Module -Name Az.Resources -Force
Install-Module -Name Az.Storage -Force
Install-Module -Name Az.KeyVault -Force

# Update modules
Update-Module -Name Az

# List installed Az modules
Get-Module -Name Az.* -ListAvailable
```

### Development Tools

```powershell
# Install PSScriptAnalyzer (linter)
Install-Module -Name PSScriptAnalyzer -Force

# Install Pester (testing framework)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Install platyPS (help documentation)
Install-Module -Name platyPS -Force

# Install PSReadLine (command line editing)
Install-Module -Name PSReadLine -Force -AllowPrerelease
```

## Code Templates

### Script Template with Best Practices

```powershell
<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description of the script's functionality, including any prerequisites,
    assumptions, or important notes about its operation.

.PARAMETER ResourceGroupName
    Name of the Azure resource group to process.

.PARAMETER Location
    Azure region where resources will be created.

.PARAMETER Tags
    Hashtable of tags to apply to resources.

.PARAMETER WhatIf
    Shows what would happen if the script runs. No changes are made.

.EXAMPLE
    .\Deploy-Resources.ps1 -ResourceGroupName "rg-test" -Location "eastus"

    Creates resources in the specified resource group.

.EXAMPLE
    .\Deploy-Resources.ps1 -ResourceGroupName "rg-test" -Location "eastus" -WhatIf

    Shows what would be created without making changes.

.NOTES
    Author: Your Name
    Version: 1.0.0
    Last Modified: 2024-01-15
    Requires: PowerShell 7.0+, Az.Resources module

.LINK
    https://docs.microsoft.com/azure/
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Name of the resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("eastus", "westus", "centralus", "northeurope", "westeurope")]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Dev"
        ManagedBy   = "PowerShell"
    },

    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error", "Debug")]
    [string]$LogLevel = "Info"
)

#Requires -Version 7.0
#Requires -Modules Az.Resources

# Script-level settings
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Script variables
$ScriptName = $MyInvocation.MyCommand.Name
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = Join-Path -Path $ScriptPath -ChildPath "Logs"

#region Functions

<#
.SYNOPSIS
    Writes a log message to the console and optionally to a file.
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    switch ($Level) {
        "Info" { Write-Information $LogMessage }
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
        "Debug" { Write-Debug $Message }
    }

    # Write to log file
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }

    $LogFile = Join-Path -Path $LogPath -ChildPath "$ScriptName-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $LogFile -Value $LogMessage
}

<#
.SYNOPSIS
    Ensures the user is connected to Azure.
#>
function Test-AzureConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $Context = Get-AzContext -ErrorAction Stop
        if ($null -eq $Context) {
            return $false
        }

        Write-Log -Message "Connected to Azure as $($Context.Account.Id)" -Level "Info"
        Write-Log -Message "Subscription: $($Context.Subscription.Name)" -Level "Info"
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Connects to Azure with interactive or service principal authentication.
#>
function Connect-ToAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId
    )

    try {
        if (Test-AzureConnection) {
            return
        }

        Write-Log -Message "Connecting to Azure..." -Level "Info"

        $ConnectParams = @{}
        if ($TenantId) {
            $ConnectParams['TenantId'] = $TenantId
        }
        if ($SubscriptionId) {
            $ConnectParams['SubscriptionId'] = $SubscriptionId
        }

        Connect-AzAccount @ConnectParams -ErrorAction Stop | Out-Null
        Write-Log -Message "Successfully connected to Azure" -Level "Info"
    }
    catch {
        Write-Log -Message "Failed to connect to Azure: $_" -Level "Error"
        throw
    }
}

<#
.SYNOPSIS
    Creates or updates an Azure resource group.
#>
function New-AzResourceGroupEx {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $false)]
        [hashtable]$Tags
    )

    try {
        $ExistingRg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

        if ($ExistingRg) {
            Write-Log -Message "Resource group '$Name' already exists" -Level "Info"

            if ($PSCmdlet.ShouldProcess($Name, "Update resource group tags")) {
                if ($Tags) {
                    $ExistingRg | Set-AzResourceGroup -Tag $Tags | Out-Null
                    Write-Log -Message "Updated tags for resource group '$Name'" -Level "Info"
                }
            }

            return $ExistingRg
        }
        else {
            if ($PSCmdlet.ShouldProcess($Name, "Create resource group")) {
                Write-Log -Message "Creating resource group '$Name' in '$Location'" -Level "Info"

                $Params = @{
                    Name     = $Name
                    Location = $Location
                }

                if ($Tags) {
                    $Params['Tag'] = $Tags
                }

                $NewRg = New-AzResourceGroup @Params
                Write-Log -Message "Successfully created resource group '$Name'" -Level "Info"
                return $NewRg
            }
        }
    }
    catch {
        Write-Log -Message "Failed to create/update resource group '$Name': $_" -Level "Error"
        throw
    }
}

#endregion

#region Main Script Logic

try {
    Write-Log -Message "Starting script: $ScriptName" -Level "Info"
    Write-Log -Message "Parameters: ResourceGroupName=$ResourceGroupName, Location=$Location" -Level "Debug"

    # Connect to Azure
    Connect-ToAzure

    # Create resource group
    $ResourceGroup = New-AzResourceGroupEx -Name $ResourceGroupName -Location $Location -Tags $Tags

    # Display results
    Write-Log -Message "Resource Group Details:" -Level "Info"
    Write-Log -Message "  Name: $($ResourceGroup.ResourceGroupName)" -Level "Info"
    Write-Log -Message "  Location: $($ResourceGroup.Location)" -Level "Info"
    Write-Log -Message "  Provisioning State: $($ResourceGroup.ProvisioningState)" -Level "Info"

    if ($ResourceGroup.Tags.Count -gt 0) {
        Write-Log -Message "  Tags:" -Level "Info"
        foreach ($Tag in $ResourceGroup.Tags.GetEnumerator()) {
            Write-Log -Message "    $($Tag.Key): $($Tag.Value)" -Level "Info"
        }
    }

    Write-Log -Message "Script completed successfully" -Level "Info"
    exit 0
}
catch {
    Write-Log -Message "Script failed: $_" -Level "Error"
    Write-Log -Message "Stack Trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 1
}
finally {
    Write-Log -Message "Script finished at $(Get-Date)" -Level "Info"
}

#endregion
```

### PowerShell Module Template

```powershell
# AzureResourceManager.psm1

# Module variables
$script:ModuleName = "AzureResourceManager"
$script:ModuleVersion = "1.0.0"

# Import private functions
$PrivateFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Private") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import private function $($Function.FullName): $_"
    }
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Public") -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import public function $($Function.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function ($PublicFunctions.BaseName)
```

```powershell
# AzureResourceManager.psd1

@{
    # Script module or binary module file associated with this manifest
    RootModule        = 'AzureResourceManager.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-4a5b-8c7d-9e8f7a6b5c4d'

    # Author of this module
    Author            = 'Your Name'

    # Company or vendor of this module
    CompanyName       = 'Your Company'

    # Copyright statement for this module
    Copyright         = '(c) 2024. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'PowerShell module for managing Azure resources'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        @{ModuleName = 'Az.Accounts'; ModuleVersion = '2.0.0' }
        @{ModuleName = 'Az.Resources'; ModuleVersion = '6.0.0' }
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-AzResourceGroupEx',
        'New-AzResourceGroupEx',
        'Remove-AzResourceGroupEx',
        'Get-AzResourceEx'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module
            Tags       = @('Azure', 'ResourceManagement', 'Automation')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/yourorg/yourrepo/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/yourorg/yourrepo'

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release'
        }
    }
}
```

### Advanced Function Template

```powershell
<#
.SYNOPSIS
    Gets Azure resource groups with enhanced filtering.

.DESCRIPTION
    Retrieves Azure resource groups with additional filtering capabilities
    beyond the standard Get-AzResourceGroup cmdlet. Supports filtering by
    tags, location, and provisioning state.

.PARAMETER Name
    Name of the resource group. Supports wildcards.

.PARAMETER Location
    Filter by Azure region.

.PARAMETER Tag
    Filter by resource tags. Provide a hashtable of tag key-value pairs.

.PARAMETER ProvisioningState
    Filter by provisioning state (Succeeded, Failed, etc.).

.PARAMETER IncludeResourceCount
    Include count of resources in each resource group.

.EXAMPLE
    Get-AzResourceGroupEx -Name "rg-*-prod"

    Gets all resource groups with names matching the pattern.

.EXAMPLE
    Get-AzResourceGroupEx -Location "eastus" -Tag @{Environment="Production"}

    Gets resource groups in East US with the Production environment tag.

.EXAMPLE
    Get-AzResourceGroupEx -IncludeResourceCount

    Gets all resource groups and includes the resource count for each.

.OUTPUTS
    PSCustomObject representing resource groups with additional properties.

.NOTES
    Requires Az.Resources module version 6.0.0 or later.
#>
function Get-AzResourceGroupEx {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'Default'
        )]
        [SupportsWildcards()]
        [Alias('ResourceGroupName')]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "eastus", "eastus2", "westus", "westus2", "westus3",
            "centralus", "northcentralus", "southcentralus",
            "northeurope", "westeurope", "uksouth", "ukwest",
            "francecentral", "germanywestcentral", "switzerlandnorth",
            "norwayeast", "swedencentral"
        )]
        [string]$Location,

        [Parameter(Mandatory = $false)]
        [hashtable]$Tag,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Succeeded", "Failed", "Canceled", "Accepted", "Creating", "Created", "Updating", "Updated", "Deleting", "Deleted", "Running")]
        [string]$ProvisioningState,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeResourceCount
    )

    begin {
        Write-Verbose "Starting Get-AzResourceGroupEx"

        # Validate Azure connection
        $Context = Get-AzContext
        if (-not $Context) {
            throw "Not connected to Azure. Run Connect-AzAccount first."
        }

        Write-Verbose "Using subscription: $($Context.Subscription.Name)"

        # Initialize results array
        $Results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        try {
            # Get base resource groups
            $GetParams = @{}
            if ($Name) {
                $GetParams['Name'] = $Name
            }

            $ResourceGroups = Get-AzResourceGroup @GetParams

            foreach ($Rg in $ResourceGroups) {
                # Apply filters
                if ($Location -and $Rg.Location -ne $Location) {
                    continue
                }

                if ($ProvisioningState -and $Rg.ProvisioningState -ne $ProvisioningState) {
                    continue
                }

                if ($Tag) {
                    $TagMatch = $true
                    foreach ($Key in $Tag.Keys) {
                        if (-not $Rg.Tags.ContainsKey($Key) -or $Rg.Tags[$Key] -ne $Tag[$Key]) {
                            $TagMatch = $false
                            break
                        }
                    }
                    if (-not $TagMatch) {
                        continue
                    }
                }

                # Build result object
                $Result = [PSCustomObject]@{
                    PSTypeName         = 'AzureResourceManager.ResourceGroup'
                    ResourceGroupName  = $Rg.ResourceGroupName
                    Location           = $Rg.Location
                    ProvisioningState  = $Rg.ProvisioningState
                    ResourceId         = $Rg.ResourceId
                    Tags               = $Rg.Tags
                    ManagedBy          = $Rg.ManagedBy
                }

                # Add resource count if requested
                if ($IncludeResourceCount) {
                    $ResourceCount = (Get-AzResource -ResourceGroupName $Rg.ResourceGroupName).Count
                    $Result | Add-Member -NotePropertyName 'ResourceCount' -NotePropertyValue $ResourceCount
                }

                $Results.Add($Result)
            }
        }
        catch {
            Write-Error "Failed to retrieve resource groups: $_"
            throw
        }
    }

    end {
        Write-Verbose "Found $($Results.Count) resource groups"
        return $Results
    }
}
```

### Class-Based PowerShell

```powershell
<#
.SYNOPSIS
    Azure resource group manager class.
#>
class AzureResourceGroupManager {
    # Properties
    [string]$SubscriptionId
    [string]$TenantId
    [hashtable]$DefaultTags

    # Constructor
    AzureResourceGroupManager([string]$SubscriptionId, [string]$TenantId) {
        $this.SubscriptionId = $SubscriptionId
        $this.TenantId = $TenantId
        $this.DefaultTags = @{
            ManagedBy = "PowerShell"
            CreatedDate = (Get-Date -Format "yyyy-MM-dd")
        }
    }

    # Method: Connect to Azure
    [void]Connect() {
        try {
            $Context = Get-AzContext
            if ($null -eq $Context -or $Context.Subscription.Id -ne $this.SubscriptionId) {
                Write-Verbose "Connecting to Azure..."
                Connect-AzAccount -TenantId $this.TenantId -SubscriptionId $this.SubscriptionId | Out-Null
            }
        }
        catch {
            throw "Failed to connect to Azure: $_"
        }
    }

    # Method: Get resource group
    [object]GetResourceGroup([string]$Name) {
        $this.Connect()
        return Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
    }

    # Method: Create resource group
    [object]CreateResourceGroup([string]$Name, [string]$Location, [hashtable]$Tags) {
        $this.Connect()

        $ExistingRg = $this.GetResourceGroup($Name)
        if ($ExistingRg) {
            Write-Warning "Resource group '$Name' already exists"
            return $ExistingRg
        }

        # Merge default tags with provided tags
        $AllTags = $this.DefaultTags.Clone()
        if ($Tags) {
            foreach ($Key in $Tags.Keys) {
                $AllTags[$Key] = $Tags[$Key]
            }
        }

        $Params = @{
            Name     = $Name
            Location = $Location
            Tag      = $AllTags
        }

        return New-AzResourceGroup @Params
    }

    # Method: Delete resource group
    [bool]DeleteResourceGroup([string]$Name, [bool]$Force) {
        $this.Connect()

        $Rg = $this.GetResourceGroup($Name)
        if (-not $Rg) {
            Write-Warning "Resource group '$Name' not found"
            return $false
        }

        try {
            if ($Force) {
                Remove-AzResourceGroup -Name $Name -Force | Out-Null
            }
            else {
                Remove-AzResourceGroup -Name $Name | Out-Null
            }
            return $true
        }
        catch {
            Write-Error "Failed to delete resource group '$Name': $_"
            return $false
        }
    }

    # Method: List all resource groups
    [array]ListResourceGroups() {
        $this.Connect()
        return Get-AzResourceGroup
    }

    # Method: List resource groups by location
    [array]ListResourceGroupsByLocation([string]$Location) {
        $this.Connect()
        return Get-AzResourceGroup | Where-Object { $_.Location -eq $Location }
    }

    # Method: List resource groups by tag
    [array]ListResourceGroupsByTag([string]$TagName, [string]$TagValue) {
        $this.Connect()
        return Get-AzResourceGroup | Where-Object {
            $_.Tags.ContainsKey($TagName) -and $_.Tags[$TagName] -eq $TagValue
        }
    }
}

# Usage example
<#
$Manager = [AzureResourceGroupManager]::new("subscription-id", "tenant-id")
$Rg = $Manager.CreateResourceGroup("rg-test", "eastus", @{Environment="Dev"})
$AllRgs = $Manager.ListResourceGroups()
#>
```

## Azure Automation Patterns

### Authentication Patterns

```powershell
<#
.SYNOPSIS
    Authenticates to Azure using various methods.
#>

# Method 1: Interactive Login
function Connect-AzureInteractive {
    param(
        [string]$TenantId,
        [string]$SubscriptionId
    )

    $Params = @{}
    if ($TenantId) { $Params['TenantId'] = $TenantId }
    if ($SubscriptionId) { $Params['SubscriptionId'] = $SubscriptionId }

    Connect-AzAccount @Params
}

# Method 2: Service Principal with Secret
function Connect-AzureServicePrincipal {
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$ApplicationId,

        [Parameter(Mandatory)]
        [securestring]$Secret,

        [string]$SubscriptionId
    )

    $Credential = New-Object System.Management.Automation.PSCredential($ApplicationId, $Secret)

    $Params = @{
        TenantId           = $TenantId
        Credential         = $Credential
        ServicePrincipal   = $true
    }

    if ($SubscriptionId) {
        $Params['SubscriptionId'] = $SubscriptionId
    }

    Connect-AzAccount @Params
}

# Method 3: Managed Identity (Azure VM, Function App, etc.)
function Connect-AzureManagedIdentity {
    param(
        [string]$SubscriptionId
    )

    $Params = @{
        Identity = $true
    }

    if ($SubscriptionId) {
        $Params['SubscriptionId'] = $SubscriptionId
    }

    Connect-AzAccount @Params
}

# Method 4: Certificate-based Authentication
function Connect-AzureCertificate {
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [string]$ApplicationId,

        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,

        [string]$SubscriptionId
    )

    $Params = @{
        TenantId              = $TenantId
        ApplicationId         = $ApplicationId
        CertificateThumbprint = $CertificateThumbprint
        ServicePrincipal      = $true
    }

    if ($SubscriptionId) {
        $Params['SubscriptionId'] = $SubscriptionId
    }

    Connect-AzAccount @Params
}

# Method 5: Using Environment Variables
function Connect-AzureFromEnvironment {
    $TenantId = $env:AZURE_TENANT_ID
    $SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
    $ApplicationId = $env:AZURE_CLIENT_ID
    $ClientSecret = $env:AZURE_CLIENT_SECRET

    if (-not ($TenantId -and $ApplicationId -and $ClientSecret)) {
        throw "Required environment variables not set"
    }

    $SecureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    Connect-AzureServicePrincipal -TenantId $TenantId `
                                   -ApplicationId $ApplicationId `
                                   -Secret $SecureSecret `
                                   -SubscriptionId $SubscriptionId
}
```

### Resource Management Patterns

```powershell
<#
.SYNOPSIS
    Common patterns for Azure resource management.
#>

# Pattern 1: Bulk Resource Operations with Progress
function Get-AllAzureResources {
    [CmdletBinding()]
    param(
        [string]$ResourceType,
        [hashtable]$Tag
    )

    $AllResources = [System.Collections.Generic.List[object]]::new()
    $ResourceGroups = Get-AzResourceGroup
    $TotalGroups = $ResourceGroups.Count
    $Counter = 0

    foreach ($Rg in $ResourceGroups) {
        $Counter++
        $PercentComplete = [math]::Round(($Counter / $TotalGroups) * 100, 2)

        Write-Progress -Activity "Scanning Resource Groups" `
                       -Status "Processing $($Rg.ResourceGroupName)" `
                       -PercentComplete $PercentComplete

        $Params = @{
            ResourceGroupName = $Rg.ResourceGroupName
        }

        if ($ResourceType) {
            $Params['ResourceType'] = $ResourceType
        }

        $Resources = Get-AzResource @Params

        if ($Tag) {
            $Resources = $Resources | Where-Object {
                $ResourceTags = $_.Tags
                $Match = $true
                foreach ($Key in $Tag.Keys) {
                    if (-not $ResourceTags.ContainsKey($Key) -or $ResourceTags[$Key] -ne $Tag[$Key]) {
                        $Match = $false
                        break
                    }
                }
                $Match
            }
        }

        $AllResources.AddRange($Resources)
    }

    Write-Progress -Activity "Scanning Resource Groups" -Completed
    return $AllResources
}

# Pattern 2: Parallel Processing with ForEach-Object -Parallel
function Remove-OldAzureResourceGroups {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [int]$DaysOld,

        [int]$ThrottleLimit = 5
    )

    $CutoffDate = (Get-Date).AddDays(-$DaysOld)
    $ResourceGroups = Get-AzResourceGroup | Where-Object {
        $_.Tags.ContainsKey("CreatedDate") -and
        [datetime]$_.Tags["CreatedDate"] -lt $CutoffDate
    }

    $ResourceGroups | ForEach-Object -Parallel {
        $Rg = $_

        if ($using:PSCmdlet.ShouldProcess($Rg.ResourceGroupName, "Delete resource group")) {
            try {
                Remove-AzResourceGroup -Name $Rg.ResourceGroupName -Force -ErrorAction Stop
                Write-Host "Deleted resource group: $($Rg.ResourceGroupName)"
            }
            catch {
                Write-Warning "Failed to delete $($Rg.ResourceGroupName): $_"
            }
        }
    } -ThrottleLimit $ThrottleLimit
}

# Pattern 3: Retry Logic with Exponential Backoff
function Invoke-AzureOperationWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRetries = 3,

        [int]$InitialDelaySeconds = 2
    )

    $Attempt = 0
    $Delay = $InitialDelaySeconds

    while ($Attempt -lt $MaxRetries) {
        try {
            $Attempt++
            Write-Verbose "Attempt $Attempt of $MaxRetries"

            $Result = & $ScriptBlock
            return $Result
        }
        catch {
            $LastError = $_

            if ($Attempt -ge $MaxRetries) {
                Write-Error "Operation failed after $MaxRetries attempts: $LastError"
                throw
            }

            Write-Warning "Attempt $Attempt failed: $($LastError.Exception.Message)"
            Write-Verbose "Waiting $Delay seconds before retry..."

            Start-Sleep -Seconds $Delay
            $Delay = $Delay * 2  # Exponential backoff
        }
    }
}

# Usage:
# Invoke-AzureOperationWithRetry -ScriptBlock {
#     Get-AzResourceGroup -Name "rg-test"
# }

# Pattern 4: Resource Tagging
function Set-AzureResourceTags {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Resource,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [switch]$Merge
    )

    process {
        try {
            $CurrentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }

            if ($Merge) {
                # Merge new tags with existing
                $NewTags = $CurrentTags.Clone()
                foreach ($Key in $Tags.Keys) {
                    $NewTags[$Key] = $Tags[$Key]
                }
            }
            else {
                # Replace all tags
                $NewTags = $Tags
            }

            if ($PSCmdlet.ShouldProcess($Resource.Name, "Update tags")) {
                Set-AzResource -ResourceId $Resource.ResourceId -Tag $NewTags -Force
                Write-Verbose "Updated tags for $($Resource.Name)"
            }
        }
        catch {
            Write-Error "Failed to update tags for $($Resource.Name): $_"
        }
    }
}
```

### Storage Account Operations

```powershell
<#
.SYNOPSIS
    Azure Storage Account management functions.
#>

function New-AzStorageAccountEx {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateLength(3, 24)]
        [ValidatePattern('^[a-z0-9]+$')]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$Location,

        [Parameter()]
        [ValidateSet('Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_ZRS', 'Premium_LRS')]
        [string]$SkuName = 'Standard_LRS',

        [Parameter()]
        [ValidateSet('StorageV2', 'Storage', 'BlobStorage')]
        [string]$Kind = 'StorageV2',

        [Parameter()]
        [hashtable]$Tags,

        [Parameter()]
        [switch]$EnableHttpsTrafficOnly = $true,

        [Parameter()]
        [switch]$EnableHierarchicalNamespace
    )

    try {
        # Check if storage account already exists
        $ExistingAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue

        if ($ExistingAccount) {
            Write-Warning "Storage account '$Name' already exists"
            return $ExistingAccount
        }

        if ($PSCmdlet.ShouldProcess($Name, "Create storage account")) {
            $Params = @{
                ResourceGroupName = $ResourceGroupName
                Name              = $Name
                Location          = $Location
                SkuName           = $SkuName
                Kind              = $Kind
            }

            if ($Tags) {
                $Params['Tag'] = $Tags
            }

            if ($EnableHttpsTrafficOnly) {
                $Params['EnableHttpsTrafficOnly'] = $true
            }

            if ($EnableHierarchicalNamespace) {
                $Params['EnableHierarchicalNamespace'] = $true
            }

            $StorageAccount = New-AzStorageAccount @Params

            Write-Verbose "Successfully created storage account '$Name'"
            return $StorageAccount
        }
    }
    catch {
        Write-Error "Failed to create storage account '$Name': $_"
        throw
    }
}

function Get-AzStorageAccountKeys {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $Keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $Name

        return @{
            Key1 = $Keys[0].Value
            Key2 = $Keys[1].Value
        }
    }
    catch {
        Write-Error "Failed to retrieve storage account keys: $_"
        throw
    }
}

function New-AzStorageContainerEx {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Context,

        [Parameter()]
        [ValidateSet('Container', 'Blob', 'Off')]
        [string]$Permission = 'Off'
    )

    try {
        $ExistingContainer = Get-AzStorageContainer -Name $Name -Context $Context -ErrorAction SilentlyContinue

        if ($ExistingContainer) {
            Write-Warning "Container '$Name' already exists"
            return $ExistingContainer
        }

        if ($PSCmdlet.ShouldProcess($Name, "Create storage container")) {
            $Container = New-AzStorageContainer -Name $Name -Context $Context -Permission $Permission
            Write-Verbose "Successfully created container '$Name'"
            return $Container
        }
    }
    catch {
        Write-Error "Failed to create container '$Name': $_"
        throw
    }
}
```

## Testing with Pester

### Unit Test Template

```powershell
# Tests/AzureResourceManager.Tests.ps1

BeforeAll {
    # Import module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Modules\AzureResourceManager"
    Import-Module $ModulePath -Force

    # Mock Azure cmdlets
    Mock Connect-AzAccount { return @{ Context = @{ Subscription = @{ Name = "Test" } } } }
    Mock Get-AzContext { return @{ Account = @{ Id = "test@example.com" }; Subscription = @{ Name = "Test" } } }
}

Describe "Get-AzResourceGroupEx" {
    Context "When retrieving resource groups" {
        BeforeEach {
            Mock Get-AzResourceGroup {
                return @(
                    @{
                        ResourceGroupName  = "rg-test-1"
                        Location           = "eastus"
                        ProvisioningState  = "Succeeded"
                        ResourceId         = "/subscriptions/test/resourceGroups/rg-test-1"
                        Tags               = @{ Environment = "Dev" }
                        ManagedBy          = $null
                    },
                    @{
                        ResourceGroupName  = "rg-test-2"
                        Location           = "westus"
                        ProvisioningState  = "Succeeded"
                        ResourceId         = "/subscriptions/test/resourceGroups/rg-test-2"
                        Tags               = @{ Environment = "Prod" }
                        ManagedBy          = $null
                    }
                )
            }
        }

        It "Should return all resource groups when no filters are applied" {
            $Result = Get-AzResourceGroupEx
            $Result.Count | Should -Be 2
        }

        It "Should filter by location" {
            $Result = Get-AzResourceGroupEx -Location "eastus"
            $Result.Count | Should -Be 1
            $Result[0].Location | Should -Be "eastus"
        }

        It "Should filter by tag" {
            $Result = Get-AzResourceGroupEx -Tag @{ Environment = "Dev" }
            $Result.Count | Should -Be 1
            $Result[0].Tags.Environment | Should -Be "Dev"
        }

        It "Should filter by provisioning state" {
            $Result = Get-AzResourceGroupEx -ProvisioningState "Succeeded"
            $Result.Count | Should -Be 2
        }
    }

    Context "When Azure is not connected" {
        BeforeEach {
            Mock Get-AzContext { return $null }
        }

        It "Should throw an error" {
            { Get-AzResourceGroupEx } | Should -Throw "Not connected to Azure*"
        }
    }
}

Describe "New-AzResourceGroupEx" {
    Context "When creating a new resource group" {
        BeforeEach {
            Mock Get-AzResourceGroup { return $null }
            Mock New-AzResourceGroup {
                return @{
                    ResourceGroupName  = $Name
                    Location           = $Location
                    ProvisioningState  = "Succeeded"
                    ResourceId         = "/subscriptions/test/resourceGroups/$Name"
                    Tags               = $Tag
                }
            }
        }

        It "Should create a new resource group" {
            $Result = New-AzResourceGroupEx -Name "rg-new" -Location "eastus" -Tags @{ Environment = "Test" }

            $Result.ResourceGroupName | Should -Be "rg-new"
            $Result.Location | Should -Be "eastus"
            $Result.Tags.Environment | Should -Be "Test"

            Should -Invoke New-AzResourceGroup -Times 1
        }
    }

    Context "When resource group already exists" {
        BeforeEach {
            Mock Get-AzResourceGroup {
                return @{
                    ResourceGroupName  = "rg-existing"
                    Location           = "eastus"
                    ProvisioningState  = "Succeeded"
                    Tags               = @{}
                }
            }
            Mock Set-AzResourceGroup { }
        }

        It "Should update tags if provided" {
            $Result = New-AzResourceGroupEx -Name "rg-existing" -Location "eastus" -Tags @{ Updated = "Yes" }

            Should -Invoke Set-AzResourceGroup -Times 1
            Should -Invoke New-AzResourceGroup -Times 0
        }
    }
}

Describe "AzureResourceGroupManager Class" {
    BeforeEach {
        Mock Connect-AzAccount { }
        Mock Get-AzContext { return @{ Subscription = @{ Id = "test-sub" } } }
    }

    Context "When initializing the class" {
        It "Should create instance with correct properties" {
            $Manager = [AzureResourceGroupManager]::new("test-sub", "test-tenant")

            $Manager.SubscriptionId | Should -Be "test-sub"
            $Manager.TenantId | Should -Be "test-tenant"
            $Manager.DefaultTags.ContainsKey("ManagedBy") | Should -Be $true
        }
    }

    Context "When creating a resource group" {
        BeforeEach {
            Mock Get-AzResourceGroup { return $null }
            Mock New-AzResourceGroup {
                return @{
                    ResourceGroupName = "rg-test"
                    Location          = "eastus"
                }
            }
        }

        It "Should create resource group with merged tags" {
            $Manager = [AzureResourceGroupManager]::new("test-sub", "test-tenant")
            $Result = $Manager.CreateResourceGroup("rg-test", "eastus", @{ Custom = "Value" })

            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke New-AzResourceGroup -Times 1
        }
    }
}

AfterAll {
    # Cleanup
    Remove-Module AzureResourceManager -Force -ErrorAction SilentlyContinue
}
```

### Integration Test Template

```powershell
# Tests/Integration/Deploy.Tests.ps1

#Requires -Modules Pester, Az.Resources

BeforeAll {
    # Load configuration
    $Config = Import-PowerShellDataFile -Path "$PSScriptRoot\..\..\Config\settings.psd1"

    # Set test variables
    $script:TestResourceGroupName = "rg-pester-test-$(Get-Random)"
    $script:TestLocation = "eastus"
    $script:TestTags = @{
        Environment = "Test"
        CreatedBy   = "Pester"
    }
}

Describe "Integration: Resource Group Lifecycle" -Tag "Integration" {
    Context "When managing resource groups end-to-end" {
        It "Should connect to Azure successfully" {
            { Connect-AzAccount -Identity } | Should -Not -Throw
            $Context = Get-AzContext
            $Context | Should -Not -BeNullOrEmpty
        }

        It "Should create a new resource group" {
            $Rg = New-AzResourceGroup -Name $script:TestResourceGroupName -Location $script:TestLocation -Tag $script:TestTags

            $Rg | Should -Not -BeNullOrEmpty
            $Rg.ResourceGroupName | Should -Be $script:TestResourceGroupName
            $Rg.ProvisioningState | Should -Be "Succeeded"
        }

        It "Should retrieve the created resource group" {
            $Rg = Get-AzResourceGroup -Name $script:TestResourceGroupName

            $Rg | Should -Not -BeNullOrEmpty
            $Rg.Tags.Environment | Should -Be "Test"
        }

        It "Should update resource group tags" {
            $UpdatedTags = @{
                Environment = "Test"
                CreatedBy   = "Pester"
                Updated     = (Get-Date -Format "yyyy-MM-dd")
            }

            Set-AzResourceGroup -Name $script:TestResourceGroupName -Tag $UpdatedTags

            $Rg = Get-AzResourceGroup -Name $script:TestResourceGroupName
            $Rg.Tags.Updated | Should -Not -BeNullOrEmpty
        }

        It "Should delete the resource group" {
            Remove-AzResourceGroup -Name $script:TestResourceGroupName -Force

            Start-Sleep -Seconds 5  # Wait for deletion to propagate

            $Rg = Get-AzResourceGroup -Name $script:TestResourceGroupName -ErrorAction SilentlyContinue
            $Rg | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    # Cleanup - ensure test resource group is deleted
    $Rg = Get-AzResourceGroup -Name $script:TestResourceGroupName -ErrorAction SilentlyContinue
    if ($Rg) {
        Remove-AzResourceGroup -Name $script:TestResourceGroupName -Force
    }
}
```

## Error Handling Patterns

```powershell
<#
.SYNOPSIS
    Demonstrates various error handling patterns.
#>

# Pattern 1: Try-Catch with Specific Error Types
function Get-AzResourceSafe {
    param(
        [string]$ResourceId
    )

    try {
        $Resource = Get-AzResource -ResourceId $ResourceId -ErrorAction Stop
        return $Resource
    }
    catch [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Entities.ErrorResponses.ErrorResponseException] {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Warning "Resource not found: $ResourceId"
            return $null
        }
        throw
    }
    catch {
        Write-Error "Unexpected error retrieving resource: $_"
        throw
    }
}

# Pattern 2: Custom Error Records
function New-CustomError {
    param(
        [string]$Message,
        [string]$ErrorId,
        [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,
        [object]$TargetObject
    )

    $Exception = New-Object System.Exception($Message)
    $ErrorRecord = New-Object System.Management.Automation.ErrorRecord(
        $Exception,
        $ErrorId,
        $Category,
        $TargetObject
    )

    $PSCmdlet.WriteError($ErrorRecord)
}

# Usage:
# New-CustomError -Message "Resource group not found" `
#                  -ErrorId "ResourceGroupNotFound" `
#                  -Category ObjectNotFound `
#                  -TargetObject $ResourceGroupName

# Pattern 3: Error Handling with Finally Block
function Invoke-AzureOperationWithCleanup {
    param(
        [scriptblock]$Operation,
        [scriptblock]$Cleanup
    )

    try {
        & $Operation
    }
    catch {
        Write-Error "Operation failed: $_"
        throw
    }
    finally {
        if ($Cleanup) {
            try {
                & $Cleanup
            }
            catch {
                Write-Warning "Cleanup failed: $_"
            }
        }
    }
}

# Pattern 4: Collecting and Reporting Multiple Errors
function Remove-MultipleResourceGroups {
    [CmdletBinding()]
    param(
        [string[]]$Names
    )

    $Errors = [System.Collections.Generic.List[object]]::new()
    $Succeeded = [System.Collections.Generic.List[string]]::new()

    foreach ($Name in $Names) {
        try {
            Remove-AzResourceGroup -Name $Name -Force -ErrorAction Stop
            $Succeeded.Add($Name)
            Write-Verbose "Successfully deleted: $Name"
        }
        catch {
            $Errors.Add([PSCustomObject]@{
                ResourceGroup = $Name
                Error         = $_.Exception.Message
                Timestamp     = Get-Date
            })
            Write-Warning "Failed to delete $Name: $($_.Exception.Message)"
        }
    }

    # Return summary
    return [PSCustomObject]@{
        TotalAttempted = $Names.Count
        Succeeded      = $Succeeded.Count
        Failed         = $Errors.Count
        SucceededList  = $Succeeded
        Errors         = $Errors
    }
}
```

## Performance Optimization

```powershell
<#
.SYNOPSIS
    Performance optimization patterns for PowerShell.
#>

# Pattern 1: Use Generic Collections Instead of Arrays
function Get-LargeDataSet {
    # BAD - Array concatenation is slow
    $Results = @()
    1..10000 | ForEach-Object {
        $Results += $_  # Creates new array each time
    }

    # GOOD - Generic list is fast
    $Results = [System.Collections.Generic.List[int]]::new()
    1..10000 | ForEach-Object {
        $Results.Add($_)  # Adds to existing list
    }

    return $Results
}

# Pattern 2: Use -Filter Parameter Instead of Where-Object
function Get-FilteredResources {
    # BAD - Retrieves all, then filters in PowerShell
    $Resources = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }

    # GOOD - Filters server-side
    $Resources = Get-AzResource -ResourceType "Microsoft.Storage/storageAccounts"

    return $Resources
}

# Pattern 3: Use StringBuilder for String Concatenation
function Build-LargeString {
    # BAD - String concatenation creates new string each time
    $Result = ""
    1..1000 | ForEach-Object {
        $Result += "Line $_`n"
    }

    # GOOD - StringBuilder is efficient
    $StringBuilder = [System.Text.StringBuilder]::new()
    1..1000 | ForEach-Object {
        [void]$StringBuilder.AppendLine("Line $_")
    }
    $Result = $StringBuilder.ToString()

    return $Result
}

# Pattern 4: Disable Progress for Better Performance
function Get-AllResourcesOptimized {
    $OldProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"

    try {
        $Resources = Get-AzResource
        return $Resources
    }
    finally {
        $ProgressPreference = $OldProgressPreference
    }
}

# Pattern 5: Use Jobs for Parallel Processing (PowerShell 7+)
function Get-MultipleResourceGroupsParallel {
    param(
        [string[]]$Names
    )

    $Results = $Names | ForEach-Object -Parallel {
        Get-AzResourceGroup -Name $_ -ErrorAction SilentlyContinue
    } -ThrottleLimit 10

    return $Results
}
```

## Configuration Management

```powershell
# settings.psd1
@{
    Azure = @{
        TenantId       = $env:AZURE_TENANT_ID
        SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
        DefaultLocation = "eastus"
        DefaultTags = @{
            ManagedBy   = "PowerShell"
            Environment = "Production"
        }
    }

    Logging = @{
        Level      = "Info"
        Path       = ".\Logs"
        MaxSizeMB  = 100
        Retention  = 30  # days
    }

    Retry = @{
        MaxAttempts = 3
        InitialDelay = 2
        Backoff     = "Exponential"
    }
}
```

```powershell
# Load and use configuration
function Get-Configuration {
    [CmdletBinding()]
    param(
        [string]$Path = ".\Config\settings.psd1"
    )

    if (-not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }

    $Config = Import-PowerShellDataFile -Path $Path

    # Validate required settings
    if (-not $Config.Azure.TenantId) {
        throw "Azure TenantId not configured"
    }

    return $Config
}

# Usage
$Config = Get-Configuration
Connect-AzAccount -TenantId $Config.Azure.TenantId -SubscriptionId $Config.Azure.SubscriptionId
```

## PSScriptAnalyzer Configuration

```powershell
# PSScriptAnalyzerSettings.psd1
@{
    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        PSAvoidGlobalVars = @{
            Enable = $true
        }
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
    }

    ExcludeRules = @(
        'PSAvoidUsingWriteHost'  # Allow Write-Host for user-facing output
    )

    IncludeDefaultRules = $true
}
```

## Azure-Specific Best Practices

### Multi-Subscription Operations

**CRITICAL**: Always assume operations apply to ALL subscriptions unless explicitly filtered.

```powershell
<#
.SYNOPSIS
    Gets all resource groups across all subscriptions.

.DESCRIPTION
    By default, operates on ALL accessible subscriptions. Use -SubscriptionId
    to limit scope to specific subscriptions.

.PARAMETER SubscriptionId
    Optional. Specific subscription(s) to query. If not provided, queries all subscriptions.

.PARAMETER ExcludeSubscriptionId
    Optional. Subscriptions to exclude from the operation.
#>
function Get-AllAzResourceGroups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeSubscriptionId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Tag
    )

    # Get subscriptions to query
    if ($SubscriptionId) {
        $Subscriptions = $SubscriptionId | ForEach-Object {
            Get-AzSubscription -SubscriptionId $_ -ErrorAction SilentlyContinue
        }
    }
    else {
        # DEFAULT: Get ALL subscriptions
        $Subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }

        if ($ExcludeSubscriptionId) {
            $Subscriptions = $Subscriptions | Where-Object {
                $_.Id -notin $ExcludeSubscriptionId
            }
        }
    }

    Write-Verbose "Operating on $($Subscriptions.Count) subscriptions"

    $AllResourceGroups = [System.Collections.Generic.List[object]]::new()

    foreach ($Sub in $Subscriptions) {
        try {
            Set-AzContext -SubscriptionId $Sub.Id -ErrorAction Stop | Out-Null
            Write-Verbose "Querying subscription: $($Sub.Name)"

            $ResourceGroups = Get-AzResourceGroup

            if ($Tag) {
                $ResourceGroups = $ResourceGroups | Where-Object {
                    $RgTags = $_.Tags
                    $Match = $true
                    foreach ($Key in $Tag.Keys) {
                        if (-not $RgTags.ContainsKey($Key) -or $RgTags[$Key] -ne $Tag[$Key]) {
                            $Match = $false
                            break
                        }
                    }
                    $Match
                }
            }

            # Add subscription context to results
            foreach ($Rg in $ResourceGroups) {
                $Rg | Add-Member -NotePropertyName "SubscriptionId" -NotePropertyValue $Sub.Id -Force
                $Rg | Add-Member -NotePropertyName "SubscriptionName" -NotePropertyValue $Sub.Name -Force
                $AllResourceGroups.Add($Rg)
            }
        }
        catch {
            Write-Warning "Failed to query subscription $($Sub.Name): $_"
        }
    }

    return $AllResourceGroups
}

# Usage examples:
# Get-AllAzResourceGroups                                    # ALL subscriptions (default)
# Get-AllAzResourceGroups -SubscriptionId "sub-123"          # Single subscription
# Get-AllAzResourceGroups -ExcludeSubscriptionId "sub-test"  # All except test
```

### Prefer Graph API Over PowerShell Loops

**CRITICAL**: Never query items individually in a loop. Use batch operations and Graph API.

```powershell
<#
.SYNOPSIS
    Demonstrates efficient resource querying using Azure Resource Graph.
#>

# BAD: Querying individual resources in a loop
function Get-ResourcesSlowly {
    $AllResources = @()
    $ResourceGroups = Get-AzResourceGroup

    foreach ($Rg in $ResourceGroups) {
        # This makes N API calls - VERY SLOW
        $Resources = Get-AzResource -ResourceGroupName $Rg.ResourceGroupName
        $AllResources += $Resources
    }

    return $AllResources
}

# GOOD: Using Azure Resource Graph for batch queries
function Get-ResourcesEfficiently {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [string]$ResourceType,

        [Parameter(Mandatory = $false)]
        [hashtable]$Tag
    )

    # Build query
    $Query = "Resources"

    # Add filters
    $Filters = [System.Collections.Generic.List[string]]::new()

    if ($ResourceType) {
        $Filters.Add("type == '$ResourceType'")
    }

    if ($Tag) {
        foreach ($Key in $Tag.Keys) {
            $Value = $Tag[$Key]
            $Filters.Add("tags['$Key'] == '$Value'")
        }
    }

    if ($Filters.Count -gt 0) {
        $Query += " | where $($Filters -join ' and ')"
    }

    # Add projection for relevant fields
    $Query += " | project id, name, type, resourceGroup, location, subscriptionId, tags"

    Write-Verbose "Query: $Query"

    # Execute query
    if ($SubscriptionId) {
        $Results = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 1000
    }
    else {
        # Query ALL subscriptions efficiently
        $Results = Search-AzGraph -Query $Query -First 1000
    }

    # Handle pagination if needed
    $AllResults = [System.Collections.Generic.List[object]]::new()
    $AllResults.AddRange($Results)

    while ($Results.SkipToken) {
        if ($SubscriptionId) {
            $Results = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 1000 -SkipToken $Results.SkipToken
        }
        else {
            $Results = Search-AzGraph -Query $Query -First 1000 -SkipToken $Results.SkipToken
        }
        $AllResults.AddRange($Results)
    }

    Write-Verbose "Retrieved $($AllResults.Count) resources"
    return $AllResults
}

# Advanced Resource Graph Queries
function Get-ResourcesByComplexCriteria {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$SubscriptionId
    )

    # Complex query example: Find all VMs without backup enabled
    $Query = @"
Resources
| where type == 'microsoft.compute/virtualmachines'
| extend backupEnabled = isnotnull(properties.protectionPolicy)
| where backupEnabled == false
| project id, name, resourceGroup, location, subscriptionId, tags
| order by name asc
"@

    if ($SubscriptionId) {
        $Results = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 1000
    }
    else {
        $Results = Search-AzGraph -Query $Query -First 1000
    }

    return $Results
}

# Example: Get resources with specific tags across all subscriptions
function Get-ResourcesByTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$RequiredTags
    )

    # Build tag filter
    $TagFilters = $RequiredTags.GetEnumerator() | ForEach-Object {
        "tags['$($_.Key)'] == '$($_.Value)'"
    }

    $Query = @"
Resources
| where $($TagFilters -join ' and ')
| project id, name, type, resourceGroup, location, subscriptionId, tags
"@

    return Search-AzGraph -Query $Query -First 1000
}
```

### Session Validation and Auto-Login

**CRITICAL**: Always validate session and prompt for login if needed.

```powershell
<#
.SYNOPSIS
    Validates Azure session and prompts for login if needed.
#>

function Test-AzureSession {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RequiredSubscriptionId,

        [Parameter(Mandatory = $false)]
        [switch]$RequireGraphAPI
    )

    $SessionValid = $true

    # Check Az PowerShell context
    try {
        $Context = Get-AzContext -ErrorAction Stop

        if ($null -eq $Context -or $null -eq $Context.Account) {
            Write-Warning "No active Azure PowerShell session found"
            $SessionValid = $false
        }
        else {
            Write-Verbose "Azure PowerShell session active: $($Context.Account.Id)"

            if ($RequiredSubscriptionId -and $Context.Subscription.Id -ne $RequiredSubscriptionId) {
                Write-Verbose "Switching to subscription: $RequiredSubscriptionId"
                Set-AzContext -SubscriptionId $RequiredSubscriptionId -ErrorAction Stop | Out-Null
            }
        }
    }
    catch {
        Write-Warning "Azure PowerShell session validation failed: $_"
        $SessionValid = $false
    }

    # Check Microsoft Graph session if required
    if ($RequireGraphAPI) {
        try {
            $GraphContext = Get-MgContext -ErrorAction Stop

            if ($null -eq $GraphContext) {
                Write-Warning "No active Microsoft Graph session found"
                $SessionValid = $false
            }
            else {
                Write-Verbose "Microsoft Graph session active: $($GraphContext.Account)"
            }
        }
        catch {
            Write-Warning "Microsoft Graph session validation failed: $_"
            $SessionValid = $false
        }
    }

    return $SessionValid
}

function Connect-AzureWithValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,

        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [switch]$RequireGraphAPI,

        [Parameter(Mandatory = $false)]
        [string[]]$GraphScopes = @(
            "User.Read.All",
            "Group.Read.All",
            "Directory.Read.All"
        )
    )

    Write-Host "Validating Azure sessions..." -ForegroundColor Cyan

    # Check if already connected
    if (Test-AzureSession -RequiredSubscriptionId $SubscriptionId -RequireGraphAPI:$RequireGraphAPI) {
        Write-Host "✓ Azure sessions validated" -ForegroundColor Green
        return
    }

    # Connect to Azure PowerShell
    Write-Host "Connecting to Azure PowerShell..." -ForegroundColor Yellow

    $ConnectParams = @{}
    if ($TenantId) { $ConnectParams['TenantId'] = $TenantId }
    if ($SubscriptionId) { $ConnectParams['SubscriptionId'] = $SubscriptionId }

    try {
        Connect-AzAccount @ConnectParams -ErrorAction Stop | Out-Null
        Write-Host "✓ Connected to Azure PowerShell" -ForegroundColor Green

        # Display account info
        $Context = Get-AzContext
        Write-Host "  Account: $($Context.Account.Id)" -ForegroundColor Gray
        Write-Host "  Subscription: $($Context.Subscription.Name)" -ForegroundColor Gray
        Write-Host "  Tenant: $($Context.Tenant.Id)" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to connect to Azure PowerShell: $_"
        throw
    }

    # Connect to Microsoft Graph if required
    if ($RequireGraphAPI) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow

        try {
            Connect-MgGraph -Scopes $GraphScopes -ErrorAction Stop | Out-Null
            Write-Host "✓ Connected to Microsoft Graph" -ForegroundColor Green

            $GraphContext = Get-MgContext
            Write-Host "  Account: $($GraphContext.Account)" -ForegroundColor Gray
            Write-Host "  Scopes: $($GraphContext.Scopes -join ', ')" -ForegroundColor Gray
        }
        catch {
            Write-Error "Failed to connect to Microsoft Graph: $_"
            throw
        }
    }
}

# Use at the start of every script
function Initialize-AzureSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $false)]
        [switch]$RequireGraphAPI
    )

    if (-not (Test-AzureSession -RequiredSubscriptionId $SubscriptionId -RequireGraphAPI:$RequireGraphAPI)) {
        Connect-AzureWithValidation -SubscriptionId $SubscriptionId -RequireGraphAPI:$RequireGraphAPI
    }
}

# Example usage at script start:
# Initialize-AzureSession -RequireGraphAPI
```

### Complete Example: Multi-Subscription Resource Audit

```powershell
<#
.SYNOPSIS
    Audits resources across all subscriptions using Graph API.

.EXAMPLE
    .\Audit-AzureResources.ps1

    Audits all subscriptions.

.EXAMPLE
    .\Audit-AzureResources.ps1 -SubscriptionId "sub-123"

    Audits single subscription.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\azure-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.ResourceGraph

$ErrorActionPreference = "Stop"

# Validate session first
Initialize-AzureSession

# Get all subscriptions to audit
if ($SubscriptionId) {
    $Subscriptions = $SubscriptionId | ForEach-Object {
        Get-AzSubscription -SubscriptionId $_
    }
    Write-Host "Auditing $($Subscriptions.Count) specified subscription(s)" -ForegroundColor Cyan
}
else {
    $Subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }
    Write-Host "Auditing ALL $($Subscriptions.Count) enabled subscriptions" -ForegroundColor Cyan
}

# Use Resource Graph for efficient querying
$Query = @"
Resources
| extend
    hasName = isnotempty(name),
    hasLocation = isnotempty(location),
    hasEnvironmentTag = isnotempty(tags['Environment']),
    hasOwnerTag = isnotempty(tags['Owner']),
    hasCostCenterTag = isnotempty(tags['CostCenter'])
| project
    subscriptionId,
    resourceGroup,
    name,
    type,
    location,
    hasEnvironmentTag,
    hasOwnerTag,
    hasCostCenterTag,
    tags
| order by subscriptionId, resourceGroup, name
"@

Write-Host "Executing Resource Graph query..." -ForegroundColor Yellow

if ($SubscriptionId) {
    $Results = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 5000
}
else {
    $Results = Search-AzGraph -Query $Query -First 5000
}

# Handle pagination
$AllResults = [System.Collections.Generic.List[object]]::new()
$AllResults.AddRange($Results)

while ($Results.SkipToken) {
    Write-Verbose "Fetching next page..."
    if ($SubscriptionId) {
        $Results = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 5000 -SkipToken $Results.SkipToken
    }
    else {
        $Results = Search-AzGraph -Query $Query -First 5000 -SkipToken $Results.SkipToken
    }
    $AllResults.AddRange($Results)
}

Write-Host "✓ Retrieved $($AllResults.Count) resources" -ForegroundColor Green

# Analyze results
$Analysis = [PSCustomObject]@{
    TotalResources       = $AllResults.Count
    MissingEnvironmentTag = ($AllResults | Where-Object { -not $_.hasEnvironmentTag }).Count
    MissingOwnerTag      = ($AllResults | Where-Object { -not $_.hasOwnerTag }).Count
    MissingCostCenterTag = ($AllResults | Where-Object { -not $_.hasCostCenterTag }).Count
    SubscriptionsScanned = $Subscriptions.Count
}

# Export results
$AllResults | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "✓ Exported results to: $OutputPath" -ForegroundColor Green

# Display summary
Write-Host "`nAudit Summary:" -ForegroundColor Cyan
Write-Host "  Total Resources: $($Analysis.TotalResources)" -ForegroundColor White
Write-Host "  Missing Environment Tag: $($Analysis.MissingEnvironmentTag)" -ForegroundColor $(if ($Analysis.MissingEnvironmentTag -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Missing Owner Tag: $($Analysis.MissingOwnerTag)" -ForegroundColor $(if ($Analysis.MissingOwnerTag -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Missing CostCenter Tag: $($Analysis.MissingCostCenterTag)" -ForegroundColor $(if ($Analysis.MissingCostCenterTag -gt 0) { "Yellow" } else { "Green" })
```

## Editor Setup

For LazyVim (preferred) or VSCode configuration, see [EDITORS.md](./EDITORS.md).

## AI Assistant Guidelines

### When Reviewing Code

1. **Check PowerShell Version**
   - Verify scripts target PowerShell 7+ when possible
   - Check for Windows PowerShell 5.1 specific code
   - Ensure cross-platform compatibility is considered

2. **Check Best Practices**
   - Verify approved verbs are used
   - Check for proper parameter validation
   - Ensure error handling is comprehensive
   - Verify ShouldProcess is implemented for state-changing functions

3. **Check Azure Patterns**
   - **CRITICAL**: Verify multi-subscription operations are the default
   - **CRITICAL**: Check if Azure Resource Graph is used instead of loops
   - **CRITICAL**: Ensure session validation is performed at script start
   - Verify proper authentication methods
   - Check for retry logic on API calls
   - Ensure resource cleanup is implemented
   - Verify proper use of Az modules

4. **Check Code Quality**
   - Run PSScriptAnalyzer and fix issues
   - Verify comment-based help is complete
   - Check for proper logging
   - Ensure variables use proper naming

5. **Check Performance**
   - Verify no individual resource queries in loops
   - Check if batch operations are used
   - Ensure Resource Graph queries are optimized
   - Verify pagination is handled correctly

### When Writing Code

1. Always include comment-based help
2. Use approved verbs for function names
3. Implement proper parameter validation
4. Include error handling with try-catch
5. Use `$ErrorActionPreference = "Stop"` for robust error handling
6. Implement ShouldProcess for state-changing operations
7. Use `Write-Verbose` for detailed logging
8. Test with PSScriptAnalyzer
9. Write Pester tests for functions
10. Consider cross-platform compatibility
11. **ALWAYS validate Azure session at script start**
12. **DEFAULT to all subscriptions unless filtered**
13. **PREFER Azure Resource Graph over loops**

### When Writing Azure Scripts

1. **Multi-Subscription by Default**
   - Always assume ALL subscriptions unless explicitly filtered
   - Add `-SubscriptionId` parameter for filtering
   - Add `-ExcludeSubscriptionId` for exclusions

2. **Use Azure Resource Graph**
   - Never query resources individually in loops
   - Build efficient KQL queries
   - Handle pagination properly
   - Project only needed fields

3. **Session Validation**
   - Always check for valid Az context
   - Check for Microsoft Graph context if needed
   - Prompt for login if session invalid
   - Display connection info after login

4. **Efficiency Patterns**
   - Use `Search-AzGraph` instead of `Get-AzResource` loops
   - Use generic collections instead of arrays
   - Disable progress bars for performance
   - Use parallel processing for independent operations

### When Debugging

1. Use `Set-PSDebug -Trace 2` for detailed tracing
2. Check `$Error[0]` for last error details
3. Use `Get-Error` for detailed error information
4. Enable verbose output with `-Verbose`
5. Use breakpoints in Neovim with nvim-dap
6. Check Azure Activity Log for API issues
7. Verify authentication with `Get-AzContext` and `Get-MgContext`
8. Test Resource Graph queries in Azure Portal first

### Neovim-Specific Guidance

When providing code examples or debugging help:

- Assume user is working in Neovim, not VSCode
- Reference Neovim LSP features (`:LspInfo`, `:LspRestart`)
- Suggest nvim-dap for debugging, not VSCode debugger
- Reference Treesitter for syntax highlighting issues
- Suggest Telescope or fzf for file navigation
- Use terminal commands compatible with Neovim's terminal mode

Example debugging workflow for Neovim:

```vim
" Check LSP status
:LspInfo

" Format current file
:lua vim.lsp.buf.format()

" Run current PowerShell script
:!pwsh -File %

" Run with debugging
:lua require('dap').continue()
```

## Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Azure PowerShell Documentation](https://docs.microsoft.com/powershell/azure/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [Pester Testing Framework](https://pester.dev/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Az PowerShell Module](https://github.com/Azure/azure-powershell)
- [PowerShell Best Practices](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)

## Version History

- 1.0.0 - Initial version with comprehensive PowerShell development guidelines
