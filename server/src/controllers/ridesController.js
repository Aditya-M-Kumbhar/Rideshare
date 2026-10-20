import pool from '../db.js';

// WHAT: Queries vw_available_rides view with dynamic filters (community, origin, destination, date).
// WHY: Pure SELECT from a high-performance database view without application-level joins.
export async function searchRides(req, res) {
  try {
    const { communityId, pickupId, destinationId, date, minSeats } = req.query;

    let query = `SELECT * FROM vw_available_rides WHERE ride_status = 'OPEN' AND departure_time >= NOW()`;
    const params = [];

    if (communityId && communityId !== 'ALL' && communityId !== '0') {
      query += ` AND (community_id = ? OR community_type = 'GENERAL')`;
      params.push(parseInt(communityId, 10));
    }

    if (pickupId && pickupId !== '0') {
      query += ` AND pickup_location_id = ?`;
      params.push(parseInt(pickupId, 10));
    }

    if (destinationId && destinationId !== '0') {
      query += ` AND destination_location_id = ?`;
      params.push(parseInt(destinationId, 10));
    }

    if (date) {
      query += ` AND DATE(departure_time) = ?`;
      params.push(date);
    }

    if (minSeats) {
      query += ` AND seats_available >= ?`;
      params.push(parseInt(minSeats, 10));
    }

    query += ` ORDER BY departure_time ASC LIMIT 50`;

    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    console.error('Ride search error:', err);
    res.status(500).json({ error: err.message || 'Failed to search rides.' });
  }
}

// WHAT: Retrieves single ride post and its sequence of waypoints from RIDE_STOP.
// WHY: Displays full route itinerary for riders inspecting a trip.
export async function getRideDetails(req, res) {
  try {
    const rideId = parseInt(req.params.id, 10);

    const [rides] = await pool.query(
      `SELECT * FROM vw_available_rides WHERE ride_id = ?`,
      [rideId]
    );

    if (rides.length === 0) {
      return res.status(404).json({ error: 'Ride not found.' });
    }

    const [stops] = await pool.query(
      `SELECT s.sequence_no, s.stop_type, s.expected_time, loc.name AS stop_name, loc.address
       FROM RIDE_STOP s
       JOIN LOCATION loc ON s.location_id = loc.location_id
       WHERE s.ride_id = ?
       ORDER BY s.sequence_no ASC`,
      [rideId]
    );

    res.json({
      ...rides[0],
      stops
    });
  } catch (err) {
    console.error('Ride details error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Calls the transactional stored procedure sp_create_ride to schedule a ride offer.
// WHY: Offloads vehicle ownership checks, seat boundary enforcement, and table inserts strictly to MySQL.
export async function createRide(req, res) {
  try {
    const driverId = req.user ? req.user.userId : parseInt(req.body.driverId, 10);
    const {
      vehicleId,
      pickupLocationId,
      destinationLocationId,
      communityId = 1,
      departureTime,
      seatsOffered,
      estimatedFare,
      notes = ''
    } = req.body;

    if (!driverId || !vehicleId || !pickupLocationId || !destinationLocationId || !departureTime || !seatsOffered || !estimatedFare) {
      return res.status(400).json({ error: 'Missing required ride parameters.' });
    }

    // Call stored procedure sp_create_ride with OUT parameter
    const [result] = await pool.query(
      `CALL sp_create_ride(?, ?, ?, ?, ?, ?, ?, ?, ?, @out_ride_id);
       SELECT @out_ride_id AS ride_id;`,
      [
        driverId,
        parseInt(vehicleId, 10),
        parseInt(pickupLocationId, 10),
        parseInt(destinationLocationId, 10),
        communityId ? parseInt(communityId, 10) : null,
        departureTime,
        parseInt(seatsOffered, 10),
        parseFloat(estimatedFare),
        notes
      ]
    );

    // Multiple statements return an array of result sets; second query is the SELECT @out_ride_id
    const outSet = Array.isArray(result) && result.length > 1 ? result[1] : result;
    const newRideId = outSet[0]?.ride_id;

    res.status(201).json({
      message: 'Ride offered successfully!',
      rideId: newRideId
    });
  } catch (err) {
    console.error('Create ride error:', err);
    // MySQL SIGNAL error message extraction
    const msg = err.sqlMessage || err.message || 'Failed to create ride offer.';
    res.status(400).json({ error: msg });
  }
}
