# Relational Schema Normalization Analysis (1NF to 3NF/BCNF)

This document provides formal proof and rationale for the normalization of the **CampusPool** database schema to **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)**.

---

## 1. Normal Forms Definitions Reference

- **First Normal Form (1NF)**: A relation is in 1NF if and only if all underlying domains contain only atomic (indivisible) values, there are no repeating groups, and every row has a unique identifier (Primary Key).
- **Second Normal Form (2NF)**: A relation is in 2NF if it is in 1NF and every non-prime attribute is fully functionally dependent on the entire primary key (no partial dependencies on a composite key).
- **Third Normal Form (3NF)**: A relation is in 3NF if it is in 2NF and no non-prime attribute is transitively dependent on the primary key (i.e., for every non-trivial functional dependency $X \rightarrow Y$, either $X$ is a superkey or $Y$ is a prime attribute).
- **Boyce-Codd Normal Form (BCNF)**: A relation is in BCNF if for every non-trivial functional dependency $X \rightarrow Y$, $X$ must be a superkey.

---

## 2. Decomposition of ER Diagram Attributes

### 2.1 Multivalued Attribute: `USER.phone_numbers`
- **Initial State**: In the conceptual ER diagram, `USER` has a multi-valued attribute `phone_numbers` (a user can have a primary mobile and an alternate mobile).
- **Violation in 1NF**: Storing multiple phone numbers in a single column (e.g., `"9822011223, 9822011224"`) violates atomicity.
- **Decomposition**: Decomposed into relation `USER_PHONE(user_id, phone_no, is_primary)` with composite primary key `(user_id, phone_no)`.
- **Result**: Atomic domains, zero repeating groups, strictly satisfies 1NF.

### 2.2 Composite Attribute: `USER.name`
- **Initial State**: `name` in the ER diagram consists of `first_name` and `last_name`.
- **Resolution**: Stored as distinct atomic columns `first_name` and `last_name` in table `USER`.

### 2.3 Weak Entities
- **`EMERGENCY_CONTACT`**: Weak entity dependent on `USER`.
  - Composite Key: `(user_id, contact_no)`.
  - Non-key attributes: `contact_name`, `phone`, `relationship`.
  - Functional Dependency: `(user_id, contact_no)` $\rightarrow$ `contact_name, phone, relationship`.
  - Since the determinant is the full composite primary key, there are no partial dependencies $\Rightarrow$ **2NF & 3NF satisfied**.
- **`RIDE_STOP`**: Weak entity dependent on `RIDE_POST`.
  - Composite Key: `(ride_id, sequence_no)`.
  - Non-key attributes: `location_id`, `stop_type`, `expected_time`.
  - Functional Dependency: `(ride_id, sequence_no)` $\rightarrow$ `location_id, stop_type, expected_time`.
  - Full functional dependency on composite key $\Rightarrow$ **2NF & 3NF satisfied**.

---

## 3. Table-by-Table Functional Dependency Analysis

### 3.1 `COLLEGE`
- **Primary Key**: `college_id`
- **Functional Dependencies**:
  - `college_id` $\rightarrow$ `name, address, city, state, latitude, longitude, created_at`
- **Analysis**:
  - The determinant `college_id` is a candidate key.
  - No transitive dependencies exist.
  - **Form**: **3NF / BCNF**.

### 3.2 `USER`
- **Primary Key**: `user_id`
- **Candidate Keys**: `user_id`, `email`
- **Functional Dependencies**:
  - `user_id` $\rightarrow$ `first_name, last_name, email, password_hash, gender, date_of_birth, profile_photo, status, is_verified, joined_on`
  - `email` $\rightarrow$ `user_id, first_name, last_name, ...`
- **Derived Attributes**:
  - `age`: Implemented as a MySQL `VIRTUAL GENERATED COLUMN` (`TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())`). It is not stored redundantly, preventing update anomalies.
- **Analysis**:
  - Every determinant is a candidate key.
  - **Form**: **3NF / BCNF**.

### 3.3 Specialization (ISA): `STUDENT` and `DRIVER`
- **`STUDENT`**:
  - Primary Key: `user_id` (FK to `USER`)
  - Functional Dependencies: `user_id` $\rightarrow$ `roll_no, program, year, college_id`
  - Normal Form: **3NF / BCNF**.
- **`DRIVER`**:
  - Primary Key: `user_id` (FK to `USER`)
  - Candidate Keys: `user_id`, `license_no`
  - Functional Dependencies:
    - `user_id` $\rightarrow$ `license_no, average_rating`
    - `license_no` $\rightarrow$ `user_id, average_rating`
  - Note on `average_rating`: Maintained via an `AFTER INSERT ON RATING` trigger as an indexed denormalized aggregate to avoid high-cost real-time table scans across millions of reviews.
  - Normal Form: **3NF / BCNF**.

### 3.4 `COMMUNITY` and `COMMUNITY_MEMBER`
- **`COMMUNITY`**:
  - Primary Key: `community_id`
  - FDs: `community_id` $\rightarrow$ `name, type, college_id, description, created_at`
  - Normal Form: **3NF / BCNF**.
- **`COMMUNITY_MEMBER`**:
  - Composite Key: `(user_id, community_id)`
  - FDs: `(user_id, community_id)` $\rightarrow$ `joined_at`
  - Normal Form: **3NF / BCNF**.

