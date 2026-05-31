let socket = null
let onMessageReceivedCallback = null
let selfNode = null
let beaconTimer = null

// Generate a deterministic and stable unique device mock name and coordinates offset
const generateSelfNode = () => {
  const randId = Math.random().toString(36).substring(2, 8)
  const nodeId = `web-node-${randId}`
  
  // Resolve browser brand name
  let browserName = 'Web Browser Node'
  const userAgent = navigator.userAgent
  if (userAgent.indexOf('Chrome') > -1) browserName = 'Chrome Web'
  else if (userAgent.indexOf('Safari') > -1) browserName = 'Safari Web'
  else if (userAgent.indexOf('Firefox') > -1) browserName = 'Firefox Web'

  // Standard seed coordinates: Chennai, India (local context fallback)
  let lat = 13.0827
  let lng = 80.2707

  // Apply a small stable coordinate offset so multiple browser tabs don't overlap
  const hash = nodeId.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
  const offsetLat = (hash % 100 - 50) * 0.00005
  const offsetLng = (hash % 100 - 50) * 0.00005
  
  return {
    id: nodeId,
    name: `${browserName} (${randId.toUpperCase()})`,
    lat: lat + offsetLat,
    lng: lng + offsetLng
  }
}

export const initMeshService = (onMessageCallback) => {
  onMessageReceivedCallback = onMessageCallback
  selfNode = generateSelfNode()

  // Connect WebSockets
  connectWebSocket()

  // Attempt to fetch actual real-world GPS coordinates via HTML5 Geolocation API
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const actualLat = position.coords.latitude
        const actualLng = position.coords.longitude
        console.log(`ACTUAL GPS POSITION RESOLVED: Lat: ${actualLat}, Lng: ${actualLng}`)

        const hash = selfNode.id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
        const offsetLat = (hash % 100 - 50) * 0.00005
        const offsetLng = (hash % 100 - 50) * 0.00005

        selfNode.lat = actualLat + offsetLat
        selfNode.lng = actualLng + offsetLng

        // Persist and sync coordinates immediately
        upsertNodeLocally(selfNode)
        sendLocationBeacon()

        // Notify client app shell to immediately recenter the leaflet viewport
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
      },
      (error) => {
        console.warn('GPS query denied/failed, utilizing standard India fallback beacon coordinates: ', error.message)
      },
      { enableHighAccuracy: true, timeout: 5000 }
    )
  }

  // Start periodic GPS Coordinate beacon broadcasting (every 15 seconds)
  startLocationBeacon()

  return {
    selfNode,
    close: () => {
      if (socket) socket.close()
      if (beaconTimer) clearInterval(beaconTimer)
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
      // Immediately send our details to the REST db and broadcast first beacon
      upsertNodeLocally(selfNode)
      sendLocationBeacon()
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
      console.warn('WS MESH SOCKET CLOSED - RETRYING IN 5S...')
      setTimeout(connectWebSocket, 5000)
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
