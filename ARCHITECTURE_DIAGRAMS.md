# Hospital Management Architecture Diagrams

This file is a diagrams-only companion to the main architecture document. It is optimized for direct Mermaid rendering in Markdown viewers, documentation portals, and design review sessions.

## 1. System Context Diagram

```mermaid
flowchart LR
    subgraph Users
        PAT[Patient Support]
        DOC[Doctor]
        ADM[Admin / Operations]
        REC[Reception / Front Desk]
    end

    subgraph Experience
        PORTAL[hm-portal<br/>React + TypeScript + Vite]
    end

    subgraph Edge
        GATEWAY[api-gateway<br/>JWT validation<br/>Versioned routing<br/>Correlation ID propagation]
    end

    subgraph Domain_Services
        AUTH[auth-service]
        PATIENT[patient-service]
        DOCTOR[doctor-service]
        APPT[appointment-service]
        RECORDS[medical-records-service]
        DEPT[department-service]
        STAFF[staff-service]
        NOTIFY[notification-service]
    end

    subgraph Data_and_Integration
        SQL[(SQL Server<br/>Current shared database)]
        BUS[(Event Backbone<br/>Target-state assumption)]
        CHANNELS[Email / SMS / Push]
    end

    PAT --> PORTAL
    DOC --> PORTAL
    ADM --> PORTAL
    REC --> PORTAL

    PORTAL --> GATEWAY

    GATEWAY --> AUTH
    GATEWAY --> PATIENT
    GATEWAY --> DOCTOR
    GATEWAY --> APPT
    GATEWAY --> RECORDS
    GATEWAY --> DEPT
    GATEWAY --> STAFF
    GATEWAY --> NOTIFY

    AUTH --> SQL
    PATIENT --> SQL
    DOCTOR --> SQL
    APPT --> SQL
    RECORDS --> SQL
    DEPT --> SQL
    STAFF --> SQL
    NOTIFY --> SQL

    AUTH -. events .-> BUS
    PATIENT -. PatientAllergyUpdated .-> BUS
    DOCTOR -. DoctorAvailabilityUpdated .-> BUS
    APPT -. AppointmentCreated / AppointmentCancelled .-> BUS
    RECORDS -. MedicalRecordCreated .-> BUS
    BUS --> NOTIFY
    NOTIFY --> CHANNELS
```

## 2. Container and Microservices Architecture

```mermaid
flowchart LR
    subgraph Client
        BROWSER[Browser]
        PORTAL[hm-portal]
        BROWSER --> PORTAL
    end

    subgraph Access
        ALB[Application Load Balancer]
        GATEWAY[api-gateway]
    end

    subgraph Clinical
        PATIENT[patient-service]
        DOCTOR[doctor-service]
        APPT[appointment-service]
        RECORDS[medical-records-service]
    end

    subgraph Operations
        DEPT[department-service]
        STAFF[staff-service]
    end

    subgraph Identity_and_Comms
        AUTH[auth-service]
        NOTIFY[notification-service]
    end

    subgraph Persistence_Current
        SHARED[(Stage 1 Shared SQL Server)]
    end

    subgraph Persistence_Target
        AUTHDB[(Auth DB)]
        APPTDB[(Appointment DB)]
        OWNED[(Other service-owned databases)]
    end

    subgraph Async
        OUTBOX[(Outbox / Relay)]
        BUS[(Event Bus)]
    end

    PORTAL --> ALB --> GATEWAY

    GATEWAY --> AUTH
    GATEWAY --> PATIENT
    GATEWAY --> DOCTOR
    GATEWAY --> APPT
    GATEWAY --> RECORDS
    GATEWAY --> DEPT
    GATEWAY --> STAFF
    GATEWAY --> NOTIFY

    APPT --> PATIENT
    APPT --> DOCTOR
    RECORDS --> PATIENT
    RECORDS --> APPT
    DOCTOR --> DEPT
    STAFF --> DEPT

    AUTH --> SHARED
    PATIENT --> SHARED
    DOCTOR --> SHARED
    APPT --> SHARED
    RECORDS --> SHARED
    DEPT --> SHARED
    STAFF --> SHARED
    NOTIFY --> SHARED

    AUTH -. Stage 2 .-> AUTHDB
    APPT -. Stage 2 .-> APPTDB
    PATIENT -. Stage 3 .-> OWNED
    DOCTOR -. Stage 3 .-> OWNED
    RECORDS -. Stage 3 .-> OWNED
    DEPT -. Stage 3 .-> OWNED
    STAFF -. Stage 3 .-> OWNED
    NOTIFY -. Stage 3 .-> OWNED

    APPT --> OUTBOX --> BUS
    DOCTOR --> OUTBOX
    PATIENT --> OUTBOX
    RECORDS --> OUTBOX
    BUS --> NOTIFY
```

## 3. Service Interaction Diagram

```mermaid
flowchart TD
    GATEWAY[api-gateway]

    AUTH[auth-service]
    PATIENT[patient-service]
    DOCTOR[doctor-service]
    APPT[appointment-service]
    RECORDS[medical-records-service]
    DEPT[department-service]
    STAFF[staff-service]
    NOTIFY[notification-service]
    BUS[(Event Backbone)]

    GATEWAY --> AUTH
    GATEWAY --> PATIENT
    GATEWAY --> DOCTOR
    GATEWAY --> APPT
    GATEWAY --> RECORDS
    GATEWAY --> DEPT
    GATEWAY --> STAFF
    GATEWAY --> NOTIFY

    APPT --> PATIENT
    APPT --> DOCTOR
    RECORDS --> PATIENT
    RECORDS --> APPT
    DOCTOR --> DEPT
    STAFF --> DEPT

    AUTH -. UserRegistered / UserRoleChanged .-> BUS
    PATIENT -. PatientAllergyUpdated .-> BUS
    DOCTOR -. DoctorAvailabilityUpdated .-> BUS
    APPT -. AppointmentCreated / AppointmentCancelled .-> BUS
    RECORDS -. MedicalRecordCreated .-> BUS

    BUS --> NOTIFY
```

