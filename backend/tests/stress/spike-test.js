import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// Configuration
const BASE_URL = 'https://ritualsappclean-production.up.railway.app/api';
const TEST_USER = {
    email: 'spiketest@rituals.app',
    password: 'test123456'
};

// Spike test options - sudden traffic surge
export const options = {
    stages: [
        { duration: '10s', target: 10 },   // Normal load
        { duration: '10s', target: 200 },  // SPIKE! Sudden surge
        { duration: '30s', target: 200 },  // Stay at peak
        { duration: '10s', target: 10 },   // Scale down
        { duration: '1m', target: 10 },    // Recovery period
        { duration: '10s', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<5000'], // 95% of requests should be below 5s during spike
        http_req_failed: ['rate<0.1'],     // Error rate should be below 10% during spike
    },
};

// Setup
export function setup() {
    http.post(`${BASE_URL}/auth/register`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password,
        name: 'Spike Test User'
    }), { headers: { 'Content-Type': 'application/json' } });

    const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password
    }), { headers: { 'Content-Type': 'application/json' } });

    return { token: JSON.parse(loginRes.body || '{}').token };
}

// Main test
export default function (data) {
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${data.token}`
    };

    group('High Load Endpoints', () => {
        const start = Date.now();

        // Most critical endpoints under spike load
        const ritualsRes = http.get(`${BASE_URL}/rituals`, { headers });
        responseTime.add(Date.now() - start);

        check(ritualsRes, {
            'rituals status 200': (r) => r.status === 200,
        }) || errorRate.add(1);

        const profileRes = http.get(`${BASE_URL}/profile`, { headers });
        check(profileRes, {
            'profile status 200': (r) => r.status === 200,
        }) || errorRate.add(1);

        const leaderboardRes = http.get(`${BASE_URL}/leaderboard`, { headers });
        check(leaderboardRes, {
            'leaderboard status 200': (r) => r.status === 200,
        }) || errorRate.add(1);
    });

    sleep(0.5); // Minimal sleep during spike test
}
