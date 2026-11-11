# Book&Cut App

Aplicación móvil en Flutter para clientes y barberos de Book&Cut.

## Descarga directa de la APK (última versión)

Cada actualización en la rama `main` compila y publica automáticamente una nueva APK en el siguiente enlace permanente (sin necesidad de descargar el repositorio):

**[Descargar BookCut-app.apk (Última versión)](https://github.com/Book-Cut/app_movil_book_cut/releases/latest/download/BookCut-app.apk)**

> Si el repositorio es privado, quien descargue desde ese enlace debe tener sesión iniciada en GitHub y acceso al repositorio. En repositorios públicos el enlace funciona de forma directa para cualquier usuario.

## Configuración de Secrets en GitHub (para firma oficial sin exponer claves)

Nunca subas archivos `.jks`, `.keystore`, `key.properties` ni contraseñas al repositorio. Configúralos una sola vez en GitHub dentro de **Settings → Secrets and variables → Actions → New repository secret**:

- `ANDROID_KEYSTORE_BASE64`: contenido de tu archivo `.jks` codificado en Base64.
- `ANDROID_KEYSTORE_PASSWORD`: contraseña del almacén de llaves (`storePassword`).
- `ANDROID_KEY_ALIAS`: alias de la llave (`keyAlias`).
- `ANDROID_KEY_PASSWORD`: contraseña de la llave (`keyPassword`).
- `API_URL` *(opcional)*: URL base del backend si deseas sobrescribirla en compilación sin modificar el código (`--dart-define=API_URL=...`).

### Cómo generar tu keystore localmente (PowerShell)

```powershell
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bookcut
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.jks")) | Set-Clipboard
```

El segundo comando copia al portapapeles el texto Base64 listo para pegarlo en el secret `ANDROID_KEYSTORE_BASE64`. Conserva una copia segura de `release.jks` fuera del repositorio para poder actualizar la app en el futuro sin conflictos de firma.

## Desarrollo local

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
