const test = require('node:test');
const assert = require('node:assert/strict');

const {
  payload,
  compactText,
  notificationId,
  canClaimDelivery,
  INVALID_TOKEN_CODES,
} = require('../notification_payload');

test('builds a cross-platform data notification with a deep link', () => {
  const message = payload(
    'matchFound', '/match-found', 'match-1', 'Match found', 'Your Rally is ready.',
  );
  assert.equal(message.data.type, 'matchFound');
  assert.equal(message.data.route, '/match-found');
  assert.equal(message.data.matchId, 'match-1');
  assert.equal(message.webpush.fcmOptions.link, '/#/match-found');
  assert.equal(message.android.notification.channelId, 'rally_matches');
  assert.equal(message.apns.payload.aps.sound, 'default');
  assert.equal(message.data.notificationId.length, 32);
  assert.equal(message.android.notification.tag, message.data.notificationId);
  assert.equal(message.webpush.notification.tag, message.data.notificationId);
});

test('bounds notification text and creates stable duplicate identifiers', () => {
  const longText = 'Rally '.repeat(100);
  assert.equal(compactText(longText, 40).length, 40);
  assert.equal(notificationId('event-1'), notificationId('event-1'));
  assert.notEqual(notificationId('event-1'), notificationId('event-2'));
});

test('suppresses completed and actively leased delivery attempts', () => {
  const now = 1000;
  assert.equal(canClaimDelivery(null, now), true);
  assert.equal(canClaimDelivery({status: 'sent'}, now), false);
  assert.equal(canClaimDelivery({status: 'failed'}, now), true);
  assert.equal(canClaimDelivery({status: 'processing', leaseUntil: 2000}, now), false);
  assert.equal(canClaimDelivery({status: 'processing', leaseUntil: 900}, now), true);
});

test('invalid FCM token codes are removed', () => {
  assert.equal(INVALID_TOKEN_CODES.has('messaging/invalid-registration-token'), true);
  assert.equal(
    INVALID_TOKEN_CODES.has('messaging/registration-token-not-registered'),
    true,
  );
  assert.equal(INVALID_TOKEN_CODES.has('messaging/internal-error'), false);
});
