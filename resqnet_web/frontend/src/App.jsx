import React, { useState, useEffect } from 'react'
import { Network as NetworkIcon } from 'lucide-react'
import StatusPanel from './components/StatusPanel'
import MapPanel from './components/MapPanel'
import ChatPanel from './components/ChatPanel'
import BroadcastPanel from './components/BroadcastPanel'
import { initMeshService, broadcastPayload } from './services/meshService'

function App() {
  const [messages, setMessages] = useState([])
  const [nodes, setNodes] = useState([])
  const [selfNode, setSelfNode] = useState(null)
  const [connected, setConnected] = useState(false)
  const [activeProtocols, setActiveProtocols] = useState(['Bluetooth LE', 'Wi-Fi Direct', 'WebRTC Mesh'])

  useEffect(() => {
    // Initialize the WebSocket connection & fetch historical logs
    const service = initMeshService((payload) => {
      if (payload.type === 'GPS_BEACON') {
        setNodes((prevNodes) => {
          const filtered = prevNodes.filter((n) => n.id !== payload.senderId);
          return [
            ...filtered,
            {
              id: payload.senderId,
              name: payload.name,
              lat: payload.lat,
              lng: payload.lng,
              lastSeen: payload.timestamp,
            },
          ];
        });
      } else if (payload.messageId) {
        setMessages((prevMsgs) => {
          const filtered = prevMsgs.filter((m) => m.messageId !== payload.messageId);
          const updated = [
            ...filtered,
            {
              messageId: payload.messageId,
              senderId: payload.senderId,
              receiverId: payload.receiverId,
              content: payload.content,
              timestamp: payload.timestamp,
              ttl: payload.ttl,
              hops: payload.hops,
              status: payload.status,
            },
          ];
          return updated.sort((a, b) => a.timestamp - b.timestamp);
        });
      }
    });

    setSelfNode(service.selfNode);
    setConnected(true);

    // Load initial Rest records
    service.fetchHistory().then(({ loadedMessages, loadedNodes }) => {
      setMessages(loadedMessages);
      setNodes((prev) => {
        // Merge without self or duplicate overrides
        const map = new Map();
        [...prev, ...loadedNodes].forEach((n) => map.set(n.id, n));
        return Array.from(map.values());
      });
    });

    return () => {
      service.close();
    };
  }, []);

  const handleSendMessage = (text, receiverId = 'BROADCAST') => {
    if (!selfNode) return;
    const messageId = `web-msg-${Math.random().toString(36).substring(2, 10)}`;
    const msgPayload = {
      messageId,
      senderId: selfNode.id,
      receiverId,
      content: text,
      timestamp: Date.now(),
      ttl: 5,
      hops: 0,
      status: receiverId === 'AUTHORITIES' ? 'Gateway Delivered' : 'Sent',
    };

    // Add locally
    setMessages((prev) => [...prev, msgPayload]);

    // Send across WS
    broadcastPayload(msgPayload);
  };

  const toggleProtocol = (protocol) => {
    setActiveProtocols((prev) =>
      prev.includes(protocol)
        ? prev.filter((p) => p !== protocol)
        : [...prev, protocol]
    );
  };

  return (
    <div className="app-container">
      {/* Comms Header Bar */}
      <header className="header-bar">
        <div className="logo-section">
          <NetworkIcon className="logo-icon" size={20} />
          <h1 className="logo-text">ResQNet Web</h1>
        </div>
        <div className="status-badge">
          <span className={`status-indicator ${connected ? 'active' : ''}`} />
          {connected ? 'MESH WEB ACTIVE' : 'CONNECTING TO MESH...'}
        </div>
      </header>

      {/* Main Dashboard Panels Grid */}
      <main className="main-dashboard">
        {/* Left Side: System Integrity and Protocols */}
        <StatusPanel
          selfNode={selfNode}
          activeProtocols={activeProtocols}
          toggleProtocol={toggleProtocol}
          connectedCount={nodes.filter((n) => n.id !== selfNode?.id).length}
        />

        {/* Middle: Map Panel */}
        <MapPanel selfNode={selfNode} nodes={nodes} />

        {/* Right Panel: Chats Terminal & Broadcast SOS */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', height: '100%' }}>
          <ChatPanel
            messages={messages}
            selfNode={selfNode}
            onSendMessage={handleSendMessage}
          />
          <BroadcastPanel onSendMessage={handleSendMessage} />
        </div>
      </main>
    </div>
  )
}

export default App
