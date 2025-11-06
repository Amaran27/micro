# MCP Integration - User Interface Guide

## 🎨 What Was Built - Visual Overview

### 1. Settings Page Integration

**Navigation Path**: Settings → MCP Servers

```
┌──────────────────────────────────────┐
│  Settings                         ✕  │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 🤖 AI Providers            →   │ │
│  │ Manage AI model providers      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 📡 MCP Servers             →   │ ← NEW!
│  │ Manage Model Context Protocol  │ │
│  │ server connections             │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ⚙️ General                  →   │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

### 2. MCP Server Settings Page

**Main interface for managing MCP servers**

#### Empty State (No Servers Configured)
```
┌──────────────────────────────────────┐
│  MCP Servers    🔍 Discover  🔄  ✕  │
├──────────────────────────────────────┤
│                                      │
│          📡 (large icon)             │
│                                      │
│      No MCP Servers Configured       │
│                                      │
│   Add MCP servers to extend your AI  │
│   assistant with additional tools    │
│   and capabilities                   │
│                                      │
│   [🔍 Discover Servers] (button)     │
│                                      │
│                                   ➕  │
│                            Add Server │
└──────────────────────────────────────┘
```

#### Server List View (With Configured Servers)
```
┌──────────────────────────────────────┐
│  MCP Servers    🔍 Discover  🔄  ✕  │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 🟢 Filesystem Server       🔗 ⋮ │ ← Click to expand
│  │ Access local files & dirs      │ │
│  │ [Connected] [STDIO] [3 tools]  │ │
│  │ ▼                              │ │
│  │ ┌──────────────────────────┐   │ │
│  │ │ Transport:    STDIO       │   │ │
│  │ │ Command:      npx         │   │ │
│  │ │ Arguments:    -y @model...│   │ │
│  │ │ Last Active:  2m ago      │   │ │
│  │ │ Tool Calls:   5           │   │ │
│  │ │                           │   │ │
│  │ │ Available Tools:          │   │ │
│  │ │ [read_file] [write_file]  │   │ │
│  │ │ [list_dir]                │   │ │
│  │ └──────────────────────────┘   │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ 🔴 GitHub Server           🔄 ⋮ │ ← Error state
│  │ GitHub API integration         │ │
│  │ [Error] [HTTP]                 │ │
│  │ Error: Connection refused      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ⚪ Brave Search             🔗 ⋮ │ ← Disconnected
│  │ Web search capability          │ │
│  │ [Disconnected] [HTTP]          │ │
│  └────────────────────────────────┘ │
│                                   ➕  │
│                            Add Server │
└──────────────────────────────────────┘
```

**Status Indicators**:
- 🟢 Green (Connected) - Server online, ready to use
- 🟠 Orange (Connecting) - Connection in progress
- 🔴 Red (Error) - Connection failed
- ⚪ Grey (Disconnected) - Not connected

**Actions**:
- 🔗 Connect button
- 🔗❌ Disconnect button
- 🔄 Retry button (on error)
- ⋮ Menu: Edit | Test Connection | Delete

---

### 3. Add/Edit Server Dialog

#### Add New Server Form
```
┌──────────────────────────────────────┐
│  Add MCP Server                   ✕  │
├──────────────────────────────────────┤
│  Basic Information                   │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Server Name *                  │ │
│  │ e.g., My Filesystem Server     │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Description                    │ │
│  │ What does this server do?      │ │
│  └────────────────────────────────┘ │
│                                      │
│  Transport Type                      │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ [HTTP     ▼]                   │ │
│  └────────────────────────────────┘ │
│                                      │
│  HTTP/SSE Configuration              │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Server URL *                   │ │
│  │ e.g., http://localhost:8000/mcp│ │
│  └────────────────────────────────┘ │
│                                      │
│  Examples:                           │
│  ┌────────────────────────────────┐ │
│  │ GitHub                         │ │
│  │ http://localhost:3000/mcp      │ │
│  │ Add Authorization header...    │ │
│  └────────────────────────────────┘ │
│                                      │
│  Options                             │
│  ☑ Auto-connect on startup           │
│                                      │
│              [Cancel]  [Add]         │
└──────────────────────────────────────┘
```

#### stdio Transport Form (Desktop Only)
```
┌──────────────────────────────────────┐
│  Add MCP Server                   ✕  │
├──────────────────────────────────────┤
│  Transport Type                      │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ [STDIO    ▼]                   │ │
│  └────────────────────────────────┘ │
│                                      │
│  Stdio Configuration                 │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Command *                      │ │
│  │ e.g., npx, python, node        │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Arguments                      │ │
│  │ e.g., -y @model.../filesystem  │ │
│  └────────────────────────────────┘ │
│                                      │
│  Examples:                           │
│  ┌────────────────────────────────┐ │
│  │ Filesystem                     │ │
│  │ npx -y @model.../filesystem    │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │ Git                            │ │
│  │ npx -y @model.../server-git    │ │
│  └────────────────────────────────┘ │
│                                      │
│              [Cancel]  [Add]         │
└──────────────────────────────────────┘
```

#### Platform Warning (Mobile + stdio)
```
┌──────────────────────────────────────┐
│  Transport Type                      │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ [STDIO    ▼]                   │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ⚠️ stdio transport is not      │ │
│  │    supported on mobile.        │ │
│  │    Please use HTTP or SSE.     │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

