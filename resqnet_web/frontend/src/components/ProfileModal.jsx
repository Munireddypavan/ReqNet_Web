import React, { useState } from 'react'
import { User, Mail, Phone, Lock, Save, X, Activity } from 'lucide-react'

function ProfileModal({ user, onClose, onUpdateSuccess }) {
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

      setTimeout(() => {
        onClose()
      }, 1500)
    } catch (err) {
      setErrorMsg(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.7)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 9999,
      backdropFilter: 'blur(4px)'
    }}>
      <div style={{
        width: '100%',
        maxWidth: '480px',
        backgroundColor: 'var(--surface)',
        border: '1px solid var(--surface-high)',
        borderRadius: '20px',
        padding: '30px',
        boxShadow: '0 24px 48px rgba(0, 0, 0, 0.8)',
        position: 'relative'
      }}>
        {/* Close Button */}
        <button
          onClick={onClose}
          style={{
            position: 'absolute',
            top: '20px',
            right: '20px',
            background: 'transparent',
            border: 'none',
            color: 'var(--outline)',
            cursor: 'pointer',
            padding: '4px'
          }}
        >
          <X size={20} />
        </button>

        {/* Modal Title */}
        <h3 style={{
          fontSize: '18px',
          fontWeight: '700',
          letterSpacing: '1px',
          color: 'var(--on-surface)',
          textTransform: 'uppercase',
          marginBottom: '24px',
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          <User size={18} style={{ color: 'var(--primary)' }} />
          Edit Profile
        </h3>

        {/* Feedback Messages */}
        {successMsg && (
          <div style={{
            background: 'rgba(76, 175, 80, 0.15)',
            border: '1px solid #4caf50',
            color: '#4caf50',
            padding: '10px 14px',
            borderRadius: '10px',
            fontSize: '12px',
            fontWeight: '600',
            marginBottom: '16px'
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
            fontWeight: '600',
            marginBottom: '16px'
          }}>
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
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

          {/* Password (Optional change) */}
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

export default ProfileModal
