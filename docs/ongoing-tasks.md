# Ongoing Tasks

## ☁️ Phase 6: Backend API Setup (Node.js + Postgres)

We are currently building a Node.js/Express backend connected to a cloud Aiven Postgres database to power the new auth and social features.

**Currently implemented building blocks:**
- [x] Initialised Node.js `package.json` with dependencies (express, pg, bcrypt, jsonwebtoken, zod, cors)
- [x] Created `backend/.env` containing the secure Aiven Postgres connection string
- [x] Written Postgres schema (`schema.sql`) defining tables: `users`, `groups`, `group_members`, and `group_invites`
- [x] Written DB migration script (`migrate.js`) and connection pool (`pool.js`)
- [x] Implemented JWT verification middleware (`middleware/auth.js`)
- [x] Implemented Auth routes (`POST /auth/register` and `POST /auth/login`) with bcrypt password hashing
- [x] Implemented User routes (`GET/PUT /users/me` and `GET /users/:id` with public/group visibility logic)

**Up next:**
- Implementing groups and invite endpoints