### 4. MCP Server Discovery Page

**Browse and install recommended servers**

```
┌──────────────────────────────────────┐
│  Discover MCP Servers              ✕ │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │ 🔍 Search servers...           │  │
│  └────────────────────────────────┘  │
│                                      │
│  [All] [Desktop] [Mobile]  9 servers │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────┐  ┌──────────┐  ┌────┐ │
│  │ 📁       │  │ 🐙       │  │ 🔍 │ │
│  │Filesystem│  │  GitHub  │  │Brave│ │
│  │[Desktop] │  │[Both]    │  │[Both│ │
│  │[STDIO]   │  │[HTTP]    │  │HTTP]│ │
│  │          │  │          │  │     │ │
│  │Access    │  │Interact  │  │Search│
│  │local     │  │with      │  │the  │ │
│  │files and │  │GitHub    │  │web  │ │
│  │dirs      │  │repos     │  │     │ │
│  │          │  │          │  │     │ │
│  │[?] [Install]│[?] [Install]│[?][Install]│
│  └──────────┘  └──────────┘  └────┘ │
│                                      │
│  ┌──────────┐  ┌──────────┐  ┌────┐ │
│  │ 🐘       │  │ 💬       │  │ 📊 │ │
│  │PostgreSQL│  │  Slack   │  │Drive│ │
│  │[Desktop] │  │[Both]    │  │[Both│ │
│  │[STDIO]   │  │[HTTP]    │  │HTTP]│ │
│  │          │  │          │  │     │ │
│  │Connect   │  │Send msgs │  │Google│
│  │to        │  │and read  │  │Drive│ │
│  │databases │  │channels  │  │files│ │
│  │          │  │          │  │     │ │
│  │[?] [Install]│[?] [Install]│[?][Install]│
│  └──────────┘  └──────────┘  └────┘ │
│                                      │
│  (more servers...)                   │
└──────────────────────────────────────┘
```

**Card Details**:
- Large emoji icon
- Server name
- Platform badges (Desktop/Mobile)
- Transport type badge (STDIO/HTTP/SSE)
- Description (truncated)
- "?" Documentation button
- "Install"/"Configure" button
- Disabled "Install" if incompatible platform

**Search & Filters**:
- Live search by name/description
- Platform chips: All | Desktop | Mobile
- Server count display
- Empty state for no results

---

### 5. Installation Flows

#### stdio Server Installation Dialog
```
┌──────────────────────────────────────┐
│  Install Filesystem Server         ✕ │
├──────────────────────────────────────┤
│  This server requires installation   │
│  via command line:                   │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ npx -y @modelcontextprotocol/  │ │
│  │ server-filesystem               │ │
│  └────────────────────────────────┘ │
│                                      │
│  After installation, configure with: │
│                                      │
│  Command: npx                        │
│  Args: -y @model.../filesystem /path │
│                                      │
│              [Close] [Configure Now] │
└──────────────────────────────────────┘
```

