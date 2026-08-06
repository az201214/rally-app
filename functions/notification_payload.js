const {createHash} = require('node:crypto');

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

function compactText(value, limit) {
  const normalized = String(value || '').replace(/\s+/g, ' ').trim();
  if (normalized.length <= limit) return normalized;
  return `${normalized.slice(0, limit - 1).trimEnd()}…`;
}

function notificationId(seed) {
  return createHash('sha256').update(String(seed)).digest('hex').slice(0, 32);
}

function canClaimDelivery(data, nowMillis) {
  if (!data) return true;
  if (data.status === 'sent') return false;
  if (data.status !== 'processing') return true;
  const leaseMillis = typeof data.leaseUntil?.toMillis === 'function'
    ? data.leaseUntil.toMillis()
    : Number(data.leaseUntil || 0);
  return leaseMillis <= nowMillis;
}

function payload(type, route, matchId, title, body, extra = {}, idSeed = '') {
  const id = notificationId(idSeed || `${type}:${matchId}`);
  return {
    notification: {
      title: compactText(title, 80),
      body: compactText(body, 240),
    },
    data: {type, route, matchId: String(matchId || ''), notificationId: id, ...extra},
    android: {
      priority: 'high',
      collapseKey: id,
      notification: {channelId: 'rally_matches', sound: 'default', tag: id},
    },
    apns: {
      headers: {'apns-collapse-id': id},
      payload: {aps: {sound: 'default', 'content-available': 1}},
    },
    webpush: {
      fcmOptions: {link: `/#${route}`},
      notification: {icon: '/icons/Icon-192.png', tag: id, renotify: false},
    },
  };
}

module.exports = {
  payload,
  compactText,
  notificationId,
  canClaimDelivery,
  INVALID_TOKEN_CODES,
};
