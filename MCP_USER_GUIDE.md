# MCP Integration - User Guide

## What is MCP?

**Model Context Protocol (MCP)** is a protocol that allows AI assistants to access external tools and services. Think of it as a way to give your AI assistant "superpowers" - the ability to read files, search the web, access GitHub, and much more.

### Why Use MCP?

- 🔧 **Extend Capabilities**: Add tools beyond what's built into the AI
- 🔌 **Modular Design**: Enable/disable tools as needed
- 🔒 **Controlled Access**: You decide which tools the AI can use
- 🚀 **Growing Ecosystem**: New MCP servers are being created constantly

---

## Quick Start Guide

### 1. Configure MCP Servers

#### Step 1: Open MCP Settings
1. Navigate to **Settings → MCP Servers**
2. You'll see an empty list if no servers are configured

#### Step 2: Discover Servers
1. Click **"Discover Servers"** or the 🔍 icon in the top bar
2. Browse the list of recommended MCP servers:
   - **Filesystem** (Desktop only) - Read/write local files
   - **GitHub** - GitHub API integration
   - **Brave Search** - Web search
   - **PostgreSQL** (Desktop only) - Database access
   - **Slack** - Slack integration
   - **Google Drive** - Access Google Docs/Sheets
   - **Git** (Desktop only) - Git operations
   - **Memory** - Persistent memory across conversations
   - **Custom Server** - Connect your own MCP server

#### Step 3: Install a Server
1. Click **"Install"** on a server
2. For **stdio servers** (Desktop only):
   - You'll see installation instructions
   - Run the command in your terminal (e.g., `npx -y @modelcontextprotocol/server-filesystem`)
   - Click **"Configure Now"**
3. For **HTTP/SSE servers**:
   - Check that the server is running
   - Click **"Configure"**

#### Step 4: Configure Server Details
1. Fill in the server information:
   - **Name**: Give it a memorable name
   - **Description**: Optional description
   - **Transport Type**: stdio/HTTP/SSE (pre-selected)
   - **Connection Details**:
     - For stdio: Command and arguments
     - For HTTP/SSE: Server URL
2. Toggle **"Auto-connect on startup"** if desired
3. Click **"Add"**

#### Step 5: Connect the Server
1. Find your server in the list
2. Click the 🔗 **Connect** button
3. Wait for status to change from ⚪ Disconnected to 🟢 Connected
4. Expand the card to see available tools

---

### 2. Enable MCP for AI Providers

#### Step 1: Edit Provider Settings
1. Navigate to **Settings → AI Providers**
2. Click **Edit** on any provider (e.g., OpenAI, Anthropic)

#### Step 2: Navigate to MCP Step
1. Go through the configuration wizard
2. Reach **Step 5: MCP Integration (Optional)**

#### Step 3: Enable MCP
1. Toggle **"Enable MCP Integration"** ON
2. Select which MCP servers this provider can use:
   - ☑ Filesystem Server [Connected] [3 tools]
   - ☑ GitHub Server [Connected] [12 tools]
   - ☐ Brave Search [Disconnected]

#### Step 4: Save Configuration
1. Click **"Update"** or **"Finish"**
2. Provider card now shows blue **"MCP Integration"** badge
3. Lists configured MCP servers

---

### 3. Create Agents with MCP Tools

#### Step 1: Open Agent Dashboard
1. Navigate to **Agent Dashboard**
2. Click **"Create Agent"** button

#### Step 2: Configure Basic Settings
1. Choose **Agent Type** (Research, Analysis, Planning, etc.)
2. Set **Name** and other basic settings
3. Toggle **"Show Advanced Settings"**

#### Step 3: Enable MCP for Agent
1. Scroll to **"MCP Integration"** section
2. Toggle **"Enable MCP Tools"** ON
3. Select which MCP servers the agent can use
4. See real-time connection status and tool counts

#### Step 4: Create Agent
1. Click **"Create Agent"**
2. Agent now has access to MCP tools
3. Can use these tools during execution