### 3.5 `VEHICLE`
- **Primary Key**: `vehicle_id`
- **Candidate Keys**: `vehicle_id`, `plate_no`
- **Functional Dependencies**:
  - `vehicle_id` $\rightarrow$ `driver_id, plate_no, vehicle_type, make, model, color, capacity, created_at`
  - `plate_no` $\rightarrow$ `vehicle_id, driver_id, ...`
- **Analysis**:
  - Determinants are candidate keys.
  - No non-prime attribute determines another non-prime attribute.
  - Normal Form: **3NF / BCNF**.

### 3.6 `LOCATION`
- **Primary Key**: `location_id`
- **Functional Dependencies**:
  - `location_id` $\rightarrow$ `name, type, address, latitude, longitude, geohash`
- **Analysis**:
  - Locations are normalized into their own table rather than repeating addresses and GPS coordinates across `RIDE_POST` and `RIDE_STOP`.
  - Normal Form: **3NF / BCNF**.

### 3.7 `RIDE_POST`
- **Primary Key**: `ride_id`
- **Functional Dependencies**:
  - `ride_id` $\rightarrow$ `driver_id, vehicle_id, pickup_location_id, destination_location_id, community_id, post_time, departure_time, status, seats_offered, seats_available, estimated_fare, notes`
- **Analysis**:
  - All non-prime attributes depend solely on `ride_id`.
  - Seat integrity rule `seats_available <= seats_offered` is enforced by database CHECK constraints and reactive triggers.
  - Normal Form: **3NF / BCNF**.

### 3.8 `RIDE_REQUEST`
- **Primary Key**: `request_id`
- **Functional Dependencies**:
  - `request_id` $\rightarrow$ `ride_id, rider_id, seats_requested, message, fare_share, request_time, status`
- **Analysis**:
  - Each request is uniquely identified by `request_id`.
  - Normal Form: **3NF / BCNF**.

### 3.9 `TRIP`
- **Primary Key**: `trip_id`
- **Candidate Key**: `ride_id` (1:1 with `RIDE_POST`)
- **Functional Dependencies**:
  - `trip_id` $\rightarrow$ `ride_id, driver_id, vehicle_id, start_time, end_time, distance_km, total_fare, fare_per_person, status`
  - `ride_id` $\rightarrow$ `trip_id, driver_id, ...`
- **Derived Attribute**:
  - `duration_minutes`: Implemented as a virtual generated column `TIMESTAMPDIFF(MINUTE, start_time, end_time)` $\Rightarrow$ Zero update anomalies.
- **Normal Form**: **3NF / BCNF**.

### 3.10 `PAYMENT`
- **Primary Key**: `payment_id`
- **Candidate Key**: `transaction_reference`
- **Functional Dependencies**:
  - `payment_id` $\rightarrow$ `trip_id, rider_id, amount, method, status, transaction_reference, payment_time`
  - `transaction_reference` $\rightarrow$ `payment_id, ...`
- **Normal Form**: **3NF / BCNF**.

### 3.11 `RATING`
- **Primary Key**: `rating_id`
- **Alternate Unique Key**: `(trip_id, rater_user_id, ratee_user_id)`
- **Functional Dependencies**:
  - `rating_id` $\rightarrow$ `trip_id, rater_user_id, ratee_user_id, score, comment, created_at`
- **Normal Form**: **3NF / BCNF**.

---

## 4. Summary Matrix

| Relation | Primary Key | Candidate Keys | 1NF? | 2NF? | 3NF? | BCNF? |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **COLLEGE** | `college_id` | `college_id` | Yes | Yes | Yes | Yes |
| **COMMUNITY** | `community_id` | `community_id` | Yes | Yes | Yes | Yes |
| **USER** | `user_id` | `user_id`, `email` | Yes | Yes | Yes | Yes |
| **COMMUNITY_MEMBER**| `(user_id, community_id)` | `(user_id, community_id)` | Yes | Yes | Yes | Yes |
| **USER_PHONE** | `(user_id, phone_no)` | `(user_id, phone_no)` | Yes | Yes | Yes | Yes |
| **STUDENT** | `user_id` | `user_id` | Yes | Yes | Yes | Yes |
| **DRIVER** | `user_id` | `user_id`, `license_no` | Yes | Yes | Yes | Yes |
| **EMERGENCY_CONTACT**| `(user_id, contact_no)` | `(user_id, contact_no)` | Yes | Yes | Yes | Yes |
| **VEHICLE** | `vehicle_id` | `vehicle_id`, `plate_no` | Yes | Yes | Yes | Yes |
| **LOCATION** | `location_id` | `location_id` | Yes | Yes | Yes | Yes |
| **RIDE_POST** | `ride_id` | `ride_id` | Yes | Yes | Yes | Yes |
| **RIDE_STOP** | `(ride_id, sequence_no)`| `(ride_id, sequence_no)`| Yes | Yes | Yes | Yes |
| **RIDE_REQUEST** | `request_id` | `request_id` | Yes | Yes | Yes | Yes |
| **TRIP** | `trip_id` | `trip_id`, `ride_id` | Yes | Yes | Yes | Yes |
| **PAYMENT** | `payment_id` | `payment_id`, `transaction_reference` | Yes | Yes | Yes | Yes |
| **RATING** | `rating_id` | `rating_id` | Yes | Yes | Yes | Yes |
| **NOTIFICATION** | `notification_id` | `notification_id` | Yes | Yes | Yes | Yes |
| **AUDIT_LOG** | `log_id` | `log_id` | Yes | Yes | Yes | Yes |

Every relation in CampusPool adheres to 3NF and BCNF guidelines, providing minimal storage overhead, maximum relational integrity, and zero insertion, update, or deletion anomalies.
