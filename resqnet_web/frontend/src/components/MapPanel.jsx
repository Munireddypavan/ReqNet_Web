import React, { useState, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet'
import L from 'leaflet'
import { Navigation, MessageSquare, Info, Shield, Radio, Locate } from 'lucide-react'

// Set up custom glowing tactical icons to bypass leaflet's default asset resolving bugs
const createSelfIcon = () => L.divIcon({
  className: 'custom-leaflet-marker',
  html: `<div class="custom-marker-circle self"></div>`,
  iconSize: [24, 24],
  iconAnchor: [12, 12]
})

const createPeerIcon = (name) => L.divIcon({
  className: 'custom-leaflet-marker',
  html: `
    <div style="display: flex; flex-direction: column; align-items: center;">
      <div class="custom-marker-tag">${name.length > 8 ? name.substring(0, 8) : name}</div>
      <div class="custom-marker-circle">
        <div style="width: 6px; height: 6px; border-radius: 50%; background-color: #ffdb3c;"></div>
      </div>
    </div>
  `,
  iconSize: [60, 60],
  iconAnchor: [30, 42]
})

// Helper component to center and move leaflet view programmatically
function MapRecenter({ center, zoom }) {
  const map = useMap()
  useEffect(() => {
    if (center) {
      map.setView(center, zoom || map.getZoom())
    }
  }, [center, map])
  return null
}

function MapPanel({ selfNode, nodes }) {
  const [selectedNode, setSelectedNode] = useState(null)
  const [mapCenter, setMapCenter] = useState([13.0827, 80.2707]) // Default center (Chennai, India)

  useEffect(() => {
    if (selfNode && selfNode.lat && selfNode.lng) {
      setMapCenter([selfNode.lat, selfNode.lng])
    }
  }, [selfNode])

  // Haversine formula to compute distance in meters
  const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3 // Earth radius in meters
    const phi1 = lat1 * Math.PI / 180
    const phi2 = lat2 * Math.PI / 180
    const deltaPhi = (lat2 - lat1) * Math.PI / 180
    const deltaLambda = (lon2 - lon1) * Math.PI / 180

    const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
              Math.cos(phi1) * Math.cos(phi2) *
              Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    return R * c
  }

  const getDistanceStr = (node) => {
    if (!selfNode || !node.lat || !node.lng) return 'N/A'
    const dist = calculateDistance(selfNode.lat, selfNode.lng, node.lat, node.lng)
    return dist >= 1000 ? `${(dist / 1000).toFixed(2)} km` : `${Math.round(dist)} m`
  }

  const getLastSeenStr = (timestamp) => {
    if (!timestamp) return 'Offline'
    const diff = Date.now() - timestamp
    if (diff < 15000) return 'Active just now'
    if (diff < 60000) return `Active ${Math.round(diff / 1000)}s ago`
    return `Active ${Math.round(diff / 60000)}m ago`
  }

  const handleFocusNode = (node) => {
    if (node.lat && node.lng) {
      setMapCenter([node.lat, node.lng])
    }
  }

  return (
    <section className="dashboard-panel" style={{ flex: 1, position: 'relative' }}>
      <header className="panel-header" style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 1000, background: 'rgba(23, 24, 24, 0.9)', backdropFilter: 'blur(5px)' }}>
        <h2 className="panel-title">
          <Locate size={16} />
          OFF-GRID GPS TRACKER
        </h2>
        <div style={{ fontSize: '10px', color: 'var(--outline)', fontWeight: 'bold', letterSpacing: '0.8px' }}>
          {nodes.filter(n => n.id !== selfNode?.id).length} PEERS ON TACTICAL GRID
        </div>
      </header>

      {/* Map Content Frame */}
      <div className="map-frame">
        {selfNode && (
          <MapContainer
            center={[selfNode.lat || 13.0827, selfNode.lng || 80.2707]}
            zoom={16}
            className="map-container"
            zoomControl={false}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            
            {/* Center Manager */}
            <MapRecenter center={mapCenter} />

            {/* Self Marker */}
            {selfNode.lat && selfNode.lng && (
              <Marker
                position={[selfNode.lat, selfNode.lng]}
                icon={createSelfIcon()}
              />
            )}

            {/* Discovered Peer Markers */}
            {nodes
              .filter((n) => n.id !== selfNode?.id && n.lat && n.lng)
              .map((n) => (
                <Marker
                  key={n.id}
                  position={[n.lat, n.lng]}
                  icon={createPeerIcon(n.name)}
                  eventHandlers={{
                    click: () => {
                      setSelectedNode(n)
                    },
                  }}
                />
              ))}
          </MapContainer>
        )}

        {/* Floating Quick Map Action Center */}
        {selfNode && (
          <button
            onClick={() => setMapCenter([selfNode.lat, selfNode.lng])}
            style={{
              position: 'absolute',
              top: '80px',
              right: '20px',
              zIndex: 1000,
              padding: '12px',
              background: 'var(--primary-container)',
              color: 'var(--on-primary-container)',
              border: 'none',
              borderRadius: '50%',
              cursor: 'pointer',
              boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all 0.2s',
            }}
            title="Focus My Location"
          >
            <Navigation size={18} style={{ transform: 'rotate(45deg)' }} />
          </button>
        )}

        {/* Dynamic Glassmorphic Inspector Card */}
        {selectedNode && (
          <div className="inspector-card">
            {/* Inspector Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: '700', color: 'var(--on-surface)' }}>
                  {selectedNode.name}
                </h3>
                <p style={{ fontSize: '9px', color: 'var(--outline)', fontWeight: '600', letterSpacing: '0.8px', marginTop: '2px', textTransform: 'uppercase' }}>
                  NODE ID: {selectedNode.id.toUpperCase()}
                </p>
              </div>
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <span style={{ fontSize: '10px', background: 'rgba(255, 181, 160, 0.15)', color: 'var(--primary)', padding: '4px 10px', borderRadius: '12px', fontWeight: 'bold' }}>
                  {getLastSeenStr(selectedNode.lastSeen)}
                </span>
                <button
                  onClick={() => setSelectedNode(null)}
                  style={{ background: 'transparent', border: 'none', color: 'var(--outline)', cursor: 'pointer', fontSize: '16px', fontWeight: 'bold' }}
                >
                  &times;
                </button>
              </div>
            </div>

            {/* Inspector Body Specs Grid */}
            <div style={{ display: 'flex', gap: '24px', margin: '20px 0' }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '9px', color: 'var(--outline)', fontWeight: '700', letterSpacing: '0.8px' }}>
                  <Radio size={12} />
                  EST. DISTANCE
                </div>
                <div style={{ fontSize: '15px', color: 'var(--on-surface)', marginTop: '4px' }}>
                  {getDistanceStr(selectedNode)}
                </div>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '9px', color: 'var(--outline)', fontWeight: '700', letterSpacing: '0.8px' }}>
                  <Info size={12} />
                  COORDINATES
                </div>
                <div style={{ fontSize: '14px', color: 'var(--on-surface)', marginTop: '4px' }}>
                  {selectedNode.lat.toFixed(4)}, {selectedNode.lng.toFixed(4)}
                </div>
              </div>
            </div>

            {/* Inspector CTA Action Triggers */}
            <div style={{ display: 'flex', gap: '12px' }}>
              <button
                onClick={() => handleFocusNode(selectedNode)}
                style={{
                  flex: 1,
                  padding: '10px',
                  background: 'var(--surface-high)',
                  color: 'var(--on-surface)',
                  border: '1px solid var(--surface-highest)',
                  borderRadius: '10px',
                  fontSize: '11px',
                  fontWeight: '700',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                }}
              >
                <Navigation size={12} style={{ transform: 'rotate(45deg)' }} />
                FOCUS NODE
              </button>
              <button
                onClick={() => {
                  alert(`Starting secure chat handshake request with ${selectedNode.name}...`)
                }}
                style={{
                  flex: 1,
                  padding: '10px',
                  background: 'var(--primary)',
                  color: 'var(--surface-lowest)',
                  border: 'none',
                  borderRadius: '10px',
                  fontSize: '11px',
                  fontWeight: '700',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                }}
              >
                <MessageSquare size={12} />
                SECURE CHAT
              </button>
            </div>
          </div>
        )}
      </div>
    </section>
  )
}

export default MapPanel