---

### 4. Monitor MCP Activity

#### Dashboard Overview
1. Navigate to **Agent Dashboard**
2. Click **"MCP"** tab (4th tab with 📡 icon)

#### Three Main Sections:

##### A. Connected Servers
- Lists all configured MCP servers
- Real-time connection status
- Tool count per server
- Click **▼** to expand and see:
  - Transport type
  - URL or command
  - Last connected/activity time
  - Tool call count
  - Available tools list
- **Disconnect** button for active servers
- **Manage** button to go to settings

##### B. Recent Activity
- Log of tool executions
- Each entry shows:
  - Tool name and duration (e.g., "read_file - 125ms")
  - Server name
  - Timestamp (e.g., "5m ago")
  - Status icon (✓ success, ✗ failed, ⟳ running)
- Click **▼** to expand and see:
  - Parameters sent to tool
  - Result returned
  - Error message (if failed)
  - Copy-to-clipboard buttons

##### C. Statistics
- **Total Tool Calls**: Count of all executions
- **Success Rate**: Percentage successful
- **Avg Duration**: Average execution time
- **Active Servers**: Currently connected servers

---

## Platform Differences

### Desktop (Windows/Mac/Linux)
✅ **Full Support**
- All transport types: stdio, HTTP, SSE
- Can run local MCP servers (stdio)
- Can install npm packages
- Full filesystem access

**Best For:**
- Development and testing
- Local file operations
- Running multiple MCP servers
- Git operations

### Mobile (Android/iOS)
⚠️ **Limited Support**
- HTTP and SSE transport only (no stdio)
- Cannot run local processes
- Network-based MCP servers only

**Best For:**
- Cloud-based MCP services
- GitHub/API integrations
- Web search tools
- Remote databases

---

## Common Use Cases

### 1. Code Assistant with File Access
**Setup:**
1. Configure **Filesystem MCP server** (Desktop)
2. Create **"Coder" agent** with filesystem access
3. Enable MCP for your preferred AI provider

**Use:**
- "Read the contents of app.py and suggest improvements"
- "Create a new file called test.py with unit tests"
- "Search for all TODO comments in the project"

### 2. Research Assistant with Web Search
**Setup:**
1. Configure **Brave Search MCP server**
2. Create **"Researcher" agent** with search access
3. Enable MCP for provider

**Use:**
- "Search for the latest Flutter best practices"
- "Find articles about MCP protocol"
- "What are the top 5 AI tools released this month?"

### 3. GitHub Integration
**Setup:**
1. Configure **GitHub MCP server** with auth token
2. Create **"DevOps" agent** with GitHub access
3. Enable MCP for provider

**Use:**
- "List all open issues in my repository"
- "Create a new branch called feature/mcp-integration"
- "Show recent commits on the main branch"

### 4. Multi-Tool Agent
**Setup:**
1. Configure multiple MCP servers
2. Create agent with access to all
3. Enable MCP for provider

**Use:**
- "Search the web for MCP examples, then save results to a file"
- "Read config.json, update the database, and commit the changes to Git"
- "Fetch GitHub issues and analyze them with GPT-4"

---

## Troubleshooting

### Server Won't Connect

**Problem**: Server status stays at ⚪ Disconnected or 🔴 Error

**Solutions:**
1. **For stdio servers (Desktop):**
   - Check if the npm package is installed: `npm list -g @modelcontextprotocol/server-NAME`
   - Verify the command is correct
   - Check if the path exists (for filesystem server)
   - Look at error message in expanded server card

2. **For HTTP/SSE servers:**
   - Verify the server is running: Test URL in browser
   - Check firewall settings
   - Verify authentication headers are correct
   - Check server logs for errors

3. **General:**
   - Click "Test Connection" from server menu (⋮)
   - Check internet connection
   - Restart the app
   - Re-configure the server

### No Tools Available

**Problem**: Server connected but shows "0 tools"

