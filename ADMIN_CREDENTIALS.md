# Admin Credentials

The system has been seeded with an admin user. Use the following credentials to log in:

## Admin User Details

- **Email**: admin@nbcc.com
- **Name**: Admin User
- **Unique Code**: TQRQCDQM
- **Password**: admin123 _(for future use if password authentication is implemented)_

## How to Login

Use the existing login endpoint at `/api/auth/login/` with the admin unique code:

```json
{
  "unique_code": "TQRQCDQM"
}
```

The login response will include an `is_staff` field in the player object to identify admin users:

```json
{
  "access": "jwt_access_token",
  "refresh": "jwt_refresh_token",
  "player": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@nbcc.com",
    "unique_code": "TQRQCDQM",
    "organization": "",
    "location": "",
    "is_staff": true,
    "created_at": "2026-02-08T..."
  }
}
```

## Re-run Admin Seed

If you need to view the admin code again, run:

```bash
cd backend
python manage.py seed_admin
```

This command is idempotent - it will not create duplicate admin users.
