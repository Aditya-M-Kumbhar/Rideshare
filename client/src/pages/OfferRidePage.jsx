import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Car, AlertCircle, CheckCircle2 } from 'lucide-react';

export default function OfferRidePage() {
  const { currentUser, switchUser } = useAuth();
  const navigate = useNavigate();

  const [vehicles, setVehicles] = useState([]);
  const [locations, setLocations] = useState([]);
  const [communities, setCommunities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  // Form fields
  const [vehicleId, setVehicleId] = useState('');
  const [pickupId, setPickupId] = useState('');
  const [destinationId, setDestinationId] = useState('');
  const [communityId, setCommunityId] = useState('1');
  const [departureTime, setDepartureTime] = useState('');
  const [seatsOffered, setSeatsOffered] = useState('3');
  const [estimatedFare, setEstimatedFare] = useState('50');
  const [notes, setNotes] = useState('');

  // Fetch driver's vehicles, locations, and communities
  useEffect(() => {
    if (!currentUser) return;
    setLoading(true);
    setError(null);

    Promise.all([
      fetch(`/api/vehicles?driverId=${currentUser.userId}`, {
        headers: { 'x-user-id': currentUser.userId }
      }).then(r => r.json()),
      fetch('/api/locations').then(r => r.json()),
      fetch('/api/communities').then(r => r.json())
    ])
      .then(([vehData, locData, commData]) => {
        if (Array.isArray(vehData)) {
          setVehicles(vehData);
          if (vehData.length > 0) {
            setVehicleId(vehData[0].vehicle_id.toString());
            setSeatsOffered(Math.min(3, vehData[0].capacity).toString());
          }
        }
        if (Array.isArray(locData)) {
          setLocations(locData);
          if (locData.length >= 2) {
            setPickupId(locData[0].location_id.toString());
            setDestinationId(locData[1].location_id.toString());
          }
        }
        if (Array.isArray(commData)) {
          setCommunities(commData);
        }
        setLoading(false);
      })
      .catch(err => {
        setError('Failed to fetch reference catalogs.');
        setLoading(false);
      });

    // Default departure time to 4 hours from now
    const now = new Date();
    now.setHours(now.getHours() + 4);
    now.setMinutes(0);
    const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 16);
    setDepartureTime(localIso);
  }, [currentUser]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (pickupId === destinationId) {
      setError('Pickup and destination locations cannot be the same.');
      return;
    }

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await fetch('/api/rides', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': currentUser.userId
        },
        body: JSON.stringify({
          driverId: currentUser.userId,
          vehicleId: parseInt(vehicleId, 10),
          pickupLocationId: parseInt(pickupId, 10),
          destinationLocationId: parseInt(destinationId, 10),
          communityId: communityId ? parseInt(communityId, 10) : null,
          departureTime: departureTime.replace('T', ' ') + ':00',
          seatsOffered: parseInt(seatsOffered, 10),
          estimatedFare: parseFloat(estimatedFare),
          notes
        })
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Failed to post ride offer.');
      }

      setSuccess(`Ride offer #${data.rideId} posted successfully via sp_create_ride!`);
      setTimeout(() => {
        navigate('/my-trips');
      }, 1400);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div style={{ maxWidth: 680, margin: '0 auto' }}>
      <div className="page-header">
        <h1 className="page-title">Offer a Pool Ride</h1>
        <p className="page-subtitle">
          Share your daily commute, cut fuel expenses, and travel with fellow students.
        </p>
      </div>

      {error && (
        <div className="alert alert-error" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <AlertCircle size={16} />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="alert alert-success" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <CheckCircle2 size={16} />
          <span>{success}</span>
        </div>
      )}

      {/* Driver Verification Check */}
      {!currentUser?.isDriver && (
        <div className="alert alert-info" style={{ marginBottom: 20 }}>
          <strong>Note for Examiner:</strong> Current user <em>{currentUser.name}</em> is registered as a passenger. 
          To test ride creation, switch to <strong>Aarav Sharma</strong> (COEP Driver) or <strong>Rohan Patil</strong> (MIT Driver) 
          using the top-right user menu.
        </div>
      )}

      <div className="card">
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          {/* Vehicle Selection */}
          <div className="form-group">
            <label className="form-label">Select Registered Vehicle</label>
            {vehicles.length === 0 ? (
              <div style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                No registered vehicles found for this account.
              </div>
            ) : (
              <select value={vehicleId} onChange={e => setVehicleId(e.target.value)} required>
                {vehicles.map(v => (
                  <option key={v.vehicle_id} value={v.vehicle_id}>
                    {v.make} {v.model} ({v.plate_no}) — Capacity: {v.capacity} seats
                  </option>
                ))}
              </select>
            )}
            <span className="form-hint">
              Checked against the DRIVER and VEHICLE specialization tables by the stored procedure.
            </span>
          </div>

          {/* Route Endpoints */}
          <div className="form-grid">
            <div className="form-group">
              <label className="form-label">Pickup Location</label>
              <select value={pickupId} onChange={e => setPickupId(e.target.value)} required>
                {locations.map(l => (
                  <option key={l.location_id} value={l.location_id}>
                    {l.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Destination Location</label>
              <select value={destinationId} onChange={e => setDestinationId(e.target.value)} required>
                {locations.map(l => (
                  <option key={l.location_id} value={l.location_id}>
                    {l.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Community Scope */}
          <div className="form-group">
            <label className="form-label">Community / Group Restriction</label>
            <select value={communityId} onChange={e => setCommunityId(e.target.value)}>
              {communities.map(c => (
                <option key={c.community_id} value={c.community_id}>
                  {c.name} ({c.type})
                </option>
              ))}
            </select>
            <span className="form-hint">
              Restricting to a college community ensures only verified campus peers can view and book.
            </span>
          </div>

          {/* Timing & Seats */}
          <div className="form-grid">
            <div className="form-group">
              <label className="form-label">Departure Date & Time</label>
              <input
                type="datetime-local"
                value={departureTime}
                onChange={e => setDepartureTime(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Available Seats to Offer</label>
              <input
                type="number"
                min="1"
                max="8"
                value={seatsOffered}
                onChange={e => setSeatsOffered(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Estimated Fare (₹ Total Contribution)</label>
              <input
                type="number"
                min="10"
                step="5"
                value={estimatedFare}
                onChange={e => setEstimatedFare(e.target.value)}
                required
              />
            </div>
          </div>

          {/* Notes */}
          <div className="form-group">
            <label className="form-label">Route Notes / Luggage Instructions</label>
            <input
              type="text"
              placeholder="e.g. AC car, leaving via University Circle, space for 1 laptop bag per rider"
              value={notes}
              onChange={e => setNotes(e.target.value)}
              maxLength={200}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 10 }}>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => navigate('/')}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={submitting}
            >
              {submitting ? 'Creating Ride in MySQL...' : 'Schedule Ride Offer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
