# Qatra Backend - Donation Service & Notification Service

## Overview

Two Spring Boot 4.0.6 microservices using Spring Modulith with Hexagonal Architecture (Ports & Adapters). Communication via Apache Kafka (event-driven). PostgreSQL 16 for persistence, Redis 7 for caching.

| Service | Port | Technology | Role |
|---|---|---|---|
| **donation-service** | 8080 | Spring Boot, Spring Modulith, JPA, Kafka, Redis, Flyway | Core business logic |
| **notification-service** | 8082 | Spring Boot, Kafka, WebSocket, Spring Retry | Email + in-app notifications |

---

## Architecture Patterns

- **Hexagonal Architecture** (Ports & Adapters): each module uses `domain/port/in` (use cases), `domain/port/out` (repository ports), `infrastructure/persistence/adapter` (JPA), `infrastructure/web` (REST controllers)
- **Spring Modulith**: modular monolith within donation-service with enforced module boundaries
- **Saga Pattern with Compensation**: Kafka-based event flow with result callbacks and compensation on failure
- **CQRS-lite**: separate command and query use case interfaces per module
- **MapStruct + Lombok**: DTO mapping and boilerplate reduction

---

## Modules (donation-service)

1. **user** - Authentication, sessions, roles, verification tokens, GDPR
2. **donor** - Donor profiles, health questionnaires, eligibility, certificates, reliability scoring
3. **center** - Donation centers, operating hours, slots, staff management
4. **appointment** - Booking, check-in, screening, completion, queue management
5. **emergency** - Emergency requests, donor matching (expanding radius), donor responses
6. **notification** (event publishing) - Publishes Kafka events to notification-service
7. **analytics** - Audit logs, metrics aggregation, center-specific metrics
8. **report** - CSV center reports for date ranges
9. **system** - GDPR deletion requests, scheduled tasks

---

## Database Schema

### Tables (18 total via Flyway migrations)

```
users
  |-- user_roles (1:N) -- Roles: SUPER_ADMIN, CENTER_ADMIN, CENTER_STAFF, DONOR
  |-- sessions (1:N) -- JWT session management (access_token_hash, refresh_token_hash)
  |-- verification_tokens (1:N) -- EMAIL_VERIFICATION, PASSWORD_RESET
  |-- audit_logs (1:N) -- System audit trail
  |-- gdpr_deletion_requests (1:N) -- GDPR compliance
  |
  |-- donor_profiles (1:1 per user) -- blood_type, eligibility, location, availability, reliability_score
  |     |-- health_questionnaires (1:1) -- chronic illness, medication, surgeries, travel, tattoos
  |     |-- donation_certificates (1:N) -- Generated PDFs (OpenPDF)
  |
  |-- center_admin_profiles (1:N per user) -- links user to donation center
  |-- center_staff_profiles (1:N per user) -- links user to donation center + is_verified

donation_centers
  |-- slots (1:N) -- Time slots with booked_count, max_bookings, is_blocked
  |-- emergency_requests (1:N)
  |     |-- match_results (1:N) -- Donor-emergency matching
  |     |-- donor_responses (1:N) -- ACCEPTED/DECLINED
  |
  |-- appointments (N:1 to center)
        |-- health_screenings (1:1) -- weight, blood pressure, hemoglobin, temperature, eligible
```

### Key Enums

| Enum | Values |
|---|---|
| Role | SUPER_ADMIN, CENTER_ADMIN, CENTER_STAFF, DONOR |
| BloodType | A_POSITIVE, A_NEGATIVE, B_POSITIVE, B_NEGATIVE, AB_POSITIVE, AB_NEGATIVE, O_POSITIVE, O_NEGATIVE, UNKNOWN (with `canDonateTo()` compatibility logic) |
| UserStatus | ACTIVE, INACTIVE, SUSPENDED, PENDING_VERIFICATION, PENDING_DELETION, DELETED |
| CenterStatus | PENDING_APPROVAL, ACTIVE, SUSPENDED, CLOSED |
| FacilityType | BLOOD_BANK, HOSPITAL, CLINIC, MOBILE_UNIT, COMMUNITY_CENTER |
| AppointmentType | REGULAR, EMERGENCY |
| AppointmentStatus | SCHEDULED, CHECKED_IN, IN_SCREENING, COMPLETED, CANCELLED, NO_SHOW, RESCHEDULED |
| EmergencyStatus | OPEN, FULFILLED, CANCELLED, EXPIRED |
| EmergencyUrgency | CRITICAL, HIGH, MEDIUM, LOW |
| NotificationType | EMERGENCY_ALERT, APPOINTMENT_REMINDER, ELIGIBILITY_REMINDER, PROFILE_COMPLETION, EMAIL_VERIFICATION, PASSWORD_RESET, GENERAL |
| NotificationChannel | IN_APP, PUSH, EMAIL |
| NotificationStatus | PENDING, SENT, DELIVERED, READ, FAILED |

