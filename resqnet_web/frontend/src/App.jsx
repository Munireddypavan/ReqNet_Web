import React, { useState, useEffect } from 'react'
import { Network as NetworkIcon, LogOut, User as UserIcon, Map as MapIcon, Megaphone as BroadcastIcon, MessageSquare as ChatIcon, Activity as StatusIcon } from 'lucide-react'
import StatusPanel from './components/StatusPanel'
import MapPanel from './components/MapPanel'
import ChatPanel from './components/ChatPanel'
import BroadcastPanel from './components/BroadcastPanel'
import AuthPage from './components/AuthPage'
import ProfilePanel from './components/ProfilePanel'
import { initMeshService, broadcastPayload, updateActiveProtocols } from './services/meshService'

function App() {
  const [activeTab, setActiveTab] = useState('map')
  const [authUser, setAuthUser] = useState(() => {
    const saved = localStorage.getItem('resqnet_user')
    return saved ? JSON.parse(saved) : null
  })
  const [messages, setMessages] = useState([])
  const [nodes, setNodes] = useState([])
  const [selfNode, setSelfNode] = useState(null)
  const [connected, setConnected] = useState(false)
  const [activeProtocols, setActiveProtocols] = useState(['Bluetooth LE', 'Wi-Fi Direct', 'WebRTC Mesh'])

  useEffect(() => {
    if (!authUser) return

    // Initialize the WebSocket connection & fetch historical logs
    const service = initMeshService((payload) => {
      if (payload.type === 'GPS_BEACON') {
        if (service.selfNode && payload.senderId === service.selfNode.id) {
          setSelfNode((prev) => ({
            ...prev,
            lat: payload.lat,
            lng: payload.lng
          }));
        }
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
      } else if (payload.type === 'CONNECTION_STATUS') {
        setConnected(payload.connected);
      }
    }, authUser.username);

    setSelfNode(service.selfNode);

    // Load initial Rest records and filter active nodes
    service.fetchHistory().then(({ loadedMessages, loadedNodes }) => {
      setMessages(loadedMessages);
      setNodes((prev) => {
        const map = new Map();
        // Only keep nodes seen within the last 2 minutes
        const activeLoaded = loadedNodes.filter(n => (Date.now() - (n.lastSeen || 0)) < 120000);
        [...prev, ...activeLoaded].forEach((n) => map.set(n.id, n));
        return Array.from(map.values());
      });
    });

    return () => {
      service.close();
    };
  }, [authUser]);

  const handleLogout = () => {
    localStorage.removeItem('resqnet_user')
    setAuthUser(null)
  }

  const handleSendMessage = (text, receiverId = 'BROADCAST') => {
    if (!selfNode) return;
    const messageId = `web-msg-${Math.random().toString(36).substring(2, 10)}`;
    const msgPayload = {
      messageId,
      senderId: authUser.username,
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
    setActiveProtocols((prev) => {
      const next = prev.includes(protocol)
        ? prev.filter((p) => p !== protocol)
        : [...prev, protocol];
      
      updateActiveProtocols(next);
      return next;
    });
  };

  if (!authUser) {
    return <AuthPage onAuthSuccess={(user) => setAuthUser(user)} />
  }

  return (
    <div className="app-container">
      {/* Comms Header Bar */}
      <header id="header-bar" className="header-bar">
        <div id="logo-section" className="logo-section">
          <NetworkIcon id="logo-icon" className="logo-icon" size={20} />
          <h1 id="logo-text" className="logo-text">ResQNet Web</h1>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div
            onClick={() => setActiveTab('profile')}
            style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', color: 'var(--on-surface)', fontWeight: '600', cursor: 'pointer' }}
            title="View/Edit Profile"
          >
            <UserIcon size={14} style={{ color: 'var(--primary)' }} />
            <span>{authUser.fullName || authUser.username}</span>
          </div>
          <div id="status-badge" className="status-badge">
            <span id="status-indicator" className={`status-indicator ${connected ? 'active' : ''}`} />
            {connected ? 'MESH WEB ACTIVE' : 'CONNECTING TO MESH...'}
          </div>
          <button
            onClick={handleLogout}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '6px 12px',
              background: 'var(--surface-low)',
              border: '1px solid var(--surface-high)',
              borderRadius: '20px',
              color: 'var(--outline)',
              fontSize: '11px',
              fontWeight: '700',
              cursor: 'pointer',
              transition: 'var(--transition)'
            }}
            title="Logout"
          >
            <LogOut size={12} />
            LOGOUT
          </button>
        </div>
      </header>

      {/* Main Dashboard Workspace */}
      <main className="main-dashboard">
        {/* Left Side: Sidebar Navigation */}
        <nav className="sidebar-nav">
          <div
            className={`sidebar-item ${activeTab === 'map' ? 'active' : ''}`}
            onClick={() => setActiveTab('map')}
          >
            <MapIcon size={14} />
            Map Grid
          </div>
          <div
            className={`sidebar-item ${activeTab === 'broadcast' ? 'active' : ''}`}
            onClick={() => setActiveTab('broadcast')}
          >
            <BroadcastIcon size={14} />
            Broadcast SOS
          </div>
          <div
            className={`sidebar-item ${activeTab === 'chats' ? 'active' : ''}`}
            onClick={() => setActiveTab('chats')}
          >
            <ChatIcon size={14} />
            Mesh Chat
          </div>
          <div
            className={`sidebar-item ${activeTab === 'status' ? 'active' : ''}`}
            onClick={() => setActiveTab('status')}
          >
            <StatusIcon size={14} />
            System Status
          </div>
          <div
            className={`sidebar-item ${activeTab === 'profile' ? 'active' : ''}`}
            onClick={() => setActiveTab('profile')}
          >
            <UserIcon size={14} />
            My Profile
          </div>
        </nav>

        {/* Right Side: Tab Workspace Content Area */}
        <div className="workspace-area">
          {activeTab === 'map' && (
            <MapPanel selfNode={selfNode} nodes={nodes} onSelectTab={setActiveTab} />
          )}
          {activeTab === 'broadcast' && (
            <BroadcastPanel onSendMessage={handleSendMessage} selfNode={selfNode} />
          )}
          {activeTab === 'chats' && (
            <ChatPanel
              messages={messages}
              selfNode={selfNode}
              onSendMessage={handleSendMessage}
              nodes={nodes}
              username={authUser.username}
            />
          )}
          {activeTab === 'status' && (
            <StatusPanel
              selfNode={selfNode}
              activeProtocols={activeProtocols}
              toggleProtocol={toggleProtocol}
              connectedCount={nodes.filter((n) => n.id !== selfNode?.id && (Date.now() - (n.lastSeen || 0)) < 120000).length}
            />
          )}
          {activeTab === 'profile' && (
            <ProfilePanel user={authUser} onUpdateSuccess={(updatedUser) => setAuthUser(updatedUser)} />
          )}
        </div>
      </main>
    </div>
  )
}

export default App
