import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

// Custom metrics
const responseTime = new Trend('response_time');

// Configuration
const BASE_URL = 'https://ritualsappclean-production.up.railway.app/api';
const TEST_USER = {
    email: 'soaktest@rituals.app',
    password: 'test123456'
};

// Soak test options - long running test to find memory leaks
export const options = {
    stages: [
        { duration: '2m', target: 50 },   // Ramp up
        { duration: '30m', target: 50 },  // Stay at 50 users for 30 minutes
        { duration: '2m', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<3000'], // 95% under 3s
        http_req_failed: ['rate<0.02'],    // Below 2% error rate
    },
};

// Setup
export function setup() {
    http.post(`${BASE_URL}/auth/register`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password,
        name: 'Soak Test User'
    }), { headers: { 'Content-Type': 'application/json' } });

    const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password
    }), { headers: { 'Content-Type': 'application/json' } });

    return { token: JSON.parse(loginRes.body || '{}').token };
}

// Main test - simulates typical user behavior
export default function (data) {
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${data.token}`
    };

    // Typical user session
    const start = Date.now();

    // 1. Check rituals
    http.get(`${BASE_URL}/rituals`, { headers });
    sleep(2);

    // 2. Check profile
    http.get(`${BASE_URL}/profile`, { headers });
    sleep(1);

    // 3. Check leaderboard
    http.get(`${BASE_URL}/leaderboard`, { headers });
    sleep(1);

    // 4. Check badges
    http.get(`${BASE_URL}/badges`, { headers });
    sleep(1);

    // 5. Check friends
    http.get(`${BASE_URL}/friends`, { headers });
    sleep(1);

    // 6. Check partnerships
    http.get(`${BASE_URL}/partnerships/my`, { headers });

    responseTime.add(Date.now() - start);

    // User thinks/rests
    sleep(Math.random() * 5 + 3); // 3-8 seconds
}
