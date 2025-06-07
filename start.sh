#!/bin/bash

# Change to the directory where this script is located (root repo)
cd "$(dirname "$0")" || { echo "❌ Failed to change directory!"; exit 1; }

# Stash local changes before pulling
echo "🔄 Stashing local changes..."
git stash --include-untracked

# Pull the latest changes from the remote repository
echo "⬇️ Pulling latest changes from remote..."
git pull origin main --rebase
if [ $? -ne 0 ]; then
  echo "❌ Git pull failed!"
  exit 1
fi

# Sync submodules
echo "🔄 Syncing submodules..."
git submodule sync --recursive
git submodule update --init --recursive

# Ensure submodules are up to date
echo "⬇️ Updating submodules..."
git submodule foreach git pull origin main

# Restore stashed changes if any
echo "🔄 Restoring local changes..."
git stash pop || echo "⚠️ No stashed changes to apply."

# Done
echo "✅ Repository and submodules updated successfully!"

# Check for .env file
check_env_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "❌ .env file not found at $path!"
    echo "Please create a .env file or copy from .env.example:"
    echo "  cp $path.example $path"
    return 1
  else
    echo "✅ .env file found at $path."
    return 0
  fi
}

# Check for .env file
missing_env=0

check_env_file "./web/.env" || missing_env=1

# If any .env file is missing, exit with code 1
if [ $missing_env -eq 1 ]; then
  echo "❌ .env file is missing. Please fix it and re-run this script."
  exit 1
else
  echo "✔️ .env file found. Merging..."
  rm ./.env
  cat ./web/.env > ./.env
fi

# Ensure Node.js is installed
echo "Checking if Node.js is installed..."
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found!"
  echo "Please make sure Node.js is properly installed."
  exit 1
else
  echo "✔️ Node.js is installed."
  echo "Installing dependencies..."
  cd ./web
  npm install
fi

# Ensure Docker Compose is installed
echo "Checking if Docker Compose is installed..."
if ! command -v docker compose &> /dev/null; then
  echo "❌ Docker Compose not found!"
  echo "Please make sure Docker Compose is properly installed."
  exit 1
else
  echo "✔️ Docker Compose is installed."
fi

# Run Database Migrations
echo "Running database migrations..."
node ace migration:run
if [ $? -ne 0 ]; then
  echo "❌ An error occurred while running database migrations."
  exit 1
else
  echo "✔️ Migration step completed."
fi
cd ./..

# Ask if the user wants to rebuild the image
echo "Do you want to rebuild the image? (y/n)"
read -r REBUILD
docker compose down

if [[ "$REBUILD" == "y" || "$REBUILD" == "Y" ]]; then
  echo "🔄 Rebuilding the image before starting Docker Compose..."
  docker compose down --rmi local
  DOCKER_BUILDKIT=0 docker compose --env-file ./.env up --build -d
else
  echo "🚀 Starting containers without rebuilding..."
  DOCKER_BUILDKIT=0 docker compose --env-file ./.env up -d
fi

if [ $? -ne 0 ]; then
  echo "❌ An error occurred while running Docker Compose."
  exit 1
else
  echo "✔️ Docker Compose started successfully."
fi
