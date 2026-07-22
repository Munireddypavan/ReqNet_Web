import React, { useState, useRef, useEffect } from 'react'
import { Megaphone, AlertTriangle, ShieldAlert } from 'lucide-react'

function BroadcastPanel({ onSendMessage, selfNode }) {
  const [msgText, setMsgText] = useState('')
  const [holdingButton, setHoldingButton] = useState(null) // 'sos' | 'auth'
  const [holdProgress, setHoldProgress] = useState(0) // 0 to 100
  const progressTimerRef = useRef(null)

  const handleStartHold = (e, type) => {
    if (e && e.cancelable) {
      e.preventDefault()
    }
    if (holdingButton) return
    setHoldingButton(type)
    setHoldProgress(0)
  }

  const handleEndHold = (e) => {
    if (e && e.cancelable) {
      e.preventDefault()
    }
    if (progressTimerRef.current) {
      clearInterval(progressTimerRef.current)
    }
    setHoldingButton(null)
    setHoldProgress(0)
  }

  useEffect(() => {
    if (holdingButton) {
      const step = 4 // step size in percent
      const interval = 120 // ms per step (approx 3 seconds total)
      
      progressTimerRef.current = setInterval(() => {
        setHoldProgress((prev) => {
          if (prev >= 100) {
            clearInterval(progressTimerRef.current)
            triggerBroadcast(holdingButton)
            return 0
          }
          return prev + step
        })
      }, interval)
    }

    return () => {
      if (progressTimerRef.current) {
        clearInterval(progressTimerRef.current)
      }
    }
  }, [holdingButton])

  const triggerBroadcast = (type) => {
    let text = msgText.trim() ? msgText.trim() : (type === 'sos' ? 'SOS EMERGENCY BROADCAST' : 'CRITICAL EMERGENCY WARNING')
    
    if (selfNode && selfNode.lat && selfNode.lng) {
      text += `\nLocation: Lat ${selfNode.lat.toFixed(6)}, Lng ${selfNode.lng.toFixed(6)}`
    }

    if (type === 'sos') {
      onSendMessage(`*** SOS ***\n${text}`, 'BROADCAST')
    } else if (type === 'auth') {
      onSendMessage(`*** DISPATCH EMERGENCY ***\n${text}`, 'AUTHORITIES')
    }

    setMsgText('')
    setHoldingButton(null)
    setHoldProgress(0)

    alert(`${type === 'sos' ? 'GLOBAL SOS' : 'AUTHORITIES'} broadcast alert successfully dispatched into local mesh network!`)
  }

  return (
    <div className="dashboard-panel" style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Panel Header */}
      <header className="panel-header">
        <h2 className="panel-title">
          <Megaphone size={16} />
          COMMS BROADCAST CENTER
        </h2>
      </header>

      {/* Panel Content */}
      <div className="panel-content sos-container">
        {/* Message Input Box */}
        <div>
          <textarea
            id="broadcast-input"
            value={msgText}
            onChange={(e) => setMsgText(e.target.value)}
            placeholder="Enter urgent broadcast message details..."
            className="input-box"
          />
        </div>

        {/* Hold Button Activators */}
        <div>
          <div className="sos-button-section">
            {/* GLOBAL SOS hold button */}
            <button
              id="sos-hold-button"
              className={`hold-button ${holdingButton === 'sos' ? 'holding' : ''}`}
              onMouseDown={(e) => handleStartHold(e, 'sos')}
              onMouseUp={(e) => handleEndHold(e)}
              onMouseLeave={(e) => handleEndHold(e)}
              onTouchStart={(e) => handleStartHold(e, 'sos')}
              onTouchEnd={(e) => handleEndHold(e)}
            >
              {holdingButton === 'sos' && (
                <div className="hold-progress-bar" style={{ height: `${holdProgress}%`, background: 'rgba(239, 83, 80, 0.2)' }} />
              )}
              <div className="hold-button-content">
                <AlertTriangle size={24} style={{ color: 'var(--error)' }} />
                <span className="hold-button-label" style={{ color: 'var(--error)' }}>
                  {holdingButton === 'sos' ? 'HOLDING...' : 'GLOBAL SOS'}
                </span>
              </div>
            </button>

            {/* AUTHORITIES hold button */}
            <button
              id="auth-hold-button"
              className={`hold-button ${holdingButton === 'auth' ? 'holding' : ''}`}
              onMouseDown={(e) => handleStartHold(e, 'auth')}
              onMouseUp={(e) => handleEndHold(e)}
              onMouseLeave={(e) => handleEndHold(e)}
              onTouchStart={(e) => handleStartHold(e, 'auth')}
              onTouchEnd={(e) => handleEndHold(e)}
            >
              {holdingButton === 'auth' && (
                <div className="hold-progress-bar" style={{ height: `${holdProgress}%`, background: 'rgba(255, 219, 60, 0.2)' }} />
              )}
              <div className="hold-button-content">
                <ShieldAlert size={24} style={{ color: 'var(--secondary-container)' }} />
                <span className="hold-button-label" style={{ color: 'var(--secondary-container)' }}>
                  {holdingButton === 'auth' ? 'HOLDING...' : 'AUTHORITIES'}
                </span>
              </div>
            </button>
          </div>

          <p style={{ fontSize: '10px', color: 'var(--outline)', textAlign: 'center', marginTop: '16px', fontWeight: '500' }}>
            Hold button click for 3s to initiate mesh network broadcast
          </p>
        </div>
      </div>
    </div>
  )
}

export default BroadcastPanel
