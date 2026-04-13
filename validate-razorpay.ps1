# Razorpay Setup Validation Script (PowerShell)
# Run: .\validate-razorpay.ps1

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Razorpay Configuration Validation Script            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path "backend\.env")) {
    Write-Host "❌ ERROR: backend\.env file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Reading credentials from backend\.env..." -ForegroundColor Yellow
Write-Host ""

# Read .env file
$envFile = Get-Content "backend\.env" -Raw

# Extract credentials using regex
$keyIdMatch = [regex]::Match($envFile, 'RAZORPAY_KEY_ID=(.*)(\r?\n|$)')
$keySecretMatch = [regex]::Match($envFile, 'RAZORPAY_KEY_SECRET=(.*)(\r?\n|$)')

$KEY_ID = $keyIdMatch.Groups[1].Value.Trim()
$KEY_SECRET = $keySecretMatch.Groups[1].Value.Trim()

$KEY_ID_LEN = $KEY_ID.Length
$KEY_SECRET_LEN = $KEY_SECRET.Length

Write-Host "🔐 RAZORPAY CREDENTIALS VALIDATION" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Validate KEY_ID
Write-Host "Key ID:" -ForegroundColor White
if ([string]::IsNullOrEmpty($KEY_ID)) {
    Write-Host "  ❌ MISSING - Not found in .env" -ForegroundColor Red
} elseif ($KEY_ID -eq "rzp_test_YOUR_TEST_KEY") {
    Write-Host "  ❌ PLACEHOLDER - Still using default value" -ForegroundColor Red
    Write-Host "     Current: $KEY_ID" -ForegroundColor Red
} elseif ($KEY_ID -match '^rzp_test_') {
    Write-Host "  ✅ VALID FORMAT - Appears to be a test key" -ForegroundColor Green
    $shortId = $KEY_ID.Substring(0, 15) + "..." + $KEY_ID.Substring($KEY_ID.Length - 5)
    Write-Host "     Value: $shortId" -ForegroundColor Green
    Write-Host "     Length: $KEY_ID_LEN characters" -ForegroundColor Green
} elseif ($KEY_ID -match '^rzp_live_') {
    Write-Host "  ⚠️  LIVE KEY - You're using a PRODUCTION key" -ForegroundColor Yellow
    $shortId = $KEY_ID.Substring(0, 15) + "..." + $KEY_ID.Substring($KEY_ID.Length - 5)
    Write-Host "     Value: $shortId" -ForegroundColor Yellow
    Write-Host "     Length: $KEY_ID_LEN characters" -ForegroundColor Yellow
} else {
    Write-Host "  ❌ INVALID FORMAT - Should start with 'rzp_test_' or 'rzp_live_'" -ForegroundColor Red
    Write-Host "     Current: $KEY_ID" -ForegroundColor Red
}
Write-Host ""

# Validate KEY_SECRET
Write-Host "Key Secret:" -ForegroundColor White
if ([string]::IsNullOrEmpty($KEY_SECRET)) {
    Write-Host "  ❌ MISSING - Not found in .env" -ForegroundColor Red
} elseif ($KEY_SECRET -eq "YOUR_KEY_SECRET") {
    Write-Host "  ❌ PLACEHOLDER - Still using default value" -ForegroundColor Red
    Write-Host "     Current: $KEY_SECRET" -ForegroundColor Red
} elseif ($KEY_SECRET_LEN -lt 30) {
    Write-Host "  ❌ TOO SHORT - Expected 40+ characters, got $KEY_SECRET_LEN" -ForegroundColor Red
    $shortSecret = $KEY_SECRET.Substring(0, [Math]::Min(10, $KEY_SECRET_LEN)) + "..." + $KEY_SECRET.Substring([Math]::Max(0, $KEY_SECRET_LEN - 5))
    Write-Host "     Current: $shortSecret" -ForegroundColor Red
    Write-Host "     This is usually invalid - check Razorpay dashboard" -ForegroundColor Red
} elseif ($KEY_SECRET_LEN -gt 50) {
    Write-Host "  ⚠️  VERY LONG - Seems unusual but may be valid" -ForegroundColor Yellow
    $shortSecret = $KEY_SECRET.Substring(0, 15) + "..." + $KEY_SECRET.Substring([Math]::Max(0, $KEY_SECRET_LEN - 5))
    Write-Host "     Value: $shortSecret" -ForegroundColor Yellow
    Write-Host "     Length: $KEY_SECRET_LEN characters" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ VALID LENGTH - Appears to be correct" -ForegroundColor Green
    $shortSecret = $KEY_SECRET.Substring(0, 15) + "..." + $KEY_SECRET.Substring([Math]::Max(0, $KEY_SECRET_LEN - 5))
    Write-Host "     Value: $shortSecret" -ForegroundColor Green
    Write-Host "     Length: $KEY_SECRET_LEN characters" -ForegroundColor Green
}
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Final verdict
$VALID = $true

if ([string]::IsNullOrEmpty($KEY_ID) -or $KEY_ID -eq "rzp_test_YOUR_TEST_KEY") {
    $VALID = $false
}

if ([string]::IsNullOrEmpty($KEY_SECRET) -or $KEY_SECRET -eq "YOUR_KEY_SECRET" -or $KEY_SECRET_LEN -lt 30) {
    $VALID = $false
}

if ($VALID) {
    Write-Host "✅ CONFIGURATION APPEARS VALID" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart backend: pm2 restart smartcanteen-backend" -ForegroundColor White
    Write-Host "  2. Run the app and test a payment" -ForegroundColor White
    Write-Host "  3. Check logs for success messages" -ForegroundColor White
} else {
    Write-Host "❌ CONFIGURATION IS INVALID" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix required:" -ForegroundColor Cyan
    Write-Host "  1. Visit https://dashboard.razorpay.com/app/keys" -ForegroundColor White
    Write-Host "  2. Copy the Key ID and Key Secret (test mode)" -ForegroundColor White
    Write-Host "  3. Update backend\.env with actual credentials" -ForegroundColor White
    Write-Host "  4. Restart backend: pm2 restart smartcanteen-backend" -ForegroundColor White
    Write-Host "  5. Run this script again to verify" -ForegroundColor White
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
