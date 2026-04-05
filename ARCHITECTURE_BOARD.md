# Hospital Management Architecture Board

This board is the compact, presentation-first version of the architecture. It is meant for design walkthroughs, stakeholder reviews, and roadmap conversations where the audience needs a clear picture of how the platform works now and how it is expected to evolve.

## At a Glance

- Frontend: hm-portal is the single hospital web experience
- Public entry: api-gateway is the only supported external API boundary
- Core domains: auth, patient, doctor, appointment, medical records, department, staff, notification
- Current data posture: shared SQL Server with schema ownership rules
- Target data posture: service-owned persistence with event-driven side effects
- Target runtime: AWS ECS Fargate behind ALB with Terraform-managed infrastructure

## Executive Board View

```mermaid
flowchart LR
    classDef actor fill:#f3f7fb,stroke:#4a6b86,color:#183247,stroke-width:1px;
    classDef experience fill:#fff4dc,stroke:#b47a00,color:#4c3400,stroke-width:1px;
    classDef edge fill:#ffe6e0,stroke:#c0563d,color:#5e1f12,stroke-width:1px;
    classDef domain fill:#eef6ea,stroke:#4f7f39,color:#1f3b17,stroke-width:1px;
    classDef platform fill:#eaf0fb,stroke:#4769a8,color:#1e325d,stroke-width:1px;
    classDef data fill:#edf9f2,stroke:#2f7d4d,color:#124227,stroke-width:1px;
    classDef event fill:#fff1f1,stroke:#bb4f5d,color:#5b1820,stroke-width:1px;

    subgraph People
        FD[Front Desk]
        DR[Doctor]
        AD[Admin]
    end

    subgraph Experience
        UI[hm-portal<br/>React + TypeScript + Vite]
    end

    subgraph Access
        GW[api-gateway<br/>JWT validation<br/>RBAC<br/>Versioned APIs]
    end

    subgraph Core_Domains
        AUTH[Identity<br/>auth-service]
        PAT[Patient<br/>patient-service]
        DOC[Doctor<br/>doctor-service]
        APPT[Scheduling<br/>appointment-service]
        MED[Clinical Records<br/>medical-records-service]
        ORG[Operations<br/>department-service + staff-service]
        NOTIF[Communication<br/>notification-service]
    end

    subgraph Platform
        DB[(SQL Server now<br/>Service DBs later)]
        BUS[(Domain Events)]
        AWS[AWS ECS Fargate + ALB]
        OBS[CloudWatch + OpenTelemetry]
    end

    FD --> UI
    DR --> UI
    AD --> UI
    UI --> GW

    GW --> AUTH
    GW --> PAT
    GW --> DOC
    GW --> APPT
    GW --> MED
    GW --> ORG
    GW --> NOTIF

    APPT --> PAT
    APPT --> DOC
    MED --> APPT

    AUTH --> DB
    PAT --> DB
    DOC --> DB
    APPT --> DB
    MED --> DB
    ORG --> DB
    NOTIF --> DB

    APPT -. AppointmentCreated / Cancelled .-> BUS
    DOC -. DoctorAvailabilityUpdated .-> BUS
    PAT -. PatientAllergyUpdated .-> BUS
    MED -. MedicalRecordCreated .-> BUS
    BUS --> NOTIF

    AWS --- GW
    AWS --- AUTH
    AWS --- PAT
    AWS --- DOC
    AWS --- APPT
    AWS --- MED
    AWS --- ORG
    AWS --- NOTIF
    OBS --- AWS

    class FD,DR,AD actor;
    class UI experience;
    class GW edge;
    class AUTH,PAT,DOC,APPT,MED,ORG,NOTIF domain;
    class AWS,OBS platform;
    class DB data;
    class BUS event;
```

## Current to Target Transition

```mermaid
flowchart LR
    classDef current fill:#fff4dc,stroke:#b47a00,color:#4c3400,stroke-width:1px;
    classDef transition fill:#eef6ea,stroke:#4f7f39,color:#1f3b17,stroke-width:1px;
    classDef target fill:#eaf0fb,stroke:#4769a8,color:#1e325d,stroke-width:1px;

    subgraph Current_State
        C1[Shared SQL Server]
        C2[Schema ownership by service]
        C3[Mostly synchronous validation]
        C4[Central SQL object tracking in hm-database]
    end

    subgraph Transition
        T1[Extract Auth DB]
        T2[Extract Appointment DB]
        T3[Introduce outbox relay]
        T4[Harden API-only cross-service access]
    end

    subgraph Target_State
        N1[Database per service]
        N2[Independent migration pipelines]
        N3[Event-driven side effects]
        N4[Looser coupling and safer releases]
    end

    C1 --> T1 --> N1
    C2 --> T4 --> N2
    C3 --> T3 --> N3
    C4 --> T2 --> N4

    class C1,C2,C3,C4 current;
    class T1,T2,T3,T4 transition;
    class N1,N2,N3,N4 target;
```

