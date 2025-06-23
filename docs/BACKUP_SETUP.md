# Memory Service Backup - Cron Setup Guide

## Quick Setup (for Warp Terminal)

Add this line to your crontab to run backups on the 1st of every month at 2 AM:

```bash
0 2 1 * * cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh
```

## Detailed Setup Instructions

### 1. Make scripts executable
```bash
cd "/Users/rogers/GitHub/Memory Defragmenter"
chmod +x scripts/backup_memory_service_enhanced.sh
chmod +x scripts/check_backup_health.sh
```

### 2. Test the enhanced backup script
```bash
./scripts/backup_memory_service_enhanced.sh
```

### 3. Check backup health
```bash
./scripts/check_backup_health.sh
```

### 4. Set up cron job
```bash
# Open crontab editor
crontab -e

# Add one of these lines (choose your preferred schedule):

# Monthly - 1st of month at 2 AM
0 2 1 * * cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh

# Weekly - Every Sunday at 2 AM
0 2 * * 0 cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh

# Daily - Every day at 2 AM (if you have lots of memory activity)
0 2 * * * cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh

# Bi-weekly - 1st and 15th of month at 2 AM
0 2 1,15 * * cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh
```

### 5. Verify cron job
```bash
# List current cron jobs
crontab -l

# Check backup health anytime
./scripts/check_backup_health.sh
```

## What the Enhanced Script Does

1. **Comprehensive Logging**
   - Logs to `/logs/backup.log` with timestamps
   - Separate error log at `/logs/backup_errors.log`
   - JSON summary at `/logs/backup_summary.json`

2. **Pre-backup Checks**
   - Verifies ChromaDB directory exists
   - Records database size and memory count
   - Checks if Memory Service is running

3. **Backup Process**
   - Activates Memory Service virtual environment
   - Runs the official backup script
   - Tracks duration and exit status

4. **Post-backup Actions**
   - Verifies backup file was created
   - Records backup metadata
   - Cleans up old backups (keeps last 12)

5. **Health Monitoring**
   - Creates JSON summary for easy monitoring
   - Provides backup age warnings
   - Lists recent backups

## Monitoring

Run the health check script anytime:
```bash
./scripts/check_backup_health.sh
```

Check logs:
```bash
# View recent backup logs
tail -50 logs/backup.log

# Check for errors
cat logs/backup_errors.log

# View backup summary
cat logs/backup_summary.json
```

## Notifications (Optional)

To get email notifications on backup failure, add this to your crontab:
```bash
MAILTO=your-email@example.com
0 2 1 * * cd "/Users/rogers/GitHub/Memory Defragmenter" && ./scripts/backup_memory_service_enhanced.sh || echo "Memory Service backup failed"
```

## Troubleshooting

If backups fail:
1. Check logs: `tail -50 logs/backup.log`
2. Verify paths exist: `./scripts/check_backup_health.sh`
3. Test manually: `./scripts/backup_memory_service_enhanced.sh`
4. Ensure Memory Service is properly installed
5. Check virtual environment: `cd /Users/rogers/GitHub/mcp-memory-service && source venv/bin/activate`