**Solutions:**
- Wait a few seconds (tools may be loading)
- Disconnect and reconnect the server
- Check MCP server documentation for tool list
- Verify server version is compatible

### Tool Execution Fails

**Problem**: Tools are called but return errors

**Solutions:**
- Check parameters are correct
- Verify permissions (file access, API quotas)
- Look at error message in activity log
- Check MCP server logs
- Verify authentication is still valid

### Mobile Platform Warning

**Problem**: "stdio not supported on mobile"

**Solution:**
- This is expected - mobile platforms cannot run stdio servers
- Use HTTP or SSE transport instead
- Connect to a remote MCP server
- Consider using cloud-based MCP services

### Performance Issues

**Problem**: Slow response times

**Solutions:**
- Check server connection quality
- Reduce number of active MCP servers
- Use local servers when possible (Desktop)
- Check network bandwidth
- Monitor server logs for bottlenecks

---

## Best Practices

### Security

1. **API Keys**: Store securely, never commit to version control
2. **File Access**: Only give filesystem access to trusted agents
3. **Network Access**: Use HTTPS for remote servers
4. **Least Privilege**: Only enable tools that are actually needed
5. **Review Logs**: Check activity feed for unexpected behavior

### Performance

1. **Selective Enabling**: Don't enable all MCP servers for every agent
2. **Connection Management**: Disconnect unused servers
3. **Tool Selection**: Be specific about which tools to use
4. **Local First**: Prefer local (stdio) servers on desktop
5. **Monitor Activity**: Check statistics for bottlenecks

### Organization

1. **Naming**: Use clear, descriptive names for servers
2. **Documentation**: Add descriptions to servers and agents
3. **Grouping**: Create agents specialized for specific tools
4. **Regular Cleanup**: Remove unused servers and agents
5. **Testing**: Test connection before production use

---

## Advanced Topics

### Creating Custom MCP Servers

1. **Server Development**: Follow MCP protocol specification
2. **Tool Definition**: Define tools with JSON schemas
3. **Deployment**: Run as HTTP/SSE server or stdio process
4. **Registration**: Add as "Custom Server" in Micro

### Multi-Agent Coordination with MCP

1. **Shared Tools**: Multiple agents can use same MCP servers
2. **Specialized Agents**: Create agents for specific tool sets
3. **Sequential Execution**: Chain agents with different tools
4. **Parallel Execution**: Run multiple agents simultaneously

### Integration with Workflows

1. **Automation**: Schedule agents with MCP tools
2. **Chaining**: Output from one tool feeds into another
3. **Conditional Logic**: Use different tools based on results
4. **Error Handling**: Graceful fallback when tools fail

---

## FAQ

**Q: Do I need to configure MCP servers?**
A: No, it's optional. Your AI will work without MCP, but won't have access to external tools.

**Q: How many MCP servers can I configure?**
A: No limit, but performance may degrade with too many active connections.

**Q: Can I use the same MCP server for multiple providers?**
A: Yes! Configure once, use everywhere.

**Q: Are there costs associated with MCP?**
A: Depends on the server. Some are free (filesystem, git), others require API keys with quotas (GitHub, search APIs).

**Q: Can I disable MCP after enabling it?**
A: Yes, simply toggle it off in provider or agent settings.

**Q: What happens if an MCP server goes offline?**
A: Tool calls will fail gracefully, and the agent will handle the error.

**Q: Can I create my own MCP tools?**
A: Yes! See the MCP protocol documentation for creating custom servers.

**Q: Is my data secure with MCP?**
A: Data is sent to the MCP server. Use trusted servers and secure connections (HTTPS).

---

## Resources

- **MCP Protocol**: https://modelcontextprotocol.io
- **Server List**: https://github.com/modelcontextprotocol/servers
- **Community**: Discord / GitHub Discussions
- **Support**: File issues in the Micro repository

---

**Need Help?** Check the troubleshooting section or file an issue on GitHub.
