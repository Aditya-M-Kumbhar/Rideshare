import pool from '../db.js';

// WHAT: Invokes stored procedure sp_request_seat to book a seat on a ride.
// WHY: Ensures fare split calculation and prevents self-booking or overbooking via trigger/procedure.
export async function requestSeat(req, res) {
  try {
    const rideId = parseInt(req.params.id, 10);
    const riderId = req.user ? req.user.userId : parseInt(req.body.riderId, 10);
    const { seatsRequested = 1, message = '' } = req.body;

    if (!rideId || !riderId) {
      return res.status(400).json({ error: 'Ride ID and Rider ID are required.' });
    }

    const [result] = await pool.query(
      `CALL sp_request_seat(?, ?, ?, ?, @out_req_id);
       SELECT @out_req_id AS request_id;`,
      [rideId, riderId, parseInt(seatsRequested, 10), message]
    );

    const outSet = Array.isArray(result) && result.length > 1 ? result[1] : result;
    const newRequestId = outSet[0]?.request_id;

    res.status(201).json({
      message: 'Seat request submitted successfully!',
      requestId: newRequestId
    });
  } catch (err) {
    console.error('Seat request error:', err);
    const msg = err.sqlMessage || err.message || 'Failed to submit seat request.';
    res.status(400).json({ error: msg });
  }
}

// WHAT: Calls sp_accept_request which uses pessimistic locking (SELECT ... FOR UPDATE) to approve a seat.
// WHY: Guarantees concurrency safety during peak booking times directly inside MySQL.
export async function acceptRequest(req, res) {
  try {
    const requestId = parseInt(req.params.id, 10);
    const driverId = req.user ? req.user.userId : parseInt(req.body.driverId, 10);

    if (!requestId || !driverId) {
      return res.status(400).json({ error: 'Request ID and Driver authorization required.' });
    }

    await pool.query(`CALL sp_accept_request(?, ?)`, [requestId, driverId]);

    res.json({ message: 'Request accepted successfully! Seat reserved.' });
  } catch (err) {
    console.error('Accept request error:', err);
    const msg = err.sqlMessage || err.message || 'Failed to accept request.';
    res.status(400).json({ error: msg });
  }
}

// WHAT: Invokes sp_reject_request to decline a pending passenger request.
// WHY: Enforces driver authorization checks inside the stored procedure.
export async function rejectRequest(req, res) {
  try {
    const requestId = parseInt(req.params.id, 10);
    const driverId = req.user ? req.user.userId : parseInt(req.body.driverId, 10);

    if (!requestId || !driverId) {
      return res.status(400).json({ error: 'Request ID and Driver authorization required.' });
    }

    await pool.query(`CALL sp_reject_request(?, ?)`, [requestId, driverId]);

    res.json({ message: 'Request has been rejected.' });
  } catch (err) {
    console.error('Reject request error:', err);
    const msg = err.sqlMessage || err.message || 'Failed to decline request.';
    res.status(400).json({ error: msg });
  }
}

// WHAT: Cancels a user request. If previously ACCEPTED, trigger trg_restore_seats_on_cancel restores the seat.
// WHY: Demonstrates self-healing reactive database trigger execution.
export async function cancelRequest(req, res) {
  try {
    const requestId = parseInt(req.params.id, 10);
    const riderId = req.user ? req.user.userId : parseInt(req.body.riderId, 10);

    const [rows] = await pool.query(
      `SELECT rider_id, status FROM RIDE_REQUEST WHERE request_id = ?`,
      [requestId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Request not found.' });
    }

    if (rows[0].rider_id !== riderId) {
      return res.status(403).json({ error: 'Unauthorized to cancel this request.' });
    }

    await pool.query(
      `UPDATE RIDE_REQUEST SET status = 'CANCELLED' WHERE request_id = ?`,
      [requestId]
    );

    res.json({ message: 'Request cancelled successfully.' });
  } catch (err) {
    console.error('Cancel request error:', err);
    res.status(500).json({ error: err.message });
  }
}
