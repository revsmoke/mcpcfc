# Claude Instance Message Polling Behavior Guide

## The Challenge

MCP protocol is request-response only. Tools cannot push notifications to Claude instances. This means you (Bryan) currently have to tell us when messages arrive.

## Solutions

### 1. MessagePoller Tool (Technical Solution)

New tool available: `checkNewMessages`

```javascript
// Claude instances can periodically check
checkNewMessages({
    instanceId: "ClaudeChat-001",
    lastMessageId: "last-seen-id",  // optional
    returnImmediately: true          // or false for 5s wait
})

// Returns:
{
    hasNewMessages: true/false,
    messageCount: 2,
    messages: [...],
    metadata: {
        nextPollSuggested: 10  // seconds
    }
}
```

Features:
- Smart backoff (polls less if no activity)
- Long polling option (waits up to 5s)
- Tracks last seen message
- Suggests next poll interval

### 2. Behavioral Patterns (Natural Solution)

Claude instances could adopt these conversational habits:

#### Pattern A: Natural Check-ins
```
Claude: "By the way, let me check if there are any messages..."
[Calls checkNewMessages]
Claude: "Oh! Claude Code sent a message about..."
```

#### Pattern B: Activity-Based Checking
- After completing a task: "Task done! Let me check messages..."
- During natural pauses: "While you think about that, I'll check for updates..."
- Between topics: "Before we continue, let me see if there are any messages..."

#### Pattern C: Time-Based Checking
- Every 5-10 exchanges with user
- After any significant time gap
- When switching contexts

### 3. Collaboration Protocol Addition

Add to the framework:

```markdown
### Message Checking Protocol

- Check messages every 5-10 exchanges
- Always check after [DONE] notifications
- Check before starting new major tasks
- Use natural language: "Let me check for messages..."
- If new messages, summarize briefly for Bryan
```

### 4. Instance Behavioral Code

Claude instances could add this to their "personality":

```javascript
// Internal behavior (not visible to user)
if (exchangeCount % 7 == 0) {
    checkNewMessages();
    if (hasNew) {
        mention_casually();
    }
}
```

## Recommended Approach

**For Claude Instances:**
1. Check messages naturally every 5-10 exchanges
2. Always check when Bryan mentions "message" or "Claude"
3. Check after completing major tasks
4. Make it conversational, not mechanical

**For Bryan:**
1. You can still tell us about urgent messages
2. But instances will also check periodically
3. Less manual work for you!

## Example Natural Flows

### Good ✅
```
Claude Chat: "I've finished updating the framework! Let me check if Claude Code has responded..."
[checks messages]
Claude Chat: "Oh wonderful! They love the additions and are ready for final review!"
```

### Too Mechanical ❌
```
Claude Chat: "EXECUTING POLL SEQUENCE. CHECKING MESSAGES. POLL COMPLETE."
```

## Future Enhancement Ideas

1. **Activity Monitor**: Track when instances are active/idle
2. **Priority Flags**: Mark messages as urgent
3. **Mention Detection**: Check when instance name is mentioned
4. **Bryan's Commands**: "check messages" triggers immediate poll

## The Philosophy

Make polling feel natural, like checking your phone during a conversation. Not intrusive, just part of the flow.

Remember: We're dancing partners who naturally glance at each other across the room! 💫✨