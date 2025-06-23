#!/bin/bash

# Quick setup script for backup automation

echo "Setting up Memory Service backup automation..."
echo "============================================="

# Make scripts executable
chmod +x scripts/backup_memory_service_enhanced.sh
chmod +x scripts/check_backup_health.sh
echo "✓ Scripts made executable"

# Test the backup
echo ""
echo "Testing backup script..."
./scripts/backup_memory_service_enhanced.sh

# Check health
echo ""
echo "Checking backup health..."
./scripts/check_backup_health.sh

echo ""
echo "Setup complete!"
echo ""
echo "To add automatic monthly backups, copy and run this command:"
echo ""
echo "(crontab -l 2>/dev/null; echo '0 2 1 * * cd \"/Users/rogers/GitHub/Memory Defragmenter\" && ./scripts/backup_memory_service_enhanced.sh') | crontab -"
echo ""
echo "Or for weekly backups:"
echo "(crontab -l 2>/dev/null; echo '0 2 * * 0 cd \"/Users/rogers/GitHub/Memory Defragmenter\" && ./scripts/backup_memory_service_enhanced.sh') | crontab -"
