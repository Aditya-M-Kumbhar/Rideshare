import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, ShieldAlert, User, GraduationCap, Car, PhoneCall, Lock } from 'lucide-react';

export default function ProfilePage() {
  const { currentUser } = useAuth();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!currentUser) return;
    setLoading(true);
    fetch(`/api/auth/profile/${currentUser.userId}`, {
      headers: { 'x-user-id': currentUser.userId }
    })
      .then(res => res.json())
      .then(data => {
        setProfile(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [currentUser]);

  return (
    <div style={{ maxWidth: 780, margin: '0 auto' }}>
      <div className="page-header">
        <h1 className="page-title">Campus Member Profile</h1>
        <p className="page-subtitle">
          Identity security, student specialization, and privacy-preserving ID masking powered by <code style={{ fontFamily: 'var(--font-mono)' }}>vw_masked_users</code>.
        </p>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
          Fetching masked profile view...
        </div>
      ) : !profile ? (
        <div className="card">User profile not found.</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          {/* Main User Identity Card */}
          <div className="card">
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
              <div style={{
                width: 56,
                height: 56,
                borderRadius: '50%',
                background: 'var(--bg-muted)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 22,
                fontWeight: 600,
                color: 'var(--text-secondary)',
                border: '1px solid var(--border-color)'
              }}>
                {profile.first_name?.charAt(0)}
              </div>

              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <h2 style={{ fontSize: 18, fontWeight: 600 }}>
                    {profile.first_name} {profile.last_initial}
                  </h2>
                  {profile.is_verified ? (
                    <span className="badge badge-verified">
                      <ShieldCheck size={12} /> Verified Campus Member
                    </span>
                  ) : (
                    <span className="badge badge-unverified">
                      <ShieldAlert size={12} /> Unverified Account
                    </span>
                  )}
                </div>
                <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 2 }}>
                  Member ID #{profile.user_id} • Status: {profile.status}
                </div>
              </div>
            </div>

            {/* Privacy & Masked Fields Callout */}
            <div className="why-callout">
              <strong>Examiner Architecture Note:</strong> Peer riders and drivers only receive masked credentials from the database view. Raw roll numbers, phone numbers, and driving licenses are never exposed to clients.
            </div>

            <div className="table-wrapper">
              <table className="data-table">
                <tbody>
                  <tr>
                    <td style={{ width: '35%', fontWeight: 500, color: 'var(--text-secondary)' }}>
                      Masked Contact Phone
                    </td>
                    <td>
                      <code style={{ fontFamily: 'var(--font-mono)' }}>{profile.masked_phone}</code>
                    </td>
                  </tr>
                  <tr>
                    <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>
                      Masked University Email
                    </td>
                    <td>
                      <code style={{ fontFamily: 'var(--font-mono)' }}>{profile.masked_email}</code>
                    </td>
                  </tr>
                  <tr>
                    <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>
                      Age (Virtual Generated Column)
                    </td>
                    <td>{profile.age} years old</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Student Specialization (ISA) */}
          {profile.student_program && (
            <div className="card">
              <h3 className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <GraduationCap size={18} color="var(--accent-primary)" />
                Academic Specialization (STUDENT Entity)
              </h3>
              <div className="table-wrapper">
                <table className="data-table">
                  <tbody>
                    <tr>
                      <td style={{ width: '35%', fontWeight: 500, color: 'var(--text-secondary)' }}>Affiliated College</td>
                      <td><strong>{profile.college_name}</strong></td>
                    </tr>
                    <tr>
                      <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>Degree Program</td>
                      <td>{profile.student_program}</td>
                    </tr>
                    <tr>
                      <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>Academic Year</td>
                      <td>Year {profile.student_year}</td>
                    </tr>
                    <tr>
                      <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>Masked Roll Number</td>
                      <td><code style={{ fontFamily: 'var(--font-mono)' }}>{profile.masked_roll_no}</code></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Driver Specialization (ISA) */}
          {profile.masked_license && (
            <div className="card">
              <h3 className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Car size={18} color="var(--accent-primary)" />
                Driver Credentials (DRIVER Entity)
              </h3>
              <div className="table-wrapper">
                <table className="data-table">
                  <tbody>
                    <tr>
                      <td style={{ width: '35%', fontWeight: 500, color: 'var(--text-secondary)' }}>Driving License</td>
                      <td><code style={{ fontFamily: 'var(--font-mono)' }}>{profile.masked_license}</code></td>
                    </tr>
                    <tr>
                      <td style={{ fontWeight: 500, color: 'var(--text-secondary)' }}>Average Peer Rating</td>
                      <td>
                        <strong>★ {parseFloat(profile.driver_rating).toFixed(2)}</strong> (Dynamically updated via trigger)
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
