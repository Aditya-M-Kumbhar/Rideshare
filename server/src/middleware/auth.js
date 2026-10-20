import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'campuspool_super_secret_jwt_key_2026';

// WHAT: Validates incoming JWT or dev user header and injects authenticated user into req.user.
// WHY: Protects member-only endpoints while remaining lightweight (auth is not the focus of this DBMS project).
export function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  // Dev bypass support: If client passes x-user-id, use it for testing
  const devUserId = req.headers['x-user-id'];
  if (!token && devUserId) {
    req.user = { userId: parseInt(devUserId, 10) };
    return next();
  }

  if (!token) {
    return res.status(401).json({ error: 'Access denied. Authentication token required.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid or expired token.' });
  }
}

// Optional auth: Populates req.user if token exists, but doesn't block unauthenticated guests
export function optionalAuth(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  const devUserId = req.headers['x-user-id'];

  if (devUserId) {
    req.user = { userId: parseInt(devUserId, 10) };
    return next();
  }

  if (token) {
    try {
      req.user = jwt.verify(token, JWT_SECRET);
    } catch (e) {
      // Ignore token errors in optional auth
    }
  }
  next();
}
