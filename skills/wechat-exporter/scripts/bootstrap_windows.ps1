#Requires -Version 5.1
<#
.SYNOPSIS
Detects and, with explicit consent, bootstraps the official WechatExporter client.

.DESCRIPTION
The default invocation is read-only. Use -Install only after the user confirms
the network download and interactive installer launch. The current official
installer is unsigned, so -AcceptUnsignedInstaller is also required until the
release manifest announces an Authenticode-signed build.
#>
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$DownloadOnly,
    [switch]$ConfigureProject,
    [switch]$Launch,
    [switch]$AcceptUnsignedInstaller,
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$CliPath = "",
    [string]$DownloadDirectory = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$script:ProductWebsite = "https://omniexporter.com"
$script:ManifestUrl = "https://omniexporter.com/api/downloads/windows/manifest"
$script:DownloadUrl = "https://omniexporter.com/api/downloads/windows?version=0.4.3"
$script:FallbackManifest = [pscustomobject][ordered]@{
    schemaVersion = 1
    channel = "stable"
    platform = "windows"
    architecture = "x64"
    version = "0.4.3"
    filename = "WechatExporter-0.4.3-Setup.exe"
    downloadUrl = $script:DownloadUrl
    size = 115114128
    sha256 = "3972E462DC5BB3FDDAEEA3DFB6B4DBE9C934F2283844CEA71AA9051890B995AD"
    signatureStatus = "unsigned"
}

function Write-ResultAndExit {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [int]$ExitCode = 0
    )
    $Result | ConvertTo-Json -Depth 8
    exit $ExitCode
}

