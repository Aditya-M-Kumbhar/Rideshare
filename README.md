# CampusPool — University Vehicle Pooling Web App (MySQL 8 Showcase)

**CampusPool** is a full-featured campus ride-sharing and vehicle-pooling web application developed for the Database Management Systems (DBMS) major project. While providing an intuitive, calm interface for college students to share daily commutes and split travel costs, the primary goal of this application is to showcase enterprise-grade relational database principles using **MySQL 8**.

---

## 🏛️ DBMS Concepts Implemented & Demonstrable

Every relational concept is demonstrable via the interactive **DBMS Showcase** page inside the web application or directly via `sql/99_test_queries.sql`:

1. **Relational Normalization**: Rigorously normalized to **3NF / BCNF** (see [`docs/normalization.md`](docs/normalization.md)).
2. **ISA Specialization**: Hierarchical subtyping for `STUDENT` and `DRIVER` entities derived from `USER`.
3. **Weak Entities**: `EMERGENCY_CONTACT` (weak entity of `USER`) and `RIDE_STOP` (weak entity of `RIDE_POST`).
4. **Multivalued Decomposition**: `USER_PHONE` mapped into 1NF child table.
5. **Virtual Generated Columns**: Automatic `age` calculation from `date_of_birth` and `duration_minutes` from trip timestamps.
6. **Integrity Constraints**: Multi-table `CHECK` constraints, foreign keys with deliberate `ON DELETE / UPDATE CASCADE/RESTRICT/SET NULL` rules.
7. **Composite & Covering Indexes**: `idx_rides_search_composite` with before/after `EXPLAIN` query execution plans (see [`docs/indexing_optimization.md`](docs/indexing_optimization.md)).
8. **Complex Multi-Table Joins**: `INNER JOIN` (5 tables), `LEFT JOIN`, `RIGHT JOIN`, and `SELF JOIN` (peer batchmate matching).
9. **Correlated & Non-Correlated Subqueries**: `EXISTS`, `NOT EXISTS`, and `> ALL` predicates.
10. **Advanced Aggregations & OLAP**: `GROUP BY` with `HAVING`, plus multi-level hierarchical subtotals with `WITH ROLLUP`.
11. **Analytical Window Functions**: `DENSE_RANK()` for campus driver leaderboards, `SUM() OVER ()` for running financial volume, and `ROW_NUMBER()`.
12. **Common Table Expressions (CTEs)**: Non-recursive route analytics and **Recursive CTE** for stop sequence path traversal.
13. **Database Views**: Non-updatable multi-table views (`vw_available_rides`, `vw_driver_leaderboard`), data privacy masked view (`vw_masked_users`), and single-table updatable view (`vw_updatable_emergency_contact`).
14. **Deterministic Stored Functions**: `fn_mask_id`, Haversine spherical distance `fn_distance_km`, and fare share split `fn_calculate_fare_share`.
15. **ACID Transactions & Pessimistic Locks**: `START TRANSACTION`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, and `SELECT ... FOR UPDATE` preventing seat overbooking (see `sql/08_transactions_demo.sql`).
16. **Reactive Triggers**: Auto-recalculating driver average ratings, restoring available seats on cancellation, blocking illegal self-booking, dispatching notifications, and logging JSON audit snapshots.
17. **Cursors & Background Events**: Explicit cursor loop in `sp_dispatch_ride_reminders` and automated recurring cleanup with MySQL Event Scheduler (`ev_expire_past_rides`).
18. **Data Control Language (DCL)**: Least-privilege role-based access control (`app_role`, `admin_role`, `readonly_role`).
19. **Disaster Recovery**: Logical `mysqldump` and Point-in-Time Recovery (PITR) procedures (see [`docs/backup_restore.md`](docs/backup_restore.md)).

---

## 🚀 Quick Setup & Run Instructions

### 1. Database Initialization (MySQL 8)
Make sure MySQL 8 is running locally or on your cloud host. Open a terminal or MySQL Workbench:
```bash
# Execute the master runner (sources all 10 SQL scripts in order)
mysql -u root -p < sql/run_all.sql
```
*Alternatively, you can open and execute `sql/run_all.sql` in MySQL Workbench.*

---

### 2. Backend Server Setup
```bash
cd server

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit server/.env with your MySQL credentials (DB_USER, DB_PASSWORD, etc.)

# Start backend dev server (runs on http://localhost:5000)
npm run dev
```

---

### 3. Frontend Web Client Setup
```bash
cd ../client

# Install dependencies
npm install

# Start Vite React frontend (runs on http://localhost:5173)
npm run dev
```
Open **`http://localhost:5173`** in your browser.

---

## 🧪 Testing & Examiner Viva Demonstration

1. **Interactive Showcase**: Navigate to **DBMS Showcase** in the top navigation bar. Select any concept (EXPLAIN Plan, Rollup, Window Functions, Recursive CTE, Functions, Triggers, Views) and click **"Run Live Query"** to see live tabular results, query latency, and architectural WHY explanations.
2. **Instant Role Switching**: Use the top-right user menu to instantly switch between **Aarav Sharma** (COEP Driver), **Priya Kulkarni** (COEP Rider), **Ananya Deshmukh** (PICT Rider), or **Neha Shinde** (Unverified Student) without logging out.
3. **Pessimistic Locking & Deadlock Demo**: Follow the step-by-step instructions in [`sql/08_transactions_demo.sql`](sql/08_transactions_demo.sql) across two open terminal sessions.
4. **All Viva Queries**: Review [`sql/99_test_queries.sql`](sql/99_test_queries.sql) for 17+ standalone queries with explanations.

---

## 📁 Repository Structure
```
/
├── client/                     # React + Vite frontend
│   ├── src/
│   │   ├── components/         # Clean UI components (Navbar, etc.)
│   │   ├── context/            # AuthContext & instant demo user switcher
│   │   ├── pages/              # FindRide, OfferRide, MyTrips, Alerts, Profile, DBMS Showcase
│   │   ├── index.css           # Calm design tokens (#FAF8F5, soft charcoal, sage teal)
│   │   └── main.jsx
│   └── package.json
├── server/                     # Thin Express API gateway (Plain JS, mysql2)
│   ├── src/
│   │   ├── controllers/        # Stored procedure invokers & view queries
│   │   ├── middleware/         # Lightweight JWT auth
│   │   ├── db.js               # mysql2 connection pool with SSL option
│   │   └── index.js
│   ├── .env.example            # Credentials template
│   └── package.json
├── sql/                        # Strict modular MySQL 8 scripts
│   ├── 00_create_database.sql
│   ├── 01_schema_tables.sql
│   ├── 02_constraints_indexes.sql
│   ├── 03_seed_data.sql
│   ├── 04_views.sql
│   ├── 05_functions.sql
│   ├── 06_stored_procedures.sql
│   ├── 07_triggers.sql
│   ├── 08_transactions_demo.sql
│   ├── 09_events_cursors.sql
│   ├── 10_security_roles.sql
│   ├── 99_test_queries.sql
│   └── run_all.sql
├── docs/                       # Academic DBMS evaluation documentation
│   ├── normalization.md        # 3NF / BCNF functional dependency proofs
│   ├── indexing_optimization.md# Composite indexes & EXPLAIN before/after
│   ├── backup_restore.md       # mysqldump & Point-in-Time Recovery
│   └── rideshare.pdf           # Original ER diagram
├── PROJECT_STATUS.md           # Master status & continuity handoff
└── README.md
```
