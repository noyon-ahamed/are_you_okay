#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Are You Okay Backend Setup${NC}\n"

# Check if MongoDB is running
echo -e "${YELLOW}Checking MongoDB...${NC}"
if pgrep -x "mongod" > /dev/null; then
    echo -e "${GREEN}✅ MongoDB is running${NC}"
else
    echo -e "${YELLOW}Starting MongoDB...${NC}"
    brew services start mongodb-community@7.0
    sleep 3
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
    echo -e "${RED}⚠️  Please edit .env and set JWT_SECRET${NC}"
else
    echo -e "${GREEN}✅ .env file exists${NC}"
fi

# Check if node_modules exists
if [ ! -d node_modules ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
else
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

echo -e "\n${GREEN}✅ Setup complete! Starting server...${NC}\n"
npm run dev
