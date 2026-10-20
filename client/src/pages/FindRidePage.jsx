import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { ArrowRight, Clock, Users, ShieldCheck, ShieldAlert, Sparkles, Filter, CheckCircle2 } from 'lucide-react';

export default function FindRidePage() {
  const { currentUser } = useAuth();
  const [rides, setRides] = useState([]);
  const [communities, setCommunities] = useState([]);
  const [locations, setLocations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [successMsg, setSuccessMsg] = useState(null);

  // Filter state
  const [communityId, setCommunityId] = useState('ALL');
  const [pickupId, setPickupId] = useState('0');
  const [destinationId, setDestinationId] = useState('0');
  const [date, setDate] = useState('');

  // Request modal state
  const [activeRideForRequest, setActiveRideForRequest] = useState(null);
  const [seatsRequested, setSeatsRequested] = useState(1);
  const [requestMessage, setRequestMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Fetch initial dropdown references
  useEffect(() => {
    Promise.all([
      fetch('/api/communities').then(r => r.json()),
      fetch('/api/locations').then(r => r.json())
    ])
      .then(([commData, locData]) => {
        if (Array.isArray(commData)) setCommunities(commData);
        if (Array.isArray(locData)) setLocations(locData);
      })
      .catch(err => console.error('Error fetching references:', err));
  }, []);

  // Fetch rides whenever filters change
  const fetchRides = () => {
    setLoading(true);
    setError(null);
    let url = `/api/rides?communityId=${communityId}&pickupId=${pickupId}&destinationId=${destinationId}`;
    if (date) url += `&date=${date}`;

    fetch(url)
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          setRides(data);
        } else {
          setError(data.error || 'Failed to load rides.');
        }
        setLoading(false);
      })
      .catch(err => {
        setError('Cannot reach server. Please ensure database and server are running.');
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchRides();
  }, [communityId, pickupId, destinationId, date]);

  // Submit seat request
  const handleSubmitRequest = async (e) => {
    e.preventDefault();
    if (!activeRideForRequest) return;
    setSubmitting(true);
    setError(null);

    try {
      const res = await fetch(`/api/rides/${activeRideForRequest.ride_id}/request`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': currentUser.userId
        },
        body: JSON.stringify({
          riderId: currentUser.userId,
          seatsRequested,
          message: requestMessage
        })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Request submission failed.');
      }

      setSuccessMsg(`Request sent for Ride #${activeRideForRequest.ride_id}! The driver has been notified via database trigger.`);
      setActiveRideForRequest(null);
      setRequestMessage('');
      setSeatsRequested(1);
      fetchRides();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <h1 className="page-title">Available Campus Pools</h1>
        <p className="page-subtitle">
          Search daily rides shared by verified university peers. ID masking and college tags protect your privacy.
        </p>
      </div>

      {/* Alerts */}
      {successMsg && (
        <div className="alert alert-success" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>{successMsg}</span>
          <button onClick={() => setSuccessMsg(null)} style={{ fontWeight: 600 }}>✕</button>
        </div>
      )}
      {error && (
        <div className="alert alert-error" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>{error}</span>
          <button onClick={() => setError(null)} style={{ fontWeight: 600 }}>✕</button>
        </div>
      )}

      {/* Filter Toolbar */}
      <div className="card" style={{ marginBottom: 20, padding: '16px 20px' }}>
        <div className="form-grid">
          <div className="form-group">
            <label className="form-label">Community Filter</label>
            <select value={communityId} onChange={e => setCommunityId(e.target.value)}>
              <option value="ALL">All Communities (Open & Campus)</option>
              {communities.map(c => (
                <option key={c.community_id} value={c.community_id}>
                  {c.name} ({c.type})
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Pickup Location</label>
            <select value={pickupId} onChange={e => setPickupId(e.target.value)}>
              <option value="0">Any Origin / Gate</option>
              {locations.map(l => (
                <option key={l.location_id} value={l.location_id}>
                  {l.name}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Destination Location</label>
            <select value={destinationId} onChange={e => setDestinationId(e.target.value)}>
              <option value="0">Any Destination / Campus</option>
              {locations.map(l => (
                <option key={l.location_id} value={l.location_id}>
                  {l.name}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Departure Date</label>
            <input 
              type="date" 
              value={date} 
              onChange={e => setDate(e.target.value)} 
            />
          </div>
        </div>
      </div>

      {/* Ride Results Listing */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
          Querying vw_available_rides view...
        </div>
      ) : rides.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '50px 20px', color: 'var(--text-secondary)' }}>
          <p style={{ fontWeight: 500, fontSize: 16, marginBottom: 6 }}>No upcoming rides match your filter criteria.</p>
          <p style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            Try selecting "All Communities" or choose different pickup/dropoff points.
          </p>
        </div>
      ) : (
        <div className="ride-list">
          {rides.map(ride => {
            const isSelf = currentUser && currentUser.userId === ride.driver_id;
            return (
              <div key={ride.ride_id} className="ride-row">
                {/* Route Information */}
                <div className="ride-route-info">
                  <div className="ride-route-title">
                    <span>{ride.pickup_name}</span>
                    <ArrowRight size={15} color="var(--text-muted)" />
                    <span>{ride.destination_name}</span>
                  </div>
                  <div className="ride-meta-line">
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <Clock size={13} color="var(--text-muted)" />
                      {new Date(ride.departure_time).toLocaleString('en-IN', {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </span>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <Users size={13} color="var(--text-muted)" />
                      <strong>{ride.seats_available}</strong> of {ride.seats_offered} seats left
                    </span>
                    <span className="badge badge-community">
                      {ride.community_name}
                    </span>
                    {ride.notes && (
                      <span style={{ fontStyle: 'italic', fontSize: 12 }}>
                        "{ride.notes}"
                      </span>
                    )}
                  </div>
                </div>

                {/* Driver Identity (Masked & Verified) */}
                <div className="ride-driver-info">
                  <div className="driver-avatar-circle">
                    {ride.driver_name.charAt(0)}
                  </div>
                  <div className="driver-text">
                    <div className="driver-name-line">
                      <span>{ride.driver_name}</span>
                      {ride.driver_verified ? (
                        <span className="badge badge-verified">
                          <ShieldCheck size={11} /> Verified
                        </span>
                      ) : (
                        <span className="badge badge-unverified">
                          <ShieldAlert size={11} /> Unverified
                        </span>
                      )}
                    </div>
                    <div className="driver-subline">
                      {ride.vehicle_model} • Plate: <code style={{ fontFamily: 'var(--font-mono)' }}>{ride.masked_plate_no}</code> • ★ {parseFloat(ride.driver_rating).toFixed(1)}
                    </div>
                  </div>
                </div>

                {/* Pricing & Booking Action */}
                <div className="ride-action-box">
                  <div>
                    <div className="price-tag">₹{Math.round(ride.estimated_fare)}</div>
                    <span className="price-unit">per person</span>
                  </div>

                  {isSelf ? (
                    <span className="badge badge-neutral" style={{ padding: '6px 10px' }}>
                      Your Ride Offer
                    </span>
                  ) : ride.seats_available <= 0 ? (
                    <span className="badge badge-unverified" style={{ padding: '6px 10px' }}>
                      Full
                    </span>
                  ) : (
                    <button
                      className="btn btn-primary"
                      onClick={() => setActiveRideForRequest(ride)}
                    >
                      Request Seat
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Booking Modal */}
      {activeRideForRequest && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.4)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000,
          padding: 20
        }}>
          <div className="card" style={{ maxWidth: 440, width: '100%', background: '#fff' }}>
            <h2 className="card-title" style={{ fontSize: 17, marginBottom: 8 }}>
              Request Seats on Ride #{activeRideForRequest.ride_id}
            </h2>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
              Route: <strong>{activeRideForRequest.pickup_name}</strong> to <strong>{activeRideForRequest.destination_name}</strong>
              <br />
              Driver: {activeRideForRequest.driver_name} ({activeRideForRequest.masked_plate_no})
            </p>

            <form onSubmit={handleSubmitRequest} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div className="form-group">
                <label className="form-label">Number of Seats (Max: {activeRideForRequest.seats_available})</label>
                <input
                  type="number"
                  min="1"
                  max={activeRideForRequest.seats_available}
                  value={seatsRequested}
                  onChange={e => setSeatsRequested(Math.max(1, parseInt(e.target.value || 1, 10)))}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Note for Driver (Optional)</label>
                <input
                  type="text"
                  placeholder="e.g. Carrying a backpack, waiting at gate 1"
                  value={requestMessage}
                  onChange={e => setRequestMessage(e.target.value)}
                  maxLength={200}
                />
              </div>

              <div style={{
                background: 'var(--bg-muted)',
                padding: '10px 12px',
                borderRadius: 'var(--radius-md)',
                fontSize: 13,
                color: 'var(--text-secondary)'
              }}>
                Total estimated share: <strong style={{ color: 'var(--text-primary)', fontSize: 15 }}>₹{Math.round(activeRideForRequest.estimated_fare * seatsRequested)}</strong>
                <div style={{ fontSize: 11, marginTop: 2 }}>
                  * Split equally with driver upon trip completion.
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 6 }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setActiveRideForRequest(null)}
                  disabled={submitting}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={submitting}
                >
                  {submitting ? 'Submitting to MySQL...' : 'Confirm Request'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
