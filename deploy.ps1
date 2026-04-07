flutter build web --pwa-strategy=none --dart-define=API_BASE_URL=http://140.245.33.196 --dart-define=WS_BASE_URL=wss://forex-backend-production-bc44.up.railway.app --dart-define=APP_WEB_URL=https://forexcompanion-e5a28.web.app
firebase deploy --only hosting
