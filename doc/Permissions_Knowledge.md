---

## Health Connect Special Read Permissions Behavior (Android)

Android Health Connect includes special permissions to extend data access. These permissions are **modifiers** and will not trigger a user consent dialog unless paired with a corresponding data-type permission.

| Special Permission | Purpose | Required Pairing for Dialog |
| :--- | :--- | :--- |
| `READ_HEALTH_DATA_HISTORY` | Grants access to data older than the default 30-day window. | Must be requested with at least one data-type **READ** permission. |
| `READ_HEALTH_DATA_IN_BACKGROUND` | Grants access to read data when the app is not in the foreground. | Must be requested with at least one data-type **READ** or **WRITE** permission. |

**Key Constraints:**

1.  Requesting either History or Background permission **alone** will fail to show the consent dialog.
2.  Requesting **History** with only **WRITE** data-type permissions will fail to show the History dialog.
