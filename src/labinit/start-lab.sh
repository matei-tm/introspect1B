#!/bin/bash
# Lab Initialization Script for Bash/Linux/macOS
# Reproduces the same steps a student would perform manually

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse arguments
HEADED=false
TRACE=false
REINSTALL_BROWSERS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --headed)
      HEADED=true
      shift
      ;;
    --trace)
      TRACE=true
      shift
      ;;
    --reinstall-browsers)
      REINSTALL_BROWSERS=true
      shift
      ;;
    --user)
      SITE_USER="$2"
      shift 2
      ;;
    --password)
      SITE_PASSWORD="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --user <username>        Set SITE_USER (overrides environment variable)"
      echo "  --password <password>    Set SITE_PASSWORD (overrides environment variable)"
      echo "  --headed                 Run tests in headed mode (visible browser)"
      echo "  --trace                  Enable trace recording"
      echo "  --reinstall-browsers     Force reinstall of Playwright browsers"
      echo "  -h, --help               Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  SITE_USER                Username for lab login"
      echo "  SITE_PASSWORD            Password for lab login"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Ensure Node.js is available
if ! command -v node &> /dev/null; then
  echo -e "${RED}Error: Node.js not found${NC}"
  echo "Install Node.js from https://nodejs.org/ and retry."
  exit 1
fi

echo -e "${YELLOW}Node.js version: $(node --version)${NC}"

# Install npm packages
echo -e "\n${YELLOW}Installing npm packages...${NC}"
if [ -f "package-lock.json" ]; then
  npm ci
else
  npm install
fi

# Install or reinstall Playwright browsers
if [ "$REINSTALL_BROWSERS" = true ]; then
  echo -e "\n${YELLOW}Installing Playwright browsers (forced)...${NC}"
  npx playwright install --with-deps
else
  echo -e "\n${YELLOW}Ensuring Playwright browsers are installed...${NC}"
  npx playwright install
fi

# Validate environment variables
if [ -z "$SITE_USER" ] || [ -z "$SITE_PASSWORD" ]; then
  echo -e "${YELLOW}Warning: SITE_USER or SITE_PASSWORD not provided.${NC}"
  echo -e "${YELLOW}Test will attempt to run without login.${NC}"
fi

# Export environment variables for Playwright
export SITE_USER
export SITE_PASSWORD

# Build Playwright arguments
PLAYWRIGHT_ARGS=()

if [ "$HEADED" = true ]; then
  export PWDEBUG=1
  echo -e "${YELLOW}Running in headed mode (PWDEBUG=1)${NC}"
fi

if [ "$TRACE" = true ]; then
  PLAYWRIGHT_ARGS+=(--trace=on)
  echo -e "${YELLOW}Trace recording enabled${NC}"
fi

# Run Playwright tests
echo -e "\n${GREEN}Running Playwright tests...${NC}"
if [ ${#PLAYWRIGHT_ARGS[@]} -gt 0 ]; then
  npx playwright test --reporter=list "${PLAYWRIGHT_ARGS[@]}"
else
  npx playwright test --reporter=list
fi

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo -e "\n${RED}Playwright tests finished with exit code $EXIT_CODE${NC}"
  exit $EXIT_CODE
fi

echo -e "\n${GREEN}✅ Playwright tests completed successfully${NC}"
