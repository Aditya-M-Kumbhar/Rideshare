import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { ArrowRight, Clock, ShieldCheck, Check, X, Play, CheckCircle, CreditCard, Star } from 'lucide-react';

export default function MyTripsPage() {
  const { currentUser } = useAuth();
  const [activeTab, setActiveTab] = useState('offered'); // 'offered' | 'booked'
  const [tripsData, setTripsData] = useState({ offeredRides: [], driverRequests: [], bookedRides: [] });
  const [loading, setLoading] = useState(true);
  const [actionError, setActionError] = useState(null);
  const [actionSuccess, setActionSuccess] = useState(null);

  // Rating modal state
  const [ratingModal, setRatingModal] = useState(null); // { tripId, rateeUserId, rateeName }
  const [ratingScore, setRatingScore] = useState(5);
  const [ratingComment, setRatingComment] = useState('');

  // Complete trip modal state
  const [completeModal, setCompleteModal] = useState(null); // { tripId, rideId }
  const [distanceKm, setDistanceKm] = useState('12.5');

  const fetchTrips = () => {
    if (!currentUser) return;
    setLoading(true);
    fetch(`/api/my-trips?userId=${currentUser.userId}`, {
      headers: { 'x-user-id': currentUser.userId }
    })
      .then(res => res.json())
      .then(data => {
        setTripsData(data);
        setLoading(false);
      })
      .catch(err => {
        setActionError('Failed to load trips data.');
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchTrips();
  }, [currentUser]);

  // Handle Driver: Accept Request
  const handleAcceptRequest = async (requestId) => {
    setActionError(null);
    try {
      const res = await fetch(`/api/requests/${requestId}/accept`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({ driverId: currentUser.userId })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess('Request accepted! Seat count decremented via pessimistic row lock.');
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  // Handle Driver: Reject Request
  const handleRejectRequest = async (requestId) => {
    setActionError(null);
    try {
      const res = await fetch(`/api/requests/${requestId}/reject`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({ driverId: currentUser.userId })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess('Request rejected.');
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  // Handle Driver: Start Trip
  const handleStartTrip = async (rideId) => {
    setActionError(null);
    try {
      const res = await fetch(`/api/trips/${rideId}/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({ driverId: currentUser.userId })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess(`Trip #${data.tripId} started! Status changed to IN_PROGRESS.`);
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  // Handle Driver: Complete Trip
  const handleCompleteTrip = async (e) => {
    e.preventDefault();
    if (!completeModal) return;
    setActionError(null);
    try {
      const res = await fetch(`/api/trips/${completeModal.tripId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({ driverId: currentUser.userId, distanceKm: parseFloat(distanceKm) })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess('Trip completed! Calculated split fares and inserted payment rows for all riders.');
      setCompleteModal(null);
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  // Handle Passenger: Pay
  const handlePay = async (paymentId) => {
    setActionError(null);
    try {
      const res = await fetch(`/api/payments/${paymentId}/pay`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({ riderId: currentUser.userId, method: 'UPI' })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess('Payment of fare share settled via UPI!');
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  // Handle Mutual Rating
  const handleSubmitRating = async (e) => {
    e.preventDefault();
    if (!ratingModal) return;
    setActionError(null);
    try {
      const res = await fetch('/api/ratings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': currentUser.userId },
        body: JSON.stringify({
          tripId: ratingModal.tripId,
          raterUserId: currentUser.userId,
          rateeUserId: ratingModal.rateeUserId,
          score: parseInt(ratingScore, 10),
          comment: ratingComment
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setActionSuccess('Rating submitted! Driver average rating updated via trg_update_driver_rating_after_insert.');
      setRatingModal(null);
      setRatingComment('');
      fetchTrips();
    } catch (err) {
      setActionError(err.message);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">My Rides & Bookings</h1>
        <p className="page-subtitle">
          Manage your offered carpools, approve rider requests, track payments, and review mutual ratings.
        </p>
      </div>

      {actionSuccess && (
        <div className="alert alert-success" style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span>{actionSuccess}</span>
          <button onClick={() => setActionSuccess(null)}>✕</button>
        </div>
      )}
      {actionError && (
        <div className="alert alert-error" style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span>{actionError}</span>
          <button onClick={() => setActionError(null)}>✕</button>
        </div>
      )}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
        <button
          className={`btn ${activeTab === 'offered' ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setActiveTab('offered')}
        >
          Rides I Offer ({tripsData.offeredRides.length})
        </button>
        <button
          className={`btn ${activeTab === 'booked' ? 'btn-primary' : 'btn-secondary'}`}
          onClick={() => setActiveTab('booked')}
        >
          My Passenger Bookings ({tripsData.bookedRides.length})
        </button>
      </div>

      {loading ? (
        <div style={{ padding: '40px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
          Loading your trips from MySQL...
        </div>
      ) : activeTab === 'offered' ? (
        /* Driver View */
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {tripsData.offeredRides.length === 0 ? (
            <div className="card" style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
              You haven't scheduled any rides as driver yet. Click "Offer a ride" above to post your daily commute!
            </div>
          ) : (
            tripsData.offeredRides.map(ride => {
              const pendingRequests = tripsData.driverRequests.filter(
                req => req.ride_id === ride.ride_id && req.request_status === 'PENDING'
              );
              const acceptedRequests = tripsData.driverRequests.filter(
                req => req.ride_id === ride.ride_id && req.request_status === 'ACCEPTED'
              );

              return (
                <div key={ride.ride_id} className="card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 10, marginBottom: 12 }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 16, fontWeight: 600 }}>
                        <span>{ride.pickup_name}</span>
                        <ArrowRight size={15} color="var(--text-muted)" />
                        <span>{ride.destination_name}</span>
                        <span className="badge badge-neutral">Ride #{ride.ride_id}</span>
                        <span className={`badge ${ride.ride_status === 'OPEN' ? 'badge-verified' : 'badge-neutral'}`}>
                          {ride.ride_status}
                        </span>
                        {ride.trip_status && (
                          <span className="badge badge-verified" style={{ background: '#E2F0D9', color: '#385723' }}>
                            Trip: {ride.trip_status}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>
                        Departs: {new Date(ride.departure_time).toLocaleString()} • {ride.seats_available} of {ride.seats_offered} seats available • Fare: ₹{Math.round(ride.estimated_fare)}
                      </div>
                    </div>

                    {/* Driver Actions */}
                    <div style={{ display: 'flex', gap: 8 }}>
                      {!ride.trip_id && ride.ride_status !== 'COMPLETED' && ride.ride_status !== 'CANCELLED' && (
                        <button
                          className="btn btn-secondary btn-sm"
                          onClick={() => handleStartTrip(ride.ride_id)}
                          title="Invokes sp_start_trip procedure"
                        >
                          <Play size={13} /> Start Trip
                        </button>
                      )}

                      {ride.trip_id && ride.trip_status === 'IN_PROGRESS' && (
                        <button
                          className="btn btn-primary btn-sm"
                          onClick={() => setCompleteModal({ tripId: ride.trip_id, rideId: ride.ride_id })}
                          title="Invokes sp_complete_trip procedure"
                        >
                          <CheckCircle size={13} /> Complete Trip
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Pending Passenger Requests for this ride */}
                  {pendingRequests.length > 0 && (
                    <div style={{ marginTop: 14, paddingTop: 14, borderTop: '1px solid var(--border-light)' }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 8 }}>
                        Pending Passenger Requests ({pendingRequests.length}):
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                        {pendingRequests.map(req => (
                          <div key={req.request_id} style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            background: 'var(--bg-muted)',
                            padding: '10px 14px',
                            borderRadius: 'var(--radius-md)'
                          }}>
                            <div>
                              <div style={{ fontWeight: 500, fontSize: 13.5 }}>
                                {req.rider_name} ({req.college_name || 'Student'})
                                <span style={{ marginLeft: 8, fontSize: 12, color: 'var(--text-secondary)' }}>
                                  requested {req.seats_requested} seat(s) • Share: ₹{Math.round(req.fare_share)}
                                </span>
                              </div>
                              {req.message && (
                                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontStyle: 'italic', marginTop: 2 }}>
                                  "{req.message}"
                                </div>
                              )}
                            </div>
                            <div style={{ display: 'flex', gap: 8 }}>
                              <button
                                className="btn btn-secondary btn-sm"
                                onClick={() => handleRejectRequest(req.request_id)}
                              >
                                <X size={13} /> Reject
                              </button>
                              <button
                                className="btn btn-primary btn-sm"
                                onClick={() => handleAcceptRequest(req.request_id)}
                              >
                                <Check size={13} /> Accept (Pessimistic Lock)
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Confirmed passengers */}
                  {acceptedRequests.length > 0 && (
                    <div style={{ marginTop: 10, fontSize: 12.5, color: 'var(--text-secondary)' }}>
                      <strong>Confirmed Passengers:</strong> {acceptedRequests.map(a => a.rider_name).join(', ')}
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      ) : (
        /* Passenger View */
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {tripsData.bookedRides.length === 0 ? (
            <div className="card" style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-secondary)' }}>
              You haven't requested any seats yet. Head to "Find a ride" to book upcoming campus carpools!
            </div>
          ) : (
            tripsData.bookedRides.map(booking => (
              <div key={booking.request_id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 14 }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 15, fontWeight: 600 }}>
                    <span>{booking.pickup_name}</span>
                    <ArrowRight size={14} color="var(--text-muted)" />
                    <span>{booking.destination_name}</span>
                    <span className={`badge ${
                      booking.request_status === 'ACCEPTED' ? 'badge-verified' :
                      booking.request_status === 'PENDING' ? 'badge-unverified' : 'badge-neutral'
                    }`}>
                      Request: {booking.request_status}
                    </span>
                  </div>
                  <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>
                    Driver: {booking.driver_name} • Departs: {new Date(booking.departure_time).toLocaleString()} • Share: ₹{Math.round(booking.fare_share)}
                  </div>
                </div>

                {/* Passenger Actions */}
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  {/* Payment Action */}
                  {booking.payment_id && booking.payment_status === 'PENDING' && (
                    <button
                      className="btn btn-primary btn-sm"
                      onClick={() => handlePay(booking.payment_id)}
                    >
                      <CreditCard size={13} /> Pay ₹{Math.round(booking.payment_amount)}
                    </button>
                  )}

                  {booking.payment_id && booking.payment_status === 'COMPLETED' && (
                    <span className="badge badge-verified">
                      Paid ₹{Math.round(booking.payment_amount)}
                    </span>
                  )}

                  {/* Rating Action */}
                  {booking.trip_status === 'COMPLETED' && !booking.my_rating_id && (
                    <button
                      className="btn btn-secondary btn-sm"
                      onClick={() => setRatingModal({
                        tripId: booking.trip_id,
                        rateeUserId: booking.driver_user_id,
                        rateeName: booking.driver_name
                      })}
                    >
                      <Star size={13} /> Rate Driver
                    </button>
                  )}

                  {booking.my_rating_id && (
                    <span className="badge badge-verified">
                      Rated ★ {booking.my_rating_score}
                    </span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Complete Trip Modal */}
      {completeModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card" style={{ maxWidth: 420, width: '100%', background: '#fff' }}>
            <h2 className="card-title">Complete Trip #{completeModal.tripId}</h2>
            <form onSubmit={handleCompleteTrip} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div className="form-group">
                <label className="form-label">Total Actual Odometer Distance (KM)</label>
                <input
                  type="number"
                  step="0.1"
                  min="0.5"
                  value={distanceKm}
                  onChange={e => setDistanceKm(e.target.value)}
                  required
                />
                <span className="form-hint">
                  The procedure will divide total fuel cost among confirmed riders and create payment liabilities.
                </span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 10 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setCompleteModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Complete Trip</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Submit Rating Modal */}
      {ratingModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="card" style={{ maxWidth: 420, width: '100%', background: '#fff' }}>
            <h2 className="card-title">Rate {ratingModal.rateeName}</h2>
            <form onSubmit={handleSubmitRating} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div className="form-group">
                <label className="form-label">Score (1 to 5 Stars)</label>
                <select value={ratingScore} onChange={e => setRatingScore(e.target.value)}>
                  <option value="5">5 Stars — Excellent & Safe</option>
                  <option value="4">4 Stars — Good Ride</option>
                  <option value="3">3 Stars — Average</option>
                  <option value="2">2 Stars — Below Expectations</option>
                  <option value="1">1 Star — Poor Experience</option>
                </select>
              </div>
              <div className="form-group">
                <label className="form-label">Feedback Comment</label>
                <input
                  type="text"
                  placeholder="e.g. Very punctual and smooth driving."
                  value={ratingComment}
                  onChange={e => setRatingComment(e.target.value)}
                  maxLength={200}
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 10 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setRatingModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Submit Rating</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
