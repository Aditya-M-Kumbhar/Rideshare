# Database Backup, Disaster Recovery & Point-in-Time Restoration

This guide outlines production-grade backup and recovery strategies for the **CampusPool** MySQL 8 database.

---

## 1. Logical Backups via `mysqldump`

Logical backups produce human-readable SQL scripts containing the `CREATE TABLE`, `INSERT`, and routine statements needed to reconstruct the database.

### 1.1 Complete Full Backup (Schema + Data + Routines + Triggers + Events)
```bash
mysqldump -u root -p \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  campuspool > campuspool_full_backup.sql
```
- **Flags Explained**:
  - `--single-transaction`: Uses InnoDB snapshot isolation to take a consistent backup without locking concurrent read/write transactions.
  - `--quick`: Forces `mysqldump` to stream rows directly from the server rather than buffering them in memory.
  - `--routines`: Backs up stored procedures (`sp_create_ride`, etc.) and stored functions (`fn_mask_id`, etc.).
  - `--triggers`: Preserves reactive triggers (`trg_prevent_overbooking`, etc.).
  - `--events`: Preserves scheduled events (`ev_expire_past_rides`).

---

### 1.2 Schema-Only DDL Backup (Zero Table Data)
Useful for exporting database architecture for academic review or deploying to staging.
```bash
mysqldump -u root -p \
  --no-data \
  --routines \
  --triggers \
  --events \
  campuspool > campuspool_schema_only.sql
```

---

### 1.3 Data-Only Backup (Seeds and Records Only)
```bash
mysqldump -u root -p \
  --no-create-info \
  --complete-insert \
  campuspool > campuspool_data_only.sql
```

---

### 1.4 Single Table Backup (e.g. Audit Log or Trips)
```bash
mysqldump -u root -p campuspool AUDIT_LOG > audit_log_backup.sql
```

---

## 2. Restoration Procedures

### 2.1 Restoring from Full Backup
```bash
# 1. Create target database if it does not exist
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS campuspool CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. Pipe the SQL dump into MySQL
mysql -u root -p campuspool < campuspool_full_backup.sql
```

---

## 3. Point-in-Time Recovery (PITR) via Binary Logs

Point-in-Time Recovery allows restoring a database to the exact second before a catastrophic hardware failure, accidental `DROP TABLE`, or data corruption event.

### 3.1 Prerequisites (in `my.cnf` / `my.ini`):
```ini
[mysqld]
log-bin=mysql-bin
binlog_format=ROW
server-id=1
```

### 3.2 Recovery Workflow:
1. **Restore Latest Full Backup**:
   ```bash
   mysql -u root -p campuspool < campuspool_full_backup.sql
   ```
2. **Replay Binary Log Events up to specific timestamp**:
   ```bash
   mysqlbinlog --stop-datetime="2026-10-20 18:30:00" /var/lib/mysql/mysql-bin.000001 | mysql -u root -p campuspool
   ```
This restores all committed transactions up to `18:30:00` while skipping the faulty operation that occurred immediately afterwards.
