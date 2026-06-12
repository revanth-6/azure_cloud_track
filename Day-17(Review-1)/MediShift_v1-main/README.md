# MediShift - Healthcare Staff & Shift Management System

A microservices-based healthcare platform for managing staff, shifts, and leave requests.

## Tech Stack
- **Frontend:** React 18, React Router v6, Axios
- **Backend:** Node.js, Express.js, Sequelize ORM
- **Database:** PostgreSQL 15
- **Auth:** JWT, bcryptjs
- **Infra:** Docker, Docker Compose, Nginx

## Architecture
| Service | Port | Purpose |
|---------|------|---------|
| Frontend (Nginx) | 3000 | React SPA + API proxy |
| Auth Service | 3001 | Login, JWT, user management |
| Staff Service | 3002 | Staff & department CRUD |
| Shift Service | 3003 | Shift management |
| Leave Service | 3004 | Leave requests |
| PostgreSQL | 5432 | Shared database |

## Quick Start
```bash
docker-compose down -v
docker-compose up --build
```
Open http://localhost:3000

## Default Admin
- Email: admin@medishift.com
- Password: admin123

## User Roles
- **Admin:** Manage departments, staff, shifts, leaves
- **Staff:** View shifts, apply for leave

## API Endpoints
### Auth
- POST /api/auth/login
- GET /api/auth/verify
- POST /api/auth/create-user (admin)
- DELETE /api/auth/delete-user/:id (internal)

### Departments
- GET/POST /api/departments (admin)
- GET/PUT/DELETE /api/departments/:id (admin)

### Staff
- GET/POST /api/staff (admin)
- GET/PUT/DELETE /api/staff/:id (admin)
- GET /api/staff/by-user/:userId (internal)

### Shifts
- GET/POST /api/shifts (admin)
- PUT/DELETE /api/shifts/:id (admin)
- GET /api/shifts/my-shifts (staff)
- GET /api/shifts/check-dates (internal)
- PUT /api/shifts/cancel-by-leave (internal)

### Leaves
- GET /api/leaves (admin)
- PUT /api/leaves/:id (admin)
- POST /api/leaves (staff)
- GET /api/leaves/my-leaves (staff)
- GET /api/leaves/check-approved (internal)
