import admin from '../config/firebase';
import pool from '../config/db';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface NotificationResult {
  success: boolean;
  successCount: number;
  failureCount: number;
  errors?: string[];
}

// =====================
// FCM TOKEN YÖNETİMİ
// =====================

// Kullanıcının FCM token'ını kaydet veya güncelle
export const saveFcmToken = async (
  userId: string,
  fcmToken: string,
  deviceId?: string
): Promise<boolean> => {
  try {
    // Önce mevcut token'ı kontrol et
    const existingToken = await pool.query(
      'SELECT id FROM user_fcm_tokens WHERE user_id = $1 AND fcm_token = $2',
      [userId, fcmToken]
    );

    if (existingToken.rows.length > 0) {
      // Token zaten var, updated_at güncelle
      await pool.query(
        'UPDATE user_fcm_tokens SET updated_at = NOW() WHERE user_id = $1 AND fcm_token = $2',
        [userId, fcmToken]
      );
    } else {
      // Yeni token ekle
      await pool.query(
        `INSERT INTO user_fcm_tokens (user_id, fcm_token, device_id, created_at, updated_at)
         VALUES ($1, $2, $3, NOW(), NOW())
         ON CONFLICT (user_id, fcm_token) DO UPDATE SET updated_at = NOW()`,
        [userId, fcmToken, deviceId]
      );
    }

    console.log(`✅ FCM token saved for user ${userId}`);
    return true;
  } catch (error) {
    console.error('Error saving FCM token:', error);
    return false;
  }
};

// Kullanıcının FCM token'ını sil
export const removeFcmToken = async (
  userId: string,
  fcmToken: string
): Promise<boolean> => {
  try {
    await pool.query(
      'DELETE FROM user_fcm_tokens WHERE user_id = $1 AND fcm_token = $2',
      [userId, fcmToken]
    );
    console.log(`✅ FCM token removed for user ${userId}`);
    return true;
  } catch (error) {
    console.error('Error removing FCM token:', error);
    return false;
  }
};

// Kullanıcının tüm FCM token'larını al
export const getUserFcmTokens = async (userId: string): Promise<string[]> => {
  try {
    const result = await pool.query(
      'SELECT fcm_token FROM user_fcm_tokens WHERE user_id = $1',
      [userId]
    );
    return result.rows.map(row => row.fcm_token);
  } catch (error) {
    console.error('Error getting user FCM tokens:', error);
    return [];
  }
};

// =====================
// BİLDİRİM GÖNDERME
// =====================

// Tek bir kullanıcıya bildirim gönder
export const sendNotificationToUser = async (
  userId: string,
  notification: NotificationPayload
): Promise<NotificationResult> => {
  try {
    const tokens = await getUserFcmTokens(userId);

    if (tokens.length === 0) {
      console.log(`No FCM tokens found for user ${userId}`);
      return { success: false, successCount: 0, failureCount: 0 };
    }

    return await sendNotificationToTokens(tokens, notification, userId);
  } catch (error) {
    console.error('Error sending notification to user:', error);
    return { success: false, successCount: 0, failureCount: 1, errors: [(error as Error).message] };
  }
};

// Birden fazla kullanıcıya bildirim gönder
export const sendNotificationToUsers = async (
  userIds: string[],
  notification: NotificationPayload
): Promise<NotificationResult> => {
  try {
    let totalSuccess = 0;
    let totalFailure = 0;
    const errors: string[] = [];

    for (const userId of userIds) {
      const result = await sendNotificationToUser(userId, notification);
      totalSuccess += result.successCount;
      totalFailure += result.failureCount;
      if (result.errors) errors.push(...result.errors);
    }

    return {
      success: totalSuccess > 0,
      successCount: totalSuccess,
      failureCount: totalFailure,
      errors: errors.length > 0 ? errors : undefined
    };
  } catch (error) {
    console.error('Error sending notification to users:', error);
    return { success: false, successCount: 0, failureCount: userIds.length, errors: [(error as Error).message] };
  }
};

