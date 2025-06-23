# Memory Defragmenter TODO & Future Enhancements

## Version 2.0 Features (Planned)

### Core Features
- [ ] Scheduled optimization - Allow users to set automatic optimization schedules (daily, weekly, monthly)
- [ ] Memory usage graphs over time - Track and visualize how memory usage changes
- [ ] Backup management UI - Interface to view, restore, and manage all backups
- [ ] Dark/Light mode toggle - Theme switcher respecting system settings

### Security Enhancements
- [ ] **Encrypted Memory Storage** 
  - Memory Service MCP stores everything in plain text (no encryption)
  - Add optional encryption layer for sensitive memories
  - Encrypt backups with password protection
  - Key management UI for encryption settings

### Advanced Features
- [ ] Memory search and filtering within the app
- [ ] Bulk operations (delete by date range, tags)
- [ ] Memory import from other formats
- [ ] Cloud backup integration (iCloud, Dropbox)
- [ ] Memory statistics dashboard
- [ ] Duplicate detection algorithms improvement
- [ ] Memory compression before optimization

### Technical Improvements
- [ ] Performance optimization for large databases (100k+ memories)
- [ ] Background operation support
- [ ] Memory preview before deletion
- [ ] Undo/Redo functionality
- [ ] Export to multiple formats (CSV, Markdown, HTML)

### Integration Features
- [ ] Direct integration with Memory Service MCP
- [ ] API for automation
- [ ] Command-line interface version
- [ ] Homebrew cask for GUI app distribution

## Known Issues to Address
- Memory Service MCP auto-backup feature not implemented (we worked around this)
- No encryption in Memory Service MCP (security concern)

## Notes
- Current backup automation uses cron + manual scripts
- All operations are read-only on source ChromaDB
- Version 1.0 focuses on core functionality and safety
