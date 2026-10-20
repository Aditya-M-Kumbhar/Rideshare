import pool from '../db.js';

// WHAT: Returns all carpooling communities (General and College-specific).
// WHY: Populates community selection dropdowns for ride searching and offering.
export async function getCommunities(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT community_id, name, type, college_id, description FROM COMMUNITY ORDER BY community_id ASC`
    );
    res.json(rows);
  } catch (err) {
    console.error('Fetch communities error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Returns geographic locations, metro stations, gates, and campus hubs.
// WHY: Supplies origin and destination pickers with address and coordinates.
export async function getLocations(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT location_id, name, type, address, latitude, longitude FROM LOCATION ORDER BY name ASC`
    );
    res.json(rows);
  } catch (err) {
    console.error('Fetch locations error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Returns participating colleges and universities.
// WHY: Powers campus registration and student profile displays.
export async function getColleges(req, res) {
  try {
    const [rows] = await pool.query(`SELECT * FROM COLLEGE ORDER BY name ASC`);
    res.json(rows);
  } catch (err) {
    console.error('Fetch colleges error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Returns vehicles owned by the logged-in driver.
// WHY: Lets drivers choose which of their registered vehicles they are taking on a ride.
export async function getMyVehicles(req, res) {
  try {
    const driverId = req.user ? req.user.userId : parseInt(req.query.driverId, 10);
    if (!driverId) {
      return res.status(400).json({ error: 'Driver ID required.' });
    }

    const [rows] = await pool.query(
      `SELECT vehicle_id, plate_no, vehicle_type, make, model, color, capacity
       FROM VEHICLE
       WHERE driver_id = ?`,
      [driverId]
    );
    res.json(rows);
  } catch (err) {
    console.error('Fetch vehicles error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Returns user notifications dispatched by triggers or system events.
// WHY: Feeds the notification center and top navbar bell badge.
export async function getNotifications(req, res) {
  try {
    const userId = req.user ? req.user.userId : parseInt(req.query.userId, 10);
    if (!userId) {
      return res.status(400).json({ error: 'User ID required.' });
    }

    const [rows] = await pool.query(
      `SELECT notification_id, type, message, read_status, sent_at
       FROM NOTIFICATION
       WHERE user_id = ?
       ORDER BY sent_at DESC LIMIT 30`,
      [userId]
    );
    res.json(rows);
  } catch (err) {
    console.error('Fetch notifications error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Marks a single notification as read.
// WHY: Clears the unread status badge in the UI.
export async function markNotificationRead(req, res) {
  try {
    const notifId = parseInt(req.params.id, 10);
    await pool.query(
      `UPDATE NOTIFICATION SET read_status = TRUE WHERE notification_id = ?`,
      [notifId]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Mark read error:', err);
    res.status(500).json({ error: err.message });
  }
}

// WHAT: Queries vw_driver_leaderboard to show top campus drivers.
// WHY: Highlights campus carpooling leaders and proves analytical view querying.
export async function getLeaderboard(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM vw_driver_leaderboard ORDER BY average_rating DESC, total_trips_completed DESC LIMIT 10`
    );
    res.json(rows);
  } catch (err) {
    console.error('Fetch leaderboard error:', err);
    res.status(500).json({ error: err.message });
  }
}