---

## API Endpoints (Complete)

### AuthController (`/api/v1/auth`)
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/auth/login` | Public | Email+password login, returns JWT + refresh token |
| POST | `/api/v1/auth/signup` | Public | Register new donor, auto-assigns DONOR role |
| POST | `/api/v1/auth/logout` | Authenticated | Revokes session |
| POST | `/api/v1/auth/refresh` | Public | Rotate access+refresh tokens |
| POST | `/api/v1/auth/request-verification` | Authenticated | Resend email verification |
| POST | `/api/v1/auth/verify-email` | Public | Verify email with token |
| POST | `/api/v1/auth/change-password` | Authenticated | Change password (requires current password) |
| POST | `/api/v1/auth/forgot-password` | Public | Request password reset (publishes Kafka event) |
| POST | `/api/v1/auth/reset-password` | Public | Reset password with token |

### UserController (`/api/v1/admin/users`)
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/admin/users` | SUPER_ADMIN | List all users (paginated, searchable) |
| GET | `/api/v1/admin/users/{id}` | Authenticated | Get user details |
| POST | `/api/v1/admin/users` | SUPER_ADMIN, CENTER_ADMIN | Create user |
| PUT | `/api/v1/admin/users/{id}` | Authenticated | Update user |
| PATCH | `/api/v1/admin/users/{id}/status` | SUPER_ADMIN | Update user status |
| POST | `/api/v1/admin/users/{id}/roles` | SUPER_ADMIN | Assign role |
| DELETE | `/api/v1/admin/users/{id}/roles` | SUPER_ADMIN | Revoke role |
| DELETE | `/api/v1/admin/users/{id}` | SUPER_ADMIN | Delete user |

### InternalUserController (`/api/v1/internal/users`)
| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/internal/users/{id}` | Get user by ID |
| GET | `/api/v1/internal/users/by-email` | Find by email |
| GET | `/api/v1/internal/users/by-phone` | Find by phone |
| GET | `/api/v1/internal/users/{id}/roles` | Get user roles |
| GET | `/api/v1/internal/users/exists/by-email` | Check existence |
| GET | `/api/v1/internal/users/exists/by-phone` | Check existence |

### DonorController (`/api/v1/donors`)
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/donors/me` | DONOR | Get own profile |
| PUT | `/api/v1/donors/me` | SUPER_ADMIN, DONOR | Update profile |
| GET | `/api/v1/donors/me/health-questionnaire` | SUPER_ADMIN, DONOR | Get health questionnaire |
| PUT | `/api/v1/donors/me/health-questionnaire` | SUPER_ADMIN, DONOR | Update health questionnaire |
| PUT | `/api/v1/donors/me/blood-type` | SUPER_ADMIN, DONOR | Update blood type |
| PUT | `/api/v1/donors/me/location` | SUPER_ADMIN, DONOR | Update location (lat/lng/city/country) |
| PUT | `/api/v1/donors/me/availability` | SUPER_ADMIN, DONOR | Update availability |
| PUT | `/api/v1/donors/me/notification-prefs` | SUPER_ADMIN, DONOR | Update notification preferences |
| GET | `/api/v1/donors/me/eligibility` | DONOR | Get eligibility status |
| GET | `/api/v1/donors/me/impact` | SUPER_ADMIN, DONOR | Get donation impact stats |
| GET | `/api/v1/donors/me/certificates` | SUPER_ADMIN, DONOR | List donation certificates |
| GET | `/api/v1/donors/me/certificates/{id}/download` | SUPER_ADMIN, DONOR | Download PDF certificate |
| GET | `/api/v1/donors/{id}` | CENTER_ADMIN, CENTER_STAFF | Get donor by ID |
| GET | `/api/v1/donors/{id}/eligibility` | CENTER_ADMIN, CENTER_STAFF | Get donor eligibility |
| GET | `/api/v1/donors/{id}/health-questionnaire` | CENTER_ADMIN, CENTER_STAFF | Get donor health |
| GET | `/api/v1/admin/donors/restricted` | SUPER_ADMIN | List permanently restricted donors |
| PATCH | `/api/v1/donors/{id}/restriction` | SUPER_ADMIN, CENTER_ADMIN | Update restriction |
| PATCH | `/api/v1/donors/{id}/flag` | SUPER_ADMIN, CENTER_ADMIN | Flag for manual review |