// Token listesine bildirim gönder
export const sendNotificationToTokens = async (
  tokens: string[],
  notification: NotificationPayload,
  userId?: string
): Promise<NotificationResult> => {
  if (tokens.length === 0) {
    return { success: false, successCount: 0, failureCount: 0 };
  }

  try {
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'rituals_notifications',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    // Geçersiz token'ları temizle
    if (response.failureCount > 0 && userId) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp: admin.messaging.SendResponse, idx: number) => {
        if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
          failedTokens.push(tokens[idx]);
        }
      });

      // Geçersiz token'ları sil
      for (const token of failedTokens) {
        await removeFcmToken(userId, token);
      }
    }

    console.log(`✅ Notification sent: ${response.successCount} success, ${response.failureCount} failure`);

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: response.responses
        .filter((r: admin.messaging.SendResponse) => !r.success)
        .map((r: admin.messaging.SendResponse) => r.error?.message || 'Unknown error')
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    return { success: false, successCount: 0, failureCount: tokens.length, errors: [(error as Error).message] };
  }
};

// =====================
// HAZIR BİLDİRİM TİPLERİ
// =====================

// Streak uyarı bildirimi (3 saat kala)
export const sendStreakWarningNotification = async (userId: string, ritualName: string): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '⚠️ Streak at Risk!',
    body: `You haven't completed "${ritualName}" today. Only 3 hours left to save your streak!`,
    data: {
      type: 'streak_warning',
      ritual_name: ritualName,
    },
  });
};

// Partner tamamlama bildirimi
export const sendPartnerCompletedNotification = async (
  userId: string,
  partnerName: string,
  ritualName: string
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '🎉 Partner Completed!',
    body: `${partnerName} completed "${ritualName}". Now it's your turn!`,
    data: {
      type: 'partner_completed',
      partner_name: partnerName,
      ritual_name: ritualName,
    },
  });
};

// Level up bildirimi
export const sendLevelUpNotification = async (
  userId: string,
  newLevel: number,
  coinsEarned: number
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '🎊 Level Up!',
    body: `Congratulations! You've reached Level ${newLevel} and earned ${coinsEarned} coins!`,
    data: {
      type: 'level_up',
      new_level: newLevel.toString(),
      coins_earned: coinsEarned.toString(),
    },
  });
};

// Badge kazanma bildirimi
export const sendBadgeEarnedNotification = async (
  userId: string,
  badgeName: string,
  badgeIcon: string
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: `${badgeIcon} New Badge!`,
    body: `You've earned the "${badgeName}" badge! Well done!`,
    data: {
      type: 'badge_earned',
      badge_name: badgeName,
      badge_icon: badgeIcon,
    },
  });
};

// Arkadaşlık isteği bildirimi
export const sendFriendRequestNotification = async (
  userId: string,
  requesterName: string
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '👋 Friend Request',
    body: `${requesterName} sent you a friend request.`,
    data: {
      type: 'friend_request',
      requester_name: requesterName,
    },
  });
};

// Ritual davet bildirimi
export const sendRitualInviteNotification = async (
  userId: string,
  inviterName: string,
  ritualName: string
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '📨 Ritual Invite',
    body: `${inviterName} invited you to join "${ritualName}".`,
    data: {
      type: 'ritual_invite',
      inviter_name: inviterName,
      ritual_name: ritualName,
    },
  });
};

// Freeze hatırlatması bildirimi
export const sendFreezeReminderNotification = async (
  userId: string,
  freezeCount: number
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, {
    title: '🧊 Freeze Reminder',
    body: `You have ${freezeCount} freeze power-ups. You can use them to protect your streak!`,
    data: {
      type: 'freeze_reminder',
      freeze_count: freezeCount.toString(),
    },
  });
};

// Genel bildirim gönder
export const sendCustomNotification = async (
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<NotificationResult> => {
  return await sendNotificationToUser(userId, { title, body, data });
};

// =====================
// VERİTABANI BİLDİRİMLERİ
// =====================

// Bildirimi veritabanına kaydet (in-app için)
export const saveNotificationToDb = async (
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: Record<string, any>
): Promise<void> => {
  try {
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data, is_read, created_at)
       VALUES ($1, $2, $3, $4, $5, false, NOW())`,
      [userId, type, title, body, data ? JSON.stringify(data) : null]
    );
  } catch (error) {
    console.error('Error saving notification to DB:', error);
  }
};

// Bildirimi hem push hem de DB'ye kaydet
export const sendAndSaveNotification = async (
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<NotificationResult> => {
  // Veritabanına kaydet
  await saveNotificationToDb(userId, type, title, body, data);

  // Push notification gönder
  return await sendNotificationToUser(userId, { title, body, data });
};
