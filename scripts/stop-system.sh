#!/bin/bash

echo "🛑 Resetting Multi-Agent Observability System"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Function to kill processes on a port
kill_port() {
    local port=$1
    local name=$2
    
    echo -e "\n${YELLOW}Checking for $name on port $port...${NC}"
    
    # Find PIDs using the port
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        PIDS=$(lsof -ti :$port 2>/dev/null)
    else
        # Linux
        PIDS=$(lsof -ti :$port 2>/dev/null || fuser -n tcp $port 2>/dev/null | awk '{print $2}')
    fi
    
    if [ -n "$PIDS" ]; then
        echo -e "${RED}Found processes on port $port: $PIDS${NC}"
        for PID in $PIDS; do
            kill -9 $PID 2>/dev/null && echo -e "${GREEN}✅ Killed process $PID${NC}" || echo -e "${RED}❌ Failed to kill process $PID${NC}"
        done
    else
        echo -e "${GREEN}✅ No processes found on port $port${NC}"
    fi
}

# Kill server processes (port 4000)
kill_port 4000 "server"

# Kill client dev server (port 5173)
kill_port 5173 "client"

# Kill any remaining bun processes related to our apps
echo -e "\n${YELLOW}Checking for remaining bun processes...${NC}"
ps aux | grep -E "bun.*(apps/(server|client))" | grep -v grep | awk '{print $2}' | while read PID; do
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null && echo -e "${GREEN}✅ Killed bun process $PID${NC}"
    fi
done

# Optional: Clear SQLite WAL files
echo -e "\n${YELLOW}Cleaning up SQLite WAL files...${NC}"
if [ -f "$PROJECT_ROOT/apps/server/events.db-wal" ]; then
    rm -f "$PROJECT_ROOT/apps/server/events.db-wal" "$PROJECT_ROOT/apps/server/events.db-shm"
    echo -e "${GREEN}✅ Removed SQLite WAL files${NC}"
else
    echo -e "${GREEN}✅ No WAL files to clean${NC}"
fi

# Optional: Ask if user wants to clear the database
# echo -e "\n${YELLOW}Database Management${NC}"
# if [ -f "$PROJECT_ROOT/apps/server/events.db" ]; then
#     echo -n "Do you want to clear the event database? (y/N): "
#     read -r response
#     if [[ "$response" =~ ^[Yy]$ ]]; then
#         rm -f "$PROJECT_ROOT/apps/server/events.db"
#         echo -e "${GREEN}✅ Database cleared${NC}"
#     else
#         echo -e "${GREEN}✅ Database preserved${NC}"
#     fi
# else
#     echo -e "${GREEN}✅ No database found${NC}"
# fi

echo -e "\n${GREEN}🎉 System reset complete!${NC}"
echo -e "\nTo start fresh:"
echo "1. Run ./scripts/start-system.sh to start both server and client"
echo "2. Or manually: cd apps/server && bun run dev"
echo "3. And: cd apps/client && bun run dev"