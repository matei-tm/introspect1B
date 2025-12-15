param(
  [string]$User = $env:SITE_USER,
  [string]$Pass = $env:SITE_PASSWORD,
  [switch]$Headed,
  [switch]$Trace,
  [switch]$ReinstallBrowsers
)

function Write-ErrorAndExit($msg) {
  Write-Error $msg
  exit 1
}

# Ensure Node is available
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-ErrorAndExit "Node.js not found. Install from https://nodejs.org/ and retry."
}

# Install npm packages
Write-Host "`nInstalling npm packages..."
if (Test-Path package-lock.json) {
  npm ci 2>&1 | Write-Host
} else {
  npm install 2>&1 | Write-Host
}

# Install or reinstall Playwright browsers if requested
if ($ReinstallBrowsers) {
  Write-Host "`nInstalling Playwright browsers (forced)..."
  npx playwright install --with-deps 2>&1 | Write-Host
} else {
  Write-Host "`nEnsuring Playwright browsers are installed..."
  npx playwright install 2>&1 | Write-Host
}

# Validate environment args (best-effort)
if (-not $User -or -not $Pass) {
  Write-Warning "SITE_USER or SITE_PASSWORD not provided. Test will attempt to run without login."
}

# Set env vars for the test run
if ($User) { $env:SITE_USER = $User }
if ($Pass) { $env:SITE_PASSWORD = $Pass }

# Build playwright run args
$pwArgs = @()
if ($Headed) { $env:PWDEBUG = '1' } else { $env:PWDEBUG = $null }
if ($Trace) { $pwArgs += '--trace=on' }

Write-Host "`nRunning Playwright tests..."
# Use npx to run playwright test, show list reporter by default for readable output
if ($pwArgs.Count -gt 0) {
  npx playwright test --reporter=list $pwArgs
} else {
  npx playwright test --reporter=list
}

$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
  Write-Host "`nPlaywright tests finished with exit code $exitCode."
  exit $exitCode
}

Write-Host "`nPlaywright tests completed successfully."