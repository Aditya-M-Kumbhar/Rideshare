import pool from '../db.js';

// WHAT: Calls sp_start_trip to transition a scheduled ride into an active live trip.
// WHY: Centralizes trip lifecycle changes in a transactional procedure.
export async function startTrip(req, res) {
  try {
    const rideId = parseInt(req.params.id, 10);
    const driverId = req.user ? req.user.userId : parseInt(req.body.driverId, 10);

    const [result] = await pool.query(
      `CALL sp_start_trip(?, ?, @out_trip_id);
       SELECT @out_trip_id AS trip_id;`,
      [rideId, driverId]
    );

    const outSet = Array.isArray(result) && result.length > 1 ? result[1] : result;
    const tripId = outSet[0]?.trip_id;

    res.json({ message: 'Trip started successfully!', tripId });
  } catch (err) {
    console.error('Start trip error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
}

// WHAT: Calls sp_complete_trip to conclude the journey and generate pending payment rows.
// WHY: Atomically calculates final split costs and logs trip completion to the audit log.
export async function completeTrip(req, res) {
  try {
    const tripId = parseInt(req.params.id, 10);
    const driverId = req.user ? req.user.userId : parseInt(req.body.driverId, 10);
    const { distanceKm = 10.0 } = req.body;

    await pool.query(
      `CALL sp_complete_trip(?, ?, ?)`,
      [tripId, driverId, parseFloat(distanceKm)]
    );

    res.json({ message: 'Trip completed! Payments generated for all passengers.' });
  } catch (err) {
    console.error('Complete trip error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
}

// WHAT: Fetches all rides offered by user (as driver) and all bookings requested by user (as rider).
// WHY: Powers the unified "My Trips" dashboard with trip, payment, and rating status.
export async function getMyTrips(req, res) {
  try {
    const userId = req.user ? req.user.userId : parseInt(req.query.userId, 10);
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required.' });
    }

    // 1. Rides offered by this user (if driver)
    const [offeredRides] = await pool.query(
      `SELECT r.ride_id, r.departure_time, r.status AS ride_status, r.seats_offered,
              r.seats_available, r.estimated_fare, r.notes,
              loc_from.name AS pickup_name, loc_to.name AS destination_name,
              t.trip_id, t.status AS trip_status, t.distance_km, t.fare_per_person,
              COUNT(DISTINCT req.request_id) AS total_requests,
              SUM(CASE WHEN req.status = 'ACCEPTED' THEN 1 ELSE 0 END) AS accepted_count
       FROM RIDE_POST r
       JOIN LOCATION loc_from ON r.pickup_location_id = loc_from.location_id
       JOIN LOCATION loc_to ON r.destination_location_id = loc_to.location_id
       LEFT JOIN TRIP t ON r.ride_id = t.ride_id
       LEFT JOIN RIDE_REQUEST req ON r.ride_id = req.ride_id
       WHERE r.driver_id = ?
       GROUP BY r.ride_id, loc_from.name, loc_to.name, t.trip_id, t.status, t.distance_km, t.fare_per_person
       ORDER BY r.departure_time DESC`,
      [userId]
    );

    // 2. Fetch requests for the driver's active rides so driver can accept/reject
    const rideIds = offeredRides.map(r => r.ride_id);
    let driverRequests = [];
    if (rideIds.length > 0) {
      const [requests] = await pool.query(
        `SELECT req.request_id, req.ride_id, req.rider_id, req.seats_requested, req.message,
                req.fare_share, req.status AS request_status, req.request_time,
                CONCAT(u.first_name, ' ', u.last_name) AS rider_name,
                u.is_verified AS rider_verified,
                s.program AS student_program, c.name AS college_name
         FROM RIDE_REQUEST req
         JOIN USER u ON req.rider_id = u.user_id
         LEFT JOIN STUDENT s ON u.user_id = s.user_id
         LEFT JOIN COLLEGE c ON s.college_id = c.college_id
         WHERE req.ride_id IN (?)
         ORDER BY req.request_time DESC`,
        [rideIds]
      );
      driverRequests = requests;
    }

    // 3. Rides booked by this user (as passenger)
    const [bookedRides] = await pool.query(
      `SELECT req.request_id, req.ride_id, req.seats_requested, req.fare_share,
              req.status AS request_status, req.request_time, req.message,
              r.departure_time, r.status AS ride_status,
              loc_from.name AS pickup_name, loc_to.name AS destination_name,
              CONCAT(u.first_name, ' ', u.last_name) AS driver_name,
              u.user_id AS driver_user_id,
              u.is_verified AS driver_verified,
              d.average_rating AS driver_rating,
              t.trip_id, t.status AS trip_status,
              p.payment_id, p.status AS payment_status, p.amount AS payment_amount,
              rat.rating_id AS my_rating_id, rat.score AS my_rating_score
       FROM RIDE_REQUEST req
       JOIN RIDE_POST r ON req.ride_id = r.ride_id
       JOIN USER u ON r.driver_id = u.user_id
       JOIN DRIVER d ON u.user_id = d.user_id
       JOIN LOCATION loc_from ON r.pickup_location_id = loc_from.location_id
       JOIN LOCATION loc_to ON r.destination_location_id = loc_to.location_id
       LEFT JOIN TRIP t ON r.ride_id = t.ride_id
       LEFT JOIN PAYMENT p ON t.trip_id = p.trip_id AND p.rider_id = req.rider_id
       LEFT JOIN RATING rat ON t.trip_id = rat.trip_id AND rat.rater_user_id = req.rider_id
       WHERE req.rider_id = ?
       ORDER BY req.request_time DESC`,
      [userId]
    );

    res.json({
      offeredRides,
      driverRequests,
      bookedRides
    });
  } catch (err) {
    console.error('My trips error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Calls sp_process_payment to settle outstanding passenger dues.
// WHY: Ensures safe payment updates with transaction references.
export async function payTrip(req, res) {
  try {
    const paymentId = parseInt(req.params.id, 10);
    const riderId = req.user ? req.user.userId : parseInt(req.body.riderId, 10);
    const { method = 'UPI', reference = `TXN-MANUAL-${Date.now()}` } = req.body;

    await pool.query(
      `CALL sp_process_payment(?, ?, ?, ?)`,
      [paymentId, riderId, method, reference]
    );

    res.json({ message: 'Payment successfully processed!' });
  } catch (err) {
    console.error('Payment error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
}

// WHAT: Calls sp_submit_rating to review a driver or passenger after trip completion.
// WHY: Fires trg_update_driver_rating_after_insert to maintain real-time average star ratings.
export async function submitRating(req, res) {
  try {
    const raterUserId = req.user ? req.user.userId : parseInt(req.body.raterUserId, 10);
    const { tripId, rateeUserId, score, comment = '' } = req.body;

    if (!tripId || !raterUserId || !rateeUserId || !score) {
      return res.status(400).json({ error: 'Missing required rating parameters.' });
    }

    const [result] = await pool.query(
      `CALL sp_submit_rating(?, ?, ?, ?, ?, @out_rating_id);
       SELECT @out_rating_id AS rating_id;`,
      [parseInt(tripId, 10), raterUserId, parseInt(rateeUserId, 10), parseInt(score, 10), comment]
    );

    const outSet = Array.isArray(result) && result.length > 1 ? result[1] : result;
    const ratingId = outSet[0]?.rating_id;

    res.status(201).json({ message: 'Rating submitted successfully!', ratingId });
  } catch (err) {
    console.error('Submit rating error:', err);
    res.status(400).json({ error: err.sqlMessage || err.message });
  }
}