function Get-ObjectProperty {
    param($InputObject, [string]$Name)
    if ($null -eq $InputObject) {
        return $null
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Normalize-ReleaseManifest {
    param([Parameter(Mandatory = $true)]$Manifest)

    $schemaVersion = Get-ObjectProperty $Manifest "schemaVersion"
    $channel = [string](Get-ObjectProperty $Manifest "channel")
    $platform = [string](Get-ObjectProperty $Manifest "platform")
    $architecture = [string](Get-ObjectProperty $Manifest "architecture")
    $version = [string](Get-ObjectProperty $Manifest "version")
    $filename = [string](Get-ObjectProperty $Manifest "filename")
    $downloadUrl = [string](Get-ObjectProperty $Manifest "downloadUrl")
    $rawSize = [string](Get-ObjectProperty $Manifest "size")
    $sha256 = ([string](Get-ObjectProperty $Manifest "sha256")).ToUpperInvariant()
    $signatureStatus = [string](Get-ObjectProperty $Manifest "signatureStatus")

    if ([int]$schemaVersion -ne 1 -or $channel -ne "stable") {
        throw "Unsupported Windows release manifest schema or channel."
    }
    if ($platform -ne "windows" -or $architecture -ne "x64") {
        throw "The release manifest does not describe Windows x64."
    }
    if ($version -notmatch '^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
        throw "The release manifest version is invalid."
    }
    if (
        $filename -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.exe$' -or
        [IO.Path]::GetFileName($filename) -ne $filename
    ) {
        throw "The release manifest filename is unsafe."
    }

    $uri = $null
    if (-not [Uri]::TryCreate($downloadUrl, [UriKind]::Absolute, [ref]$uri)) {
        throw "The release manifest download URL is invalid."
    }
    if (
        $uri.Scheme -ne "https" -or
        $uri.Host -ne "omniexporter.com" -or
        -not $uri.IsDefaultPort -or
        $uri.UserInfo -ne "" -or
        $uri.AbsolutePath -ne "/api/downloads/windows" -or
        $uri.Query -ne "?version=$([Uri]::EscapeDataString($version))" -or
        $uri.Fragment -ne ""
    ) {
        throw "The release manifest download URL is not the official endpoint."
    }

    $size = [Int64]0
    if (-not [Int64]::TryParse($rawSize, [ref]$size) -or $size -le 0) {
        throw "The release manifest size is invalid."
    }
    if ($sha256 -notmatch '^[A-F0-9]{64}$') {
        throw "The release manifest SHA-256 is invalid."
    }
    if ($signatureStatus -notin @("unsigned", "authenticode")) {
        throw "The release manifest signature status is invalid."
    }

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        channel = "stable"
        platform = "windows"
        architecture = "x64"
        version = $version
        filename = $filename
        downloadUrl = $downloadUrl
        size = $size
        sha256 = $sha256
        signatureStatus = $signatureStatus
    }
}

function Get-ReleaseManifest {
    $payload = $null
    $fetched = $false
    $previousProtocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            $payload = Invoke-RestMethod `
                -Uri $script:ManifestUrl `
                -Method Get `
                -TimeoutSec 20 `
                -MaximumRedirection 0 `
                -UseBasicParsing
            $fetched = $true
        }
        catch {
            $fetched = $false
        }
    }
    finally {
        [Net.ServicePointManager]::SecurityProtocol = $previousProtocol
    }

    if (-not $fetched) {
        return [pscustomobject]@{
            manifest = Normalize-ReleaseManifest $script:FallbackManifest
            source = "embedded-official-fallback"
        }
    }

    $manifest = Get-ObjectProperty $payload "data"
    if ($null -eq $manifest) {
        $manifest = $payload
    }
    return [pscustomobject]@{
        manifest = Normalize-ReleaseManifest $manifest
        source = "official-manifest"
    }
}

function Get-ProjectConfigPath {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $null
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    return Join-Path (Join-Path $resolvedRoot ".wechat-exporter") "client.local.json"
}

function Find-WechatExporterClient {
    param([string]$ExplicitCliPath, [string]$Root)

    $candidates = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    function Add-Candidate {
        param([string]$CandidateCli, [string]$Source)
        if ([string]::IsNullOrWhiteSpace($CandidateCli)) {
            return
        }
        try {
            $fullCli = [IO.Path]::GetFullPath($CandidateCli)
        }
        catch {
            return
        }
        $key = $fullCli.ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            return
        }
        $seen[$key] = $true
        $gui = Join-Path ([IO.Path]::GetDirectoryName($fullCli)) "WechatExporter.exe"
        if (
            (Test-Path -LiteralPath $fullCli -PathType Leaf) -and
            (Test-Path -LiteralPath $gui -PathType Leaf)
        ) {
            $candidates.Add([pscustomobject]@{
                cliPath = $fullCli
                guiPath = [IO.Path]::GetFullPath($gui)
                source = $Source
            }) | Out-Null
        }
    }

    Add-Candidate $ExplicitCliPath "explicit"

    $projectConfig = Get-ProjectConfigPath $Root
    if ($null -ne $projectConfig -and (Test-Path -LiteralPath $projectConfig -PathType Leaf)) {
        try {
            $saved = Get-Content -Raw -LiteralPath $projectConfig -Encoding UTF8 | ConvertFrom-Json
            Add-Candidate ([string](Get-ObjectProperty $saved "cliPath")) "project-config"
        }
        catch {
            # A malformed local hint must not trigger an unbounded recovery scan.
        }
    }

    try {
        $embeddedRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.."))
        Add-Candidate (Join-Path $embeddedRoot "WechatExporterCLI.exe") "bundled-skill"
    }
    catch {
    }

    $pathCommand = Get-Command "WechatExporterCLI.exe" -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $pathCommand) {
        Add-Candidate $pathCommand.Source "path"
    }

    $uninstallRoots = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($uninstallRoot in $uninstallRoots) {
        try {
            $entries = Get-ItemProperty -Path $uninstallRoot -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "WechatExporter*" }
            foreach ($entry in $entries) {
                $installLocation = [string]$entry.InstallLocation
                if (-not [string]::IsNullOrWhiteSpace($installLocation)) {
                    Add-Candidate (Join-Path $installLocation "WechatExporterCLI.exe") "registry"
                    continue
                }
                $uninstallString = [string]$entry.UninstallString
                if ($uninstallString -match '^"([^"]+)"') {
                    $installLocation = [IO.Path]::GetDirectoryName($matches[1])
                    Add-Candidate (Join-Path $installLocation "WechatExporterCLI.exe") "registry"
                }
            }
        }
        catch {
        }
    }

    $commonRoots = @(
        [Environment]::GetFolderPath("LocalApplicationData"),
        [Environment]::GetFolderPath("ProgramFiles"),
        [Environment]::GetFolderPath("ProgramFilesX86")
    )
    foreach ($commonRoot in $commonRoots) {
        if (-not [string]::IsNullOrWhiteSpace($commonRoot)) {
            Add-Candidate (Join-Path (Join-Path $commonRoot "Programs\WechatExporter") "WechatExporterCLI.exe") "standard-location"
            Add-Candidate (Join-Path (Join-Path $commonRoot "WechatExporter") "WechatExporterCLI.exe") "standard-location"
        }
    }

    if ($candidates.Count -eq 0) {
        return $null
    }
    return $candidates[0]
}

function Get-ClientVersion {
    param([string]$ClientCliPath)
    try {
        $output = & $ClientCliPath --version 2>$null | Out-String
        return $output.Trim()
    }
    catch {
        return $null
    }
}

function Get-LicenseSummary {
    param([string]$ClientCliPath)
    try {
        $raw = & $ClientCliPath license status --json-output 2>$null | Out-String
        $status = $raw | ConvertFrom-Json
        return [pscustomobject][ordered]@{
            state = Get-ObjectProperty $status "state"
            valid = [bool](Get-ObjectProperty $status "valid")
            edition = Get-ObjectProperty $status "edition"
            message = Get-ObjectProperty $status "message"
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            state = "unknown"
            valid = $false
            edition = $null
            message = "Run the desktop client to check product authorization."
        }
    }
}

function Assert-InstallerSignature {
    param([string]$InstallerPath, [string]$ExpectedStatus)
    $signature = Get-AuthenticodeSignature -LiteralPath $InstallerPath
    if ($ExpectedStatus -eq "authenticode") {
        if ($signature.Status -ne "Valid") {
            throw "The installer does not have the valid Authenticode signature required by the manifest."
        }
        return
    }
    if ($signature.Status -ne "NotSigned") {
        throw "The installer signature state does not match the unsigned release manifest."
    }
}

function Get-VerifiedInstaller {
    param($Manifest, [string]$TargetDirectory)

    if ([string]::IsNullOrWhiteSpace($TargetDirectory)) {
        $localData = [Environment]::GetFolderPath("LocalApplicationData")
        if ([string]::IsNullOrWhiteSpace($localData)) {
            $localData = [IO.Path]::GetTempPath()
        }
        $TargetDirectory = Join-Path $localData "OmniExporter\WechatExporter\downloads"
    }
    $targetDirectoryFull = [IO.Path]::GetFullPath($TargetDirectory)
    New-Item -ItemType Directory -Force -Path $targetDirectoryFull | Out-Null
    $installerPath = Join-Path $targetDirectoryFull $Manifest.filename

    $existingIsValid = $false
    if (Test-Path -LiteralPath $installerPath -PathType Leaf) {
        $existing = Get-Item -LiteralPath $installerPath
        if ($existing.Length -eq $Manifest.size) {
            $existingHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToUpperInvariant()
            $existingIsValid = $existingHash -eq $Manifest.sha256
        }
    }

    if (-not $existingIsValid) {
        $temporaryPath = "$installerPath.part.$([Guid]::NewGuid().ToString('N'))"
        $previousProtocol = [Net.ServicePointManager]::SecurityProtocol
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest `
                -Uri $Manifest.downloadUrl `
                -Method Get `
                -OutFile $temporaryPath `
                -TimeoutSec 900 `
                -MaximumRedirection 0 `
                -UseBasicParsing
            $downloaded = Get-Item -LiteralPath $temporaryPath
            if ($downloaded.Length -ne $Manifest.size) {
                throw "The downloaded installer size does not match the official manifest."
            }
            $downloadedHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash.ToUpperInvariant()
            if ($downloadedHash -ne $Manifest.sha256) {
                throw "The downloaded installer SHA-256 does not match the official manifest."
            }
            Assert-InstallerSignature $temporaryPath $Manifest.signatureStatus
            Move-Item -LiteralPath $temporaryPath -Destination $installerPath -Force
        }
        finally {
            [Net.ServicePointManager]::SecurityProtocol = $previousProtocol
            if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
                Remove-Item -LiteralPath $temporaryPath -Force
            }
        }
    }
    else {
        Assert-InstallerSignature $installerPath $Manifest.signatureStatus
    }
    return [IO.Path]::GetFullPath($installerPath)
}

function Write-ProjectConfiguration {
    param($Client, [string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "ProjectRoot must be an existing directory."
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    $configDirectory = Join-Path $resolvedRoot ".wechat-exporter"
    $configPath = Join-Path $configDirectory "client.local.json"
    New-Item -ItemType Directory -Force -Path $configDirectory | Out-Null

    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        try {
            $existing = Get-Content -Raw -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            throw "Refusing to overwrite an unreadable project client configuration."
        }
        if ((Get-ObjectProperty $existing "generatedBy") -ne "wechat-exporter-skill") {
            throw "Refusing to overwrite a project client configuration not generated by this Skill."
        }
    }

    $configuration = [ordered]@{
        schemaVersion = 1
        generatedBy = "wechat-exporter-skill"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        cliPath = $Client.cliPath
        guiPath = $Client.guiPath
        mcp = [ordered]@{
            transport = "stdio"
            command = $Client.cliPath
            args = @("mcp")
        }
        website = [ordered]@{
            home = $script:ProductWebsite
            download = "$($script:ProductWebsite)/downloads"
            signUp = "$($script:ProductWebsite)/sign-up"
            signIn = "$($script:ProductWebsite)/sign-in"
            pricing = "$($script:ProductWebsite)/pricing"
        }
    }
    $json = $configuration | ConvertTo-Json -Depth 6
    $temporaryPath = "$configPath.tmp.$([Guid]::NewGuid().ToString('N'))"
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    try {
        [IO.File]::WriteAllText($temporaryPath, $json + [Environment]::NewLine, $utf8WithoutBom)
        Move-Item -LiteralPath $temporaryPath -Destination $configPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    return [IO.Path]::GetFullPath($configPath)
}

function New-BootstrapResult {
    param(
        [string]$Status,
        $Client = $null,
        $License = $null,
        [string]$ProjectConfigPath = "",
        $Installer = $null,
        [string[]]$NextActions = @()
    )
    $mcp = $null
    if ($null -ne $Client) {
        $mcp = [ordered]@{
            transport = "stdio"
            command = $Client.cliPath
            args = @("mcp")
        }
    }
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        status = $Status
        installed = $null -ne $Client
        source = if ($null -ne $Client) { $Client.source } else { $null }
        version = if ($null -ne $Client) { Get-ClientVersion $Client.cliPath } else { $null }
        cliPath = if ($null -ne $Client) { $Client.cliPath } else { $null }
        guiPath = if ($null -ne $Client) { $Client.guiPath } else { $null }
        license = $License
        projectConfigPath = if ($ProjectConfigPath) { $ProjectConfigPath } else { $null }
        projectConfigNote = if ($ProjectConfigPath) { "This file contains machine-local absolute paths; do not commit it unless that is intentional." } else { $null }
        installer = $Installer
        mcp = $mcp
        website = [ordered]@{
            home = $script:ProductWebsite
            download = "$($script:ProductWebsite)/downloads"
            signUp = "$($script:ProductWebsite)/sign-up"
            signIn = "$($script:ProductWebsite)/sign-in"
            pricing = "$($script:ProductWebsite)/pricing"
        }
        trialPolicy = [ordered]@{
            durationDays = 7
            accountRequired = $true
            oneTrialPerHardware = $true
        }
        nextActions = $NextActions
    }
}

function Invoke-WechatExporterBootstrap {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        Write-ResultAndExit (New-BootstrapResult -Status "unsupported_platform" -NextActions @("Use a Windows x64 machine for the WechatExporter desktop client.")) 11
    }
    if ($Install -and $DownloadOnly) {
        throw "Choose either -Install or -DownloadOnly, not both."
    }

    $client = Find-WechatExporterClient $CliPath $ProjectRoot
    $installerResult = $null

    if ($null -eq $client -and ($Install -or $DownloadOnly)) {
        $release = Get-ReleaseManifest
        $manifest = $release.manifest
        if ($manifest.signatureStatus -eq "unsigned" -and -not $AcceptUnsignedInstaller) {
            $consentResult = [ordered]@{
                manifestSource = $release.source
                version = $manifest.version
                filename = $manifest.filename
                size = $manifest.size
                sha256 = $manifest.sha256
                signatureStatus = $manifest.signatureStatus
            }
            Write-ResultAndExit (New-BootstrapResult -Status "unsigned_consent_required" -Installer $consentResult -NextActions @("Explain that the official installer is currently unsigned, then rerun with -Install -AcceptUnsignedInstaller only after the user explicitly accepts the risk.")) 12
        }

        $installerPath = Get-VerifiedInstaller $manifest $DownloadDirectory
        $installerResult = [ordered]@{
            manifestSource = $release.source
            version = $manifest.version
            path = $installerPath
            size = $manifest.size
            sha256 = $manifest.sha256
            signatureStatus = $manifest.signatureStatus
        }
        if ($DownloadOnly) {
            Write-ResultAndExit (New-BootstrapResult -Status "downloaded" -Installer $installerResult -NextActions @("Run the verified installer interactively after the user confirms.")) 0
        }

        $process = Start-Process -FilePath $installerPath -PassThru -Wait
        if ($process.ExitCode -ne 0) {
            throw "The interactive installer exited with code $($process.ExitCode)."
        }
        $client = Find-WechatExporterClient $CliPath $ProjectRoot
        if ($null -eq $client) {
            Write-ResultAndExit (New-BootstrapResult -Status "installation_not_detected" -Installer $installerResult -NextActions @("Open WechatExporter from the Start menu, or provide the full WechatExporterCLI.exe path.")) 15
        }
    }

    if ($null -eq $client) {
        Write-ResultAndExit (New-BootstrapResult -Status "not_installed" -NextActions @("Ask for permission to download and run the official interactive installer, then rerun with -Install. If the user accepts the current unsigned-package risk, also pass -AcceptUnsignedInstaller.")) 10
    }

    $projectConfigPath = ""
    if ($ConfigureProject) {
        $projectConfigPath = Write-ProjectConfiguration $client $ProjectRoot
    }

    $license = Get-LicenseSummary $client.cliPath
    if ($Launch) {
        Start-Process -FilePath $client.guiPath | Out-Null
    }

    $status = "ready"
    $nextActions = @("Use the configured MCP command for bounded, local workflows.")
    if (-not $license.valid) {
        $status = "authorization_required"
        $nextActions = @(
            "Launch the desktop client and choose Activate with account.",
            "Register or sign in on the official website.",
            "After sign-in, choose the one-account, one-device 7-day trial or purchase a plan, then return to the client."
        )
    }
    elseif ($Launch) {
        $nextActions = @("Complete WeChat account initialization in the desktop client if no local account is ready.")
    }

    Write-ResultAndExit (New-BootstrapResult -Status $status -Client $client -License $license -ProjectConfigPath $projectConfigPath -Installer $installerResult -NextActions $nextActions) 0
}

if ($MyInvocation.InvocationName -ne ".") {
    try {
        Invoke-WechatExporterBootstrap
    }
    catch {
        Write-ResultAndExit (New-BootstrapResult -Status "error" -NextActions @($_.Exception.Message)) 1
    }
}
