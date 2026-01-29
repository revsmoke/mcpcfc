# MCPCFC v2.0 Purge Plan

This document inventories obsolete files that can be removed following the v2.0 refactor for MCP Protocol 2025-11-25 and ColdFusion 2025 compatibility.

## Summary

| Category | File Count | Total Size |
|----------|------------|------------|
| Deprecated (in `_deprecated/`) | 10 files | ~56KB |
| Development Utilities | 5 files | ~12KB |
| Stale Files | 2 files | ~14KB |

---

## Already Deprecated (`_deprecated/` directory)

These files have been moved to `_deprecated/` and have working replacements.

### Components (24KB)

| File | Size | Replaced By | Notes |
|------|------|-------------|-------|
| `_deprecated/components/JSONRPCProcessor.cfc` | 6.4KB | `core/JSONRPCHandler.cfc` | Protocol handling refactored |
| `_deprecated/components/SessionManager.cfc` | 1.8KB | `session/SessionManager.cfc` | Enhanced session management |
| `_deprecated/components/ToolHandler.cfc` | 4.4KB | Individual tool classes in `tools/` | Monolithic handler split into tools |
| `_deprecated/components/ToolRegistry.cfc` | 0.8KB | `registry/ToolRegistry.cfc` | Registry pattern refactored |

### Endpoints (8KB)

| File | Size | Replaced By | Notes |
|------|------|-------------|-------|
| `_deprecated/endpoints/messages.cfm` | 2.3KB | `endpoints/mcp.cfm` | Unified HTTP endpoint |
| `_deprecated/endpoints/sse.cfm` | 2.3KB | `endpoints/mcp.cfm` | SSE deprecated in MCP 2025-11-25 |

### Bridge Scripts (8KB)

| File | Size | Replaced By | Notes |
|------|------|-------------|-------|
| `_deprecated/cf-mcp-simple-bridge.sh` | 0.7KB | `bridge/cf-mcp-bridge.sh` | Consolidated bridge |
| `_deprecated/cf-mcp-clean-bridge.sh` | 1.5KB | `bridge/cf-mcp-bridge.sh` | Consolidated bridge |
| `_deprecated/cf-mcp-bridge-fixed.sh` | 2.3KB | `bridge/cf-mcp-bridge.sh` | Consolidated bridge |

### Tools (8KB)

| File | Size | Replaced By | Notes |
|------|------|-------------|-------|
| `_deprecated/EmailTool.cfc` | 6.6KB | `tools/SendGridEmailTool.cfc` | Renamed and enhanced |

### Documentation

| File | Size | Status |
|------|------|--------|
| `_deprecated/README.md` | 1.2KB | Keep - documents deprecation reasons |

---

## Development Utilities (Optional Removal)

These files serve development/testing purposes and may be removed after their purpose is served.

| File | Size | Purpose | Recommendation |
|------|------|---------|----------------|
| `database-setup.cfm` | 5.1KB | One-time DB schema setup | Remove after DB configured |
| `restart-app.cfm` | 0.2KB | Dev/admin utility | Keep for dev convenience |
| `view-pdf.cfm` | 1.8KB | PDF testing utility | Remove after testing complete |
| `cleanup-obsolete-tests.sh` | 2.1KB | Cleanup script | Remove - purpose served |
| `playwright-test.js` | 2.6KB | Old endpoint tests | Update or remove - tests deprecated endpoints |

---

## Stale Files

| File | Size | Issue | Action |
|------|------|-------|--------|
| `CLAUDE.previous.md` | 13.2KB | Superseded backup of CLAUDE.md | Archive or remove |
| `cleanup-log-20250527-165842.txt` | 0.3KB | Historical cleanup log | Remove |

---

## Removal Commands

### Safe Removal (Already Deprecated)

```bash
# Remove entire _deprecated directory (keeps README for reference)
rm -rf _deprecated/components/
rm -rf _deprecated/endpoints/
rm _deprecated/cf-mcp-*.sh
rm _deprecated/EmailTool.cfc

# Or remove entire directory if no longer needed
rm -rf _deprecated/
```

### Development Utilities

```bash
# Remove after DB is configured
rm database-setup.cfm

# Remove testing utilities
rm view-pdf.cfm
rm cleanup-obsolete-tests.sh

# Remove or update Playwright tests
rm playwright-test.js playwright.config.js package.json package-lock.json
```

### Stale Files

```bash
rm CLAUDE.previous.md
rm cleanup-log-20250527-165842.txt
```

---

## Post-Cleanup Verification

After removal, verify:

1. Application starts without errors
2. All tools respond correctly via `endpoints/mcp.cfm`
3. Bridge script works: `echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-11-05"},"id":1}' | ./bridge/cf-mcp-bridge.sh`
4. No broken imports or references in remaining code

---

## Files to Keep

The following files in root that might look removable should be **kept**:

| File | Reason |
|------|--------|
| `box.json` | CommandBox package configuration |
| `CNAME` | GitHub Pages domain configuration |
| `LICENSE` | MIT license - required |
| `components/` directory | May contain active components - verify before removal |

---

## v2.0 Architecture Reference

Current production structure after cleanup:

```
/mcpcfc.local/
├── Application.cfc
├── config/
│   ├── settings.cfm
│   └── routes.cfm
├── core/
│   ├── MCPServer.cfc
│   ├── JSONRPCHandler.cfc
│   ├── CapabilityManager.cfc
│   └── TransportManager.cfc
├── registry/
│   ├── ToolRegistry.cfc
│   ├── ResourceRegistry.cfc
│   └── PromptRegistry.cfc
├── session/
│   ├── SessionManager.cfc
│   └── SessionCleanup.cfc
├── tools/
│   ├── AbstractTool.cfc
│   ├── HelloTool.cfc
│   ├── PDFTool.cfc
│   ├── SendGridEmailTool.cfc
│   ├── DatabaseTool.cfc
│   ├── FileTool.cfc
│   └── HttpClientTool.cfc
├── validators/
│   ├── InputValidator.cfc
│   └── SQLValidator.cfc
├── logging/
│   └── Logger.cfc
├── endpoints/
│   └── mcp.cfm
└── bridge/
    └── cf-mcp-bridge.sh
```

---

*Generated: 2025-01-28*
*Protocol Version: 2025-11-25*
*ColdFusion Version: 2025*
