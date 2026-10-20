import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { testConnection } from './db.js';
import { authenticateToken, optionalAuth } from './middleware/auth.js';

import { login, register, getProfile } from './controllers/authController.js';
import { searchRides, getRideDetails, createRide } from './controllers/ridesController.js';
import { requestSeat, acceptRequest, rejectRequest, cancelRequest } from './controllers/requestsController.js';
import { startTrip, completeTrip, getMyTrips, payTrip, submitRating } from './controllers/tripsController.js';
import {
  getCommunities,
  getLocations,
  getColleges,
  getMyVehicles,
  getNotifications,
  markNotificationRead,
  getLeaderboard
} from './controllers/referenceController.js';
import { getShowcaseList, executeShowcaseQuery } from './controllers/dbmsShowcaseController.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const CLIENT_URL = process.env.CLIENT_URL || 'http://localhost:5173';

// Middleware
app.use(cors({
  origin: [CLIENT_URL, 'http://localhost:5173', 'http://localhost:3000'],
  credentials: true
}));
app.use(express.json());

// Health & Diagnostic Check
app.get('/api/health', async (req, res) => {
  const dbStatus = await testConnection();
  res.json({
    status: 'online',
    timestamp: new Date().toISOString(),
    database: dbStatus
  });
});

// Authentication Routes
app.post('/api/auth/login', login);
app.post('/api/auth/register', register);
app.get('/api/auth/profile/:id?', optionalAuth, getProfile);

// Reference / Catalogs
app.get('/api/communities', getCommunities);
app.get('/api/locations', getLocations);
app.get('/api/colleges', getColleges);
app.get('/api/vehicles', optionalAuth, getMyVehicles);
app.get('/api/leaderboard', getLeaderboard);
app.get('/api/notifications', optionalAuth, getNotifications);
app.put('/api/notifications/:id/read', optionalAuth, markNotificationRead);

// Rides Endpoints
app.get('/api/rides', searchRides);
app.get('/api/rides/:id', getRideDetails);
app.post('/api/rides', optionalAuth, createRide);

// Seat Requests Endpoints
app.post('/api/rides/:id/request', optionalAuth, requestSeat);
app.post('/api/requests/:id/accept', optionalAuth, acceptRequest);
app.post('/api/requests/:id/reject', optionalAuth, rejectRequest);
app.post('/api/requests/:id/cancel', optionalAuth, cancelRequest);

// Trips & Settlements
app.post('/api/trips/:id/start', optionalAuth, startTrip);
app.post('/api/trips/:id/complete', optionalAuth, completeTrip);
app.get('/api/my-trips', optionalAuth, getMyTrips);
app.post('/api/payments/:id/pay', optionalAuth, payTrip);
app.post('/api/ratings', optionalAuth, submitRating);

// DBMS Showcase Endpoints (Viva Demonstration Suite)
app.get('/api/dbms/queries', getShowcaseList);
app.post('/api/dbms/execute', executeShowcaseQuery);

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('Unhandled API Error:', err);
  res.status(500).json({ error: err.message || 'Internal server error.' });
});

app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` CampusPool Backend API running on port ${PORT}`);
  console.log(` Connected to MySQL 8 via mysql2 connection pool`);
  console.log(` CORS enabled for: ${CLIENT_URL}`);
  console.log(`====================================================`);
});