### CenterController (`/api/v1/centers`)
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/centers` | SUPER_ADMIN, CENTER_ADMIN | Create center |
| PUT | `/api/v1/centers/{id}` | SUPER_ADMIN, CENTER_ADMIN | Update center |
| PATCH | `/api/v1/centers/{id}/status` | SUPER_ADMIN, CENTER_ADMIN | Update status |
| DELETE | `/api/v1/centers/{id}` | SUPER_ADMIN, CENTER_ADMIN | Delete center |
| GET | `/api/v1/centers/{id}` | Public | Get by ID |
| GET | `/api/v1/centers` | Public | List all (paginated, searchable) |
| GET | `/api/v1/centers/public` | Public | List active centers (optional lat/lng) |
| GET | `/api/v1/centers/pending` | Public | List pending approval centers |
| PATCH | `/api/v1/centers/{id}/approve` | SUPER_ADMIN | Approve/reject center |
| POST | `/api/v1/centers/{id}/closures` | SUPER_ADMIN, CENTER_ADMIN | Block time period |
| GET | `/api/v1/centers/{id}/slots` | Public | Get available slots |
| PATCH | `/api/v1/centers/{id}/slots/{slotId}/block` | SUPER_ADMIN, CENTER_ADMIN | Block/unblock slot |
| GET | `/api/v1/centers/{id}/staff` | Public | List staff |
| POST | `/api/v1/centers/{id}/staff` | SUPER_ADMIN, CENTER_ADMIN | Add staff |
| DELETE | `/api/v1/centers/{id}/staff/{userId}` | SUPER_ADMIN, CENTER_ADMIN | Remove staff |

### AppointmentController (`/api/v1/appointments`)
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/appointments` | SUPER_ADMIN, DONOR | Book appointment (REGULAR or EMERGENCY) |
| POST | `/api/v1/appointments/{id}/check-in` | CENTER_ADMIN, CENTER_STAFF | Donor checks in |
| POST | `/api/v1/appointments/{id}/screening` | CENTER_ADMIN, CENTER_STAFF | Start health screening |
| POST | `/api/v1/appointments/{id}/screening-results` | CENTER_ADMIN, CENTER_STAFF | Save screening results |
| POST | `/api/v1/appointments/{id}/complete` | CENTER_ADMIN, CENTER_STAFF | Complete with outcome |
| POST | `/api/v1/appointments/{id}/no-show` | CENTER_ADMIN, CENTER_STAFF | Mark no-show |
| POST | `/api/v1/appointments/{id}/cancel` | SUPER_ADMIN, DONOR, CENTER_ADMIN | Cancel appointment |
| PUT | `/api/v1/appointments/{id}/reschedule` | SUPER_ADMIN, DONOR | Reschedule |
| GET | `/api/v1/appointments/{id}` | Public | Get by ID |
| GET | `/api/v1/appointments` | Public | List all (paginated) |
| GET | `/api/v1/appointments/by-donor/{donorId}` | SUPER_ADMIN, DONOR, CENTER_ADMIN | By donor |
| GET | `/api/v1/appointments/by-center/{centerId}` | CENTER_ADMIN, CENTER_STAFF | By center + date |
| GET | `/api/v1/appointments/queue` | CENTER_ADMIN, CENTER_STAFF | Center queue (date range) |
| GET | `/api/v1/appointments/{id}/screening` | Public | Get screening |

### EmergencyController (`/api/v1/emergencies`)
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/emergencies` | Any authenticated | Create emergency blood request |
| PUT | `/api/v1/emergencies/{id}` | Any authenticated | Update emergency |
| POST | `/api/v1/emergencies/{id}/cancel` | Any authenticated | Cancel |
| POST | `/api/v1/emergencies/{id}/resolve` | CENTER_ADMIN, CENTER_STAFF | Resolve |
| GET | `/api/v1/emergencies/{id}` | Public | Get by ID |
| GET | `/api/v1/emergencies` | Authenticated | List all (paginated) |
| GET | `/api/v1/emergencies/open/{bloodType}` | Authenticated | Open by blood type |
| GET | `/api/v1/emergencies/nearby` | Authenticated | Nearby (lat/lng/radiusKm) |
| POST | `/api/v1/emergencies/{emergencyId}/responses/accept` | SUPER_ADMIN, DONOR | Accept response (auto-books appointment) |
| POST | `/api/v1/emergencies/{emergencyId}/responses/decline` | SUPER_ADMIN, DONOR | Decline response |
| GET | `/api/v1/emergencies/{id}/responses` | Authenticated | List responses |
| GET | `/api/v1/emergencies/responses/donor/{donorId}` | SUPER_ADMIN, DONOR, CENTER_ADMIN | Donor responses |

### NotificationController (`/api/v1/notifications`)
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/notifications` | Authenticated | List notifications (filterable, paginated) |
| PATCH | `/api/v1/notifications/{id}/read` | Authenticated | Mark as read |
| PATCH | `/api/v1/notifications/read-all` | Authenticated | Mark all as read |
| GET | `/api/v1/notifications/unread-count` | Authenticated | Get unread count |

