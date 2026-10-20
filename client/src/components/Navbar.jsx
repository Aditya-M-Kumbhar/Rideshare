import React, { useState, useEffect } from 'react';
import { NavLink, Link } from 'react-router-dom';
import { useAuth, DEMO_USERS } from '../context/AuthContext';
import { Car, Bell, UserCheck, ShieldCheck, ShieldAlert, ChevronDown } from 'lucide-react';

export default function Navbar() {
  const { currentUser, switchUser } = useAuth();
  const [unreadCount, setUnreadCount] = useState(0);
  const [showUserMenu, setShowUserMenu] = useState(false);

  useEffect(() => {
    if (!currentUser) return;
    fetch(`/api/notifications?userId=${currentUser.userId}`, {
      headers: { 'x-user-id': currentUser.userId }
    })
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          const unread = data.filter(n => !n.read_status).length;
          setUnreadCount(unread);
        }
      })
      .catch(() => {});
  }, [currentUser]);

  return (
    <nav className="top-nav">
      <div className="nav-container">
        {/* Brand */}
        <Link to="/" className="brand">
          <Car size={20} color="var(--accent-primary)" />
          <span>CampusPool</span>
          <span className="brand-badge">MySQL 8</span>
        </Link>

        {/* Navigation Tabs */}
        <div className="nav-links">
          <NavLink to="/" end className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            Find a ride
          </NavLink>
          <NavLink to="/offer" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            Offer a ride
          </NavLink>
          <NavLink to="/my-trips" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            My trips
          </NavLink>
          <NavLink to="/notifications" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            Alerts
            {unreadCount > 0 && (
              <span style={{
                marginLeft: 5,
                background: 'var(--accent-primary)',
                color: '#fff',
                fontSize: 10,
                padding: '1px 5px',
                borderRadius: 10
              }}>
                {unreadCount}
              </span>
            )}
          </NavLink>
          <NavLink to="/profile" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            Profile
          </NavLink>
          <NavLink to="/dbms-showcase" className={({ isActive }) => `nav-link showcase-tab ${isActive ? 'active' : ''}`}>
            DBMS Showcase
          </NavLink>
        </div>

        {/* Right User Bar with Quick Role Switcher */}
        <div className="nav-right" style={{ position: 'relative' }}>
          <button 
            className="user-pill"
            onClick={() => setShowUserMenu(!showUserMenu)}
            title="Click to toggle test users for examiner demo"
          >
            {currentUser?.isVerified ? (
              <span className="badge badge-verified" style={{ padding: '2px 4px' }}>
                <ShieldCheck size={12} />
              </span>
            ) : (
              <span className="badge badge-unverified" style={{ padding: '2px 4px' }}>
                <ShieldAlert size={12} />
              </span>
            )}
            <span style={{ fontWeight: 500 }}>{currentUser?.name}</span>
            <ChevronDown size={14} color="var(--text-muted)" />
          </button>

          {/* Quick Demo User Dropdown */}
          {showUserMenu && (
            <div style={{
              position: 'absolute',
              top: '110%',
              right: 0,
              background: '#fff',
              border: '1px solid var(--border-color)',
              borderRadius: 'var(--radius-md)',
              boxShadow: 'var(--shadow-dropdown)',
              width: 250,
              zIndex: 100,
              padding: 6
            }}>
              <div style={{ padding: '6px 10px', fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>
                Switch Demo User (Viva Testing)
              </div>
              {DEMO_USERS.map(u => (
                <button
                  key={u.userId}
                  onClick={() => {
                    switchUser(u);
                    setShowUserMenu(false);
                  }}
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'flex-start',
                    width: '100%',
                    padding: '8px 10px',
                    borderRadius: 'var(--radius-sm)',
                    background: currentUser?.userId === u.userId ? 'var(--bg-muted)' : 'transparent',
                    textAlign: 'left'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, width: '100%', justifyContent: 'space-between' }}>
                    <span style={{ fontWeight: 500, fontSize: 13 }}>{u.name}</span>
                    <span className={`badge ${u.isVerified ? 'badge-verified' : 'badge-unverified'}`} style={{ fontSize: 10 }}>
                      {u.isVerified ? 'Verified' : 'Unverified'}
                    </span>
                  </div>
                  <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                    {u.roleLabel} • {u.college}
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </nav>
  );
}
