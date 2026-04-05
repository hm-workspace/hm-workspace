# Hospital Management Architecture Generation Prompt

Use the following prompt with ChatGPT, Copilot, Claude, Gemini, or any architecture documentation generator to produce a full architecture pack for this project.

---

## Prompt

```md
You are a senior solution architect and technical writer.

Generate an architecture documentation pack for a Hospital Management platform based on the project context below.

Your response must be in Markdown and must include Mermaid diagrams.

## Primary Goal

Create:

1. A system architecture diagram
2. A deployment/infrastructure diagram
3. A service interaction diagram
4. At least 3 flow diagrams or sequence diagrams for core business journeys
5. Supporting architecture documents that explain boundaries, data ownership, integrations, and migration approach

## Output Requirements

Produce the final output in this exact section order:

1. Executive Summary
2. Architecture Overview
3. System Context Diagram
4. Container / Microservices Architecture Diagram
5. Deployment / Infrastructure Diagram
6. Service Responsibilities and Data Ownership Table
7. Core Business Flows
8. Integration and Communication Patterns
9. Security Architecture
10. Observability and Operational Concerns
11. Database and Data Migration Strategy
12. Assumptions, Risks, and Open Questions
13. Recommended Supporting Documents

## Diagram Rules

- Use Mermaid for all diagrams.
- Prefer `flowchart LR`, `flowchart TD`, `sequenceDiagram`, and `graph TD` as appropriate.
- Keep diagrams readable and grouped.
- Include legends where useful.
- Show both current-state and target-state where that distinction matters.
- If something is inferred rather than explicitly stated, mark it as an assumption.

## Project Context

### Workspace Structure

The workspace contains these repositories:

- `hm-appointment-service`
- `hm-auth-service`
- `hm-database`
- `hm-department-service`
- `hm-doctor-service`
- `hm-medical-records-service`
- `hm-notification-service`
- `hm-patient-service`
- `hm-portal`
- `hm-staff-service`
- `hm-workspace`
- `terraform-infra`

### Platform Style

- The platform is a Hospital Management system.
- The UI is a React + TypeScript application built with Vite.
- Backend services are independent .NET microservices.
- Most services follow a layered structure with projects similar to:
  - `*.Api`
  - `*.InternalModels`
  - `*.Repository`
  - `*.Services`
  - `*.Utils`
- The auth service additionally contains a data layer project.
- Docker is used for packaging services.
- Terraform is used for infrastructure provisioning.
- GitVersion is used for semantic versioning and release tagging.

### Known Services

The service inventory includes:

1. `api-gateway`
2. `auth-service`
3. `patient-service`
4. `doctor-service`
5. `appointment-service`
6. `medical-records-service`
7. `department-service`
8. `staff-service`
9. `notification-service`
10. `hm-portal` as the web frontend

### Service Responsibilities

#### 1. Identity and Access (`auth-service`)

- Owns users, roles, tokens, credentials, password flows.
- APIs include login, register, refresh token, password management, profile management.
- Publishes events such as:
  - `UserRegistered`
  - `UserRoleChanged`
  - `PasswordChanged`

#### 2. Patient Domain (`patient-service`)

- Owns:
  - `patients`
  - `patient_allergies`
  - `patient_emergency_contacts`
  - `patient_vitals`
  - `patient_insurance`
- APIs include patient CRUD, search, allergies, contacts, vitals.
- Consumes identity claims from auth.

#### 3. Doctor Domain (`doctor-service`)

- Owns:
  - `doctors`
  - `doctor_qualifications`
  - `doctor_availability`
  - `doctor_ratings`
- APIs include doctor CRUD, specializations, and availability.

#### 4. Scheduling (`appointment-service`)

- Owns:
  - `appointments`
  - `appointment_symptoms`
  - `appointment_prescriptions`
- APIs include schedule, conflict checking, cancellation, and status transitions.
- Depends on patient and doctor existence.

#### 5. Clinical Records (`medical-records-service`)

- Owns:
  - `medical_records`
  - `patient_medical_history`
- APIs include record creation, retrieval, and patient timeline views.

#### 6. Hospital Operations (`department-service`, `staff-service`)

- Department owns:
  - `departments`
  - `department_contact_info`
  - `department_locations`
  - `department_services`
- Staff owns:
  - `staff`
  - `staff_qualifications`
  - `staff_shift_schedules`
  - `staff_type`

#### 7. Communication (`notification-service`)

- Owns templates, outbound messages, and delivery state.
- Consumes domain events and sends reminders/alerts.

### API Gateway Rules

- External clients should call only `api-gateway`.
- Internal service-to-service calls use private networking/service discovery.
- Gateway applies JWT authentication and propagates identity headers.

### Frontend Notes

- The frontend repository is `hm-portal`.
- It is a unified portal UI for the hospital platform.
- Stack includes:
  - React
  - TypeScript
  - Axios
  - Redux Toolkit
  - React Router DOM
  - Tailwind CSS
  - Recharts
- It talks to backend APIs and should be shown as the main browser client in diagrams.

### Database Notes

- There is a dedicated database repository tracking SQL Server database objects.
- Structure includes folders for:
  - Database
  - User
  - Table
  - View
  - StoredProcedure
  - Index
  - Constraint
  - Other
  - Raw
- The current migration strategy starts with a shared SQL Server database and evolves toward service-owned databases.

### Migration Strategy

Use this staged migration strategy in the documentation:

#### Stage 1: Shared database with schema ownership rules

- Keep one SQL Server instance.
- Enforce per-service schema namespaces and ownership contracts.

#### Stage 2: Split critical stores

- Move Identity and Appointments into dedicated databases.
- Introduce outbox/event relay to avoid distributed transactions.

#### Stage 3: Full decomposition

- Each service owns its own persistence and migration pipeline.
- Cross-service reads should happen through APIs, read models, or events.

### Event Contracts

At minimum, include these events in the architecture:

- `AppointmentCreated`
- `AppointmentCancelled`
- `DoctorAvailabilityUpdated`
- `PatientAllergyUpdated`
- `MedicalRecordCreated`

### Non-Functional Standards

- Correlation ID required on all HTTP requests.
- OpenTelemetry tracing from gateway to services.
- Backward-compatible API evolution with versioned endpoints such as `/v1` and `/v2`.

### AWS Target Platform

Model the target deployment on AWS with:

- ECS Fargate services
- Application Load Balancer
- Amazon ECR per service
- VPC with public and private subnets
- SQL Server database initially shared, later decomposed
- AWS Secrets Manager or SSM Parameter Store for secrets
- CloudWatch for logs and metrics
- GitHub Actions for CI/CD

### Delivery and Release Model

- Feature branches go through PR validation.
- `develop` deploys to Dev.
- Release tags on `main` deploy to Prod.
- GitVersion generates semantic Docker tags and release versions.

## Required Business Flows

Create sequence or flow diagrams for at least these scenarios:

1. User Login and Token Validation
2. Patient Registration or Profile Creation
3. Appointment Booking with Doctor Availability Check
4. Appointment Cancellation with Notification Trigger
5. Medical Record Creation after Consultation

If useful, combine or add flows, but cover all five scenarios.

## Documentation Guidance

### Architecture Overview

- Explain the overall platform in plain language.
- Distinguish current state from target state.

### System Context Diagram

- Show users, frontend, gateway, services, database, and external infrastructure.

### Container / Microservices Diagram

- Show the frontend, gateway, all services, data stores, and event-driven relationships.

### Deployment Diagram

- Show GitHub, CI/CD, ECR, ECS/Fargate, ALB, VPC, private subnets, SQL Server, secrets, and observability components.

### Service Responsibilities and Data Ownership Table

- Include service name, responsibility, owned entities/data, incoming dependencies, outgoing integrations, and key APIs.

### Integration and Communication Patterns

- Separate synchronous HTTP interactions from asynchronous event-driven interactions.
- Identify likely producer/consumer relationships.

### Security Architecture

- Cover JWT, RBAC, secrets handling, network segmentation, and auditability.

### Observability and Operations

- Cover logs, metrics, tracing, health checks, CI/CD, and deployment strategy.

### Database and Migration Strategy

- Explain how the shared SQL Server evolves into service-owned persistence.

### Assumptions, Risks, and Open Questions

- Explicitly call out where the repo gives enough evidence and where assumptions were needed.

### Recommended Supporting Documents

Recommend and briefly describe the next documents the team should maintain, such as:

- C4 model set
- API inventory
- Event catalog
- Data ownership matrix
- Deployment runbook
- Incident response runbook
- Security threat model
- ADR list

## Tone and Quality Bar

- Write like an architect producing documentation for engineers, tech leads, and stakeholders.
- Be specific to this project, not generic.
- Avoid placeholder text.
- Use concise but complete explanations.
- Where repo evidence is limited, say "Assumption" and keep the assumption reasonable.
```

---

## Suggested Use

Paste only the prompt block above into your preferred AI tool if you want the generated output directly.

If you want stricter output, add one of these lines before the prompt:

- `Return diagrams only, with minimal narrative.`
- `Return a full architecture document suitable for README/docs publication.`
- `Return Mermaid diagrams plus tables only.`
- `Return output in C4-style sections.`

## Notes

- This prompt reflects the current workspace structure and documented target-state architecture.
- The `api-gateway` is included because it appears in workspace documentation even though its repository is not currently present in the visible folder structure.
- The data strategy is intentionally documented as phased because the repo indicates both a shared SQL Server present state and a service-owned target state.
