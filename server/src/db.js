import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

// WHAT: Creates a high-performance MySQL connection pool using mysql2.
// WHY: Eliminates connection overhead per HTTP request, manages concurrency, and handles reconnects automatically.
const poolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  database: process.env.DB_NAME || 'campuspool',
  user: process.env.APP_DB_USER || process.env.DB_USER || 'root',
  password: process.env.APP_DB_PASSWORD || process.env.DB_PASSWORD || '',
  waitForConnections: true,
  connectionLimit: 15,
  queueLimit: 0,
  dateStrings: true,
  multipleStatements: true
};

// Optional SSL support for hosted/cloud MySQL instances
if (process.env.DB_SSL === 'true') {
  poolConfig.ssl = {
    rejectUnauthorized: false
  };
}

const pool = mysql.createPool(poolConfig);

// Diagnostic test helper to verify connection health
export async function testConnection() {
  try {
    const [rows] = await pool.query('SELECT 1 + 1 AS result, DATABASE() as db');
    return { success: true, database: rows[0].db };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

export default pool;
