#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🚀 شروع ساخت پروژه هوشیار..."

mkdir -p app/\(tabs\) components constants hooks services store plugins __tests__/screens __tests__/services __tests__/store

echo "✅ پوشه‌ها ساخته شدند"

cat > package.json << 'PKGEOF'
{
  "name": "hoshyar",
  "main": "expo-router/entry",
  "version": "1.0.0",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android"
  },
  "dependencies": {
    "expo": "~57.0.20",
    "expo-router": "~57.0.19",
    "react": "19.2.3",
    "react-native": "0.86.3",
    "zustand": "^5.0.10"
  },
  "private": true
}
PKGEOF

echo "✅ package.json"

cat > app.json << 'APPEOF'
{
  "expo": {
    "name": "Hoshyar",
    "slug": "hoshyar",
    "version": "1.0.0",
    "scheme": "hoshyar",
    "android": { "package": "com.hoshyar.app" },
    "plugins": ["expo-router", "./plugins/with-accessibility-service"]
  }
}
APPEOF

echo "✅ app.json"

cat > tsconfig.json << 'TSEOF'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": { "@/*": ["./*"] }
  }
}
TSEOF

echo "✅ tsconfig.json"

echo ""
echo "🎯 پیکربندی کامل شد!"
