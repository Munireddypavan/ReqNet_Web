import React, { useState, useRef, useEffect } from 'react'
import { MessageSquare, Send, Check, CheckCheck, RefreshCw } from 'lucide-react'

function ChatPanel({ messages, selfNode, onSendMessage }) {
  const [inputText, setInputText] = useState('')
  const scrollRef = useRef(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages])

  const handleSubmit = (e) => {
    e.preventDefault()
    const text = inputText.trim()
    if (!text) return
    onSendMessage(text, 'BROADCAST')
    setInputText('')
  }

  const formatTime = (ts) => {
    if (!ts) return ''
    const date = new Date(ts)
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }

  return (
    <div className="dashboard-panel" style={{ width: '400px', height: '60%', display: 'flex', flexDirection: 'column' }}>
      {/* Panel Header */}
      <header className="panel-header">
        <h2 className="panel-title">
          <MessageSquare size={16} />
          SECURE MESH CHAT
        </h2>
        <div style={{ fontSize: '10px', color: 'var(--outline)', fontWeight: 'bold', letterSpacing: '0.8px' }}>
          GLOBAL CHANNEL
        </div>
      </header>

      {/* Messages Scrolling Terminal */}
      <div
        ref={scrollRef}
        className="panel-content"
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          gap: '12px',
          background: 'rgba(14, 14, 14, 0.4)',
        }}
      >
        {messages.length === 0 ? (
          <div style={{ margin: 'auto', textAlign: 'center', opacity: 0.5, padding: '24px' }}>
            <MessageSquare size={32} style={{ margin: '0 auto 12px', color: 'var(--outline)' }} />
            <p style={{ fontSize: '11px', fontWeight: '500', color: 'var(--outline)', letterSpacing: '0.5px' }}>
              No messages routed across local mesh grid yet.
            </p>
          </div>
        ) : (
          messages.map((msg, idx) => {
            const isMe = selfNode && msg.senderId === selfNode.id
            const timeStr = formatTime(msg.timestamp)
            const isSos = msg.content && msg.content.includes('*** SOS ***')
            const isDispatch = msg.content && msg.content.includes('*** DISPATCH')

            return (
              <div
                key={msg.messageId || idx}
                className={`chat-bubble ${isMe ? 'self' : 'peer'}`}
                style={{
                  border: isSos ? '1.5px solid var(--error)' : isDispatch ? '1.5px solid var(--secondary-container)' : 'none',
                  background: isSos ? 'rgba(255, 180, 171, 0.15)' : isDispatch ? 'rgba(255, 219, 60, 0.15)' : undefined,
                  color: (isSos || isDispatch) ? 'var(--on-surface)' : undefined
                }}
              >
                {/* Sender Title Badge */}
                {!isMe && (
                  <span className="chat-sender" style={{ color: isSos ? 'var(--error)' : isDispatch ? 'var(--secondary-container)' : 'var(--outline)' }}>
                    {msg.senderId ? msg.senderId.substring(0, 8) : 'Unknown'}
                  </span>
                )}

                {/* Msg content */}
                <div style={{ whiteSpace: 'pre-wrap' }}>{msg.content}</div>

                {/* Comms Stats bar */}
                <div className="chat-meta">
                  <span>{timeStr}</span>
                  {msg.hops > 0 && <span>• {msg.hops} hops</span>}
                  
                  {/* Sync ticks */}
                  {isMe && (
                    <span style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center' }}>
                      {msg.status === 'Gateway Delivered' ? (
                        <span style={{ display: 'flex', alignItems: 'center', gap: '2px', color: '#4caf50', fontWeight: 'bold', fontSize: '8px' }}>
                          <CheckCheck size={10} />
                          GATEWAY
                        </span>
                      ) : msg.status === 'Relayed' || msg.status === 'Delivered' ? (
                        <CheckCheck size={10} style={{ color: 'var(--on-primary)' }} />
                      ) : (
                        <Check size={10} style={{ color: 'var(--on-primary)', opacity: 0.6 }} />
                      )}
                    </span>
                  )}
                </div>
              </div>
            )
          })
        )}
      </div>

      {/* Inputs Comms Send Area */}
      <form
        onSubmit={handleSubmit}
        style={{
          padding: '16px',
          borderTop: '0.5px solid var(--surface-high)',
          background: 'var(--surface)',
          display: 'flex',
          gap: '12px',
        }}
      >
        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Message mesh network..."
          className="input-box"
          style={{
            height: '42px',
            borderRadius: '24px',
            padding: '0 20px',
            background: 'var(--surface-lowest)',
          }}
        />
        <button
          type="submit"
          style={{
            width: '42px',
            height: '42px',
            borderRadius: '50%',
            background: 'var(--primary)',
            border: 'none',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--surface-lowest)',
            flexShrink: 0,
            transition: 'all 0.2s',
          }}
        >
          <Send size={16} />
        </button>
      </form>
    </div>
  )
}

export default ChatPanel
