import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 50 }, // Ramp to 50 users
        { duration: '1m', target: 50 },  // Stay at 50
        { duration: '30s', target: 0 },  // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<200'], // Should be VERY fast (<200ms) because of cache
    },
};

const BASE_URL = 'https://rituals-app-clean-production.up.railway.app'; // Update if needed

export default function () {
    // Test Global Leaderboard (Cached)
    const res = http.get(`${BASE_URL}/api/leaderboard?type=global`);

    check(res, {
        'status is 200': (r) => r.status === 200,
        'protocol is HTTP/2': (r) => r.proto === 'HTTP/2.0',
    });

    sleep(1);
}
