Yes — for the **current scope**, we can simplify the schema by removing `familyMembers`. Since every user has a `familyId`, we can query:

```text
users where familyId == currentUser.familyId
```

to get all family members.

Also, for Google/Apple authentication, profile fields that may not always be available should be nullable. And we'll make `status` a Boolean.

## Final Firestore Schema

You now have **3 core collections**:

```text
users
families
todos
```

---

## 1. `users`

```text
users/{userId}
```

| Field       | Type      | Nullable | Description                          |
| ----------- | --------- | -------: | ------------------------------------ |
| `uid`       | String    |       No | Firebase Authentication UID          |
| `name`      | String    |      Yes | User's display name                  |
| `email`     | String    |      Yes | User's email                         |
| `photoUrl`  | String    |      Yes | Profile picture URL                  |
| `provider`  | String    |       No | `google`, `apple`, or `email`        |
| `familyId`  | String    |      Yes | Family the user currently belongs to |
| `createdAt` | Timestamp |       No | Account creation time                |
| `updatedAt` | Timestamp |       No | Last profile update                  |

### Example

```text
users
 └── uid_123
      ├── uid: "uid_123"
      ├── name: "Rameez"
      ├── email: "rameez@example.com"
      ├── photoUrl: null
      ├── provider: "apple"
      ├── familyId: "family_abc123"
      ├── createdAt: Timestamp
      └── updatedAt: Timestamp
```

### Nullable fields

I'd make these nullable:

```text
name       → String?
email      → String?
photoUrl   → String?
familyId   → String?
```

This is especially useful for your Apple login case.

For example, an Apple account's first login might provide:

```text
name: "Rameez Khan"
email: "private-relay@appleid.com"
```

but a subsequent authentication may not provide the same profile information again. Your app should therefore **keep the previously stored values in Firestore rather than overwriting them with null**.

---

# 2. `families`

```text
families/{familyId}
```

| Field        | Type      | Nullable | Description              |
| ------------ | --------- | -------: | ------------------------ |
| `familyId`   | String    |       No | Unique family identifier |
| `familyName` | String    |       No | Name of the family       |
| `familyCode` | String    |       No | Unique code used to join |
| `createdBy`  | String    |       No | UID of family creator    |
| `createdAt`  | Timestamp |       No | Family creation time     |
| `updatedAt`  | Timestamp |       No | Last update              |

Example:

```text
families
 └── family_abc123
      ├── familyId: "family_abc123"
      ├── familyName: "Khan Family"
      ├── familyCode: "K7X92P"
      ├── createdBy: "uid_123"
      ├── createdAt: Timestamp
      └── updatedAt: Timestamp
```

The creator is identified using:

```text
createdBy == currentUser.uid
```

So we don't need another member collection just to identify the owner.

---

# 3. `todos`

```text
todos/{todoId}
```

| Field         | Type      | Nullable | Description                           |
| ------------- | --------- | -------: | ------------------------------------- |
| `todoId`      | String    |       No | Unique todo ID                        |
| `familyId`    | String    |       No | Family this todo belongs to           |
| `assignedTo`  | String    |       No | UID of the member responsible         |
| `createdBy`   | String    |       No | UID of the member who created it      |
| `title`       | String    |       No | Todo title                            |
| `deadline`    | Timestamp |       No | Todo deadline                         |
| `status`      | Boolean   |       No | `false = pending`, `true = completed` |
| `createdAt`   | Timestamp |       No | Creation time                         |
| `updatedAt`   | Timestamp |       No | Last update                           |
| `completedAt` | Timestamp |      Yes | Completion time                       |

Example:

```text
todos
 └── todo_001
      ├── todoId: "todo_001"
      ├── familyId: "family_abc123"
      ├── assignedTo: "uid_456"
      ├── createdBy: "uid_123"
      ├── title: "Clean the kitchen"
      ├── deadline: Timestamp
      ├── status: false
      ├── createdAt: Timestamp
      ├── updatedAt: Timestamp
      └── completedAt: null
```

### Status

We'll use:

```text
false → Pending
true  → Completed
```

So there is no need for:

```text
"pending"
"completed"
```

strings.

And when a task is completed:

```text
status: true
completedAt: Timestamp
```

When it becomes pending again:

```text
status: false
completedAt: null
```

---

# Final database

So the complete structure is now:

```text
Firestore
│
├── users
│    └── {userId}
│         ├── uid
│         ├── name?
│         ├── email?
│         ├── photoUrl?
│         ├── provider
│         ├── familyId?
│         ├── createdAt
│         └── updatedAt
│
├── families
│    └── {familyId}
│         ├── familyId
│         ├── familyName
│         ├── familyCode
│         ├── createdBy
│         ├── createdAt
│         └── updatedAt
│
└── todos
     └── {todoId}
          ├── todoId
          ├── familyId
          ├── assignedTo
          ├── createdBy
          ├── title
          ├── deadline
          ├── status
          ├── createdAt
          ├── updatedAt
          └── completedAt?
```

### Relationships

```text
User
 │
 └── familyId ──────────────► Family
                                  │
                                  └── createdBy
                                       │
                                       ▼
                                  Family Owner


Users with same familyId
        │
        ├── User A
        ├── User B
        ├── User C
        └── User D
              │
              ▼
            Todos
              │
       ┌──────┴──────┐
       ▼             ▼
   createdBy      assignedTo
```

This is a much cleaner **3-collection design** for the requirements you currently have. Later, if you introduce multiple families per user, invitations, family roles beyond owner/member, or membership history, then we can reconsider the structure.