## Service Ownership Strip

| Domain           | Owning Service                    | Owns                                           | Depends On                                    | Emits or Integrates With                                           |
| ---------------- | --------------------------------- | ---------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| Identity         | auth-service                      | users, roles, tokens, credentials              | gateway                                       | UserRegistered, UserRoleChanged, PasswordChanged                   |
| Patient          | patient-service                   | patients, allergies, vitals, insurance         | auth claims                                   | appointment-service, medical-records-service                       |
| Doctor           | doctor-service                    | doctors, qualifications, availability, ratings | gateway                                       | appointment-service, department-service, DoctorAvailabilityUpdated |
| Scheduling       | appointment-service               | appointments, symptoms, prescriptions          | patient-service, doctor-service               | AppointmentCreated, AppointmentCancelled, notification-service     |
| Clinical Records | medical-records-service           | medical_records, patient_medical_history       | patient-service, optional appointment-service | MedicalRecordCreated                                               |
| Operations       | department-service, staff-service | departments, services, staff, shifts           | gateway                                       | doctor-service, staff-service internal coordination                |
| Communication    | notification-service              | templates, outbound messages, delivery state   | event backbone                                | email or SMS channels as an implementation detail                  |

## Core Journey Strip

```mermaid
flowchart LR
    classDef primary fill:#fff4dc,stroke:#b47a00,color:#4c3400,stroke-width:1px;
    classDef service fill:#eef6ea,stroke:#4f7f39,color:#1f3b17,stroke-width:1px;
    classDef async fill:#fff1f1,stroke:#bb4f5d,color:#5b1820,stroke-width:1px;

    U[User Action] --> P[hm-portal]
    P --> G[api-gateway]
    G --> A[Domain Service]
    A --> V[Cross-service validation if required]
    V --> W[Write transaction]
    W -. publish event .-> E[Domain Event]
    E --> N[notification-service]
    N --> C[Reminder or alert channel]

    class U,P,G primary;
    class A,V,W,N service;
    class E,C async;
```

## Design Narrative

### Access path

- Users interact only through hm-portal.
- hm-portal calls api-gateway.
- api-gateway performs authentication, request routing, and boundary enforcement.

### Domain path

- auth-service owns identity and access concerns.
- patient-service owns patient demographics and clinical profile metadata.
- doctor-service owns physician profile and availability.
- appointment-service owns scheduling, slot conflict rules, and lifecycle state.
- medical-records-service owns encounter records and clinical history.
- department-service and staff-service own operational structure and workforce data.
- notification-service handles outbound communications and delivery tracking.

### Data path

- Today, the platform is optimized for delivery speed with one SQL Server instance and service-level schema ownership.
- Next, auth and appointment are the best candidates to split first because they have clear boundaries and high change frequency.
- Later, each service should own its own persistence model and release its schema independently.

### Integration path

- Synchronous calls stay on critical validation paths such as doctor availability and patient existence checks.
- Notifications and other non-blocking side effects should move to event-driven flows.
- Once service databases are extracted, outbox relay becomes the preferred publishing mechanism.

## What This Board Is Saying

### Current priorities

- Keep the gateway as the only public entry point.
- Enforce schema ownership while the database is still shared.
- Keep notifications off the critical transaction path.
- Standardize correlation IDs, tracing, and versioned APIs across all services.

### Next architecture moves

- Choose the event backbone technology explicitly.
- Define the first two datastore extractions with rollback plans.
- Formalize API and data ownership contracts.
- Capture key decisions in ADRs so the migration path does not drift.

## Suggested Usage

- Use this file for stakeholder reviews and architecture presentations.
- Use ARCHITECTURE_DIAGRAMS.md for direct Mermaid rendering and engineering deep dives.
- Use ARCHITECTURE_DOCUMENTATION.md for implementation planning, governance, and migration detail.
