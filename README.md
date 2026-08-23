# EDUMON — App móvil (Flutter)

App educativa para instituciones, con roles de **superadministrador**, **administrador** (institución), **docente** y **padre/tutor**. Gestiona cursos, tareas ("retos"), entregas, calendario/eventos, foros, notificaciones y perfiles familiares.

Migración/reimplementación en Flutter de la plataforma web EDUMON. La especificación técnica completa (pantalla por pantalla, endpoints, reglas de negocio) vive en [`docs/flutter-migration/BLUEPRINT.md`](docs/flutter-migration/BLUEPRINT.md) — este README cubre cómo correr, compilar y entender el sistema de diseño del proyecto.

## Índice

- [¿Qué es EDUMON?](#qué-es-edumon)
- [Roles y funcionalidades](#roles-y-funcionalidades)
- [Stack](#stack)
- [Requisitos](#requisitos)
- [Getting started](#getting-started)
- [⚠️ Compilar en Windows dentro de una carpeta de OneDrive](#️-compilar-en-windows-dentro-de-una-carpeta-de-onedrive)
- [Assets (SVG de marca) — ojo con las subcarpetas](#assets-svg-de-marca--ojo-con-las-subcarpetas)
- [Ícono de la app](#ícono-de-la-app)
- [Sistema de diseño](#sistema-de-diseño)
- [Estructura](#estructura)
- [Autenticación y roles](#autenticación-y-roles)
- [Tests](#tests)
- [Contribuir](#contribuir)

## ¿Qué es EDUMON?

EDUMON es un **LMS (Learning Management System) educativo multi-tenant**: conecta instituciones escolares completas (colegios como clientes independientes, cada uno con sus propios docentes, cursos y usuarios) alrededor del ciclo de vida de un curso — módulos, tareas ("retos"), entregas calificadas, foros y calendario.

Esta app es la reimplementación nativa (Flutter/Android, con soporte Web) de la plataforma web original (React), consumiendo el mismo backend (`https://backend-edumon.onrender.com`). El detalle completo de la ingeniería inversa de la web original, decisiones de arquitectura y mapeo pantalla-por-pantalla está en [`docs/flutter-migration/BLUEPRINT.md`](docs/flutter-migration/BLUEPRINT.md).

## Roles y funcionalidades

| Rol | Qué hace |
|---|---|
| **Super administrador** | Da de alta instituciones (colegios) y su administrador inicial; gestión global de la plataforma. |
| **Administrador** (institución) | Gestiona su colegio: registro de docentes (individual o CSV masivo), creación de cursos, usuarios, eventos institucionales. |
| **Docente** | Estructura cursos en módulos, publica tareas/"retos" (con adjuntos, asignación total o parcial), califica entregas (1-5 estrellas + comentario), participa en foros por curso. |
| **Padre/Tutor** | Consume el contenido del curso de su(s) hijo(s) y **entrega tareas en su nombre**; puede gestionar varios perfiles familiares (varios hijos) bajo una sola cuenta. |

Existe un quinto rol, `estudiante`, contemplado en el modelo de permisos (`lib/core/security/role.dart`) pero sin flujo de login propio activo — hoy el estudiante es representado por su padre/tutor.

Dominios funcionales (un folder por feature en `lib/features/`): autenticación, cursos, tareas, entregas, foros, calendario, eventos, notificaciones, buzón de contacto, perfiles familiares, usuarios, docentes, instituciones, perfil propio, dashboard.

## Stack

- **Flutter** (Dart) — `sdk: ^3.12.2`, Material 3 fuertemente personalizado (no M3 "de fábrica").
- **Riverpod** (`flutter_riverpod`) para estado/DI.
- **go_router** para navegación declarativa con guards de auth/rol.
- **Dio** + `cookie_jar`/`dio_cookie_manager` — la sesión vive en cookies httpOnly (igual que la web), no en un JWT manejado a mano.
- **flutter_svg** — íconos/formas de marca vienen como SVG de la galería (`assets/img/`), no como PNG/emoji.

## Requisitos

- Flutter SDK **3.44.x** (canal stable) / Dart **3.12.2** — verificar con `flutter --version`.
- Un dispositivo/emulador Android, o Chrome para correr en Web (`flutter run -d chrome`).
- Backend real en `https://backend-edumon.onrender.com` (no hay backend local en este repo; no se necesita levantar nada aparte de la app).

## Getting started

```bash
flutter pub get
flutter run                # elige un device (ver "flutter devices")
flutter run -d chrome       # más rápido para iterar sobre UI
flutter test                 # suite de tests
```

Backend real: `https://backend-edumon.onrender.com` (configurado en `lib/core/network/`). No hay backend local en este repo.

## ⚠️ Compilar en Windows dentro de una carpeta de OneDrive

Si el proyecto vive bajo `OneDrive\...` (como en este equipo), **los builds de Android con Gradle pueden fallar** con errores como:

```
Cannot access output property 'outputDirectory' of task ':app:compileFlutterBuildRelease'.
> java.io.IOException: Cannot snapshot ...\build\app\...\.last_build_id: not a regular file
```

o con `FileSystemException` al borrar `build\` ("no se puede acceder al archivo porque está siendo usado por otro proceso"). Es un problema conocido: el filtro de sincronización de OneDrive interfiere con Gradle creando/borrando muchos archivos chicos rápidamente durante el build (no es un bug del código de la app).

**Solución aplicada en este equipo**: la carpeta `build/` del proyecto es un *junction* de Windows que apunta fuera de OneDrive:

```powershell
# Ya está configurado, pero si `flutter clean` borra el junction, recrearlo así:
$buildCache = "C:\FlutterBuildCache\edumon_movil"
New-Item -ItemType Directory -Force -Path $buildCache
New-Item -ItemType Junction -Path "build" -Target $buildCache
```

Si no existe ese junction y el build de Android falla, esa es la primera causa a revisar. Los builds web (`flutter build web`) y `flutter test` no se ven afectados por este problema.

Si además Gradle queda "trabado" con un `FileSystemException` de un archivo en uso, suele ser un daemon de Gradle/proceso `dart.exe` colgado de una corrida anterior — cerrar `java.exe`/`dart.exe`/`dartaotruntime.exe` sueltos (Administrador de tareas) y reintentar resuelve la mayoría de los casos.

## Assets (SVG de marca) — ojo con las subcarpetas

`assets/img/` tiene subcarpetas (`logo/`, `circulos/`, `recursos/`) con el logo, el wordmark "EDUMON" y las figuras decorativas (`circuloN.svg`), todas en SVG (sin PNG, sin emoji, por regla de diseño del proyecto). `circulos/` son los círculos usados por `EdumonShapeBackdrop` (login, forgot/reset-password, wizard); `recursos/` son ilustraciones puntuales del Home web. La carpeta `Shapes/` (formas orgánicas `shapeN.svg`) existió en una versión anterior y ya no está en el repo — no volver a agregarla a `pubspec.yaml` sin que exista en disco.

**Importante**: en `pubspec.yaml`, declarar una carpeta en `assets:` **no es recursivo** — Flutter no incluye automáticamente las subcarpetas. Por eso `assets:` lista cada subcarpeta explícitamente:

```yaml
flutter:
  assets:
    - assets/img/
    - assets/img/logo/
    - assets/img/circulos/
    - assets/img/recursos/
```

Si en algún momento se agrega una subcarpeta nueva dentro de `assets/img/` (por ejemplo `assets/img/badges/`), hay que sumarla acá a mano — si no, esos archivos compilan sin error pero fallan en tiempo de ejecución con `Unable to load asset: ...` (así se manifestó este bug la primera vez: sin errores de build, pero el logo y las figuras nunca cargaban en ningún modo, debug o release).

## Ícono de la app

El ícono (pantalla de inicio / instalador) sale del logo real de la marca, no del ícono default de Flutter:

1. `assets/img/logo/app_icon.png` — PNG 1024×1024 rasterizado de `logo.svg` (el ícono del monstruo).
2. `flutter_launcher_icons` (dev dependency, configurado en `pubspec.yaml`) genera automáticamente todas las densidades de Android (`mipmap-*dpi`) + ícono adaptativo, y el ícono de iOS.

Para regenerar después de cambiar el logo:

```bash
flutter pub get
dart run flutter_launcher_icons
```

## Sistema de diseño

Tokens centralizados en `lib/core/theme/`, no hay colores/tipografías hardcodeados sueltos por pantalla:

| Archivo | Contenido |
|---|---|
| `app_colors.dart` | Paleta de marca (`primary` = azul `#0DC5E2`, `secondary` = rosa, `success` = verde, `warning` = amarillo, `accent` = morado), escalas por color, tokens de modo oscuro (`*Dark`), y helpers `AppColors.mutedText(context)` / `subtleText(context)` / `errorSurface(isDark)` / `successSurface(isDark)` para resolver el color correcto según el tema activo sin repetir el `if` en cada pantalla. |
| `app_typography.dart` | Fredoka (encabezados) + Poppins (cuerpo/botones), vía `google_fonts` con `allowRuntimeFetching = false` (no depende de red para renderizar texto). |
| `app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` — ThemeData completo, no M3 "de fábrica". |
| `theme_mode_controller.dart` | Preferencia Claro/Oscuro/Sistema, persistida con `shared_preferences`. Selector en Perfil (ver `profile_screen.dart`). Por defecto sigue el tema del sistema operativo. |
| `theme_extensions.dart` | Extensión `context.isDarkMode`. |

Componentes reutilizables en `lib/core/design_system/`: `EdumonButton`, `EdumonTextField`, `EdumonCard`/`EdumonStatCard`/`EdumonEmptyHint`, y en `decor/`: `EdumonLogoMark` (logo + wordmark) y `EdumonShapeBackdrop` (figuras SVG decorativas posicionables, usadas en las pantallas de auth).

### Estado del modo oscuro

Infraestructura completa (`AppTheme.dark()`, detección automática + selector manual). Aplicado **por completo** en: pantallas de autenticación, los 4 dashboards, navegación (Drawer/NavigationRail), Calendario, Foro, Cursos, Notificaciones, y los componentes compartidos (`EdumonCard`, `EdumonButton`, `EdumonTextField`). El resto de pantallas heredan los colores de marca correctos automáticamente (por los tokens compartidos), pero pueden tener algún texto secundario puntual sin afinar para contraste óptimo en oscuro — no roto, solo no 100% pulido.

## Estructura

```
lib/
  core/
    theme/          # tokens de color/tipografía, AppTheme claro/oscuro
    design_system/  # EdumonButton, EdumonTextField, EdumonCard, decor/ (logo, shapes)
    router/          # go_router (app_router.dart) + shell de navegación por rol
    network/          # Dio, interceptor de auth, cookie jar, manejo de errores de red
    security/          # UserRole (enum canónico de rol, mapeo API <-> app)
    notifications/      # notificaciones in-app / push
    config/               # configuración de la app
    utils/                    # utilidades compartidas
  features/          # un folder por feature (data/domain/presentation), Riverpod + Clean Architecture liviana
    auth/ cursos/ tareas/ entregas/ foros/ calendario/ eventos/
    notificaciones/ buzon/ perfiles/ usuarios/ docentes/ instituciones/
    perfil/ dashboard/ home/
  main.dart / app.dart
test/                # flutter test (login, wizard de primer ingreso, home web, widget test base)
docs/flutter-migration/BLUEPRINT.md   # spec técnica completa pantalla por pantalla
```

Cada feature en `lib/features/<dominio>/` sigue el mismo patrón interno: `data/` (repositorios, servicios HTTP), `domain/` (modelos, casos de uso) y `presentation/` (pantallas, providers de Riverpod).

## Autenticación y roles

- Login por **teléfono + contraseña** (no hay registro público de usuarios — las cuentas las crea un admin/superadmin).
- Primer ingreso pasa por un wizard (`first_login_wizard_screen.dart`) para elegir foto, confirmar datos y cambiar la contraseña temporal.
- Sesión en cookies httpOnly; en la app nativa se persisten en disco (`path_provider` + `cookie_jar`). En Web no hay filesystem, así que se usa un `CookieJar` en memoria — pero ahí es casi vestigial: la cookie real la maneja el propio navegador vía `withCredentials` (ver `lib/core/network/api_client.dart`), independiente de ese CookieJar, así que la sesión sí sobrevive a un refresh de página en Web mientras la cookie del backend siga vigente.
- El rol se resuelve a un único enum canónico (`UserRole` en `lib/core/security/role.dart`), con mapeo explícito y exhaustivo desde el string que devuelve el backend (sin heurísticas de substring) — cualquier valor de rol no reconocido lanza una excepción en vez de fallar en silencio, para detectar cambios de contrato con el backend temprano.

## Tests

```bash
flutter test
```

Suite actual en `test/`: flujo de login, wizard de primer ingreso, home web y un widget test base. Al agregar una pantalla o flujo nuevo, sumar su test correspondiente en `test/` siguiendo el mismo patrón (nombre descriptivo del flujo, no del archivo fuente).

## Contribuir

1. Crear una rama a partir de `main` con nombre descriptivo (`feature/...`, `fix/...`).
2. Antes de tocar una pantalla, revisar si el flujo ya está documentado en [`docs/flutter-migration/BLUEPRINT.md`](docs/flutter-migration/BLUEPRINT.md) — es la fuente de verdad de reglas de negocio y contratos de API.
3. Usar los tokens de `lib/core/theme/` y los componentes de `lib/core/design_system/` en vez de colores/estilos hardcodeados por pantalla.
4. Si se agrega una pantalla nueva, aplicar modo oscuro desde el principio (ver [Estado del modo oscuro](#estado-del-modo-oscuro)) y sumar su test en `test/`.
5. Correr `flutter test` y `flutter analyze` antes de abrir el PR.
6. Abrir el Pull Request contra `main` describiendo qué cambia y por qué (no solo el qué — el diff ya lo dice).
