const readline = require('readline');

// CONFIG
const API_URL = 'https://ritualsappclean-production.up.railway.app/api';
// const API_URL = 'http://localhost:3000/api'; // Use for local testing

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const askQuestion = (query) => new Promise((resolve) => rl.question(query, resolve));

async function main() {
    console.log('🌱 Rituals App - Remote Data Seeder');
    console.log('====================================');
    console.log('This script will add 30 days of mock completion data to your account.');
    console.log(`Target: ${API_URL}\n`);

    try {
        // 1. Login
        const email = await askQuestion('Email: ');
        const password = await askQuestion('Password: ');

        console.log('\nLogging in...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        if (!loginRes.ok) {
            const err = await loginRes.text();
            throw new Error(`Login failed: ${loginRes.status} ${err}`);
        }

        const { token, user } = await loginRes.json();
        console.log(`✅ Logged in as ${user.email} (ID: ${user.id})`);

        // 2. Get Rituals
        console.log('Fetching rituals...');
        const ritualsRes = await fetch(`${API_URL}/rituals`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!ritualsRes.ok) throw new Error('Failed to fetch rituals');
        let rituals = await ritualsRes.json();

        let targetRitualId;

        if (rituals.length === 0) {
            console.log('No rituals found. Creating a temporary one...');
            const createRes = await fetch(`${API_URL}/rituals`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    name: 'Daily Meditation (Mock)',
                    reminder_time: '10:00',
                    reminder_days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                })
            });
            const newRitual = await createRes.json();
            targetRitualId = newRitual.id;
            console.log(`✅ Created ritual: ${newRitual.name}`);
        } else {
            console.log(`Found ${rituals.length} rituals. Using: ${rituals[0].name}`);
            targetRitualId = rituals[0].id;
        }

        // 3. Seed Data (Last 30 Days)
        console.log('\nSeeding data for the last 30 days...');
        let successCount = 0;

        for (let i = 0; i < 30; i++) {
            // 70% chance to complete
            if (Math.random() > 0.3) {
                const date = new Date();
                date.setDate(date.getDate() - (30 - i));

                // Set time to 10 AM to avoid timezone boundary issues
                date.setHours(10, 0, 0, 0);

                const body = {
                    ritual_id: targetRitualId,
                    step_index: -1, // Full completion
                    source: 'mock_script',
                    completed_at: date.toISOString()
                };

                const logRes = await fetch(`${API_URL}/ritual-logs`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(body)
                });

                if (logRes.ok) {
                    process.stdout.write('.'); // Progress indicator
                    successCount++;
                } else {
                    process.stdout.write('x');
                }
            }
        }

        console.log(`\n\n✅ Done! Successfully added ${successCount} completion logs.`);
        console.log('Please refresh the Stats page in the app.');

    } catch (error) {
        console.error('\n❌ Error:', error.message);
    } finally {
        rl.close();
    }
}

main();
