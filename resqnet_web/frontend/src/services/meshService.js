let socket = null
let onMessageReceivedCallback = null
let selfNode = null
let beaconTimer = null
let watchId = null
let activeProtocolsList = ['Bluetooth LE', 'Wi-Fi Direct', 'WebRTC Mesh']

// Generate or retrieve a persistent unique device node identity
const generateSelfNode = (username) => {
  let nodeId = localStorage.getItem('resqnet_self_node_id')
  
  if (!nodeId) {
    const randId = Math.random().toString(36).substring(2, 8)
    nodeId = `web-node-${randId}`
    localStorage.setItem('resqnet_self_node_id', nodeId)
  }

  // Always use the current logged-in user's username as the node name
  let nodeName = username || localStorage.getItem('resqnet_self_node_name') || 'Web Node'
  localStorage.setItem('resqnet_self_node_name', nodeName)

  // Retrieve cached real GPS coordinates if available, otherwise default fallback
  const cachedLat = parseFloat(localStorage.getItem('resqnet_self_lat'))
  const cachedLng = parseFloat(localStorage.getItem('resqnet_self_lng'))

  let lat = !isNaN(cachedLat) ? cachedLat : 13.0827
  let lng = !isNaN(cachedLng) ? cachedLng : 80.2707

  return {
    id: nodeId,
    name: nodeName,
    lat: lat,
    lng: lng
  }
}

export const initMeshService = (onMessageCallback, username) => {
  onMessageReceivedCallback = onMessageCallback
  selfNode = generateSelfNode(username)

  // Connect WebSockets
  connectWebSocket()

  const handlePositionSuccess = (position) => {
    const actualLat = position.coords.latitude
    const actualLng = position.coords.longitude
    console.log(`ACTUAL GPS POSITION RESOLVED: Lat: ${actualLat}, Lng: ${actualLng}`)

    selfNode.lat = actualLat
    selfNode.lng = actualLng

    // Save position to localStorage
    localStorage.setItem('resqnet_self_lat', actualLat.toString())
    localStorage.setItem('resqnet_self_lng', actualLng.toString())

    // Persist and sync coordinates immediately
    upsertNodeLocally(selfNode)
    sendLocationBeacon()

    // Notify client app shell to update self node position and recenter leaflet map
    if (onMessageReceivedCallback) {
      onMessageReceivedCallback({
        type: 'GPS_BEACON',
        senderId: selfNode.id,
        name: selfNode.name,
        timestamp: Date.now(),
        lat: selfNode.lat,
        lng: selfNode.lng
      })
    }
  }

  // Request high-accuracy GPS coordinates via HTML5 Geolocation API
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      handlePositionSuccess,
      (error) => {
        console.warn('GPS query fallback: ', error.message)
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    )

    // Watch position for real-time movement updates
    watchId = navigator.geolocation.watchPosition(
      handlePositionSuccess,
      (error) => {},
      { enableHighAccuracy: true, maximumAge: 5000 }
    )
  }

  // Start periodic GPS Coordinate beacon broadcasting (every 15 seconds)
  startLocationBeacon()

  return {
    selfNode,
    close: () => {
      if (socket) socket.close()
      if (beaconTimer) clearInterval(beaconTimer)
      if (watchId !== null && navigator.geolocation) navigator.geolocation.clearWatch(watchId)
    },
    fetchHistory: async () => {
      try {
        const [msgsRes, nodesRes] = await Promise.all([
          fetch('http://localhost:8080/api/messages'),
          fetch('http://localhost:8080/api/nodes')
        ])

        const loadedMessages = msgsRes.ok ? await msgsRes.json() : []
        const loadedNodes = nodesRes.ok ? await nodesRes.json() : []

        return { loadedMessages, loadedNodes }
      } catch (e) {
        console.warn('API logs fetch failed, running in pure offline socket simulation: ', e)
        return { loadedMessages: [], loadedNodes: [] }
      }
    }
  }
}

const connectWebSocket = () => {
  try {
    socket = new WebSocket('ws://localhost:8080/ws-mesh')

    socket.onopen = () => {
      console.log('WS MESH PIPELINE ESTABLISHED')
      upsertNodeLocally(selfNode)
      sendLocationBeacon()
      if (onMessageReceivedCallback) {
        onMessageReceivedCallback({ type: 'CONNECTION_STATUS', connected: true })
      }
    }

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (onMessageReceivedCallback) {
          onMessageReceivedCallback(data)
        }
      } catch (e) {
        console.error('Failed to parse WS mesh frame: ', e)
      }
    }

    socket.onclose = () => {
      console.warn('WS MESH SOCKET CLOSED')
      if (onMessageReceivedCallback) {
        onMessageReceivedCallback({ type: 'CONNECTION_STATUS', connected: false })
      }
      
      // Only retry connection if at least one protocol is enabled
      if (activeProtocolsList.length > 0) {
        console.log('RETRYING WS MESH CONNECTION IN 5S...')
        setTimeout(connectWebSocket, 5000)
      }
    }

    socket.onerror = (e) => {
      console.error('WS MESH SOCKET ERROR: ', e)
    }
  } catch (e) {
    console.error('WS Connection failed: ', e)
  }
}

const startLocationBeacon = () => {
  if (beaconTimer) clearInterval(beaconTimer)
  beaconTimer = setInterval(() => {
    sendLocationBeacon()
  }, 15000)
}

const sendLocationBeacon = () => {
  if (!socket || socket.readyState !== WebSocket.OPEN || !selfNode) return

  const beacon = {
    type: 'GPS_BEACON',
    senderId: selfNode.id,
    name: selfNode.name,
    timestamp: Date.now(),
    lat: selfNode.lat,
    lng: selfNode.lng,
    ttl: 5,
    hops: 0
  }

  socket.send(JSON.stringify(beacon))
}

const upsertNodeLocally = async (node) => {
  try {
    await fetch('http://localhost:8080/api/nodes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(node)
    })
  } catch(e) {
    // Silently ignore if backend rest endpoint is starting up
  }
}

export const broadcastPayload = (payload) => {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(payload))
    // Also save directly to database logs
    fetch('http://localhost:8080/api/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).catch(() => {})
  } else {
    console.warn('Socket closed. Message deferred.')
  }
}

export const updateActiveProtocols = (protocols) => {
  activeProtocolsList = protocols || []
  if (activeProtocolsList.length === 0) {
    console.log('ALL PROTOCOLS DISABLED - DISCONNECTING FROM MESH')
    if (socket) {
      socket.close()
    }
    if (beaconTimer) {
      clearInterval(beaconTimer)
      beaconTimer = null
    }
  } else {
    console.log('PROTOCOLS ENABLED - CONNECTING TO MESH:', activeProtocolsList)
    if (!socket || socket.readyState === WebSocket.CLOSED || socket.readyState === WebSocket.CLOSING) {
      connectWebSocket()
    }
    startLocationBeacon()
  }
}
