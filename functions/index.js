const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.notifyTodoAssignment = onDocumentCreated('todos/{todoId}', async (event) => {
  const todo = event.data?.data();
  if (!todo || !todo.assignedTo || todo.assignedTo === todo.createdBy) return;

  const firestore = getFirestore();
  const receiverRef = firestore.collection('users').doc(todo.assignedTo);
  const creatorRef = firestore.collection('users').doc(todo.createdBy);
  const [receiverSnapshot, creatorSnapshot] = await Promise.all([
    receiverRef.get(),
    creatorRef.get(),
  ]);

  const tokens = receiverSnapshot.data()?.fcmTokens || [];
  if (tokens.length === 0) return;

  const creatorName = creatorSnapshot.data()?.name || 'A family member';
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'New task assigned',
      body: `${creatorName} assigned you: ${todo.title || 'a new task'}`,
    },
    data: {
      type: 'todo_assignment',
      todoId: todo.todoId || event.params.todoId,
      familyId: todo.familyId || '',
    },
    android: {
      notification: {
        channelId: 'task_assignments',
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    const code = result.error?.code;
    if (code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token') {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await receiverRef.update({
      fcmTokens: FieldValue.arrayRemove(...invalidTokens),
    });
  }
});
