import React from "react";
import "./SimpleChatView.css";

/**
 * SimpleChatView - A clean, ChatGPT-like interface for AgenticSeek
 * This component provides a simplified view focusing on the conversation
 */
export function SimpleChatView({ 
  messages, 
  query, 
  setQuery, 
  isLoading, 
  isOnline,
  status,
  handleSubmit,
  handleStop,
  expandedReasoning,
  toggleReasoning,
  messagesEndRef 
}) {
  return (
    <div className="simple-chat-view">
      <div className="simple-chat-container">
        <div className="simple-messages">
          {messages.length === 0 ? (
            <div className="simple-welcome">
              <div className="welcome-icon">🤖</div>
              <h2>Welcome to AgenticSeek</h2>
              <p>Your local AI assistant for browsing, coding, and task automation</p>
              <div className="example-prompts">
                <div className="example-prompt">
                  💻 "Create a Python script to analyze CSV data"
                </div>
                <div className="example-prompt">
                  🌐 "Search the web for the latest AI news"
                </div>
                <div className="example-prompt">
                  📁 "List all Python files in my workspace"
                </div>
              </div>
            </div>
          ) : (
            messages.map((msg, index) => (
              <div
                key={index}
                className={`simple-message ${
                  msg.type === "user"
                    ? "simple-user-message"
                    : msg.type === "agent"
                    ? "simple-agent-message"
                    : "simple-error-message"
                }`}
              >
                <div className="message-avatar">
                  {msg.type === "user" ? "👤" : "🤖"}
                </div>
                <div className="message-body">
                  {msg.type === "agent" && msg.agentName && (
                    <div className="message-agent-badge">
                      {msg.agentName}
                    </div>
                  )}
                  <div className="message-text">
                    {msg.content}
                  </div>
                  {msg.type === "agent" && msg.reasoning && (
                    <button
                      className="reasoning-toggle-btn"
                      onClick={() => toggleReasoning(index)}
                    >
                      {expandedReasoning.has(index) ? "▼" : "▶"} Show reasoning
                    </button>
                  )}
                  {msg.type === "agent" &&
                    msg.reasoning &&
                    expandedReasoning.has(index) && (
                      <div className="reasoning-section">
                        <pre>{msg.reasoning}</pre>
                      </div>
                    )}
                </div>
              </div>
            ))
          )}
          <div ref={messagesEndRef} />
        </div>

        {!isOnline && (
          <div className="offline-banner">
            ⚠️ System offline. Please start the backend service.
          </div>
        )}

        {isOnline && status && status !== "Agents ready" && (
          <div className="status-banner">
            <div className="status-spinner"></div>
            <span>{status}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="simple-input-form">
          <div className="input-wrapper">
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Message AgenticSeek..."
              disabled={isLoading || !isOnline}
              className="simple-input"
            />
            <div className="input-actions">
              {isLoading ? (
                <button
                  type="button"
                  onClick={handleStop}
                  className="input-button stop-btn"
                  aria-label="Stop"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                    <rect x="6" y="6" width="12" height="12" rx="2" />
                  </svg>
                </button>
              ) : (
                <button
                  type="submit"
                  disabled={!query.trim() || !isOnline}
                  className="input-button send-btn"
                  aria-label="Send"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <path
                      d="M22 2L11 13M22 2L15 22L11 13M22 2L2 9L11 13"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </button>
              )}
            </div>
          </div>
          <div className="input-hint">
            Press Enter to send • Shift+Enter for new line
          </div>
        </form>
      </div>
    </div>
  );
}
