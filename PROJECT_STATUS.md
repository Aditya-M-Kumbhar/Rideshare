# CampusPool - Project Status & Continuity Master Plan

## 1. Project Summary & Goal
**CampusPool** is a full-featured, university and community-focused vehicle pooling / ride sharing web platform engineered specifically to showcase advanced Database Management System (DBMS) concepts using **MySQL 8**. 

The app allows university students and verified drivers to share daily commutes, split fuel and toll costs, and travel safely within college trust circles using verified, masked identities (`MH12****34`, `aa****@coep.ac.in`).

**Core DBMS Architectural Highlights**:
- Normalized relational schema (3NF/BCNF) directly derived from the ER diagram (`rideshare.pdf`).
- Thin Express backend executing stored procedures, views, functions, and triggers directly via `mysql2` connection pooling.
- Pessimistic row locking (`SELECT ... FOR UPDATE`), transaction isolation levels, savepoints, deadlocks, and ACID compliance.
- Reactive database triggers, cursors, scheduled MySQL events, and role-based access control (DCL).
- Interactive **DBMS Showcase** page in the React frontend demonstrating each of the 17 DBMS concepts with live execution, query latency, and plain-English WHY explanations.

---

## 2. Tech Stack & Exact Commands to Run

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Database** | MySQL 8.0+ | All business rules, transactions, stored procedures, triggers, views, roles |
| **Backend** | Node.js + Express (ES Modules) | Thin API gateway, `mysql2` connection pool, JWT auth, direct SQL invoker |
| **Frontend** | React 18 (Vite, Plain JS) + React Router | Calm aesthetic (#FAF8F5, soft charcoal, sage teal), vanilla CSS design tokens |
| **Documentation** | Markdown & SQL Scripts | Normalization proofs, indexing optimization, backup/restore, test queries |

### Setup & Run Commands:
```bash
# -------------------------------------------------------------
# 1. DATABASE SETUP (Run inside MySQL CLI or Workbench)
# -------------------------------------------------------------
mysql -u root -p < sql/run_all.sql

# -------------------------------------------------------------
# 2. BACKEND SETUP (Port 5000)
# -------------------------------------------------------------
cd server
npm install
cp .env.example .env
# Edit server/.env with your MySQL credentials
npm run dev

# -------------------------------------------------------------
# 3. FRONTEND CLIENT SETUP (Port 5173)
# -------------------------------------------------------------
cd ../client
npm install
npm run dev
# Open http://localhost:5173 in your browser
```

---

## 3. Original Plan Checklist

### Phase 1: Database Architecture & SQL Scripts (`/sql`)
- [x] `00_create_database.sql` - Database initialization with utf8mb4 encoding
- [x] `01_schema_tables.sql` - Base relational tables with PKs, standard types, weak entities, and virtual generated columns
- [x] `02_constraints_indexes.sql` - Check constraints, domain integrity, and composite indexes
- [x] `03_seed_data.sql` - Realistic dataset (16 users, 3 colleges, 4 communities, 10 vehicles, 26 ride posts, 42 requests, 15 trips, ratings, payments)
- [x] `04_views.sql` - Masked privacy views, available rides catalog, driver leaderboard, updatable views
- [x] `05_functions.sql` - Stored functions (`fn_mask_id`, `fn_calculate_fare_share`, `fn_distance_km`, `fn_rating_badge`)
- [x] `06_stored_procedures.sql` - Stored procedures with handlers & signals (`sp_create_ride`, `sp_request_seat`, `sp_accept_request`, `sp_reject_request`, `sp_start_trip`, `sp_complete_trip`, `sp_process_payment`, `sp_submit_rating`)
- [x] `07_triggers.sql` - Triggers for seat counts, self-booking prevention, driver ratings, audit logging, and automated notifications
- [x] `08_transactions_demo.sql` - Concurrency scenarios, `SELECT ... FOR UPDATE`, isolation levels, deadlock demonstration
- [x] `09_events_cursors.sql` - MySQL Event Scheduler for ride expiration + cursor-driven reminder batch procedure
- [x] `10_security_roles.sql` - DCL roles (`app_role`, `admin_role`, `readonly_role`), least-privilege service user
- [x] `99_test_queries.sql` - 17+ demonstrable queries covering all DBMS concepts
- [x] `run_all.sql` - Master script sourcing all SQL files in order

### Phase 2: Documentation (`/docs`)
- [x] `docs/normalization.md` - Functional dependencies, 1NF -> 2NF -> 3NF/BCNF proofs
- [x] `docs/indexing_optimization.md` - Single vs composite indexes, `EXPLAIN` analysis before/after
- [x] `docs/backup_restore.md` - `mysqldump` strategies, schema vs data dumps, point-in-time recovery
- [x] `docs/rideshare.pdf` - Reference ER diagram

### Phase 3: Backend API (`/server`)
- [x] Express application with `mysql2/promise` connection pool and SSL support
- [x] Environment handling via `server/.env.example`
- [x] JWT authentication middleware with dev bypass convenience
- [x] Endpoints calling stored procedures & views:
  - [x] `POST /api/auth/login` & `POST /api/auth/register`
  - [x] `GET /api/auth/profile/:id?`
  - [x] `GET /api/communities`, `GET /api/locations`, `GET /api/colleges`, `GET /api/vehicles`, `GET /api/leaderboard`
  - [x] `GET /api/rides` (`vw_available_rides`)
  - [x] `GET /api/rides/:id`
  - [x] `POST /api/rides` (`sp_create_ride`)
  - [x] `POST /api/rides/:id/request` (`sp_request_seat`)
  - [x] `POST /api/requests/:id/accept` (`sp_accept_request` with row lock)
  - [x] `POST /api/requests/:id/reject` (`sp_reject_request`)
  - [x] `POST /api/requests/:id/cancel` (reactive trigger test)
  - [x] `POST /api/trips/:id/start` (`sp_start_trip`)
  - [x] `POST /api/trips/:id/complete` (`sp_complete_trip`)
  - [x] `GET /api/my-trips`
  - [x] `POST /api/payments/:id/pay` (`sp_process_payment`)
  - [x] `POST /api/ratings` (`sp_submit_rating`)
  - [x] `GET /api/notifications` & `PUT /api/notifications/:id/read`
  - [x] `GET /api/dbms/queries` & `POST /api/dbms/execute` (Showcase runner)

### Phase 4: Frontend Web Application (`/client`)
- [x] Vite + React 18 configuration with proxy to server
- [x] Design System (`index.css`): Warm off-white background (#FAF8F5), soft charcoal text, sage green accent (#2E7D6F), subtle badges, 1px borders
- [x] Top Navigation Header with live notification counter and instant test user switcher
- [x] `FindRidePage` (Filter by community, origin, destination, date, seats with request modal)
- [x] `OfferRidePage` (Schedule ride with vehicle selector, seat capacity check, and community scope)
- [x] `MyTripsPage` (Driver ride controls, request approvals with row locks, trip start/complete, passenger payments and ratings)
- [x] `NotificationsPage` (Trigger and cursor alerts with mark-as-read interaction)
- [x] `ProfilePage` (Masked credentials vs private details, emergency contacts, student specialization)
- [x] `DbmsShowcasePage` (Interactive viva workbench running test queries live against MySQL with latency and WHY explanations)
- [x] Verified full production bundle build (`vite build` passes with zero errors)

---

## 4. Current Status: DONE
- The entire project codebase is completely built from database to backend to frontend to docs.
- All 11 SQL scripts in `/sql` crafted with mandatory plain-English `WHAT` and `WHY` comments.
- All 3 documentation reports in `/docs` completed.
- Express API server fully implemented and dependencies installed.
- React Vite client fully implemented, styled to calm muted specifications, and successfully compiled.
- `README.md` and `PROJECT_STATUS.md` written and synchronized.

---

## 5. In Progress / Next Steps
1. Request the user to provide MySQL database connection credentials in `server/.env`.
2. Connect to MySQL, execute `sql/run_all.sql`, verify all tables and routines are built without error.
3. Run `sql/99_test_queries.sql` and verify live execution across all 17 DBMS concepts.
4. Launch backend and frontend development servers.

---

## 6. Deviations & Design Decisions from ER Diagram
1. **COMMUNITY & COMMUNITY_MEMBER**:
   - *Reason*: Added to allow rides to be scoped to specific campuses (e.g., "COEP Only") or open to "General".
2. **AUDIT_LOG**:
   - *Reason*: Added to demonstrate enterprise audit compliance, capture BEFORE/AFTER trigger mutations, and log changes to critical tables (`RIDE_POST`, `TRIP`, `PAYMENT`).
3. **PASSWORD_HASH & AUTH**:
   - *Reason*: Added `password_hash` column to `USER` table to enable realistic login/registration.
4. **IS_VERIFIED & VERIFICATION_BADGES**:
   - *Reason*: Added `is_verified` boolean to `USER` for the campus trust badge requirement.
5. **MASKED USER VIEW (`vw_masked_users`)**:
   - *Reason*: Created to satisfy the requirement that peer riders and drivers see masked IDs (e.g., `MH12****34`, `j***@coep.ac.in`) for privacy and safety.

---

## 7. Known Issues / Things Not Yet Tested
- Awaiting real MySQL 8 credentials from the user to execute `sql/run_all.sql` and test live database queries against the running MySQL instance.

---

## 8. Directory & File Purpose Map
```
d:/Campuspool/
├── PROJECT_STATUS.md              # Master status, plan checklist, and architecture log
├── README.md                      # Quick start, installation, and viva overview
├── .gitignore                     # Ignores .env and node_modules
├── docs/
│   ├── normalization.md           # 3NF / BCNF functional dependency proofs
│   ├── indexing_optimization.md   # EXPLAIN plans before/after composite indexes
│   ├── backup_restore.md          # mysqldump commands and point-in-time recovery
│   └── rideshare.pdf              # Source of truth ER diagram
├── sql/
│   ├── 00_create_database.sql     # Database creation and utf8mb4 collation
│   ├── 01_schema_tables.sql       # Core tables, foreign keys, weak entities
│   ├── 02_constraints_indexes.sql # CHECK constraints and composite search indexes
│   ├── 03_seed_data.sql           # Realistic dataset (16 users, 26 rides, 42 requests, etc.)
│   ├── 04_views.sql               # Masked privacy view, ride catalog, leaderboards
│   ├── 05_functions.sql           # fn_mask_id, Haversine fn_distance_km, fn_calculate_fare_share
│   ├── 06_stored_procedures.sql   # Transactional procedures with handlers and custom signals
│   ├── 07_triggers.sql            # Triggers for seat counts, self-booking, ratings, audit logs
│   ├── 08_transactions_demo.sql   # Pessimistic locking, isolation levels, deadlocks
│   ├── 09_events_cursors.sql      # Scheduled event and cursor-driven batch notifications
│   ├── 10_security_roles.sql      # Least-privilege roles (app_role, admin_role, readonly_role)
│   ├── 99_test_queries.sql        # Examiner demonstration test queries with WHY comments
│   └── run_all.sql                # Master SQL execution script
├── server/
│   ├── package.json               # Backend dependencies (express, mysql2, etc.)
│   ├── .env.example               # Template environment variables file
│   └── src/
│       ├── index.js               # Express server entrypoint
│       ├── db.js                  # mysql2 connection pool
│       ├── middleware/
│       │   └── auth.js            # JWT auth and dev user header bypass
│       └── controllers/
│           ├── authController.js  # Registration, login, profile lookups
│           ├── ridesController.js # Ride searching via view and sp_create_ride
│           ├── requestsController.js # Seat booking, row-lock approvals
│           ├── tripsController.js # Trip start/complete, payments, ratings
│           ├── referenceController.js # Catalogs (locations, colleges, vehicles)
│           └── dbmsShowcaseController.js # Whitelisted viva query runner
└── client/
    ├── package.json               # Frontend dependencies (React 18, Vite, Lucide)
    ├── vite.config.js             # Vite configuration with proxy to port 5000
    ├── index.html                 # HTML entrypoint with Inter font
    └── src/
        ├── main.jsx               # React DOM bootstrap
        ├── App.jsx                # Router configuration and layout shell
        ├── index.css              # Calm muted design tokens and utility styles
        ├── context/
        │   └── AuthContext.jsx    # Auth state and one-click demo user switcher
        ├── components/
        │   └── Navbar.jsx         # Sticky navigation with notification badge & user menu
        └── pages/
            ├── FindRidePage.jsx   # Search catalog with ID masking and request modal
            ├── OfferRidePage.jsx  # Ride offering form calling sp_create_ride
            ├── MyTripsPage.jsx    # Driver approvals, trip lifecycle, payments, ratings
            ├── NotificationsPage.jsx # Trigger and cursor alert feeds
            ├── ProfilePage.jsx    # User profile displaying masked PII and ISA details
            └── DbmsShowcasePage.jsx # Interactive viva testing workbench
```
