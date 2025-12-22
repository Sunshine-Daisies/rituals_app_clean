import { createClient } from 'redis';

const redisUrl: string = process.env.REDIS_URL || 'redis://redis:6379';

const client = createClient({
    url: redisUrl
});

client.on('error', (err: any) => console.error('Redis Client Error', err));

let isConnected = false;

export const connectRedis = async (): Promise<void> => {
    if (!isConnected) {
        try {
            await client.connect();
            isConnected = true;
            console.log('Connected to Redis');
        } catch (err) {
            console.error('Could not connect to Redis', err);
        }
    }
};

export const cacheService = {
    async get(key: string): Promise<string | null> {
        if (!isConnected) return null;
        try {
            return await client.get(key);
        } catch (err) {
            console.error(`Redis GET error for key ${key}:`, err);
            return null;
        }
    },

    async set(key: string, value: string, ttlSeconds: number = 3600): Promise<void> {
        if (!isConnected) return;
        try {
            await client.set(key, value, {
                EX: ttlSeconds
            });
        } catch (err) {
            console.error(`Redis SET error for key ${key}:`, err);
        }
    },

    async del(key: string): Promise<void> {
        if (!isConnected) return;
        try {
            await client.del(key);
        } catch (err) {
            console.error(`Redis DEL error for key ${key}:`, err);
        }
    },

    /**
     * Try to acquire a lock. Returns true if lock was acquired, false if already locked.
     * @param key Lock key
     * @param ttlSeconds Lock duration in seconds
     */
    async acquireLock(key: string, ttlSeconds: number): Promise<boolean> {
        if (!isConnected) return true; // Fallback: if redis down, allow execution (risk of duplicate but better than nothing) or false? 
        // Better to return true and risk duplication than fail completely? Or maybe false? 
        // Ideally should be false but for this app availability > consistency.
        // Actually, if Redis is down, scaling relies on it. Let's return true but log error.

        try {
            // SET key value NX EX ttl
            const result = await client.set(key, 'locked', {
                NX: true,
                EX: ttlSeconds
            });
            return result === 'OK';
        } catch (err) {
            console.error(`Redis acquireLock error for key ${key}:`, err);
            return true; // Fallback to allowing execution
        }
    }
};
