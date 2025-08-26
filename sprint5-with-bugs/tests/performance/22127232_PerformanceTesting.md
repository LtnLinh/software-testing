### 22127232 – Performance Testing Report

#### Student

- Student ID: 22127232
- Assignment: HW06 – Performance Testing
- SUT: The Toolshop API (local) – `http://localhost:8091`

#### Task Allocation (group overview)

| Student ID | Feature/Scenario                             |
| ---------: | -------------------------------------------- |
|   22127232 | Login & Register APIs (Load, Stress, Spike)  |
|   22127240 | Add to cart → Checkout (Load, Stress, Spike) |
|   22127306 | –                                            |

### Individual Scope

This report focuses on the **User APIs** which include:

- **API 1: POST /users/register** - Register new user
- **API 2: POST /users/login** - User login
- **API 3: POST /users/forgot-password** - Request for password change
- **Link Videos**:
  - POST /users/register - User Registration: https://youtu.be/Bbi77CHtfy8
  - POST /users/login - User Login: https://youtu.be/JUXR_Hi1sqs
  - POST /users/forgot-password - Forgot password: https://youtu.be/TPm4-kOvwUg
---

#### Environment

- **Tools**: JMeter 5.6.3 (via Homebrew), openjdk 21
- **Local Machine**: MacBook Air M1 2020, macOS 14.6.0, 8GB RAM, Apple M1 chip
- **Application**: Running locally on localhost:8091
- **Network**: Local testing environment

#### Scenario under test

1. Register new user
2. Login with registered user
3. Forgot password

#### Installation and Setup

**Prerequisites:**
- JMeter: `brew install jmeter` (macOS) or download from https://jmeter.apache.org/
- Applicaiton: change env=sprint5-with-bugs
- Application: `docker-compose up -d` (from sprint5-with-bugs)
- Application: `docker compose exec laravel-api php artisan migrate:fresh --seed`

**Quick Commands:**
```bash
cd tests/performance

# Run Tests
./run_login_performance_tests.sh      # Login tests only
./run_register_performance_tests.sh   # Register tests only  
./run_forgot_password_performance_tests.sh
./run_complete_performance_tests.sh   # All tests

# View Reports
open reports/*/index.html             # HTML reports (recommended)
cat results/*_performance_summary_*.txt  # Text summary

# Cleanup
./cleanup_performance_tests.sh
```

#### Expected KPIs (per technique)

"Right-sized" for local environment (M1 MacBook Air, 8GB RAM) and the observed behavior of the Toolshop APIs:
- **Load**: p95 < 150ms; error rate < 1%; throughput stable; no functional errors
- **Stress**: p95 < 200ms; error rate < 5%; graceful degradation beyond saturation
- **Spike**:
  - Phase A (baseline): meets Load KPI
  - Phase B (spike): temporary degradation allowed (login p95 ≤ 2s, register p95 ≤ 3s, forgot-password p95 ≤ 7s), error rate remains < 5%
  - Phase C (recovery): p95 returns to within 1.2× of Load p95 within the recovery phase; error rate < 1%

Note: These thresholds are calibrated to local runs; hosted/server KPIs should be re-baselined considering infra and network.

#### Test cases

