# Session/Login/Register Fix Summary

## Issues Fixed

1. ✅ **CORS Configuration**: Updated to include VPS IP address
2. ✅ **Cookie Domain**: Removed IP address from cookie domain (cookies don't work with IP domains)
3. ✅ **Cookie Settings**: Made cookie settings configurable via environment variables
4. ✅ **API Base URL**: Ensured API_BASE_URL is read from environment

## Changes Made

### 1. Frontend CORS (`frontend/main.go`)
- Now reads `CORS_ORIGINS` from environment
- Default includes: `http://103.103.20.68,http://103.103.20.68:3000,http://localhost:3000`
- Added `ExposeHeaders: "Set-Cookie"` to expose cookies

### 2. Cookie Settings (`frontend/handlers/auth.go`)
- Added `isIPAddress()` helper function
- Cookies no longer set domain for IP addresses (cookies work without domain for IPs)
- Cookie settings now read from environment variables:
  - `COOKIE_DOMAIN`: Empty for IP addresses
  - `COOKIE_SECURE`: false for HTTP (true for HTTPS)
  - `SameSite: "Lax"` for cross-site requests

### 3. Docker Compose (`docker-compose.yml`)
- `COOKIE_DOMAIN`: Changed from `103.103.20.68` to `""` (empty)
- `CORS_ORIGINS`: Updated to include VPS IP with port

## Files Updated

- ✅ `frontend/main.go` - CORS configuration
- ✅ `frontend/handlers/auth.go` - Cookie handling
- ✅ `docker-compose.yml` - Environment variables

## Quick Fix on VPS

Run this on your VPS:

```bash
cd ~/sourcecode

# Option 1: Use fix script
./fix-session-vps.sh

# Option 2: Manual fix
# Update docker-compose.yml (already done)
docker-compose stop frontend
docker-compose up -d --build frontend
```

## Testing

After deployment, test:

1. **Login:**
   ```bash
   curl -X POST http://103.103.20.68:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}' \
     -c cookies.txt -v
   ```

2. **Check cookies:**
   ```bash
   cat cookies.txt
   ```

3. **Test authenticated request:**
   ```bash
   curl http://103.103.20.68:3000/dashboard \
     -b cookies.txt -v
   ```

## Important Notes

- **Cookie Domain**: IP addresses cannot be used as cookie domains. Leave it empty.
- **CORS**: Must include the exact origin (with port if different)
- **SameSite**: "Lax" allows cookies to be sent with top-level navigations
- **Secure**: Set to `true` only if using HTTPS

## Troubleshooting

If login/register still doesn't work:

1. **Check browser console** for CORS errors
2. **Check cookies** in browser DevTools → Application → Cookies
3. **Check backend logs**: `docker-compose logs backend`
4. **Check frontend logs**: `docker-compose logs frontend`
5. **Verify Redis is running**: `docker-compose ps redis`

