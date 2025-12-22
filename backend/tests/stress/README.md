# K6 Stress Testing

This directory contains k6 load testing scripts for the Rituals App API.

## Prerequisites

Install k6 on Windows:
1. Download from: https://dl.k6.io/msi/k6-latest-amd64.msi
2. Or via Chocolatey: `choco install k6`
3. Or via Scoop: `scoop install k6`

## Test Types

### 1. Stress Test (`stress-test.js`)
Gradually increases load to find the breaking point.
- Ramps from 10 → 50 → 100 virtual users
- Duration: ~4 minutes
- Tests: Auth, Rituals CRUD, Profile, Gamification, Social

```bash
k6 run stress-test.js
```

### 2. Spike Test (`spike-test.js`)
Simulates sudden traffic surge (e.g., viral moment).
- Normal: 10 users → Spike: 200 users
- Duration: ~2 minutes
- Tests: Critical endpoints only

```bash
k6 run spike-test.js
```

### 3. Soak Test (`soak-test.js`)
Long-running test to find memory leaks.
- Maintains 50 users for 30 minutes
- Full duration: ~34 minutes
- Tests: Typical user session flow

```bash
k6 run soak-test.js
```

## Quick Commands

```bash
# Run stress test with output summary
k6 run stress-test.js --summary-trend-stats="avg,min,med,max,p(90),p(95)"

# Run with JSON output
k6 run stress-test.js --out json=results.json

# Run with specific VUs and duration
k6 run stress-test.js --vus 50 --duration 2m

# Run spike test
k6 run spike-test.js
```

## Thresholds

| Metric | Stress | Spike | Soak |
|--------|--------|-------|------|
| p(95) Response Time | < 2s | < 5s | < 3s |
| Error Rate | < 5% | < 10% | < 2% |

## Test Users

Tests automatically create their own users:
- `stresstest@rituals.app`
- `spiketest@rituals.app`
- `soaktest@rituals.app`

## Interpreting Results

### Good Results ✅
- `http_req_duration` p(95) within threshold
- `http_req_failed` rate is low
- Consistent response times

### Warning Signs ⚠️
- Response times increasing over time → Memory leak
- Errors spiking at specific VU count → Capacity limit
- Timeouts → Server overloaded

### Failed Test ❌
- Error rate exceeds threshold
- Response times exceed threshold
- Connection refused errors
