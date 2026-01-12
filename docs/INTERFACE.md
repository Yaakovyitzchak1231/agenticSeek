# AgenticSeek User Interface Guide

AgenticSeek now offers two interface modes to suit different user preferences and use cases.

## Interface Modes

### Simple Mode (Default) 💬

The **Simple Mode** provides a clean, ChatGPT-like interface that focuses on the conversation. This is perfect for:
- Quick interactions
- General queries
- Users who want a simple chat experience
- Mobile or smaller screens

**Features:**
- Clean, centered chat interface
- Welcome screen with example prompts
- Message avatars (👤 for user, 🤖 for agent)
- Agent badges showing which specialized agent is responding
- Collapsible reasoning sections (click "Show reasoning" to see AI's thought process)
- Status indicators for agent activity
- Mobile-responsive design

### Advanced Mode 🔧

The **Advanced Mode** provides the full power-user experience with dual-pane layout. This is ideal for:
- Developers and technical users
- Monitoring file operations in real-time
- Watching browser automation
- Debugging and development

**Features:**
- Split-pane interface (Chat + Computer View)
- Editor View: See code being written and files being edited
- Browser View: Watch web automation in real-time
- Detailed tool execution feedback
- Resizable panels
- All the power features of AgenticSeek

## Switching Between Modes

Click the **🔧 Advanced** / **💬 Simple** button in the top-right corner of the header to switch between modes.

Your current conversation persists across mode changes, so you can switch freely without losing context.

## Simple Mode Interface Elements

### Welcome Screen
When you first open AgenticSeek, you'll see:
- A friendly welcome message
- Example prompts to get you started
- System status indicator

### Message Types

**User Messages (You)**
- Appear with 👤 avatar
- Aligned to show they're from you
- Highlighted in the accent color

**Agent Messages (AI)**
- Appear with 🤖 avatar
- Show which specialized agent responded (e.g., "CoderAgent", "BrowserAgent")
- Can include collapsible "reasoning" sections

**Status Messages**
- Show when agents are working
- Display current operation status
- Appear as informational banners

### Input Area

The input bar at the bottom includes:
- **Text input**: Type your message here
- **Send button** (➤): Click or press Enter to send
- **Stop button** (⏹): Appears when agent is processing, click to stop

## Tips for Best Experience

### In Simple Mode:
1. **Focus on your task** - The clean interface helps you concentrate on the conversation
2. **Check reasoning** - Click "Show reasoning" to understand the AI's decision-making process
3. **Use example prompts** - When starting out, try the example prompts on the welcome screen
4. **Mobile friendly** - Works great on phones and tablets

### In Advanced Mode:
1. **Watch the action** - See code being written in real-time
2. **Monitor browser automation** - Switch to Browser View to see web interactions
3. **Debug issues** - View detailed tool execution feedback
4. **Resize panels** - Drag the divider between panes to adjust sizing

## Keyboard Shortcuts

- **Enter**: Send message (in Simple Mode)
- **Shift+Enter**: New line in message (planned feature)

## Agent Indicators

Different agents have different specializations:

- **CoderAgent** - Writes and edits code
- **BrowserAgent** - Browses the web and interacts with websites
- **FileAgent** - Manages files and directories
- **PlannerAgent** - Breaks down complex tasks into steps
- **CasualAgent** - Handles general conversation

The active agent is shown in a badge on agent messages in Simple Mode.

## Status Indicators

- **🟢 Online** - System is ready
- **🔴 Offline** - Backend service is not running
- **🔵 Processing** - Agent is working on your request

## Example Prompts

Try these to get started:

### For Coding:
- "Create a Python script to analyze CSV data"
- "Write a JavaScript function to validate email addresses"
- "Build a simple Express.js API server"

### For Web Browsing:
- "Search the web for the latest AI news from 2025"
- "Find the top 5 cafes in Paris with their addresses"
- "Look up the current weather in Tokyo"

### For File Operations:
- "List all Python files in my workspace"
- "Create a new folder called 'projects'"
- "Find all files modified in the last week"

### For Complex Tasks:
- "Plan a trip to Japan for 2 weeks"
- "Research and summarize recent developments in quantum computing"
- "Create a project structure for a React application"

## Troubleshooting

### "System offline" message
**Solution**: Start the backend service with `docker-compose up` or `./start_services.sh full`

### Messages not sending
**Solution**: Check that the backend is running and the status indicator shows "Online"

### Can't see browser automation
**Solution**: Switch to Advanced Mode and select "Browser View"

### UI looks broken
**Solution**: Try refreshing the page or clearing your browser cache

## Getting Help

- 📖 Full documentation: [README.md](../README.md)
- 💬 Discord: https://discord.gg/8hGDaME3TC
- 🐛 Issues: https://github.com/Fosowl/agenticSeek/issues

## Accessibility

AgenticSeek's interface is designed with accessibility in mind:
- Clear visual indicators
- Keyboard navigation support
- ARIA labels for screen readers
- High contrast theme available (toggle with theme button)
- Responsive design for all screen sizes

---

**Tip**: Start with Simple Mode for everyday use, and switch to Advanced Mode when you need to see what's happening under the hood!
