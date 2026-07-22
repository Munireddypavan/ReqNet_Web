import React, { useState } from 'react'
import { User, Mail, Phone, Lock, Save, Activity } from 'lucide-react'

function ProfilePanel({ user, onUpdateSuccess }) {
  const [formData, setFormData] = useState({
    fullName: user.fullName || '',
    email: user.email || '',
    phone: user.phone || '',
    password: ''
  })
  const [loading, setLoading] = useState(false)
  const [successMsg, setSuccessMsg] = useState('')
  const [errorMsg, setErrorMsg] = useState('')

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setSuccessMsg('')
    setErrorMsg('')

    try {
      const res = await fetch('http://localhost:8080/api/auth/profile', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: user.username,
          fullName: formData.fullName,
          email: formData.email,
          phone: formData.phone,
          password: formData.password
        })
      })

      const data = await res.json()
      if (!res.ok) {
        throw new Error(data.message || 'Failed to update profile.')
      }

      setSuccessMsg(data.message || 'Profile updated successfully!')
      localStorage.setItem('resqnet_user', JSON.stringify(data.user))
      onUpdateSuccess(data.user)
      
      // Clear password field after success
      setFormData(prev => ({ ...prev, password: '' }))
    } catch (err) {
      setErrorMsg(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="dashboard-panel" style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Panel Header */}
      <header className="panel-header">
        <h2 className="panel-title">
          <User size={16} />
          TACTICAL OPERATOR PROFILE
        </h2>
        <div style={{ fontSize: '10px', color: 'var(--outline)', fontWeight: 'bold', letterSpacing: '0.8px' }}>
          USER DETAILS
        </div>
      </header>

      {/* Content */}
      <div className="panel-content" style={{ display: 'flex', flexDirection: 'column', gap: '24px', maxWidth: '600px', margin: '0 auto', width: '100%', padding: '40px 20px' }}>
        <div>
          <span style={{ fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', textTransform: 'uppercase' }}>
            OPERATOR IDENTIFIER
          </span>
          <h3 style={{ fontSize: '32px', fontWeight: '300', letterSpacing: '-0.5px', marginTop: '4px', textTransform: 'uppercase', color: 'var(--on-surface)' }}>
            {user.username.toUpperCase()}
          </h3>
          <p style={{ fontSize: '10px', color: 'var(--outline)', marginTop: '4px', letterSpacing: '0.5px' }}>
            Registered: {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : 'N/A'}
          </p>
        </div>

        {/* Feedback Messages */}
        {successMsg && (
          <div style={{
            background: 'rgba(76, 175, 80, 0.15)',
            border: '1px solid #4caf50',
            color: '#4caf50',
            padding: '10px 14px',
            borderRadius: '10px',
            fontSize: '12px',
            fontWeight: '600'
          }}>
            {successMsg}
          </div>
        )}

        {errorMsg && (
          <div style={{
            background: 'rgba(255, 180, 171, 0.15)',
            border: '1px solid var(--error)',
            color: 'var(--error)',
            padding: '10px 14px',
            borderRadius: '10px',
            fontSize: '12px',
            fontWeight: '600'
          }}>
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* Full Name */}
          <div>
            <label style={{ display: 'block', fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '0.8px', marginBottom: '6px' }}>
              FULL NAME
            </label>
            <div style={{ position: 'relative' }}>
              <User size={14} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--outline)' }} />
              <input
                type="text"
                name="fullName"
                value={formData.fullName}
                onChange={handleChange}
                className="input-box"
                style={{ height: '38px', paddingLeft: '38px', fontSize: '12px' }}
              />
            </div>
          </div>

          {/* Email */}
          <div>
            <label style={{ display: 'block', fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '0.8px', marginBottom: '6px' }}>
              EMAIL ADDRESS
            </label>
            <div style={{ position: 'relative' }}>
              <Mail size={14} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--outline)' }} />
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                required
                className="input-box"
                style={{ height: '38px', paddingLeft: '38px', fontSize: '12px' }}
              />
            </div>
          </div>

          {/* Phone Number */}
          <div>
            <label style={{ display: 'block', fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '0.8px', marginBottom: '6px' }}>
              PHONE NUMBER
            </label>
            <div style={{ position: 'relative' }}>
              <Phone size={14} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--outline)' }} />
              <input
                type="text"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                className="input-box"
                style={{ height: '38px', paddingLeft: '38px', fontSize: '12px' }}
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <label style={{ display: 'block', fontSize: '9px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '0.8px', marginBottom: '6px' }}>
              NEW PASSWORD (LEAVE EMPTY TO KEEP CURRENT)
            </label>
            <div style={{ position: 'relative' }}>
              <Lock size={14} style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--outline)' }} />
              <input
                type="password"
                name="password"
                placeholder="Enter new password"
                value={formData.password}
                onChange={handleChange}
                className="input-box"
                style={{ height: '38px', paddingLeft: '38px', fontSize: '12px' }}
              />
            </div>
          </div>

          {/* Save Button */}
          <button
            type="submit"
            disabled={loading}
            style={{
              marginTop: '10px',
              height: '40px',
              background: 'var(--primary-container)',
              color: 'var(--on-primary-container)',
              border: 'none',
              borderRadius: '10px',
              fontWeight: '700',
              fontSize: '12px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              transition: 'var(--transition)'
            }}
          >
            {loading ? (
              <Activity size={16} className="logo-icon" />
            ) : (
              <>
                <Save size={14} />
                Save Changes
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  )
}

export default ProfilePanel
