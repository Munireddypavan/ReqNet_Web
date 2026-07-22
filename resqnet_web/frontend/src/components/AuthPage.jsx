import React, { useState } from 'react'
import { Shield, Lock, Mail, User, Phone, ArrowRight, Activity } from 'lucide-react'

function AuthPage({ onAuthSuccess }) {
  const [isLogin, setIsLogin] = useState(true)
  const [formData, setFormData] = useState({
    fullName: '',
    username: '',
    email: '',
    password: '',
    phone: ''
  })
  const [errorMsg, setErrorMsg] = useState('')
  const [loading, setLoading] = useState(false)

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErrorMsg('')

    if (!isLogin) {
      if (!formData.email.endsWith('.com')) {
        setErrorMsg('Email must end with .com')
        return
      }
      if (formData.password.length < 6) {
        setErrorMsg('Password must contain at least 6 characters')
        return
      }
    }

    setLoading(true)

    const endpoint = isLogin ? 'http://localhost:8080/api/auth/login' : 'http://localhost:8080/api/auth/signup'
    const payload = isLogin
      ? { usernameOrEmail: formData.username, password: formData.password }
      : {
          fullName: formData.fullName,
          username: formData.username,
          email: formData.email,
          password: formData.password,
          phone: formData.phone
        }

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })

      const data = await res.json()
      if (!res.ok) {
        throw new Error(data.message || 'Authentication failed.')
      }

      // Success
      if (data.user) {
        localStorage.setItem('resqnet_user', JSON.stringify(data.user))
        onAuthSuccess(data.user)
      }
    } catch (err) {
      setErrorMsg(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      width: '100vw',
      backgroundColor: 'var(--background)',
      padding: '24px'
    }}>
      <div style={{
        width: '100%',
        maxWidth: '460px',
        backgroundColor: 'var(--surface)',
        border: '1px solid var(--surface-high)',
        borderRadius: '24px',
        padding: '36px 32px',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(10px)'
      }}>
        {/* Header Branding */}
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '56px',
            height: '56px',
            borderRadius: '16px',
            background: 'rgba(255, 86, 37, 0.15)',
            border: '1px solid var(--primary-container)',
            color: 'var(--primary)',
            marginBottom: '16px'
          }}>
            <Shield size={28} />
          </div>
          <h2 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '2px', textTransform: 'uppercase', color: 'var(--on-surface)' }}>
            RESQNET WEB
          </h2>
          <p style={{ fontSize: '12px', color: 'var(--outline)', marginTop: '6px', letterSpacing: '0.5px' }}>
            Tactical Mesh Operations Authentication
          </p>
        </div>

        {/* Tab Toggle Buttons */}
        <div style={{
          display: 'flex',
          background: 'var(--surface-lowest)',
          padding: '4px',
          borderRadius: '14px',
          marginBottom: '24px',
          border: '1px solid var(--surface-high)'
        }}>
          <button
            type="button"
            onClick={() => { setIsLogin(true); setErrorMsg(''); }}
            style={{
              flex: 1,
              padding: '10px',
              borderRadius: '10px',
              border: 'none',
              background: isLogin ? 'var(--surface-high)' : 'transparent',
              color: isLogin ? 'var(--primary)' : 'var(--outline)',
              fontWeight: '700',
              fontSize: '12px',
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
          >
            SIGN IN
          </button>
          <button
            type="button"
            onClick={() => { setIsLogin(false); setErrorMsg(''); }}
            style={{
              flex: 1,
              padding: '10px',
              borderRadius: '10px',
              border: 'none',
              background: !isLogin ? 'var(--surface-high)' : 'transparent',
              color: !isLogin ? 'var(--primary)' : 'var(--outline)',
              fontWeight: '700',
              fontSize: '12px',
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
          >
            CREATE ACCOUNT
          </button>
        </div>

        {/* Error Alert Box */}
        {errorMsg && (
          <div style={{
            background: 'rgba(255, 180, 171, 0.15)',
            border: '1px solid var(--error)',
            color: 'var(--error)',
            padding: '12px 16px',
            borderRadius: '12px',
            fontSize: '12px',
            marginBottom: '20px'
          }}>
            {errorMsg}
          </div>
        )}

        {/* Form Inputs */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {!isLogin && (
            <div>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', marginBottom: '6px' }}>
                FULL NAME
              </label>
              <div style={{ position: 'relative' }}>
                <User size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--outline)' }} />
                <input
                  type="text"
                  name="fullName"
                  placeholder="John Doe"
                  value={formData.fullName}
                  onChange={handleChange}
                  required={!isLogin}
                  className="input-box"
                  style={{ height: '44px', paddingLeft: '42px' }}
                />
              </div>
            </div>
          )}

          {!isLogin && (
            <div>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', marginBottom: '6px' }}>
                EMAIL ADDRESS
              </label>
              <div style={{ position: 'relative' }}>
                <Mail size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--outline)' }} />
                <input
                  type="email"
                  name="email"
                  placeholder="operator@resqnet.org"
                  value={formData.email}
                  onChange={handleChange}
                  required={!isLogin}
                  className="input-box"
                  style={{ height: '44px', paddingLeft: '42px' }}
                />
              </div>
            </div>
          )}

          <div>
            <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', marginBottom: '6px' }}>
              {isLogin ? 'USERNAME OR EMAIL' : 'USERNAME'}
            </label>
            <div style={{ position: 'relative' }}>
              <User size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--outline)' }} />
              <input
                type="text"
                name="username"
                placeholder={isLogin ? 'operator_1' : 'choose_username'}
                value={formData.username}
                onChange={handleChange}
                required
                className="input-box"
                style={{ height: '44px', paddingLeft: '42px' }}
              />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', marginBottom: '6px' }}>
              PASSWORD
            </label>
            <div style={{ position: 'relative' }}>
              <Lock size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--outline)' }} />
              <input
                type="password"
                name="password"
                placeholder="••••••••"
                value={formData.password}
                onChange={handleChange}
                required
                className="input-box"
                style={{ height: '44px', paddingLeft: '42px' }}
              />
            </div>
          </div>

          {!isLogin && (
            <div>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: 'var(--outline)', letterSpacing: '1px', marginBottom: '6px' }}>
                PHONE NUMBER
              </label>
              <div style={{ position: 'relative' }}>
                <Phone size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: 'var(--outline)' }} />
                <input
                  type="text"
                  name="phone"
                  placeholder="+91 9876543210"
                  value={formData.phone}
                  onChange={handleChange}
                  className="input-box"
                  style={{ height: '44px', paddingLeft: '42px' }}
                />
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{
              marginTop: '12px',
              height: '46px',
              background: 'var(--primary-container)',
              color: 'var(--on-primary-container)',
              border: 'none',
              borderRadius: '12px',
              fontWeight: '700',
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '10px',
              transition: 'var(--transition)'
            }}
          >
            {loading ? (
              <Activity size={18} className="logo-icon" />
            ) : (
              <>
                {isLogin ? 'LOGIN TO DASHBOARD' : 'REGISTER ACCOUNT'}
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  )
}

export default AuthPage
