import pool from '../config/db';
import { addXp } from './xpService';
import { schedulePartnershipStreakCheck, cancelPartnershipStreakCheck, scheduleRitualStreakCheck, cancelRitualStreakCheck } from './streakScheduler';
import crypto from 'crypto';

// XP Rewards
const XP_REWARDS = {
    create_invite: 5,
    partnership_formed: 15,
};

function generateInviteCode(): string {
    return crypto.randomBytes(3).toString('hex').toUpperCase();
}

export class PartnershipService {

    // Method to create an invite
    static async createInvite(userId: string, ritualId: string) {
        // Check if ritual belongs to user
        const ritualCheck = await pool.query(
            'SELECT * FROM rituals WHERE id = $1 AND user_id = $2',
            [ritualId, userId]
        );

        if (ritualCheck.rows.length === 0) {
            throw { status: 404, message: 'Ritual not found or does not belong to you' };
        }

        // Check for existing active partnership
        const existingPartnership = await pool.query(
            `SELECT * FROM ritual_partnerships 
       WHERE (ritual_id_1 = $1 OR ritual_id_2 = $1) AND status = 'active'`,
            [ritualId]
        );

        if (existingPartnership.rows.length > 0) {
            throw { status: 400, message: 'This ritual already has a partner' };
        }

        // Check for existing unused invite
        const existingInvite = await pool.query(
            `SELECT * FROM ritual_invites 
       WHERE ritual_id = $1 AND user_id = $2 AND is_used = false 
       AND (expires_at IS NULL OR expires_at > NOW())`,
            [ritualId, userId]
        );

        if (existingInvite.rows.length > 0) {
            return {
                isNew: false,
                invite: existingInvite.rows[0]
            };
        }

        const inviteCode = generateInviteCode();
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);

        const result = await pool.query(
            `INSERT INTO ritual_invites (ritual_id, user_id, invite_code, expires_at)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
            [ritualId, userId, inviteCode, expiresAt]
        );

        await addXp(userId, XP_REWARDS.create_invite, 'create_invite', ritualId);

        return {
            isNew: true,
            invite: result.rows[0]
        };
    }

    // Method to join via code
    static async joinWithCode(userId: string, code: string, partnerRitualId?: string) {
        // Find invite
        const invite = await pool.query(
            `SELECT ri.*, r.name as ritual_name, r.user_id as owner_id,
                up.username as owner_username
         FROM ritual_invites ri
         JOIN rituals r ON ri.ritual_id = r.id
         LEFT JOIN user_profiles up ON ri.user_id = up.user_id
         WHERE ri.invite_code = $1 
         AND ri.is_used = false
         AND (ri.expires_at IS NULL OR ri.expires_at > NOW())`,
            [code.toUpperCase()]
        );

        if (invite.rows.length === 0) {
            throw { status: 404, message: 'Invalid or expired invite code' };
        }

        const inv = invite.rows[0];

        if (inv.user_id === userId) {
            throw { status: 400, message: 'You cannot join your own invite' };
        }

        // Handle partner ritual selection logic
        let finalPartnerRitualId = partnerRitualId;
        if (!finalPartnerRitualId) {
            const existingRitual = await pool.query(
                `SELECT id FROM rituals WHERE user_id = $1 AND LOWER(name) = LOWER($2)`,
                [userId, inv.ritual_name]
            );
            if (existingRitual.rows.length > 0) {
                finalPartnerRitualId = existingRitual.rows[0].id;
            }
        }

        // Check for pending requests
        const existingRequest = await pool.query(
            `SELECT * FROM partnership_requests 
         WHERE inviter_ritual_id = $1 AND invitee_user_id = $2 AND status = 'pending'`,
            [inv.ritual_id, userId]
        );

        if (existingRequest.rows.length > 0) {
            throw { status: 400, message: 'You already have a pending request' };
        }

        // Create request
        const request = await pool.query(
            `INSERT INTO partnership_requests (inviter_ritual_id, inviter_user_id, invitee_user_id, invitee_ritual_id, invite_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
            [inv.ritual_id, inv.user_id, userId, finalPartnerRitualId, inv.id]
        );

        return {
            request: request.rows[0],
            invite: inv,
            finalPartnerRitualId
        };
    }
}
