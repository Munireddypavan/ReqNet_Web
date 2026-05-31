import React, { useState, useRef, useEffect } from 'react'
import { Megaphone, AlertTriangle, ShieldAlert } from 'lucide-react'

function BroadcastPanel({ onSendMessage }) {
  const [msgText, setMsgText] = useState('')
  const [holdingButton, setHoldingButton] = useState(null) // 'sos' | 'auth'
  const [holdProgress, setHoldProgress] = useState(0) // 0 to 100
  const progressTimerRef = useRef(null)

  const handleStartHold = (type) => {
    setHoldingButton(type)
    setHoldProgress(0)
  }

  const handleEndHold = () => {
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
    const text = msgText.trim() ? msgText.trim() : (type === 'sos' ? 'SOS EMERGENCY BROADCAST' : 'CRITICAL EMERGENCY WARNING')
    
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
    <div className="dashboard-panel" style={{ width: '400px', height: '40%', display: 'flex', flexDirection: 'column' }}>
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
              className={`hold-button ${holdingButton === 'sos' ? 'holding' : ''}`}
              onMouseDown={() => handleStartHold('sos')}
              onMouseUp={handleEndHold}
              onMouseLeave={handleEndHold}
              onTouchStart={() => handleStartHold('sos')}
              onTouchEnd={handleEndHold}
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
              className={`hold-button ${holdingButton === 'auth' ? 'holding' : ''}`}
              onMouseDown={() => handleStartHold('auth')}
              onMouseUp={handleEndHold}
              onMouseLeave={handleEndHold}
              onTouchStart={() => handleStartHold('auth')}
              onTouchEnd={handleEndHold}
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
