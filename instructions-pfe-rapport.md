# Instructions for Generating the PFE Rapport

## Overview

This document provides instructions for an LLM to generate a complete PFE (Projet de Fin d'Études) rapport for the **Qatra** web application -- a blood donation management platform. The rapport should follow the structure and style of the example rapport provided (the e-commerce Web3 project), adapted to Qatra's domain and architecture.

**Language:** The rapport must be written entirely in **French**.

**Project:** Qatra -- Plateforme de Gestion de la Donation de Sang

**Technologies:**
- Backend: Java 21, Spring Boot 4.0.6, Spring Modulith, JPA/Hibernate, PostgreSQL 16, Apache Kafka, Redis 7
- Frontend: Angular 20.3.x, NgRx Signals, PrimeNG 20.4.0, Tailwind CSS 4.3.1, MapLibre GL
- Infrastructure: Docker, k3s (Kubernetes), Traefik, Nginx, Prometheus, Grafana, Loki, Jaeger
- CI/CD: GitHub Actions, GHCR, SSH deployment

**Reference files for code details:**
- `rapport/qatra-backend.md` -- Backend architecture, API endpoints, database schema, Kafka events, scheduled tasks
- `rapport/qatra-frontend.md` -- Frontend components, services, routing, state management, models, validation
- `rapport/qatra-infra.md` -- Kubernetes manifests, monitoring stack, ingress, deployment pipeline
- `rapport/instructions-diagram-check.md` -- Use cases, class diagram, and user flows (already complete, do NOT modify)

---

## Rapport Structure

The rapport follows the **Scrum sprint-based** structure from the example. Each sprint chapter contains: Introduction, Backlog du sprint, Spécification des besoins, Conception, Implémentation, and Conclusion.

### Table of Contents

```
Introduction générale
1. Chapitre 1 : Cadre général du projet
2. Sprint 0 : Analyse et Spécification du projet
3. Sprint 1 : Authentification et Gestion des Centres
4. Sprint 2 : Gestion des Donations
5. Sprint 3 : Système de Rendez-vous
6. Sprint 4 : Opérations du Personnel et Fonctionnalités Admin
7. Sprint 5 : Réponse d'Urgence et Super Admin
8. Sprint 6 : Moteur de Correspondance et Moteur de Notification
9. Sprint 7 : Analytiques et Finalisation
Conclusion générale
Nétographie
Annexes
```

---

## Chapter-by-Chapter Instructions

### Introduction générale

Write a general introduction covering:
- The context of blood donation management in Tunisia and the MENA region
- The challenges: manual tracking, donor coordination, emergency response delays, lack of real-time visibility
- The objective: build a modern, scalable web platform for blood donation management
- Brief overview of the microservices architecture
- Brief overview of the tech stack chosen and why
- Organization of the rapport (chapter summary)

### Chapitre 1 : Cadre général du projet

#### Introduction

Introduce the chapter's purpose: setting the project context.

#### 1.1 Présentation de l'organisme d'accueil

- **Organisation:** Keyrus MEA (digital consulting agency)
- Describe Keyrus as a digital transformation consulting firm
- Mention their expertise in web/mobile development, cloud architecture, and DevOps

##### 1.1.1 Organigramme hiérarchique de Keyrus MEA
- Describe the hierarchical structure (Direction Générale -> Directions -> Équipes)
- Mention the PFE was done within a specific team

##### 1.1.2 Organigramme de notre équipe
- Describe the agile team structure: Product Owner, Scrum Master, Developers (Frontend/Backend/DevOps)
- Mention the role of the PFE student

##### 1.1.3 Le positionnement de Keyrus
- Keyrus's positioning in the digital consulting market
- Their approach to agile development and modern architectures

#### 1.2 Problématique

Define the problem statement:
- Blood donation centers in Tunisia face challenges: manual appointment tracking, inefficient emergency response, no real-time donor matching, fragmented notification systems
- Existing solutions are either traditional (paper-based) or lack integration
- The need for a centralized, real-time platform that connects donors, centers, and staff

#### 1.3 Étude de l'existant

##### 1.3.1 Les plateformes e-commerce traditionnelles (Web2)
- **Adapt this section** to compare traditional blood donation management systems:
  - Hospital-based manual systems (paper registers)
  - Basic web portals (static, no real-time)
  - Mobile apps (limited features, no emergency matching)
  - Limitations: no real-time matching, no automated notifications, no geographic proximity search, no reliability scoring

##### 1.3.2 Les plateformes natives du Web3
- **Adapt this section** to compare with modern platform approaches:
  - Event-driven architectures
  - Real-time notification systems
  - Geographic/proximity-based matching
  - Microservices with independent scaling

#### 1.4 Critique de l'Existant

Synthesize the limitations:
- No centralized donor management
- Manual emergency response (phone calls, SMS)
- No real-time donor matching by proximity and blood type compatibility
- No automated eligibility tracking (cooldown periods)
- No reliability scoring for donor behavior
- No GDPR compliance
- No observability (monitoring, logging, tracing)

#### 1.5 Solution Proposée : Une Architecture Hybride pour la Confiance

Describe the Qatra solution:
- Microservices architecture (donation-service + notification-service)
- Event-driven communication via Kafka
- Real-time notifications via WebSocket
- Geographic matching with expanding radius algorithm
- JWT-based authentication with RBAC (4 roles)
- GDPR compliance (deletion requests, anonymization)
- Full observability stack (Prometheus, Grafana, Loki, Jaeger)
- Kubernetes deployment (k3s) with automated CI/CD

#### 1.6 Choix méthodologique

##### 1.6.1 Adoption du Scrum
- Explain Scrum methodology choice
- Sprint duration: 3 weeks (21 days)
- 8 sprints total (January 1 - June 29)
- Artifacts: Product Backlog, Sprint Backlog, Increment
- Ceremonies: Sprint Planning, Daily Standup, Sprint Review, Sprint Retrospective

#### Conclusion

Summarize the chapter.

---

### Sprint 0 : Analyse et Spécification du projet

#### Introduction

Introduce the analysis and specification phase.

#### 1.2 Identification des acteurs

List all actors from `instructions-diagram-check.md`:
1. **Donor (Donneur)** -- registers, manages profile, books appointments, responds to emergencies
2. **Center Staff (Personnel du centre)** -- manages appointments, conducts screenings, creates emergencies
3. **Center Admin (Administrateur de centre)** -- manages center info, staff, slots, analytics
4. **Super Admin (Super Administrateur)** -- manages users, centers, roles, GDPR, system config
5. **System (Système)** -- automated tasks: matching, notifications, eligibility, slot generation, audit

#### 1.3 Les besoins fonctionnels

##### Pour un client (Donor)
Extract from use cases in `instructions-diagram-check.md` (UC-D01 to UC-D30):
- Authentication (register, login, logout, password reset, email verification)
- Profile management (dashboard, personal info, health questionnaire, blood type, location, availability)
- Emergency response (receive alerts, view details, accept/decline)
- Appointment management (browse centers, view slots, book, reschedule, cancel, check-in via QR, view history)
- Impact tracking (eligibility status, reliability score, certificates, impact dashboard)
- GDPR (request account deletion)
- Notification preferences (frequency, quiet hours, max distance)

##### Pour un administrateur (Center Admin + Super Admin)
Extract from use cases UC-CA01 to UC-CA10 and UC-SA01 to UC-SA13:
- Center Admin: center registration, update info, configure capacity/slots, closures, staff management, analytics, reports
- Super Admin: user management (CRUD, status, roles), center approval, GDPR processing, health restriction override, system dashboard, audit logs, reports

##### Pour un oracle (System/Automated)
Extract from use cases UC-SYS01 to UC-SYS17:
- Session management (issue, refresh, expire)
- Matching engine (scan, filter, score, rank, tiered matching with expanding radius)
- Notification engine (send alerts, track delivery, retry, respect quiet hours)
- Eligibility management (mark ineligible after donation, auto-restore, flag permanent restrictions)
- Reliability scoring (adjust on completion/no-show/declines, flag after 3 consecutive declines)
- Slot management (auto-generate, block, release)
- Emergency monitoring (escalate, expire)
- Analytics (real-time metrics, demand forecasting, audit logging)

#### 1.4 Les besoins non fonctionnels

- **Performance:** Response time < 200ms for API calls, support 1000+ concurrent users
- **Scalability:** Horizontal scaling via Kubernetes, independent service scaling
- **Availability:** 99.9% uptime, health checks, automatic restarts
- **Security:** JWT authentication, RBAC, BCrypt password hashing, HTTPS/TLS, CORS configuration
- **GDPR Compliance:** Account deletion with 30-day grace period, PII anonymization
- **Observability:** Distributed tracing (Jaeger), metrics (Prometheus), logging (Loki), dashboards (Grafana)
- **Maintainability:** Hexagonal architecture, modular monolith (Spring Modulith), clean code, automated tests
- **Accessibility:** Responsive design (mobile-first for donors), RTL support for Arabic

#### 1.5 Diagramme de cas d'utilisation global

Reference the complete use case diagram from `instructions-diagram-check.md`:
- Donor use cases (UC-D01 to UC-D30)
- Center Staff use cases (UC-CS01 to UC-CS11)
- Center Admin use cases (UC-CA01 to UC-CA10)
- Super Admin use cases (UC-SA01 to UC-SA13)
- System use cases (UC-SYS01 to UC-SYS17)

Present as a Mermaid use case diagram.

#### 1.6 Le Backlog produit

Create a prioritized product backlog as a table:

| ID | User Story | Priority | Sprint | Story Points |
|---|---|---|---|---|
| US-01 | En tant que donneur, je veux m'inscrire avec email/téléphone | High | Sprint 1 | 5 |
| US-02 | En tant que donneur, je veux me connecter | High | Sprint 1 | 3 |
| ... | (map all use cases to user stories) | ... | ... | ... |

#### 1.7 Diagramme de classe global

Reference the complete class diagram from `instructions-diagram-check.md`:
- User, UserRole, Session, VerificationToken, GDPRDeletionRequest, AuditLog
- DonorProfile, HealthQuestionnaire, NotificationPreferences
- DonationCenter, OperatingHours, Slot
- Appointment, HealthScreening
- EmergencyRequest, MatchResult, DonorResponse
- Notification

Present as a Mermaid class diagram with all relationships.

#### 1.8 Spécification de l'Architecture

##### 1.8.1 Architecture Physique Globale

Describe the physical architecture:
- Client (Angular SPA) -> Nginx (reverse proxy) -> API Gateway (Traefik in prod)
- Backend: Two microservices (donation-service:8080, notification-service:8082)
- Message broker: Apache Kafka (KRaft mode)
- Databases: PostgreSQL 16 (two databases), Redis 7 (caching)
- Observability: Jaeger (tracing), Prometheus (metrics), Loki + Promtail (logs), Grafana (dashboards)
- Deployment: k3s (Kubernetes) with Let's Encrypt TLS

Include a Mermaid diagram showing the architecture.

##### 1.8.2 Architecture Logique et Modèles de Conception

Describe the logical architecture:
- **Hexagonal Architecture** (Ports & Adapters) per module
- **Spring Modulith** for modular monolith within donation-service
- **Saga Pattern** for Kafka-based event flow with compensation
- **CQRS-lite** for separate command/query interfaces
- **NgRx Signal Store** for frontend state management

Include module dependency diagram.

#### 1.9 Environnement de développement

List all tools and versions:
- IDE: IntelliJ IDEA / VS Code
- Java 21 (Eclipse Temurin)
- Maven 3.9
- Node.js 24, npm
- Angular CLI 20.3.x
- Docker & Docker Compose
- PostgreSQL 16, Redis 7, Kafka (Confluent)
- Git & GitHub
- Postman / curl for API testing
- Chrome DevTools for frontend debugging

#### Conclusion

Summarize the sprint.

---

### Sprint 1 : Authentification et Gestion des Centres

#### Introduction

Introduce the sprint: implementing authentication, user management, and donation center CRUD.

#### 2.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-01 | Inscription donneur | 5 | Done |
| US-02 | Connexion multi-portal | 5 | Done |
| US-03 | Déconnexion | 2 | Done |
| US-04 | Rafraîchissement token | 3 | Done |
| US-05 | Vérification email | 3 | Done |
| US-06 | Mot de passe oublié/réinitialisation | 5 | Done |
| US-07 | Changement mot de passe | 3 | Done |
| US-08 | CRUD centres de donation | 8 | Done |
| US-09 | Liste des centres publics | 3 | Done |
| US-10 | Approbation centres par Super Admin | 5 | Done |

#### 2.2 Spécification des besoins

For each user story, describe:
- Functional requirements
- Acceptance criteria
- API endpoints involved
- Frontend components involved

**Auth endpoints:** POST /api/v1/auth/login, /signup, /logout, /refresh, /verify-email, /forgot-password, /reset-password, /change-password

**Center endpoints:** GET/POST/PUT/PATCH/DELETE /api/v1/centers, GET /api/v1/centers/public, PATCH /api/v1/centers/{id}/approve

#### 2.3 Conception

For each feature:
- Class diagram excerpt (relevant entities)
- Sequence diagram (login flow, registration flow, center CRUD flow)
- Database tables involved: users, user_roles, sessions, verification_tokens, donation_centers

#### 2.4 Implémentation

For each feature, describe the implementation with code references:

**Backend:**
- SecurityConfig.java (JWT filter, BCrypt, public endpoints)
- AuthController.java (login, signup, logout, refresh, verify-email, forgot-password, reset-password)
- JwtTokenProvider.java (token generation/validation)
- JwtAuthenticationFilter.java (token extraction from header)
- UserController.java (CRUD operations)
- CenterController.java (CRUD + approval)
- DonorController.java (profile management)

**Frontend:**
- auth.store.ts (NgRx Signal Store for auth state)
- auth.service.ts (HTTP calls to auth endpoints)
- auth.interceptor.ts (Bearer token attachment, auto-refresh on 401)
- guards/auth.guard.ts, role.guard.ts
- LoginPageComponent (multi-portal login)
- RegisterPageComponent
- MainLayoutComponent (sidebar + toolbar)

Include relevant code snippets (short, illustrative).

#### Conclusion

Summarize the sprint achievements.

---

### Sprint 2 : Gestion des Donations

#### Introduction

Introduce the sprint: donor profiles, health questionnaires, eligibility, reliability scoring, certificates.

#### 3.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-11 | Profil donneur complet | 5 | Done |
| US-12 | Questionnaire santé | 5 | Done |
| US-13 | Type sanguin + compatibilité | 3 | Done |
| US-14 | Localisation (GPS/manuel) | 5 | Done |
| US-15 | Statut de disponibilité | 3 | Done |
| US-16 | Éligibilité et score de fiabilité | 5 | Done |
| US-17 | Tableau de bord impact | 5 | Done |
| US-18 | Certificats de donation (PDF) | 5 | Done |
| US-19 | Préférences de notification | 3 | Done |
| US-20 | Onboarding 3 étapes | 8 | Done |

#### 3.2 Spécification des besoins

**Donor endpoints:** GET/PUT /api/v1/donors/me, PUT /blood-type, /location, /availability, /notification-prefs, GET /eligibility, /impact, /certificates, /certificates/{id}/download

**Health questionnaire:** GET/PUT /api/v1/donors/me/health-questionnaire

#### 3.3 Conception

- DonorProfile entity with all fields
- HealthQuestionnaire entity
- NotificationPreferences (embedded JSON)
- Eligibility calculation logic (cooldown period: 56 days)
- Reliability score algorithm (0-100, adjustments on events)
- Blood type compatibility matrix (BloodType.canDonateTo())
- Certificate PDF generation (OpenPDF)

#### 3.4 Implémentation

**Backend:**
- DonorController.java (all /me endpoints)
- DonorProfile entity, HealthQuestionnaire entity
- Eligibility calculation (canDonate(), eligibleFromDate)
- Reliability scoring (adjust on completion, no-show, declines)
- PdfCertificateService (OpenPDF)
- SlotGenerationScheduler (auto-generate slots 21 days ahead)

**Frontend:**
- DonorStore (NgRx Signal Store)
- DonorService (HTTP calls)
- OnboardingPageComponent (3-step wizard)
- DonorDashboardPageComponent
- LocationPickerComponent (MapLibre GL + GPS + reverse geocoding)
- GeolocationService (continuous GPS tracking every 5 min, Haversine skip < 100m)

#### Conclusion

Summarize the sprint.

---

### Sprint 3 : Système de Rendez-vous

#### Introduction

Introduce the sprint: appointment booking, check-in (QR), screening, completion, queue management.

#### 4.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-21 | Prise de rendez-vous | 8 | Done |
| US-22 | Annulation/Reporter RDV | 5 | Done |
| US-23 | Check-in QR code | 8 | Done |
| US-24 | Dépistage santé | 5 | Done |
| US-25 | Complétion appointment (ml collectés) | 5 | Done |
| US-26 | File d'attente en temps réel | 5 | Done |
| US-27 | Historique des donations | 3 | Done |
| US-28 | Gestion des créneaux | 5 | Done |

#### 4.2 Spécification des besoins

**Appointment endpoints:** POST /api/v1/appointments, POST /{id}/check-in, POST /{id}/screening, POST /{id}/screening-results, POST /{id}/complete, POST /{id}/no-show, POST /{id}/cancel, PUT /{id}/reschedule, GET /{id}, GET (paginated), GET /by-donor/{donorId}, GET /by-center/{centerId}, GET /queue

**Slot endpoints:** GET /api/v1/centers/{id}/slots, PATCH /{id}/slots/{slotId}/block, POST /{id}/closures

#### 4.3 Conception

- Appointment entity lifecycle: SCHEDULED -> CHECKED_IN -> IN_SCREENING -> COMPLETED/CANCELLED/NO_SHOW
- Slot management: maxBookings, bookedCount, regularBookedCount, isBlocked
- Health Screening: weight, blood pressure, hemoglobin, temperature, eligible
- QR Code generation for appointments
- Queue management (real-time list for staff)

#### 4.4 Implémentation

**Backend:**
- AppointmentController.java (all endpoints)
- Appointment entity with status transitions
- Slot generation and management
- Health screening recording
- Queue query with date range filtering

**Frontend:**
- AppointmentBookingPageComponent (slot selection)
- CheckinPageComponent (html5-qrcode camera scan + manual entry)
- ScreeningPageComponent (Zod-validated form)
- CompletionPageComponent (outcome, ml collected)
- StaffQueuePageComponent (real-time queue)
- DonorAppointmentsPageComponent (list with actions)

#### Conclusion

Summarize the sprint.

---

### Sprint 4 : Opérations du Personnel et Fonctionnalités Admin

#### Introduction

Introduce the sprint: staff operations, admin dashboard, user management, center management, reporting.

#### 5.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-29 | Dashboard admin avec métriques | 5 | Done |
| US-30 | Gestion des utilisateurs (CRUD) | 8 | Done |
| US-31 | Gestion des rôles | 5 | Done |
| US-32 | Dashboard staff du centre | 5 | Done |
| US-33 | Gestion du personnel du centre | 5 | Done |
| US-34 | Journal d'activité | 3 | Done |
| US-35 | Rapports CSV | 5 | Done |
| US-36 | Restrictions de santé | 5 | Done |
| US-37 | Santé du système | 3 | Done |

#### 5.2 Spécification des besoins

**Admin endpoints:** GET /api/v1/analytics/metrics, GET /api/v1/analytics/audit-logs, GET /api/v1/analytics/audit-logs/export, GET /api/v1/analytics/centers/{id}/metrics

**Staff endpoints:** GET /api/v1/staff/me, GET /api/v1/admin/me

**Report endpoints:** GET /api/v1/centers/{id}/report (CSV)

#### 5.3 Conception

- Admin dashboard metrics aggregation
- Audit log system (every state-changing action)
- Staff profile and center association
- CSV report generation for centers
- System health monitoring (actuator endpoints)

#### 5.4 Implémentation

**Backend:**
- AnalyticsController.java (metrics, audit logs, export)
- ReportController.java (CSV generation)
- StaffController.java, AdminController.java
- AuditLog entity and automatic logging

**Frontend:**
- DashboardPageComponent (Chart.js bar + doughnut charts)
- UserManagementPageComponent (CRUD table)
- CenterApprovalPageComponent
- AuditLogsPageComponent (with CSV export via PapaParse)
- StaffCenterAnalyticsPageComponent (custom canvas charts)
- SystemHealthPageComponent
- StatusBadgeComponent, EmptyStateComponent (shared UI)

#### Conclusion

Summarize the sprint.

---

### Sprint 5 : Réponse d'Urgence et Super Admin

#### Introduction

Introduce the sprint: emergency blood requests, donor matching, Super Admin features, GDPR.

#### 6.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-38 | Création d'urgence | 5 | Done |
| US-39 | Moteur de correspondance (matching) | 13 | Done |
| US-40 | Réponse du donneur (accepter/refuser) | 5 | Done |
| US-41 | Escalade automatique | 8 | Done |
| US-42 | Résolution d'urgence | 5 | Done |
| US-43 | Gestion des utilisateurs Super Admin | 8 | Done |
| US-44 | Approbation des centres | 5 | Done |
| US-45 | Conformité RGPD | 8 | Done |
| US-46 | Journal d'audit | 5 | Done |

#### 6.2 Spécification des besoins

**Emergency endpoints:** POST /api/v1/emergencies, PUT /{id}, POST /{id}/cancel, POST /{id}/resolve, GET /{id}, GET (paginated), GET /open/{bloodType}, GET /nearby, POST /{emergencyId}/responses/accept, POST /{emergencyId}/responses/decline, GET /{id}/responses

**GDPR endpoints:** POST /api/v1/system/gdpr/request, POST /{id}/complete, POST /{id}/cancel

#### 6.3 Conception

- EmergencyRequest entity with lifecycle: OPEN -> FULFILLED/CANCELLED/EXPIRED
- Matching algorithm: expanding radius (starts at matchRadius, increments by 10km up to 200km)
- Donor scoring: reliability score + distance sorting
- MatchResult and DonorResponse entities
- Escalation: automatic radius widening when units not met within timeframe
- Reliability penalties: 3 consecutive declines -> flagged for manual review
- GDPR: 30-day grace period, PII anonymization, audit logging

#### 6.4 Implémentation

**Backend:**
- EmergencyController.java (all endpoints)
- MatchingService.java (expanding radius algorithm, BloodType.canDonateTo())
- EmergencyService.java (CRUD, escalation, resolution)
- Donor matching with reliability + distance scoring
- GDPRService.java (request, complete, cancel)
- EmergencyMonitoringService (scheduled: escalate, expire)
- EligibilityRestorationScheduler, EligibilityReminderScheduler

**Frontend:**
- EmergencyCreatePageComponent (blood type, units, urgency, phone, match radius)
- EmergencyListPageComponent (paginated list)
- EmergencyDetailPageComponent (responses, accept/decline)
- EmergencyHistoryPageComponent
- HealthRestrictionPageComponent (Super Admin)
- DeletionRequestsPageComponent (GDPR)

#### Conclusion

Summarize the sprint.

---

### Sprint 6 : Moteur de Correspondance et Moteur de Notification

#### Introduction

Introduce the sprint: Kafka-based notification engine, WebSocket real-time notifications, email channels, retry logic.

#### 7.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-47 | Notifications en temps réel (WebSocket) | 8 | Done |
| US-48 | Notifications email (Resend/SendGrid/Gmail) | 8 | Done |
| US-49 | Centre de notifications | 5 | Done |
| US-50 | Préférences de notification (quiet hours) | 5 | Done |
| US-51 | Relance automatique (retry) | 5 | Done |
| US-52 | Rapatriement des résultats (saga compensation) | 8 | Done |
| US-53 | Rappels de rendez-vous | 5 | Done |
| US-54 | Rappels d'éligibilité | 3 | Done |

#### 7.2 Spécification des besoins

**Notification endpoints:** GET /api/v1/notifications (filterable, paginated), PATCH /{id}/read, PATCH /read-all, GET /unread-count

**WebSocket:** ws://qtra-ws.zayenha.app/ws/notifications?token=<JWT>

**Kafka topics:** emergency.created, appointment.reminder, eligibility.restored, eligibility.reminder, password.reset, email.verification, notification.result, profile.completion.nudge

#### 7.3 Conception

- Notification entity with channels (IN_APP, EMAIL, PUSH)
- Channel routing per event type (emergency -> IN_APP, password reset -> IN_APP + EMAIL)
- Quiet hours: check NotificationPreferences.quietHours before sending
- Retry logic: @Retryable with exponential backoff (3 attempts, base 2000ms)
- Saga compensation: on DELIVERY_FAILED for critical events, delete verification token
- WebSocket broadcast: ConcurrentHashMap<Long, Set<WebSocketSession>>
- Three email providers: Resend, SendGrid, Gmail SMTP (conditional activation)

#### 7.4 Implémentation

**Backend (notification-service):**
- NotificationEventConsumer.java (Kafka consumer, dispatches notifications)
- NotificationDeliveryService.java (@Retryable delivery)
- NotificationBroadcastHandler.java (WebSocket broadcast)
- NotificationResultPublisher.java (publishes result events back)
- NotificationResultListener.java (saga compensation on failure)
- ResendEmailChannel, SendGridEmailChannel, GmailSmtpEmailChannel (conditional)
- NotificationController.java (REST API)

**Frontend:**
- SocketService.ts (WebSocket client with auto-reconnect)
- NotificationStore.ts (NgRx Signal Store with WebSocket integration)
- NotificationService.ts (HTTP calls)
- NotificationBellComponent (unread badge, recent 5, mark-all-read)
- NotificationCenterPageComponent (full page)

#### Conclusion

Summarize the sprint.

---

### Sprint 7 : Analytiques et Finalisation

#### Introduction

Introduce the sprint: analytics dashboards, monitoring, final polish, deployment.

#### 8.1 Backlog du sprint

| ID | User Story | Points | Status |
|---|---|---|---|
| US-55 | Dashboard analytiques admin | 5 | Done |
| US-56 | Métriques par centre | 5 | Done |
| US-57 | Export CSV audit logs | 3 | Done |
| US-58 | Configuration système | 5 | Done |
| US-59 | Page de contact | 2 | Done |
| US-60 | Dashboard atterrissage | 5 | Done |
| US-61 | Déploiement Docker | 8 | Done |
| US-62 | Déploiement Kubernetes (k3s) | 13 | Done |
| US-63 | CI/CD GitHub Actions | 8 | Done |
| US-64 | Stack de monitoring | 8 | Done |

#### 8.2 Spécification des besoins

**Analytics endpoints:** GET /api/v1/analytics/metrics (cached 60s), GET /api/v1/analytics/centers/{id}/metrics (cached 600s)

**Monitoring:** Prometheus scrapes /actuator/prometheus, Grafana dashboards (Overview + Logs), Jaeger traces, Loki log aggregation

**Deployment:** Docker Compose (local), k3s (production), GitHub Actions (CI/CD)

#### 8.3 Conception

- Analytics metrics aggregation (total donors, centers, appointments, emergencies, completion rate)
- Center-specific metrics with day-count charts
- Grafana dashboard layout (7 row groups, ~30 panels)
- Log pipeline: Promtail -> Loki -> Grafana
- Trace pipeline: OpenTelemetry -> Jaeger
- CI pipeline: test on PR
- CD pipeline: build -> push to GHCR -> SSH -> k3s rollout

#### 8.4 Implémentation

**Backend:**
- AnalyticsController.java (metrics with @Cacheable)
- ReportController.java (CSV generation)
- SystemController.java (GDPR, config)

**Frontend:**
- Admin DashboardPageComponent (Chart.js bar + doughnut)
- AdminCenterOverviewComponent (Chart.js bar + pie)
- StaffCenterAnalyticsPageComponent (custom canvas)
- LandingPageComponent (animated stats, MapLibre map, emergency feed)
- ContactPageComponent

**Infrastructure:**
- docker-compose.yml (13 services)
- k3s/ manifests (16 files)
- Grafana dashboards (qatra-overview.json: 3784 lines, qatra-logs.json: 708 lines)
- Prometheus config (6 scrape jobs)
- Loki + Promtail config
- deploy.sh (8-step deployment script)
- GitHub Actions CI/CD (ci.yml, deploy.yml)

#### Conclusion

Summarize the sprint and overall project achievements.

---

### Conclusion générale

Write a comprehensive conclusion covering:
- Summary of what was built (Qatra platform)
- Key technical achievements (microservices, event-driven, real-time matching, observability)
- Challenges faced and how they were overcome
- Lessons learned (agile methodology, microservices complexity, DevOps)
- Future improvements:
  - Mobile app (React Native / Flutter)
  - AI-powered demand forecasting
  - Blockchain for donation certificate verification
  - Multi-language support (Arabic, French, English)
  - Payment integration for donor incentives
  - Advanced analytics (predictive models)
  - Load testing and performance optimization

### Nétographie

List all references in proper citation format:
- Spring Boot documentation
- Angular documentation
- Kafka documentation
- Kubernetes/k3s documentation
- Grafana/Prometheus/Loki/Jaeger documentation
- MapLibre GL documentation
- PrimeNG documentation
- NgRx documentation
- Docker documentation
- GitHub Actions documentation
- Academic papers on blood donation management
- GDPR regulation references

### Annexes

Include supplementary materials:
- Full API documentation (Swagger/OpenAPI)
- Database migration scripts (Flyway)
- Docker Compose file
- Key Kubernetes manifests
- Environment configuration files
- Screenshots of the application
- User manual / quick start guide

---

## Writing Guidelines

1. **Language:** French throughout. Use technical English only for code snippets, class names, and technology names.
2. **Tone:** Academic/professional. Third person. Past tense for what was done, present tense for descriptions.
3. **Code snippets:** Include short, illustrative code snippets (5-15 lines max) in the Implémentation sections. Always reference the file path and line number.
4. **Diagrams:** Use Mermaid syntax for all diagrams (use case, class, sequence, architecture). The diagrams from `instructions-diagram-check.md` should be included in Sprint 0.
5. **Tables:** Use markdown tables for backlogs, endpoint lists, entity comparisons, etc.
6. **Cross-references:** Reference `rapport/qatra-backend.md`, `rapport/qatra-frontend.md`, and `rapport/qatra-infra.md` for detailed technical information. Do NOT copy entire code blocks -- summarize and reference.
7. **Page estimates:** Each sprint chapter should be approximately 8-15 pages when rendered. Total rapport: ~120-150 pages.
8. **Consistency:** Maintain consistent terminology throughout (e.g., always "donneur" not "donateur", always "centre de donation" not "centre de collecte").
