import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../db.js';

const JWT_SECRET = process.env.JWT_SECRET || 'campuspool_super_secret_jwt_key_2026';

// WHAT: Authenticates user credentials and returns a JWT token along with student/driver status.
// WHY: Gives frontend a session token to associate requests and rides with a logged-in user.
export async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const [users] = await pool.query(
      `SELECT u.user_id, u.first_name, u.last_name, u.email, u.password_hash, u.is_verified,
              d.user_id AS is_driver, d.average_rating,
              s.roll_no, s.program, s.year, c.name AS college_name
       FROM USER u
       LEFT JOIN DRIVER d ON u.user_id = d.user_id
       LEFT JOIN STUDENT s ON u.user_id = s.user_id
       LEFT JOIN COLLEGE c ON s.college_id = c.college_id
       WHERE u.email = ? AND u.status = 'ACTIVE'`,
      [email.trim().toLowerCase()]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const user = users[0];
    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const token = jwt.sign(
      {
        userId: user.user_id,
        email: user.email,
        name: `${user.first_name} ${user.last_name}`,
        isDriver: !!user.is_driver
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      user: {
        userId: user.user_id,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        isVerified: !!user.is_verified,
        isDriver: !!user.is_driver,
        driverRating: user.average_rating,
        collegeName: user.college_name,
        studentProgram: user.program,
        studentYear: user.year
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: err.message || 'Internal server error.' });
  }
}

// WHAT: Registers a new student or driver into the USER and subtype tables.
// WHY: Adds new campus poolers while upholding 3NF relational constraints.
export async function register(req, res) {
  const connection = await pool.getConnection();
  try {
    const {
      firstName,
      lastName,
      email,
      password,
      gender = 'PREFER_NOT_TO_SAY',
      dateOfBirth,
      phone,
      isDriver = false,
      licenseNo,
      isStudent = true,
      rollNo,
      program,
      year,
      collegeId = 1
    } = req.body;

    if (!firstName || !lastName || !email || !password || !dateOfBirth || !phone) {
      return res.status(400).json({ error: 'Please provide all required registration fields.' });
    }

    await connection.beginTransaction();

    const hashedPassword = await bcrypt.hash(password, 10);

    const [userResult] = await connection.query(
      `INSERT INTO USER (first_name, last_name, email, password_hash, gender, date_of_birth, is_verified)
       VALUES (?, ?, ?, ?, ?, ?, TRUE)`,
      [firstName, lastName, email.trim().toLowerCase(), hashedPassword, gender, dateOfBirth]
    );

    const userId = userResult.insertId;

    // Insert phone
    await connection.query(
      `INSERT INTO USER_PHONE (user_id, phone_no, is_primary) VALUES (?, ?, TRUE)`,
      [userId, phone]
    );

    // If Student
    if (isStudent && rollNo && program && year) {
      await connection.query(
        `INSERT INTO STUDENT (user_id, roll_no, program, year, college_id)
         VALUES (?, ?, ?, ?, ?)`,
        [userId, rollNo, program, parseInt(year, 10), parseInt(collegeId, 10)]
      );
    }

    // If Driver
    if (isDriver && licenseNo) {
      await connection.query(
        `INSERT INTO DRIVER (user_id, license_no, average_rating)
         VALUES (?, ?, 5.00)`,
        [userId, licenseNo]
      );
    }

    // Default membership in general community
    await connection.query(
      `INSERT INTO COMMUNITY_MEMBER (user_id, community_id) VALUES (?, 1)`,
      [userId]
    );

    await connection.commit();

    const token = jwt.sign(
      {
        userId,
        email,
        name: `${firstName} ${lastName}`,
        isDriver: !!isDriver
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'Registration successful.',
      token,
      user: {
        userId,
        firstName,
        lastName,
        email,
        isVerified: true,
        isDriver: !!isDriver
      }
    });
  } catch (err) {
    await connection.rollback();
    console.error('Registration error:', err);
    res.status(500).json({ error: err.message || 'Registration failed.' });
  } finally {
    connection.release();
  }
}

// WHAT: Returns authenticated user profile including masked PII for peer display.
// WHY: Supplies user information to client state.
export async function getProfile(req, res) {
  try {
    const targetUserId = req.params.id || (req.user && req.user.userId);
    if (!targetUserId) {
      return res.status(400).json({ error: 'User ID is required.' });
    }

    const [rows] = await pool.query(
      `SELECT * FROM vw_masked_users WHERE user_id = ?`,
      [targetUserId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error('Profile fetch error:', err);
    res.status(500).json({ error: err.message });
  }
}