### AnalyticsController (`/api/v1/analytics`)
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/analytics/audit-logs` | SUPER_ADMIN, CENTER_ADMIN | Filtered audit logs (paginated) |
| GET | `/api/v1/analytics/audit-logs/export` | SUPER_ADMIN, CENTER_ADMIN | Export CSV |
| GET | `/api/v1/analytics/audit-logs/by-action/{action}` | SUPER_ADMIN, CENTER_ADMIN | By action type |
| GET | `/api/v1/analytics/audit-logs/by-user/{userId}` | SUPER_ADMIN, CENTER_ADMIN | By user |
| GET | `/api/v1/analytics/metrics` | SUPER_ADMIN, CENTER_ADMIN | Overview metrics (cached 60s) |
| GET | `/api/v1/analytics/centers/{centerId}/metrics` | SUPER_ADMIN, CENTER_ADMIN | Center-specific metrics (cached 600s) |

### Other Controllers
- **StaffController** (`/api/v1/staff/me`): Get own staff profile (CENTER_STAFF only)
- **AdminController** (`/api/v1/admin/me`): Get own admin profile (SUPER_ADMIN, CENTER_ADMIN)
- **ReportController** (`/api/v1/centers/{id}/report`): CSV center report for date range
- **SystemController** (`/api/v1/system/gdpr`): GDPR deletion request management

---

## Authentication & Authorization

### JWT-Based Stateless Auth
- **Token Generation**: HMAC-SHA key, claims: userId, roles, email, issuedAt, expiration
- **JWT Filter**: Extracts Bearer token from Authorization header, validates, sets SecurityContext with ROLE_ prefixed authorities
- **Password Hashing**: BCrypt
- **Session Management**: Server-side sessions in `sessions` table with SHA-256 hashed access/refresh tokens
- **Token Rotation**: Refresh endpoint rotates both tokens
- **Stateless**: SessionCreationPolicy.STATELESS

### Role-Based Access Control (RBAC)
| Role | Permissions |
|---|---|
| SUPER_ADMIN | Full system access, user management, center approval, GDPR, role management |
| CENTER_ADMIN | Center management, staff management, analytics, reporting |
| CENTER_STAFF | Appointment processing, health screening, emergency management |
| DONOR | Self-service profile, appointment booking, emergency responses |

---

## Kafka Event-Driven Architecture

### Topics
| Topic | Purpose |
|---|---|
| `appointment-events` | Appointment lifecycle events |
| `emergency-events` | Emergency events |
| `audit-events` | Audit log events |
| `emergency.created` | Emergency created -> notification service |
| `appointment.reminder` | Appointment reminders |
| `eligibility.restored` | Donor eligibility restored |
| `eligibility.reminder` | Eligibility reminders |
| `password.reset` | Password reset requests |
| `email.verification` | Email verification |
| `notification.result` | Notification delivery results (back to donation-service) |
| `profile.completion.nudge` | Nudge users to complete profiles |

### Event Flow (Saga Pattern)
1. Donation service publishes events via `NotificationEventPublisher`
2. Notification service consumes via `NotificationEventConsumer`, dispatches notifications
3. For critical events (password reset, email verification), notification service publishes result events back
4. Donation service listens via `NotificationResultListener` -- on DELIVERY_FAILED, compensates by deleting the verification token

### Donor Matching Algorithm
- When emergency is created, matching service finds eligible donors by blood type compatibility
- **Expanding radius** algorithm: starts at configured radius, increments by 10km up to 200km
- Sorts by distance then reliability score
- Creates MatchResult records and publishes emergency.created event

---

## Notification Service

### Three Email Provider Options (conditionally activated)
| Provider | Condition |
|---|---|
| Resend | `email.channel.provider=resend` |
| SendGrid | `email.channel.provider=sendgrid` |
| Gmail SMTP | `email.channel.provider=gmail` |

### In-App Notifications via WebSocket
- WebSocket endpoint: `/ws/notifications`
- Manages user sessions in ConcurrentHashMap
- Broadcasts JSON notification payloads to connected users in real-time

### Retry Logic
- `@Retryable` with configurable max attempts (default 3) and exponential backoff (base 2000ms, multiplier 2)

### Channel Configuration per Event Type
| Event | Channels |
|---|---|
| Emergency | IN_APP |
| Appointment | IN_APP |
| Eligibility | IN_APP, EMAIL |
| Password reset | IN_APP, EMAIL |
| Email verification | IN_APP, EMAIL |
| Profile completion | IN_APP |

---

## Scheduled Tasks

| Scheduler | Schedule | Purpose |
|---|---|---|
| SlotGenerationScheduler | Startup + cron every 21 days | Auto-generate time slots 21 days ahead |
| SessionCleanupScheduler | Periodic | Clean expired sessions |
| GDPRAnonymizationScheduler | Periodic | Anonymize/delete GDPR-requested data |
| EligibilityRestorationScheduler | Configurable (default 1hr) | Restore donor eligibility after cooldown |
| EligibilityReminderScheduler | Periodic | Send eligibility reminders |
| ProfileNudgeScheduler | Periodic | Nudge incomplete profiles |
| AppointmentReminderScheduler | Periodic | Send appointment reminders |
| EmergencyMonitoringService | Configurable (default 5min) | Monitor/escalate/expire emergencies |

---

## Observability

- **OpenTelemetry** traces exported to Jaeger via OTLP (both services)
- **Micrometer + Prometheus** metrics exposed at `/actuator/prometheus`
- **Structured logging** with traceId/spanId MDC correlation
- **Virtual threads** enabled (`spring.threads.virtual.enabled=true`)
- **Redis caching** with configurable TTLs per entity type

---

## GDPR Compliance

- Users can request account deletion via `/api/v1/system/gdpr/request`
- Status flow: IN_PROGRESS -> COMPLETED or CANCELED
- Automatic anonymization/scheduling handles deletion
- User status transitions: PENDING_DELETION -> DELETED

---

## Docker Configuration

### docker-compose.yml
| Service | Image | Ports | Purpose |
|---|---|---|---|
| postgres | postgres:16-alpine | 5432 | Dual database (qatra + qatra_notification) |
| kafka | confluentinc/cp-kafka:latest | 9092, 9093 | KRaft mode (no Zookeeper) |
| redis | redis:7-alpine | 6379 | Caching |
| redisinsight | redis/redisinsight:latest | 5540 | Redis GUI |
| donation-service | Build from ./donation-service | 8080 | Core service |
| notification-service | Build from ./notification-service | 8082 | Notifications |
| nginx | nginx:alpine | 80, 5090 | API Gateway |
| jaeger | jaegertracing/all-in-one:1.57 | 16686, 4317, 4318 | Distributed tracing |
| prometheus | prom/prometheus:latest | 9090 | Metrics |
| loki | grafana/loki:latest | 3100 | Log aggregation |
| promtail | grafana/promtail:latest | - | Log collection |
| grafana | grafana/grafana:latest | 3000 | Dashboards |

### Dockerfiles (both services)
- Multi-stage build: Maven 3.9 + Eclipse Temurin 21 (build) -> Eclipse Temurin 21 JRE (runtime)

---

## CI/CD Pipelines

### CI Pipeline (.github/workflows/ci.yml)
- Trigger: Pull requests to master or qatra-pp branches
- Strategy: Matrix build for both services in parallel
- Steps: Checkout -> Setup Java 21 (Temurin) -> `./mvnw -B test`

### Deploy Pipeline (.github/workflows/deploy.yml)
- Trigger: Push to master
- Change Detection: Uses dorny/paths-filter to detect which service changed
- Per-service deployment: Login to GHCR -> Build Docker image -> Push -> SSH to server -> Import into k3s containerd -> kubectl rollout restart

---

## Key Technical Details

- Emergency radius escalation: starts at configured radius, increments by 10km per level up to 200km
- Health questionnaire permanent restriction keywords: `insulin, chemo, immunosuppressant`
- Consecutive emergency declines: after 3 consecutive declines, donor is flagged for manual review
- Slot generation: configurable lookahead (21 days), period (default 60 min), timezone (UTC)
- Certificate generation: PDF via OpenPDF library
- Seed data: 50 users, 39 donation centers across Tunisia
- Super Admin auto-seeded on startup
