# v2node Build Script for All Platforms (PowerShell)
# This script builds v2node for all supported platforms and architectures

param(
    [string]$Version = ""
)

# Get version
if ([string]::IsNullOrEmpty($Version)) {
    try {
        $Version = git rev-parse --short HEAD 2>$null
    } catch {
        $Version = "dev"
    }
}

Write-Host "Building v2node version: $Version" -ForegroundColor Green

# Build output directory
$BuildDir = "builds"
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Path $BuildDir | Out-Null

# Function to build for a specific platform
function Build-Platform {
    param(
        [string]$GOOS,
        [string]$GOARCH,
        [string]$GOARM,
        [string]$GOMIPS,
        [string]$Name
    )
    
    Write-Host "Building for $Name..." -ForegroundColor Yellow
    
    # Create temporary build directory
    $TempDir = "build_assets_$Name"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    # Set environment variables
    $env:GOOS = $GOOS
    $env:GOARCH = $GOARCH
    $env:GOARM = $GOARM
    $env:GOMIPS = $GOMIPS
    $env:CGO_ENABLED = "0"
    $env:GOEXPERIMENT = "jsonv2"
    
    # Build command
    $OutputName = "v2node"
    if ($GOOS -eq "windows") {
        $OutputName = "v2node.exe"
    }
    
    $LDFlags = "-X 'github.com/wyx2685/v2node/cmd.version=$Version' -s -w -buildid="
    
    try {
        & go build -v -o "$TempDir\$OutputName" -trimpath -ldflags $LDFlags 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            # Copy additional files
            if (Test-Path "README.md") { Copy-Item "README.md" "$TempDir\" }
            if (Test-Path "LICENSE") { Copy-Item "LICENSE" "$TempDir\" }
            
            # Create ZIP archive
            $ZipPath = "$BuildDir\v2node-$Name.zip"
            Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal -Force
            
            # Generate checksums
            $DgstPath = "$BuildDir\v2node-$Name.zip.dgst"
            
            $md5 = (Get-FileHash -Path $ZipPath -Algorithm MD5).Hash
            $sha1 = (Get-FileHash -Path $ZipPath -Algorithm SHA1).Hash
            $sha256 = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
            $sha512 = (Get-FileHash -Path $ZipPath -Algorithm SHA512).Hash
            
            "MD5 = $md5" | Out-File -FilePath $DgstPath -Encoding UTF8
            "SHA1 = $sha1" | Add-Content -Path $DgstPath -Encoding UTF8
            "SHA256 = $sha256" | Add-Content -Path $DgstPath -Encoding UTF8
            "SHA512 = $sha512" | Add-Content -Path $DgstPath -Encoding UTF8
            
            # Cleanup temp directory
            Remove-Item -Recurse -Force $TempDir
            
            Write-Host "[OK] Built $Name" -ForegroundColor Green
        } else {
            throw "Build failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "[FAIL] Failed to build $Name : $_" -ForegroundColor Red
        if (Test-Path $TempDir) {
            Remove-Item -Recurse -Force $TempDir
        }
    }
}

Write-Host ""
Write-Host "Starting builds..." -ForegroundColor Green
Write-Host ""

# Download dependencies
Write-Host "Downloading dependencies..." -ForegroundColor Yellow
go mod download

# Windows builds
Build-Platform -GOOS "windows" -GOARCH "386" -GOARM "" -GOMIPS "" -Name "windows-32"
Build-Platform -GOOS "windows" -GOARCH "amd64" -GOARM "" -GOMIPS "" -Name "windows-64"

# Linux AMD64/386 builds
Build-Platform -GOOS "linux" -GOARCH "386" -GOARM "" -GOMIPS "" -Name "linux-32"
Build-Platform -GOOS "linux" -GOARCH "amd64" -GOARM "" -GOMIPS "" -Name "linux-64"

# Linux ARM builds
Build-Platform -GOOS "linux" -GOARCH "arm" -GOARM "5" -GOMIPS "" -Name "linux-arm32-v5"
Build-Platform -GOOS "linux" -GOARCH "arm" -GOARM "6" -GOMIPS "" -Name "linux-arm32-v6"
Build-Platform -GOOS "linux" -GOARCH "arm" -GOARM "7" -GOMIPS "" -Name "linux-arm32-v7a"
Build-Platform -GOOS "linux" -GOARCH "arm64" -GOARM "" -GOMIPS "" -Name "linux-arm64-v8a"

# Linux MIPS builds
Build-Platform -GOOS "linux" -GOARCH "mips" -GOARM "" -GOMIPS "" -Name "linux-mips32"
Build-Platform -GOOS "linux" -GOARCH "mipsle" -GOARM "" -GOMIPS "" -Name "linux-mips32le"
Build-Platform -GOOS "linux" -GOARCH "mips64" -GOARM "" -GOMIPS "" -Name "linux-mips64"
Build-Platform -GOOS "linux" -GOARCH "mips64le" -GOARM "" -GOMIPS "" -Name "linux-mips64le"

# Linux other architectures
Build-Platform -GOOS "linux" -GOARCH "ppc64" -GOARM "" -GOMIPS "" -Name "linux-ppc64"
Build-Platform -GOOS "linux" -GOARCH "ppc64le" -GOARM "" -GOMIPS "" -Name "linux-ppc64le"
Build-Platform -GOOS "linux" -GOARCH "riscv64" -GOARM "" -GOMIPS "" -Name "linux-riscv64"
Build-Platform -GOOS "linux" -GOARCH "s390x" -GOARM "" -GOMIPS "" -Name "linux-s390x"

# FreeBSD builds
Build-Platform -GOOS "freebsd" -GOARCH "386" -GOARM "" -GOMIPS "" -Name "freebsd-32"
Build-Platform -GOOS "freebsd" -GOARCH "amd64" -GOARM "" -GOMIPS "" -Name "freebsd-64"
Build-Platform -GOOS "freebsd" -GOARCH "arm" -GOARM "7" -GOMIPS "" -Name "freebsd-arm32-v7a"
Build-Platform -GOOS "freebsd" -GOARCH "arm64" -GOARM "" -GOMIPS "" -Name "freebsd-arm64-v8a"

# macOS builds
Build-Platform -GOOS "darwin" -GOARCH "amd64" -GOARM "" -GOMIPS "" -Name "macos-64"
Build-Platform -GOOS "darwin" -GOARCH "arm64" -GOARM "" -GOMIPS "" -Name "macos-arm64-v8a"

# Android builds
Build-Platform -GOOS "android" -GOARCH "arm64" -GOARM "" -GOMIPS "" -Name "android-arm64-v8a"

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "All builds completed!" -ForegroundColor Green
Write-Host "Build artifacts are in: $BuildDir\" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# List all created files
Write-Host "Created files:" -ForegroundColor Yellow
Get-ChildItem -Path $BuildDir | Format-Table Name, @{Label="Size";Expression={"{0:N2} MB" -f ($_.Length / 1MB)}}, LastWriteTime