#### HTTP Server Installation Dialog
```
┌──────────────────────────────────────┐
│  Install GitHub Server             ✕ │
├──────────────────────────────────────┤
│  Interact with GitHub repositories,  │
│  issues, and pull requests.          │
│                                      │
│  Server URL:                         │
│  http://localhost:3000/mcp           │
│                                      │
│  Note: Make sure the server is       │
│  running before connecting.          │
│                                      │
│                   [Cancel] [Configure]│
└──────────────────────────────────────┘
```

---

## 🎨 Color Scheme

### Status Colors
- **Connected**: Green (#4CAF50)
  - Includes glow effect for visual emphasis
- **Connecting**: Orange (#FF9800)
- **Error**: Red (#F44336)
- **Disconnected**: Grey (#9E9E9E)

### Badges
- **Status Badge**: Colored background with 10% opacity
- **Transport Badge**: Blue (#2196F3) background
- **Tool Count Badge**: Purple (#9C27B0) background
- **Platform Badge**: Grey with platform icon

### UI Elements
- **Cards**: Elevated with shadow
- **ExpansionTile**: Expandable server details
- **FloatingActionButton**: Primary color with extended label
- **Chips**: Compact with visual density
- **SnackBars**: Success (green), Error (red), Info (default)

---

## 🔄 User Flows

### Flow 1: Add Server from Discovery
1. Settings → MCP Servers
2. Click "Discover Servers" (or empty state button)
3. Browse recommended servers
4. Click "Install" on desired server
5. View installation instructions (stdio) or server info (HTTP)
6. Click "Configure Now" or "Configure"
7. Form pre-filled with recommended defaults
8. Modify as needed (URL, auth headers, etc.)
9. Click "Add"
10. Server appears in list with "Disconnected" status
11. Click Connect button
12. Status changes to "Connecting" → "Connected"
13. Expand card to see available tools

### Flow 2: Add Server Manually
1. Settings → MCP Servers
2. Click FAB "Add Server"
3. Fill form:
   - Name, description
   - Choose transport type
   - Enter URL or Command/Args
   - Toggle auto-connect
4. Click "Add"
5. Server added to list

### Flow 3: Edit Existing Server
1. Settings → MCP Servers → Server card
2. Click ⋮ menu → "Edit"
3. Modify fields in dialog
4. Click "Update"
5. If connected, auto-disconnects
6. Can reconnect with new config

### Flow 4: Test Connection
1. Settings → MCP Servers → Server card
2. Click ⋮ menu → "Test Connection"
3. Loading dialog: "Testing connection..."
4. Success: Green snackbar "Connection test successful!"
5. Failure: Red snackbar "Connection test failed"

### Flow 5: Delete Server
1. Settings → MCP Servers → Server card
2. Click ⋮ menu → "Delete"
3. Confirmation dialog: "Are you sure?"
4. Click "Delete" (red button)
5. Server removed from list
6. Snackbar: "Server deleted"

---

## 📱 Responsive Design

### Mobile (< 600px width)
- Grid: 1 column for discovery page
- Cards: Full width
- Dialog: Full screen on small devices
- FAB: Bottom right corner

### Tablet (600-1200px)
- Grid: 2 columns for discovery page
- Cards: Balanced width
- Dialog: Modal overlay

### Desktop (> 1200px)
- Grid: 3 columns for discovery page
- Cards: Max 400px width
- Dialog: Centered modal
- stdio transport enabled

---

## 🎯 Key Features Implemented

✅ Server CRUD operations (Create, Read, Update, Delete)  
✅ Real-time status tracking  
✅ Platform-aware configuration  
✅ Server discovery with 9 pre-configured servers  
✅ Connection management (connect/disconnect/test)  
✅ Validation (URL, command, platform)  
✅ Persistent storage (encrypted)  
✅ Error handling with user feedback  
✅ Loading states for async operations  
✅ Empty states with helpful CTAs  
✅ Search and filtering  
✅ Documentation links  
✅ Installation instructions  
✅ Material Design 3 patterns  

---

## 🚀 What's Next

Phase 2 will integrate MCP servers with AI providers, allowing tool execution through configured MCP servers. See `MCP_IMPLEMENTATION_STATUS.md` for detailed roadmap.