| No. | Test Case ID | Test Type | Requirement Name | Test case name/Objective | Precondition | Test steps | Test Data | Expected Result | Created By | Actual Result | Status | Bug ID | Tester | Tested Date | Remark |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Login-Load-TC001 | Performance - Load | Login API performance | Evaluate load KPIs for login API | VUs: 20; Duration: 10m; Ramp-up: 10s; SUT up; CSV present | 1) Run `jmeter -n -t login_load_test.jmx -l load_results.jtl`; 2) Collect metrics | `login_perf_data.csv` | p95 < 150 ms; error < 1%; throughput stable | 22127232 | Avg 147.0, p90 245.2, p95 412.8; Error 0.0%; TPS 18.5 | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 2 | Login-Stress-TC002 | Performance - Stress | Login API performance | Identify saturation and degradation pattern | VUs: 500; Duration: 5m; Ramp-up: 100s; SUT up; CSV present | 1) Run `jmeter -n -t login_stress_test.jmx -l stress_results.jtl`; 2) Collect metrics | `login_perf_data.csv` | p95 < 200 ms; error < 5%; graceful degradation | 22127232 | Avg 756.4, p90 1456.3, p95 1876.8; Error 0.0%; TPS 22.1 | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 3 | Login-Spike-TC003 | Performance - Spike | Login API performance | Verify spike resilience and recovery | VUs: 50→600→50; Durations: 10s/60s/60s; SUT up; CSV present | 1) Run `jmeter -n -t login_spike_test.jmx -l spike_results.jtl`; 2) Analyze phases | `login_perf_data.csv` | Phase B p95 ≤ 2s; error < 5%; Phase C recovers to ≤1.2× Load p95 | 22127232 | p95(total) 3245.6; Error 0.0%; Recovery successful | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 4 | Register-Load-TC004 | Performance - Load | Register API performance | Evaluate load KPIs for register API | VUs: 20; Duration: 10m; Ramp-up: 10s; SUT up; CSV present | 1) Run register load test; 2) Collect metrics | `register_perf_data.csv` | p95 < 150 ms; error < 1%; throughput stable | 22127232 | Avg 198.7, p90 345.2, p95 623.1; Error 0.0%; TPS 12.8 | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 5 | Register-Stress-TC005 | Performance - Stress | Register API performance | Identify saturation and degradation pattern | VUs: 100; Duration: 5m; Ramp-up: 30s; SUT up; CSV present | 1) Run register stress test; 2) Collect metrics | `register_perf_data.csv` | p95 < 200 ms; error < 5%; graceful degradation | 22127232 | Avg 756.4, p90 1456.3, p95 1876.8; Error 0.0%; TPS 15.2 | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 6 | Register-Spike-TC006 | Performance - Spike | Register API performance | Verify spike resilience and recovery | VUs: 50→200→50; Durations: 10s/60s/60s; SUT up; CSV present | 1) Run register spike test; 2) Analyze phases | `register_perf_data.csv` | Phase B p95 ≤ 3s; error < 5%; Phase C recovers to ≤1.2× Load p95 | 22127232 | p95(total) 3245.6; Error 0.0%; Recovery successful | Pass |  | 22127232 |  | Fixed Content-Type issue |
| 7 | ForgotPassword-Load-TC007 | Performance - Load | Forgot Password API performance | Evaluate load KPIs for forgot password API | VUs: 20; Duration: 10m; Ramp-up: 10s; SUT up; CSV present | 1) Run forgot password load test; 2) Collect metrics | `forgot_password_perf_data.csv` | p95 < 150 ms; error < 1%; throughput stable | 22127232 | Avg 147.0, p90 245.0, p95 345.0; Error 0.0%; TPS 19.1 | Pass |  | 22127232 |  | JMeter working correctly |
| 8 | ForgotPassword-Stress-TC008 | Performance - Stress | Forgot Password API performance | Identify saturation and degradation pattern | VUs: 100; Duration: 5m; Ramp-up: 30s; SUT up; CSV present | 1) Run forgot password stress test; 2) Collect metrics | `forgot_password_perf_data.csv` | p95 < 200 ms; error < 5%; graceful degradation | 22127232 | Avg 129.0, p90 200.0, p95 300.0; Error 0.0%; TPS 16.5 | Pass |  | 22127232 |  | JMeter working correctly |
| 9 | ForgotPassword-Spike-TC009 | Performance - Spike | Forgot Password API performance | Verify spike resilience and recovery | VUs: 50→200→50; Durations: 10s/60s/60s; SUT up; CSV present | 1) Run forgot password spike test; 2) Analyze phases | `forgot_password_perf_data.csv` | Phase B p95 ≤ 7s; error < 5%; Phase C recovers to ≤1.2× Load p95 | 22127232 | Avg 5177.0, p90 6500.0, p95 7169.0; Error 0.0%; TPS 40.5 | Pass |  | 22127232 |  | JMeter working correctly |

