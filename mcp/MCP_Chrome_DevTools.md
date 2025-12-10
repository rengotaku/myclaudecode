# Chrome DevTools MCP Server

**Purpose**: Browser debugging and inspection via Chrome DevTools Protocol

## Triggers
- Network request monitoring and analysis
- Console log inspection and JavaScript execution
- Performance profiling and bottleneck identification
- DOM inspection and manipulation
- Web application debugging with authentication

## Choose When
- **For network debugging**: API calls, request/response inspection, timing analysis
- **For console access**: Error logs, warnings, JavaScript evaluation
- **For performance analysis**: Load times, resource usage, memory profiling
- **Over Playwright**: When you need DevTools-level inspection, not just automation
- **For authenticated sessions**: Debug with existing login state

## Setup
```bash
# Start Chrome with debugging enabled
google-chrome --remote-debugging-port=9222

# Or with a dedicated profile
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
```

## Works Best With
- **Playwright**: Playwright automates → Chrome DevTools inspects deeper issues
- **Sequential**: Sequential plans debug strategy → Chrome DevTools executes inspection

## Key Features
- **Network Monitoring**: Capture HTTP requests/responses with filtering
- **Console Integration**: Read logs, analyze errors, execute JavaScript
- **Performance Metrics**: Timing data, resource loading, memory usage
- **Screenshots**: Capture current page state
- **DOM Access**: Inspect and manipulate page elements

## Examples
```
"check network requests for this page" → Chrome DevTools (network inspection)
"show me console errors" → Chrome DevTools (console access)
"analyze page performance" → Chrome DevTools (performance profiling)
"execute JavaScript in browser" → Chrome DevTools (JS evaluation)
"debug API calls" → Chrome DevTools (network + console)
"automate form submission" → Playwright (automation, not debugging)
```

## References
- [Official Documentation](https://developer.chrome.com/blog/chrome-devtools-mcp)
- [GitHub Repository](https://github.com/ChromeDevTools/chrome-devtools-mcp)
