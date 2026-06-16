import React from 'react'
import { Activity, ShieldAlert, Bluetooth, Wifi, Radio } from 'lucide-react'

function StatusPanel({ selfNode, activeProtocols, toggleProtocol, connectedCount }) {
  // Simple health score computation mirroring mobile statuses
  let healthScore = 100
  if (connectedCount === 0) healthScore -= 15
  
  const protocols = [
    { name: 'Bluetooth LE', icon: Bluetooth },
    { name: 'Wi-Fi Direct', icon: Wifi },
    { name: 'WebRTC Mesh', icon: Radio },
  ]

  return (
    <aside className="dashboard-panel">
      {/* Panel Header */}
      <header className="panel-header">
        <h2 className="panel-title">
          <Activity size={16} />
          SYSTEM INTEGRITY
        </h2>
      </header>

      {/* Content */}
      <div className="panel-content" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        {/* Device Identifier Card */}
        <div>
          <span style={{ fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', textTransform: 'uppercase' }}>
            LOCAL NODE IDENTIFIER
          </span>
          <h3 style={{ fontSize: '24px', fontWeight: '300', letterSpacing: '-0.5px', marginTop: '4px', textTransform: 'uppercase', color: 'var(--on-surface)' }}>
            {selfNode ? selfNode.name : 'RESOLVING DEVICE...'}
          </h3>
          <p style={{ fontSize: '10px', color: 'var(--outline)', marginTop: '4px', letterSpacing: '0.5px' }}>
            ID: {selfNode ? selfNode.id.toUpperCase() : 'N/A'}
          </p>
        </div>

        {/* Tactical Metrics Box Row */}
        <div style={{ display: 'flex', gap: '12px' }}>
          <div style={{ flex: 1, padding: '12px', background: 'var(--surface-lowest)', border: '1px solid var(--surface-high)', borderRadius: '12px' }}>
            <span style={{ fontSize: '8px', color: 'var(--outline)', fontWeight: '700' }}>PEERS</span>
            <div style={{ fontSize: '22px', fontWeight: '300', marginTop: '2px' }}>{connectedCount}</div>
          </div>
          <div style={{ flex: 1, padding: '12px', background: 'var(--surface-lowest)', border: '1px solid var(--surface-high)', borderRadius: '12px' }}>
            <span style={{ fontSize: '8px', color: 'var(--outline)', fontWeight: '700' }}>INTEGRITY</span>
            <div style={{ fontSize: '22px', fontWeight: '300', marginTop: '2px', color: healthScore > 80 ? 'var(--primary)' : 'var(--error)' }}>
              {healthScore}%
            </div>
          </div>
        </div>

        <div style={{ height: '0.5px', background: 'var(--surface-high)' }} />

        {/* Security & Cryptography Module */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <ShieldAlert size={14} style={{ color: 'var(--primary)' }} />
            <span style={{ fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px' }}>TACTICAL CRYPTO</span>
          </div>
          <p style={{ fontSize: '11px', color: 'var(--on-surface-variant)', lineHeight: '1.5' }}>
            AES-256 GCM keys rotated automatically inside browser memory buffer. Mock network packages adapted to current browser session parameters.
          </p>
        </div>

        <div style={{ height: '0.5px', background: 'var(--surface-high)' }} />

        {/* Mesh Participation Radios */}
        <div>
          <span style={{ fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', textTransform: 'uppercase', display: 'block', marginBottom: '14px' }}>
            TACTICAL PROTOCOLS
          </span>
          {protocols.map((proto) => {
            const Icon = proto.icon
            const isActive = activeProtocols.includes(proto.name)
            const protoId = proto.name.toLowerCase().replace(/\s+/g, '-')
            return (
              <div key={proto.name} id={`protocol-row-${protoId}`} className={`toggle-row ${isActive ? 'active' : ''}`}>
                <div className="toggle-info">
                  <Icon size={16} className="toggle-icon" />
                  <span className="toggle-label">{proto.name}</span>
                </div>
                <label className="switch">
                  <input
                    id={`protocol-checkbox-${protoId}`}
                    type="checkbox"
                    checked={isActive}
                    onChange={() => toggleProtocol(proto.name)}
                  />
                  <span id={`protocol-slider-${protoId}`} className="slider" />
                </label>
              </div>
            )
          })}
        </div>
      </div>
    </aside>
  )
}

export default StatusPanel