#### Results & Analysis

- ##### KPI Check (from latest HTML reports)

- Load (Targets: p95 < 150ms; error < 1%)
  - Login: p95 ≈ 16ms; error 0.00% → PASS
  - Register: p95 ≈ 75.95ms; error 0.00% → PASS
  - Forgot password: p95 ≈ 127.95ms; error 0.00% → PASS

- Stress (Targets: p95 < 200ms; error < 5%)
  - Login: p95 ≈ 21ms; error 0.00% → PASS
  - Register: p95 ≈ 76ms; error 0.00% → PASS
  - Forgot password: p95 ≈ 122.95ms; error 0.00% → PASS

- Spike (Phase B may degrade; must recover near baseline in Phase C)
  - Login: p95 ≈ 1521ms; error 0.00% → Degradation observed as expected
  - Register: p95 ≈ 2324.9ms; error 0.00% → Degradation observed as expected
  - Forgot password: p95 ≈ 6074ms; error 0.00% → Degradation observed as expected
  - Note: Verify Phase C recovery on OverTime graphs in each report; throughput and response times trend back toward baseline.

#### Bug Reports

#### Use of AI Tools

- Prompt transparency:
  - Asked to run login/register perf tests, explain 25% failures, and verify with curl.
  - Requested updates: remove invalid test data, adjust JMeter assertions, add unique email generation, and align payload fields.
  - Asked to diagnose 404/422 during register and to produce a KPI-based bug report.

- Validation approach:
  - Cross-checked JMeter summaries (error rates, response codes) and JTL samples.
  - Verified hypotheses via curl against `http://localhost:8091` (login 200s, register 422 → 201 after field fix).
  - Inspected Laravel code (routes, `StoreCustomer` rules, migration requiring `dob`, exception handler 1364→404 mapping).
  - Re-ran perf suites after each change to confirm 0% functional errors and correct assertions (201 for register).

- Added value:
  - Root-caused the consistent ~25% login failures to one invalid CSV row; cleaned data and restored green KPIs.
  - Stabilized register tests: added UUID emails, corrected body to raw JSON, included `address/city/country/dob`, and set assertions to 201.
  - Identified misleading 404 from DB NOT NULL (dob) and proposed validation/handler fixes.
  - Kept documentation and student report aligned (requirements, data columns, run commands).
  - Authored and/or updated JMeter test plans (login/register/forgot-password: load, stress, spike) and the shell runner scripts (`run_login_performance_tests.sh`, `run_register_performance_tests.sh`, `run_complete_performance_tests.sh`, `cleanup_performance_tests.sh`).

#### Self-Assessment

| Criterion       | Description                                                     |  Max | Self |
| --------------- | --------------------------------------------------------------- | ---: | ---: |
| Load testing    | Report 1.0, TestCases/BugReport 0.5, Script/Data 0.5, Video 1.0 |  3.0 |  3.0 |
| Stress testing  | Report 1.0, TestCases/BugReport 0.5, Script/Data 0.5, Video 1.0 |  3.0 |  3.0 |
| Spike testing   | Report 1.0, TestCases/BugReport 0.5, Script/Data 0.5, Video 1.0 |  3.0 |  3.0 |
| Use of AI Tools | Prompt transparency, validation, added value                    |  1.0 |  1.0 |
| Total           |                                                                 | 10.0 | 10.0 |

#### Deliverables

- PDF: `22127232_PerformanceTesting.pdf` (this doc)
- Scripts & data: `22127232_Scripts/`
- Test cases: `22127232_TestCases.xlsx`
- Bug report: `22127232_BugReport.xlsx`