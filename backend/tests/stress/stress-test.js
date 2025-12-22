import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');
const ritualsDuration = new Trend('rituals_duration');

// Configuration
const BASE_URL = 'https://ritualsappclean-production.up.railway.app/api';
const TEST_USER = {
    email: 'stresstest@rituals.app',
    password: 'test123456'
};

// Test options - ramp up load
export const options = {
    stages: [
        { duration: '30s', target: 10 },   // Ramp up to 10 users
        { duration: '1m', target: 50 },    // Ramp up to 50 users
        { duration: '2m', target: 100 },   // Maintain 100 users
        { duration: '30s', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<2000'], // 95% of requests should be below 2s
        http_req_failed: ['rate<0.05'],    // Error rate should be below 5%
        errors: ['rate<0.1'],              // Custom error rate below 10%
    },
};

// Setup - create test user if needed
export function setup() {
    // Try to register test user (will fail if exists, that's ok)
    http.post(`${BASE_URL}/auth/register`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password,
        name: 'Stress Test User'
    }), {
        headers: { 'Content-Type': 'application/json' }
    });

    // Login to get token
    const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password
    }), {
        headers: { 'Content-Type': 'application/json' }
    });

    const body = JSON.parse(loginRes.body || '{}');
    return { token: body.token };
}

// Main test function
export default function (data) {
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${data.token}`
    };

    group('Authentication', () => {
        // Login test
        const start = Date.now();
        const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
            email: TEST_USER.email,
            password: TEST_USER.password
        }), { headers: { 'Content-Type': 'application/json' } });

        loginDuration.add(Date.now() - start);

        check(loginRes, {
            'login status is 200': (r) => r.status === 200,
            'login has token': (r) => JSON.parse(r.body || '{}').token !== undefined,
        }) || errorRate.add(1);
    });

    sleep(1);

    group('Rituals CRUD', () => {
        // Get rituals
        const start = Date.now();
        const ritualsRes = http.get(`${BASE_URL}/rituals`, { headers });
        ritualsDuration.add(Date.now() - start);

        check(ritualsRes, {
            'get rituals status is 200': (r) => r.status === 200,
            'rituals is array': (r) => Array.isArray(JSON.parse(r.body || '[]')),
        }) || errorRate.add(1);

        // Create ritual
        const createRes = http.post(`${BASE_URL}/rituals`, JSON.stringify({
            name: `Stress Test Ritual ${Date.now()}`,
            steps: [],
            reminder_time: '08:00',
            reminder_days: ['Mon', 'Wed', 'Fri']
        }), { headers });

        check(createRes, {
            'create ritual status is 201': (r) => r.status === 201,
        }) || errorRate.add(1);

        // If created, try to delete it
        if (createRes.status === 201) {
            const ritual = JSON.parse(createRes.body || '{}');
            if (ritual.id) {
                const deleteRes = http.del(`${BASE_URL}/rituals/${ritual.id}`, null, { headers });
                check(deleteRes, {
                    'delete ritual status is 200 or 204': (r) => r.status === 200 || r.status === 204,
                });
            }
        }
    });

    sleep(1);

    group('Profile & Gamification', () => {
        // Get profile
        const profileRes = http.get(`${BASE_URL}/profile`, { headers });
        check(profileRes, {
            'get profile status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);

        // Get badges
        const badgesRes = http.get(`${BASE_URL}/badges`, { headers });
        check(badgesRes, {
            'get badges status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);

        // Get leaderboard
        const leaderboardRes = http.get(`${BASE_URL}/leaderboard`, { headers });
        check(leaderboardRes, {
            'get leaderboard status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);
    });

    sleep(1);

    group('Social Features', () => {
        // Get friends
        const friendsRes = http.get(`${BASE_URL}/friends`, { headers });
        check(friendsRes, {
            'get friends status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);

        // Get partnerships
        const partnershipsRes = http.get(`${BASE_URL}/partnerships/my`, { headers });
        check(partnershipsRes, {
            'get partnerships status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);
    });

    sleep(2);
}

// Teardown - cleanup
export function teardown(data) {
    console.log('Stress test completed!');
}