## 4. Deployment and Infrastructure Diagram

```mermaid
flowchart TD
    DEV[Feature branches / PRs]
    GH[GitHub Repositories]
    GHA[GitHub Actions]
    GV[GitVersion]
    ECR[Amazon ECR]
    TF[Terraform]

    DEV --> GH --> GHA
    GHA --> GV
    GHA --> ECR
    GHA --> TF

    subgraph AWS_VPC
        subgraph Public_Subnets
            ALB[Application Load Balancer]
        end

        subgraph Private_Subnets
            ECS[ECS Fargate Cluster]
            GW[api-gateway task]
            AU[auth-service task]
            PA[patient-service task]
            DR[doctor-service task]
            AP[appointment-service task]
            MR[medical-records-service task]
            DP[department-service task]
            ST[staff-service task]
            NO[notification-service task]
            SQL[(SQL Server)]
            SEC[Secrets Manager / SSM]
            OTEL[OpenTelemetry instrumentation]
        end
    end

    CW[CloudWatch Logs / Metrics / Alarms]

    ECR --> ECS
    TF --> ALB
    TF --> ECS
    TF --> SQL
    TF --> SEC

    ALB --> GW
    ECS --> GW
    ECS --> AU
    ECS --> PA
    ECS --> DR
    ECS --> AP
    ECS --> MR
    ECS --> DP
    ECS --> ST
    ECS --> NO

    GW --> AU
    GW --> PA
    GW --> DR
    GW --> AP
    GW --> MR
    GW --> DP
    GW --> ST
    GW --> NO

    AU --> SQL
    PA --> SQL
    DR --> SQL
    AP --> SQL
    MR --> SQL
    DP --> SQL
    ST --> SQL
    NO --> SQL

    SEC --> ECS
    GW --> OTEL
    AU --> OTEL
    PA --> OTEL
    DR --> OTEL
    AP --> OTEL
    MR --> OTEL
    DP --> OTEL
    ST --> OTEL
    NO --> OTEL
    OTEL --> CW
```

## 5. Flow Diagram: User Login and Token Validation

```mermaid
sequenceDiagram
    participant User
    participant Portal as hm-portal
    participant Gateway as api-gateway
    participant Auth as auth-service

    User->>Portal: Submit credentials
    Portal->>Gateway: POST /v1/auth/login
    Gateway->>Auth: Forward request with correlation ID
    Auth-->>Gateway: JWT + refresh token + claims
    Gateway-->>Portal: Auth response
    Portal-->>User: Signed in

    Portal->>Gateway: Subsequent API request with JWT
    Gateway->>Gateway: Validate token and propagate identity headers
```

## 6. Flow Diagram: Appointment Booking with Availability Check

```mermaid
sequenceDiagram
    participant User
    participant Portal as hm-portal
    participant Gateway as api-gateway
    participant Appointment as appointment-service
    participant Doctor as doctor-service
    participant Patient as patient-service
    participant EventBus as Event Backbone
    participant Notify as notification-service

    User->>Portal: Select doctor and slot
    Portal->>Gateway: POST /v1/appointments
    Gateway->>Appointment: Booking request
    Appointment->>Doctor: Check availability
    Doctor-->>Appointment: Slot valid
    Appointment->>Patient: Validate patient exists
    Patient-->>Appointment: Patient valid
    Appointment->>Appointment: Persist booking
    Appointment-->>Gateway: 201 Created
    Gateway-->>Portal: Booking confirmed
    Appointment->>EventBus: Publish AppointmentCreated
    EventBus->>Notify: Consume event
```

## 7. Flow Diagram: Appointment Cancellation and Notification

```mermaid
sequenceDiagram
    participant User
    participant Portal as hm-portal
    participant Gateway as api-gateway
    participant Appointment as appointment-service
    participant EventBus as Event Backbone
    participant Notify as notification-service

    User->>Portal: Cancel appointment
    Portal->>Gateway: PATCH /v1/appointments/{id}/cancel
    Gateway->>Appointment: Cancellation request
    Appointment->>Appointment: Validate and update status
    Appointment-->>Gateway: Cancellation success
    Gateway-->>Portal: Updated state
    Appointment->>EventBus: Publish AppointmentCancelled
    EventBus->>Notify: Trigger notification
```

## 8. Flow Diagram: Medical Record Creation After Consultation

```mermaid
sequenceDiagram
    participant Doctor
    participant Portal as hm-portal
    participant Gateway as api-gateway
    participant Records as medical-records-service
    participant Appointment as appointment-service
    participant EventBus as Event Backbone

    Doctor->>Portal: Submit consultation notes
    Portal->>Gateway: POST /v1/medical-records
    Gateway->>Records: Create record request
    Records->>Appointment: Validate consultation context
    Appointment-->>Records: Context valid
    Records->>Records: Persist record and history
    Records-->>Gateway: 201 Created
    Gateway-->>Portal: Record saved
    Records->>EventBus: Publish MedicalRecordCreated
```