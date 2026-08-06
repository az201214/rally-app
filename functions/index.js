const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {logger} = require('firebase-functions');
const {
  payload,
  canClaimDelivery,
  INVALID_TOKEN_CODES,
} = require('./notification_payload');

initializeApp();

const REGION = 'asia-south1';
const DELIVERY_LEASE_MS = 5 * 60 * 1000;

async function tokenDocuments(userIds) {
  const db = getFirestore();
  const snapshots = await Promise.all(
    [...new Set(userIds.filter(Boolean))].map((uid) =>
      db.collection('users').doc(uid).collection('deviceTokens')
        .where('enabled', '==', true).get()),
  );
  return snapshots.flatMap((snapshot) => snapshot.docs);
}

async function sendToUsers(userIds, message) {
  const documents = await tokenDocuments(userIds);
  if (documents.length === 0) return {sent: 0, failed: 0, removed: 0};
  let sent = 0;
  let failed = 0;
  let removed = 0;
  for (let offset = 0; offset < documents.length; offset += 500) {
    const batch = documents.slice(offset, offset + 500);
    const response = await getMessaging().sendEachForMulticast({
      ...message,
      tokens: batch.map((document) => document.get('token')),
    });
    sent += response.successCount;
    failed += response.failureCount;
    const invalid = [];
    response.responses.forEach((result, index) => {
      if (!result.success && INVALID_TOKEN_CODES.has(result.error?.code)) {
        invalid.push(batch[index].ref.delete());
      } else if (!result.success) {
        logger.warn('notification_delivery_failed', {
          code: result.error?.code || 'unknown',
          tokenDocument: batch[index].ref.path,
        });
      }
    });
    await Promise.all(invalid);
    removed += invalid.length;
  }
  return {sent, failed, removed};
}

async function claimDelivery(key, type, metadata = {}) {
  const db = getFirestore();
  const reference = db.collection('notificationEvents').doc(key);
  const now = Timestamp.now();
  const leaseUntil = Timestamp.fromMillis(now.toMillis() + DELIVERY_LEASE_MS);
  const claimed = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(reference);
    if (existing.exists) {
      const data = existing.data();
      if (!canClaimDelivery(data, now.toMillis())) return false;
      transaction.update(reference, {
        status: 'processing',
        leaseUntil,
        attempts: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
        lastError: FieldValue.delete(),
      });
      return true;
    }
    transaction.create(reference, {
      type,
      status: 'processing',
      leaseUntil,
      attempts: 1,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      ...metadata,
    });
    return true;
  });
  return {claimed, reference};
}

async function deliverOnce({key, type, userIds, message, metadata}) {
  const delivery = await claimDelivery(key, type, metadata);
  if (!delivery.claimed) {
    logger.info('notification_duplicate_suppressed', {key, type});
    return {duplicate: true, sent: 0, failed: 0, removed: 0};
  }
  try {
    const result = await sendToUsers(userIds, message);
    await delivery.reference.update({
      status: 'sent',
      sentAt: FieldValue.serverTimestamp(),
      leaseUntil: FieldValue.delete(),
      result,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {duplicate: false, ...result};
  } catch (error) {
    await delivery.reference.update({
      status: 'failed',
      leaseUntil: FieldValue.delete(),
      lastError: String(error?.code || error?.message || error).slice(0, 500),
      updatedAt: FieldValue.serverTimestamp(),
    });
    throw error;
  }
}

exports.notifyMatchFound = onDocumentCreated(
  {document: 'matches/{matchId}', region: REGION},
  async (event) => {
    const match = event.data?.data();
    if (!match || match.status !== 'awaitingAcceptance') return;
    const key = `match-found_${event.params.matchId}`;
    const result = await deliverOnce({
      key,
      type: 'matchFound',
      userIds: match.participantIds || [],
      message: payload(
        'matchFound', '/match-found', event.params.matchId,
        'Match found', `${match.clubName || 'Your Rally club'} is ready.`, {}, key,
      ),
      metadata: {matchId: event.params.matchId},
    });
    logger.info('match_found_notification', {matchId: event.params.matchId, ...result});
  },
);

exports.notifyMatchLifecycle = onDocumentUpdated(
  {document: 'matches/{matchId}', region: REGION},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const beforeParticipants = new Map(
      (before.participants || []).map((participant) => [participant.userId, participant]),
    );
    for (const participant of after.participants || []) {
      const previous = beforeParticipants.get(participant.userId);
      if (previous?.acceptanceStatus !== 'accepted' &&
          participant.acceptanceStatus === 'accepted') {
        const key = `match-accepted_${event.params.matchId}_${participant.userId}`;
        await deliverOnce({
          key,
          type: 'matchAccepted',
          userIds: (after.participantIds || []).filter((uid) => uid !== participant.userId),
          message: payload(
            'matchAccepted', '/match-details', event.params.matchId,
            'Match accepted', `${participant.displayName || 'Your partner'} accepted the match.`,
            {}, key,
          ),
          metadata: {matchId: event.params.matchId, actorId: participant.userId},
        });
      }
    }
    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      const key = `match-cancelled_${event.params.matchId}`;
      await deliverOnce({
        key,
        type: 'matchCancelled',
        userIds: after.participantIds || [],
        message: payload(
          'matchCancelled', '/home', event.params.matchId,
          'Match cancelled', after.cancellationReason || 'This match was cancelled.', {}, key,
        ),
        metadata: {matchId: event.params.matchId},
      });
    }
  },
);

exports.notifyChatMessage = onDocumentCreated(
  {document: 'chatThreads/{threadId}/messages/{messageId}', region: REGION},
  async (event) => {
    const message = event.data?.data();
    if (!message || message.type !== 'text' || message.deletedAt) return;
    const thread = await getFirestore().collection('chatThreads')
      .doc(event.params.threadId).get();
    if (!thread.exists) return;
    const key = `chat_${event.params.threadId}_${event.params.messageId}`;
    const result = await deliverOnce({
      key,
      type: 'newChatMessage',
      userIds: (thread.get('participantIds') || []).filter((uid) => uid !== message.senderId),
      message: payload(
        'newChatMessage', '/match-chat', message.matchId,
        message.senderName || 'New Rally message', message.text,
        {threadId: event.params.threadId}, key,
      ),
      metadata: {
        matchId: message.matchId,
        threadId: event.params.threadId,
        messageId: event.params.messageId,
      },
    });
    logger.info('chat_notification', {messageId: event.params.messageId, ...result});
  },
);

exports.sendMatchReminders = onSchedule(
  {schedule: 'every 15 minutes', region: REGION, timeZone: 'UTC'},
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const windowEnd = Timestamp.fromMillis(now.toMillis() + 45 * 60 * 1000);
    const matches = await db.collection('matches')
      .where('status', '==', 'confirmed')
      .where('scheduledStart', '>', now)
      .where('scheduledStart', '<=', windowEnd)
      .get();
    for (const matchDocument of matches.docs) {
      const match = matchDocument.data();
      const key = `reminder_${matchDocument.id}`;
      await deliverOnce({
        key,
        type: 'matchReminder',
        userIds: match.participantIds || [],
        message: payload(
          'matchReminder', '/match-details', matchDocument.id,
          'Rally starts soon', `${match.clubName || 'Your match'} starts within 45 minutes.`,
          {}, key,
        ),
        metadata: {matchId: matchDocument.id},
      });
    }
  },
);
