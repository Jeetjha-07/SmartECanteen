#!/bin/bash
# Razorpay Setup Validation Script
# This script validates your Razorpay configuration

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Razorpay Configuration Validation Script            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env exists
if [ ! -f "backend/.env" ]; then
    echo "❌ ERROR: backend/.env file not found!"
    exit 1
fi

echo "📋 Reading credentials from backend/.env..."
echo ""

# Extract credentials
KEY_ID=$(grep "^RAZORPAY_KEY_ID=" backend/.env | cut -d'=' -f2 | xargs)
KEY_SECRET=$(grep "^RAZORPAY_KEY_SECRET=" backend/.env | cut -d'=' -f2 | xargs)

# Get character counts
KEY_ID_LEN=${#KEY_ID}
KEY_SECRET_LEN=${#KEY_SECRET}

echo "🔐 RAZORPAY CREDENTIALS VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate KEY_ID
echo "Key ID:"
if [ -z "$KEY_ID" ]; then
    echo "  ❌ MISSING - Not found in .env"
elif [ "$KEY_ID" = "rzp_test_YOUR_TEST_KEY" ]; then
    echo "  ❌ PLACEHOLDER - Still using default value"
    echo "     Current: $KEY_ID"
elif [[ "$KEY_ID" == rzp_test_* ]]; then
    echo "  ✅ VALID FORMAT - Appears to be a test key"
    echo "     Value: ${KEY_ID:0:15}...${KEY_ID: -5}"
    echo "     Length: $KEY_ID_LEN characters"
elif [[ "$KEY_ID" == rzp_live_* ]]; then
    echo "  ⚠️  LIVE KEY - You're using a PRODUCTION key"
    echo "     Value: ${KEY_ID:0:15}...${KEY_ID: -5}"
    echo "     Length: $KEY_ID_LEN characters"
else
    echo "  ❌ INVALID FORMAT - Should start with 'rzp_test_' or 'rzp_live_'"
    echo "     Current: $KEY_ID"
fi
echo ""

# Validate KEY_SECRET
echo "Key Secret:"
if [ -z "$KEY_SECRET" ]; then
    echo "  ❌ MISSING - Not found in .env"
elif [ "$KEY_SECRET" = "YOUR_KEY_SECRET" ]; then
    echo "  ❌ PLACEHOLDER - Still using default value"
    echo "     Current: $KEY_SECRET"
elif [ $KEY_SECRET_LEN -lt 30 ]; then
    echo "  ❌ TOO SHORT - Expected 40+ characters, got $KEY_SECRET_LEN"
    echo "     Current: ${KEY_SECRET:0:10}...${KEY_SECRET: -5}"
    echo "     This is usually invalid - check Razorpay dashboard"
elif [ $KEY_SECRET_LEN -gt 50 ]; then
    echo "  ⚠️  VERY LONG - Seems unusual but may be valid"
    echo "     Value: ${KEY_SECRET:0:15}...${KEY_SECRET: -5}"
    echo "     Length: $KEY_SECRET_LEN characters"
else
    echo "  ✅ VALID LENGTH - Appears to be correct"
    echo "     Value: ${KEY_SECRET:0:15}...${KEY_SECRET: -5}"
    echo "     Length: $KEY_SECRET_LEN characters"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Final verdict
VALID=true

if [ -z "$KEY_ID" ] || [ "$KEY_ID" = "rzp_test_YOUR_TEST_KEY" ]; then
    VALID=false
fi

if [ -z "$KEY_SECRET" ] || [ "$KEY_SECRET" = "YOUR_KEY_SECRET" ] || [ $KEY_SECRET_LEN -lt 30 ]; then
    VALID=false
fi

if [ "$VALID" = true ]; then
    echo "✅ CONFIGURATION APPEARS VALID"
    echo ""
    echo "Next steps:"
    echo "  1. Restart backend: pm2 restart smartcanteen-backend"
    echo "  2. Run the app and test a payment"
    echo "  3. Check logs for success messages"
else
    echo "❌ CONFIGURATION IS INVALID"
    echo ""
    echo "Fix required:"
    echo "  1. Visit https://dashboard.razorpay.com/app/keys"
    echo "  2. Copy the Key ID and Key Secret (test mode)"
    echo "  3. Update backend/.env with actual credentials"
    echo "  4. Restart backend: pm2 restart smartcanteen-backend"
    echo "  5. Run this script again to verify"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
