BVCEC SmartQueue — Project Context
1. Overview

Project Name: BVCEC SmartQueue

Institution: Bonam Venkata Chalamayya Engineering College (Autonomous), Odalarevu, Andhra Pradesh, India.

Project Type: B.Tech laboratory project.

Primary Technology: Flutter / Dart.

Primary Platform: Android/mobile.

Potential Secondary Platform: Desktop/tablet administration interface.

2. Vision

BVCEC SmartQueue is a configurable campus service queue-management system.

The system should allow students/users to join virtual queues instead of unnecessarily waiting physically at service counters.

The system should provide:

digital tokens,

queue position,

estimated waiting time,

real-time queue updates,

notifications,

staff counter management,

service-session records,

analytics.

The project should contain a meaningful algorithmic component rather than being only CRUD.

3. Institutional Context

BVCEC is an autonomous engineering college located at Odalarevu, Andhra Pradesh.

The college has:

an autonomous examination section,

multiple engineering departments,

a central library,

administrative and student-facing institutional services.

The examination section is a strong candidate for an initial pilot because it is a documented institutional service area.

However, exact operational procedures must be verified before implementation.

4. Verified vs Assumed Information
Verified

Institution name and autonomous status.

Odalarevu location.

Existence of an autonomous examination section.

Multiple academic departments.

Central library.

Not Yet Verified

Number of counters.

Actual physical queue process.

Exact student-facing services.

Current token mechanism.

Service duration.

Staff workflow.

Priority rules.

No-show procedure.

Existing digital queue system.

Existing student authentication system.

Do not implement unverified details as institutional facts.

5. Target Users
Student

Primary mobile user.

Capabilities:

login,

browse service centers,

select service,

inspect queue,

join queue,

receive token,

see position,

see estimated waiting time,

cancel queue entry,

receive notifications,

view history.

Staff

Counter operator.

Capabilities:

login,

view assigned counter,

view queue,

call next,

start service,

complete service,

skip,

mark no-show,

pause/resume counter.

Administrator

System administrator.

Capabilities:

configure service centers,

configure services,

configure counters,

manage staff,

monitor queues,

configure queue rules,

view analytics.

6. Candidate Service Centers

These are candidates, not confirmed requirements.

Examination Section
Administration
Accounts
Library
Department Office


The first pilot service must be selected after requirements discovery.

7. Candidate Architecture
Flutter Client
      │
      ▼
Presentation
      │
      ▼
ViewModels / Controllers
      │
      ▼
Repositories
      │
      ▼
Backend Services
      │
      ├── Authentication
      ├── Database
      └── Notifications

8. Core Domain Model

Candidate entities:

User
Role
ServiceCenter
Service
Counter
Queue
QueueEntry
ServiceSession
QueueEvent
Notification
Appointment (optional)

9. Queue Entry

Candidate fields:

id
queueId
userId
serviceId
tokenNumber
priority
status
joinedAt
calledAt
serviceStartedAt
completedAt
counterId


Fields can change during schema design.

10. Queue State Machine
WAITING
   │
   ├── CANCELLED
   │
   └── CALLED
          │
          ├── NO_SHOW
          │
          └── SERVING
                 │
                 ├── COMPLETED
                 │
                 └── TRANSFERRED


All state transitions must be validated.

11. Queue Events

Recommended audit history:

JOINED
CALLED
SERVING
COMPLETED
CANCELLED
NO_SHOW
TRANSFERRED


Example:

A102

10:04 JOINED
10:17 CALLED
10:18 SERVING
10:22 COMPLETED

12. Multiple Counters

The system should support multiple counters.

Counter state candidates:

AVAILABLE
SERVING
PAUSED
OFFLINE


The eventual scheduling algorithm should consider workload rather than simple round-robin assignment.

13. Waiting-Time Estimation

Initial concept:

Estimated wait =
expected service time of relevant customers ahead
adjusted for active counters


Potential data sources:

historical service duration,

service type,

queue length,

current counter workload,

active counter count,

priority.

14. Adaptive Prediction

Potential approach:

newAverage =
    α × latestDuration
    +
    (1 - α) × previousAverage


The project should measure prediction error rather than assuming the adaptive model is better.

Possible metric:

MAE =
Σ |predicted - actual| / n

15. Analytics

Potential metrics:

average waiting time,

median waiting time,

maximum waiting time,

average service duration,

throughput,

cancellation rate,

no-show rate,

queue abandonment,

counter utilization,

prediction MAE.

16. MVP

Required:

Student

authentication,

service selection,

queue status,

join queue,

token,

position,

cancellation.

Staff

authentication,

counter screen,

call next,

complete,

skip/no-show.

System

queue state machine,

token generation,

real-time queue state,

basic waiting-time estimate,

service-session recording.

17. Advanced Features

After MVP:

multiple counters,

adaptive prediction,

priority queues,

aging,

notifications,

counter optimization,

analytics dashboard,

appointment + queue hybrid,

offline support.

18. Technology Candidates
Frontend

Flutter / Dart.

Potential packages:

go_router

Riverpod

HTTP/client library

local persistence solution

Exact package choices should be made during implementation.

Backend

Preferred candidate:

PostgreSQL-based backend such as Supabase.

Alternative:

Firebase.

Final decision depends on assignment constraints.

19. Non-Goals

Do not add technology for novelty.

Explicitly excluded unless justified:

blockchain,

cryptocurrency,

unnecessary AI/ML,

face recognition,

AR,

IoT,

generic chatbot,

unnecessary GPS/location tracking.

20. Academic Evaluation Questions

The project should eventually evaluate:

Can virtual queues reduce unnecessary physical waiting?

How accurately can waiting time be estimated?

Does dynamic counter assignment improve utilization?

How does the system behave under simultaneous users?

How are cancellation and no-show scenarios handled?

21. Current Status

DISCOVERY / REQUIREMENTS

Implementation should not be considered final until the questions in:

docs/OPEN_QUESTIONS.md

have been resolved sufficiently for the MVP.