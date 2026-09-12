# Manual Técnico / Descripción del Programa de Computador

## EDUMON — Aplicación Android (versión móvil)

---

## 0. Declaración de conformidad

El presente documento constituye la Memoria Técnica / Descripción del Programa de Computador de la obra **EDUMON — Aplicación Android**, elaborada para efectos de su registro ante la **Dirección Nacional de Derecho de Autor (DNDA)** de la República de Colombia, en cumplimiento de lo dispuesto en el **Decreto 1066 de 2015, artículo 2.8.1.1.2**, la **Ley 23 de 1982** (sobre Derechos de Autor) y la **Decisión Andina 351 de 1993** (Régimen Común sobre Derecho de Autor y Derechos Conexos de la Comunidad Andina).

Los suscritos autores declaran que la presente obra —el programa de computador denominado **EDUMON**, en su versión para el sistema operativo Android— es una creación original, fruto de su propio esfuerzo intelectual, y que la información técnica aquí consignada corresponde fielmente al código fuente y a los artefactos de configuración del proyecto al momento de su presentación.

> **Nota de alcance.** EDUMON es una única base de código **Flutter (Dart)** multiplataforma (Android, iOS y Web) que se compila de forma nativa para cada plataforma. Este manual describe específicamente el **artefacto Android** (APK/AAB, `applicationId: com.edumon.movil`) generado a partir de dicha base de código, documentando tanto la lógica de la aplicación (común a las tres plataformas) como los componentes específicos de la integración Android (Gradle, `AndroidManifest.xml`, firma, notificaciones push nativas).

---

## 1. Datos de registro

| Campo                                                       | Valor                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Título de la obra**                                | EDUMON — Aplicación Android                                                                                                                                                                                                                                                                                                                                                                 |
| **Tipo de obra**                                      | Programa de computador (aplicación móvil, cliente de una API REST)                                                                                                                                                                                                                                                                                                                          |
| **País**                                             | Colombia                                                                                                                                                                                                                                                                                                                                                                                      |
| **Año de creación**                                 | 2026 (primer commit: 2026-07-29; última consolidación: 2026-09-10)                                                                                                                                                                                                                                                                                                                          |
| **Institución**                                      | *[INSTITUCIÓN / UNIVERSIDAD — completar antes de radicar]*, *[CIUDAD — completar antes de radicar]*                                                                                                                                                                                                                                                                                    |
| **Autores**                                           | Bryan David Yepes; Karen Verónica Mancilla Solarte                                                                                                                                                                                                                                                                                                                                           |
| **Nombre del paquete / identificador de aplicación** | `com.edumon.movil`                                                                                                                                                                                                                                                                                                                                                                          |
| **Versión declarada**                                | `versionName` 1.0.0 (`versionCode` / build number 1) — `pubspec.yaml`, línea `version: 1.0.0+1`                                                                                                                                                                                                                                                                                     |
| **Estado del software**                               | Versión funcional finalizada. Último commit en rama`main`: *"Aplicacion movil finalizada"* (2026-09-10). Historial de hitos relevantes: implementación inicial (2026-07-29), consolidación de documentación (2026-08-23), auditoría completa de contratos de API contra el backend real (2026-08-30), integración de notificaciones push con Firebase Cloud Messaging (2026-08-31) |
| **Repositorio**                                       | Proyecto`edumon_movil` (control de versiones Git, rama principal `main`)                                                                                                                                                                                                                                                                                                                  |

---

## 2. Descripción general del sistema

### 2.1 Justificación

EDUMON es un **sistema de gestión de aprendizaje (LMS) educativo multi-tenant**: permite que múltiples instituciones escolares (colegios), cada una como cliente independiente con sus propios docentes, cursos y usuarios, gestionen el ciclo de vida completo de un curso — módulos, tareas ("retos"), entregas calificadas, foros de discusión y calendario de eventos — desde una única plataforma.

El problema real que resuelve la aplicación, inferido de las funcionalidades implementadas en el código, es la **fragmentación de la comunicación y el seguimiento académico entre instituciones, docentes y familias**: EDUMON centraliza en un solo cliente móvil (i) la publicación y calificación de tareas, (ii) la trazabilidad de entregas por estudiante, (iii) la comunicación por foros moderados por curso, (iv) el calendario institucional de eventos, y (v) la gestión de **perfiles familiares múltiples** bajo una sola cuenta de padre/tutor — un padre con varios hijos en la institución puede alternar entre perfiles sin necesitar una cuenta por cada uno.

Un caso de uso particular que justifica el diseño del sistema de roles es que el **padre/tutor entrega tareas en nombre de su hijo** (no existe un rol "estudiante" con sesión propia activa hoy — ver §3), lo cual refleja el contexto real de instituciones donde los menores no gestionan directamente una cuenta digital.

### 2.2 Introducción técnica

- **Lenguaje**: Dart (`environment.sdk: ^3.12.2` en `pubspec.yaml`). Herramientas verificadas en el entorno de build: Flutter 3.44.5 (canal *stable*), Dart 3.12.2.
- **Framework de UI**: Flutter — widgets de Material Design fuertemente personalizados mediante un sistema de diseño propio (no Material 3 "de fábrica"; ver §12).
- **Arquitectura**: **Clean Architecture ligera por *feature*, combinada con MVVM funcional vía Riverpod**. No se usa Jetpack Compose/Room/Hilt (no aplican: no es un proyecto Android nativo Kotlin/Java, ver nota de alcance en §0). Cada dominio funcional en `lib/features/<dominio>/` sigue el mismo patrón interno de tres capas:
  - `data/` — `datasources` (llamadas HTTP concretas vía Dio), `models` (DTOs de serialización JSON) y `repositories` (implementación concreta).
  - `domain/` — `entities` (modelos de negocio inmutables, sin dependencia de la capa de datos) y, en algunos *features*, `usecases` (p. ej. `login_usecase.dart`).
  - `presentation/` — `screens` (widgets de pantalla), `widgets` (subcomponentes) y `providers` (estado y orquestación vía Riverpod, haciendo las veces de *ViewModel*).
- **SDK Android objetivo**: `minSdk` 24 (Android 7.0), `targetSdk` / `compileSdk` 36 (Android 15) — valores resueltos dinámicamente por el Flutter Gradle Plugin según la versión de Flutter SDK instalada (no están hardcodeados en `build.gradle.kts`; ver §4).
- **Librerías núcleo**:
  - **Estado / inyección de dependencias**: `flutter_riverpod` (Riverpod 3.x) — no Hilt/Dagger (no aplican en Flutter).
  - **UI declarativa**: widgets Flutter estándar + sistema de diseño propio (`lib/core/design_system/`), no Jetpack Compose (no aplica).
  - **Persistencia local**: `shared_preferences` (clave-valor) — **no usa Room ni SQLite** (ver §7).
  - **Red**: `dio` (cliente HTTP) + `cookie_jar`/`dio_cookie_manager` (sesión por cookies) — no Retrofit/Ktor (no aplican en Flutter; Dio es el equivalente funcional del ecosistema Dart).
  - **Serialización**: modelos `fromJson`/`toJson` escritos a mano (no se usa `json_serializable`, `Gson` ni `Moshi` — no encontrados en el repo).

### 2.3 Objetivos del sistema

Derivados directamente de las funcionalidades implementadas (`lib/features/`):

1. Permitir a un superadministrador dar de alta instituciones educativas y su administrador inicial.
2. Permitir a un administrador de institución gestionar docentes (alta individual o masiva por CSV), usuarios y eventos institucionales.
3. Permitir a un docente estructurar cursos en módulos, publicar tareas con adjuntos y calificar entregas (escala 1-5 + comentario).
4. Permitir a un padre/tutor consultar el contenido de curso de su(s) hijo(s), entregar tareas en su nombre y gestionar varios perfiles familiares desde una sola cuenta.
5. Habilitar comunicación por foros de discusión por curso, con reglas de moderación diferenciadas por rol.
6. Consolidar un calendario de eventos institucionales y fechas de entrega de tareas.
7. Notificar en tiempo real (push, Firebase Cloud Messaging) y en la aplicación (notificaciones in-app) sobre tareas, entregas, calificaciones, foros y eventos.

---

## 3. Público objetivo

La aplicación modela **cinco roles** en el enum canónico `UserRole` (`lib/core/security/role.dart`), de los cuales cuatro tienen flujo de sesión propio activo:

| Rol                                                         | Funcionalidades habilitadas                                                                                                                                                                                                                  |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Superadministrador** (`superAdmin`)               | Alta de instituciones y su administrador inicial; gestión global de la plataforma; ruta de inicio`/admin`.                                                                                                                                |
| **Administrador de institución** (`administrador`) | Registro de docentes (individual o CSV masivo), creación de cursos, usuarios y eventos institucionales; moderación de mensajes de foro; ruta de inicio`/admin`.                                                                          |
| **Docente** (`docente`)                             | Estructuración de cursos en módulos, publicación de tareas/"retos" (adjuntos, asignación total o parcial), calificación de entregas (1-5 estrellas + comentario), creación y gestión de foros por curso; ruta de inicio`/docente`.  |
| **Padre/Tutor** (`padreTutor`)                      | Consulta de contenido de curso de sus hijos, entrega de tareas en su nombre, gestión de varios perfiles familiares bajo una cuenta, participación en foros (con restricciones de respuesta); ruta de inicio`/padre`.                     |
| **Estudiante** (`estudiante`)                       | Contemplado en el modelo de permisos y en el mapeo de roles del backend,**sin flujo de login propio activo** — el estudiante es representado hoy por su padre/tutor (`homeRoute` de `estudiante` redirige también a `/padre`). |

No existe registro público de usuarios: todas las cuentas son creadas por un administrador o superadministrador, y el primer ingreso pasa por un asistente (*wizard*) de confirmación de datos y cambio de contraseña temporal (`first_login_wizard_screen.dart`).

---

## 4. Diseño técnico — Stack tecnológico

| Categoría                    | Detalle                                                                                                                                                                                                                                                                                                     |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lenguaje                      | Dart, SDK`^3.12.2`                                                                                                                                                                                                                                                                                        |
| Framework                     | Flutter 3.44.5 (canal*stable*)                                                                                                                                                                                                                                                                            |
| Arquitectura                  | Clean Architecture ligera por*feature* (`data`/`domain`/`presentation`) + gestión de estado reactivo con Riverpod                                                                                                                                                                                  |
| Gestor de dependencias (Dart) | `pub` (`pubspec.yaml` / `pubspec.lock`)                                                                                                                                                                                                                                                               |
| Gestor de build Android       | Gradle**9.1.0** (`gradle-wrapper.properties`), Android Gradle Plugin (AGP) **8.13.1**, plugin Kotlin **2.3.20** (`android/settings.gradle.kts`) — Kotlin se usa únicamente para el *glue code* nativo de la plataforma Android que genera Flutter, no para lógica de aplicación |
| Plugin Google Services        | `com.google.gms.google-services` **4.5.0** (aplicado condicionalmente solo si existe `google-services.json`, ver §11)                                                                                                                                                                            |
| Compilador Java (Android)     | `sourceCompatibility`/`targetCompatibility` **JavaVersion 17**, con *core library desugaring* habilitado (`desugar_jdk_libs` **2.1.5**) — requerido por `flutter_local_notifications` para usar APIs de `java.time` en versiones antiguas de Android                               |

**Librerías principales** (versiones exactas resueltas en `pubspec.lock`):

| Paquete                          | Versión | Rol                                                                                                                                                                                                 |
| -------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flutter_riverpod`             | 3.4.2    | Estado de la aplicación e inyección de dependencias                                                                                                                                               |
| `go_router`                    | 17.3.0   | Navegación declarativa con*guards* de autenticación/rol                                                                                                                                         |
| `dio`                          | 5.11.0   | Cliente HTTP                                                                                                                                                                                        |
| `cookie_jar`                   | 4.0.9    | Almacén de cookies de sesión                                                                                                                                                                      |
| `dio_cookie_manager`           | 3.5.0    | Interceptor de cookies para Dio                                                                                                                                                                     |
| `path_provider`                | 2.1.6    | Resolución de rutas del sistema de archivos (persistencia de cookies)                                                                                                                              |
| `shared_preferences`           | 2.5.5    | Persistencia local clave-valor (preferencias)                                                                                                                                                       |
| `jwt_decoder`                  | 2.0.1    | Declarado en`pubspec.yaml`; **sin uso real localizado en `lib/`** — la sesión no se maneja por JWT decodificado en cliente, sino por cookies httpOnly (ver §6). Dependencia vestigial. |
| `firebase_core`                | 4.14.0   | Inicialización de Firebase                                                                                                                                                                         |
| `firebase_messaging`           | 16.6.0   | Notificaciones push (FCM)                                                                                                                                                                           |
| `flutter_local_notifications`  | 22.3.0   | Presentación de notificaciones locales/foreground                                                                                                                                                  |
| `google_fonts`                 | 8.2.0    | Tipografías de marca (Fredoka, Poppins), con*fetching* en tiempo de ejecución deshabilitado                                                                                                     |
| `flutter_svg`                  | 2.3.0    | Renderizado de recursos gráficos vectoriales de marca                                                                                                                                              |
| `file_picker`                  | 11.0.2   | Selección de archivos adjuntos                                                                                                                                                                     |
| `image_picker`                 | 1.2.3    | Selección/captura de imágenes                                                                                                                                                                     |
| `flutter_rating_bar`           | 4.0.1    | Componente de calificación 1-5 estrellas                                                                                                                                                           |
| `flutter_colorpicker`          | 1.1.0    | Selector visual de color de curso                                                                                                                                                                   |
| `table_calendar`               | 3.2.0    | Componente de calendario                                                                                                                                                                            |
| `connectivity_plus`            | 7.3.1    | Detección de estado de conectividad                                                                                                                                                                |
| `permission_handler`           | 12.0.3   | Solicitud de permisos en tiempo de ejecución                                                                                                                                                       |
| `intl`                         | 0.20.3   | Formateo de fechas/locale (`es_CO`)                                                                                                                                                               |
| `lucide_icons_flutter`         | 3.1.15   | Set de iconografía                                                                                                                                                                                 |
| `logger`                       | 2.7.0    | Registro de eventos en modo depuración                                                                                                                                                             |
| `flutter_lints` (dev)          | 6.0.0    | Reglas de análisis estático                                                                                                                                                                       |
| `flutter_launcher_icons` (dev) | 0.14.3   | Generación de iconos de aplicación                                                                                                                                                                |

### Persistencia local

**No se usa Room ni SQLite.** La persistencia local se limita a:

- `shared_preferences`: banderas de preferencia (tema claro/oscuro/sistema, si ya se solicitó el permiso de notificaciones una vez).
- `cookie_jar` (`PersistCookieJar` + `FileStorage`, vía `path_provider`): archivo de cookies de sesión HTTP persistido en el directorio de soporte de la aplicación (`getApplicationSupportDirectory()/.cookies`).

No existe una base de datos relacional local ni caché estructurada de datos de dominio: la aplicación es **online-first**, y el backend remoto es la única fuente de verdad de los datos (cursos, tareas, usuarios, etc.).

### Networking

- **Cliente HTTP**: `Dio`, configurado en `lib/core/network/api_client.dart`, con `baseUrl` apuntando al backend real (`https://backend-edumon.onrender.com/api` por defecto, sobreescribible vía `--dart-define=API_BASE_URL=...`).
- **Formato de serialización**: JSON nativo de Dart (`dart:convert`, vía los métodos `fromJson`/`toJson` de cada modelo en `data/models/`), sin librerías de terceros de serialización (no se encontró `json_serializable`, `Gson`, ni `Moshi`).
- **Timeouts**: `connectTimeout`/`receiveTimeout` de 45 segundos (dimensionado explícitamente para tolerar el arranque en frío del backend en el plan gratuito de Render).

---

## 5. Requerimientos del sistema

### 5.1 Requerimientos funcionales

| ID    | Requerimiento                                                                                                                | Pantalla / Módulo                                                                                            |
| ----- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| RF-01 | Autenticar un usuario por teléfono y contraseña                                                                            | `login_screen.dart` / `AuthController.login()`                                                            |
| RF-02 | Recuperar contraseña mediante código enviado al correo                                                                     | `forgot_password_screen.dart`, `reset_password_screen.dart`                                               |
| RF-03 | Completar asistente de primer ingreso (foto, datos, cambio de contraseña temporal)                                          | `first_login_wizard_screen.dart`                                                                            |
| RF-04 | Consultar y cerrar sesiones activas del usuario (individual o todas)                                                         | `sessions_screen.dart` / `AuthController.logoutAll()`                                                     |
| RF-05 | Dar de alta y listar instituciones (rol superadmin)                                                                          | `instituciones_screen.dart`, `institucion_form_screen.dart`                                               |
| RF-06 | Consultar/editar la institución propia (rol admin)                                                                          | `mi_institucion_screen.dart`                                                                                |
| RF-07 | Gestionar usuarios (crear, editar, reactivar)                                                                                | `usuarios_screen.dart`, `usuario_form_screen.dart`                                                        |
| RF-08 | Registrar docentes individualmente o por carga masiva CSV                                                                    | `docentes_screen.dart`, `docente_form_screen.dart`                                                        |
| RF-09 | Crear, editar, archivar y restaurar cursos                                                                                   | `cursos_screen.dart`, `curso_form_screen.dart`                                                            |
| RF-10 | Estructurar un curso en módulos                                                                                             | `modulos_tab.dart`                                                                                          |
| RF-11 | Gestionar participantes de un curso, incluyendo consulta de información de contacto de un padre                             | `participantes_tab.dart`                                                                                    |
| RF-12 | Publicar, editar y cerrar tareas ("retos"), con asignación total o parcial de participantes                                 | `tarea_form_screen.dart`, `retos_screen.dart`                                                             |
| RF-13 | Consultar el detalle de una tarea y sus estadísticas de entrega                                                             | `tarea_detail_screen.dart`                                                                                  |
| RF-14 | Realizar una entrega (borrador, envío, adjuntos, eliminación de archivo adjunto) en nombre de un hijo                      | `realizar_entrega_screen.dart`                                                                              |
| RF-15 | Listar y calificar entregas (1-5 estrellas + comentario)                                                                     | `entregas_list_screen.dart`                                                                                 |
| RF-16 | Consultar entregas propias del núcleo familiar                                                                              | `mis_entregas_screen.dart`                                                                                  |
| RF-17 | Crear, editar, cerrar/reabrir un foro por curso; enviar y responder mensajes con adjuntos, con reglas de moderación por rol | `forum_screen.dart`, `create_foro_sheet.dart`                                                             |
| RF-18 | Consultar analíticas de actividad de un foro (participantes activos, actividad de 7 días)                                  | `foro_dashboard_screen.dart`                                                                                |
| RF-19 | Crear, editar y cancelar eventos institucionales                                                                             | `evento_form_screen.dart`, `eventos_screen.dart`                                                          |
| RF-20 | Consultar calendario consolidado de tareas y eventos                                                                         | `calendario_screen.dart`                                                                                    |
| RF-21 | Gestionar perfiles familiares (varios hijos bajo una cuenta) y seleccionar perfil activo                                     | `perfiles_screen.dart`                                                                                      |
| RF-22 | Consultar, marcar como leídas y eliminar notificaciones in-app                                                              | `notificaciones_screen.dart`                                                                                |
| RF-23 | Recibir notificaciones push (con la app en segundo plano o cerrada)                                                          | `fcm_service.dart`                                                                                          |
| RF-24 | Enviar mensaje público de contacto (buzón, sin autenticación)                                                             | `landing_contacto_section.dart`, `buzon_publico_repository_impl.dart`                                     |
| RF-25 | Consultar y marcar como leídos los mensajes de buzón (rol superadmin)                                                      | `buzon_screen.dart`                                                                                         |
| RF-26 | Editar perfil propio (foto, contraseña) y preferencia de tema claro/oscuro/sistema                                          | `profile_screen.dart`                                                                                       |
| RF-27 | Consultar panel de indicadores (*dashboard*) diferenciado por rol                                                          | `superadmin_dashboard.dart`, `admin_dashboard.dart`, `docente_dashboard.dart`, `padre_dashboard.dart` |

### 5.2 Requerimientos no funcionales

- **Offline-first**: **no implementado**. La aplicación requiere conectividad activa para toda operación de datos; `connectivity_plus` se usa únicamente para mostrar un aviso visual de falta de conexión (`connectivity_banner.dart`), no para encolar operaciones offline.
- **Resiliencia de red**: tiempo de espera ampliado (45 s) para tolerar el arranque en frío del backend gratuito (Render); reintento automático de una sola vez ante expiración de sesión (`RefreshInterceptor`).
- **Internacionalización de fecha/hora**: locale `es_CO` inicializado explícitamente al arranque (`initializeDateFormatting`).
- **Disponibilidad de tipografía sin red**: `GoogleFonts.config.allowRuntimeFetching = false` — las fuentes de marca están empaquetadas como *assets* locales (`assets/fonts/`), no se descargan en tiempo de ejecución.
- **Tamaño de APK / consumo de batería y datos**: no se encontró optimización explícita documentada en el repositorio (sin `shrinkResources`, sin *baseline profiles*, sin *R8 full mode* configurado — ver §11). **No implementado / no verificado.**
- **Accesibilidad de modo oscuro**: infraestructura completa de tema claro/oscuro (`AppTheme.light()`/`AppTheme.dark()`), aplicada íntegramente en pantallas de autenticación, los 4 *dashboards*, navegación, Calendario, Foro, Cursos y Notificaciones.

### 5.3 Requerimientos del dispositivo

| Requerimiento                                 | Valor                                                                                                                                                                                                                                                                                       |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `minSdkVersion`                             | 24 (Android 7.0 Nougat)                                                                                                                                                                                                                                                                     |
| `targetSdkVersion` / `compileSdkVersion`  | 36 (Android 15)                                                                                                                                                                                                                                                                             |
| Versión NDK                                  | 28.2.13676358                                                                                                                                                                                                                                                                               |
| Permisos declarados (`AndroidManifest.xml`) | `INTERNET` — requerido para las llamadas HTTP al backend real (Dio); `POST_NOTIFICATIONS` — requerido desde Android 13 (API 33) para poder solicitar el permiso de notificaciones en tiempo de ejecución                                                                             |
| Hardware/sensores requeridos                  | Ninguno declarado explícitamente más allá de conectividad de red; el uso de cámara/galería (`image_picker`) y de selección de archivos (`file_picker`) es opcional y bajo demanda del usuario, sin declaración `<uses-feature>` obligatoria en el manifiesto                   |
| RAM / almacenamiento estimado                 | No especificado en el repositorio (**no implementado / no verificado**) — dependiente de los requisitos generales del *engine* Flutter para el `minSdk` declarado                                                                                                                |
| Conexión de red requerida                    | **Híbrida con dependencia fuerte de red**: la aplicación arranca y renderiza sin red (UI/tipografía locales), pero toda operación de datos (autenticación, cursos, tareas, notificaciones, etc.) requiere conexión activa al backend en `https://backend-edumon.onrender.com` |

---

## 6. Arquitectura de componentes

### 6.1 Diagrama de capas

```
┌─────────────────────────────────────────────────────────────┐
│  UI (Flutter Widgets)                                        │
│  lib/features/<dominio>/presentation/screens, widgets        │
└───────────────────────────┬─────────────────────────────────┘
                             │ consume / observa
┌───────────────────────────▼─────────────────────────────────┐
│  Estado / "ViewModel" (Riverpod Providers)                   │
│  lib/features/<dominio>/presentation/providers               │
│  (StateNotifier / Notifier — ej. AuthController, ...)        │
└───────────────────────────┬─────────────────────────────────┘
                             │ invoca
┌───────────────────────────▼─────────────────────────────────┐
│  Dominio (Entities / UseCases)                                │
│  lib/features/<dominio>/domain/entities, usecases             │
└───────────────────────────┬─────────────────────────────────┘
                             │ implementado por
┌───────────────────────────▼─────────────────────────────────┐
│  Repositorios (contrato + implementación)                     │
│  lib/features/<dominio>/domain/repositories (interfaz)        │
│  lib/features/<dominio>/data/repositories (impl.)              │
└───────────────────────────┬─────────────────────────────────┘
                             │ usa
┌───────────────────────────▼─────────────────────────────────┐
│  DataSource remoto (Dio)                                      │
│  lib/features/<dominio>/data/datasources                      │
└───────────────────────────┬─────────────────────────────────┘
                             │ HTTP/HTTPS + cookies httpOnly
┌───────────────────────────▼─────────────────────────────────┐
│  Backend remoto (Node.js/Express, fuera de este repositorio)  │
│  https://backend-edumon.onrender.com/api                      │
└─────────────────────────────────────────────────────────────┘
```

No existe capa de `DataSource` **local** con persistencia estructurada: al no usarse Room/SQLite, cada *feature* consulta directamente al `DataSource` remoto; solo `shared_preferences` y el archivo de cookies actúan como persistencia local (ver §7).

### 6.2 Patrón de comunicación con el backend

- **Base URL**: `https://backend-edumon.onrender.com/api` (configurable en tiempo de compilación vía `--dart-define=API_BASE_URL=...`, `lib/core/config/env.dart`).
- **Autenticación**: **cookies httpOnly de sesión** (`access_token` + `refresh_token`, con rotación), **no** un token JWT manejado a mano ni cabecera `Authorization: Bearer`. El cliente HTTP (`Dio`) delega el manejo de cookies a `dio_cookie_manager`, respaldado por un `CookieJar` persistente en disco (móvil) o en memoria (Web, donde el propio navegador gestiona la cookie real vía `withCredentials`).
- **Manejo de expiración de sesión**: interceptor dedicado (`RefreshInterceptor`, `lib/core/network/auth_interceptor.dart`) que, ante una respuesta `401` fuera de las rutas exentas (`/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout`), invoca `POST /auth/refresh` una única vez y reintenta la solicitud original; si el refresco también falla, fuerza el cierre de sesión local (`AuthController.forceLogout()`). Las solicitudes de refresco concurrentes se coalescen para evitar invalidar el token rotado por una llamada paralela.
- **Manejo de errores**: normalización centralizada en `AppException.fromDioException()` (`lib/core/network/network_exceptions.dart`), que interpreta los tres formatos de error observados en el backend real (`{message}`, `{error}`, `{errors:[...]}` de `express-validator`, con claves `path`/`msg`).

---

## 7. Estructura de base de datos local

**No aplica.** El proyecto **no utiliza Room, SQLite ni ningún motor de base de datos local estructurado**. Toda la persistencia de datos de negocio (usuarios, cursos, tareas, entregas, foros, eventos, notificaciones) reside exclusivamente en el backend remoto; la aplicación no mantiene una réplica local ni caché relacional.

Para efectos de trazabilidad del modelo de datos que la aplicación sí consume (vía API, sin persistirlo localmente), se documentan a continuación las principales **entidades de dominio** (`domain/entities/`), que actúan como el contrato de datos interno de la aplicación:

### Entidad `User` (`lib/features/auth/domain/entities/user.dart`)

| Campo                                        | Tipo             | Restricción     | Descripción                                               |
| -------------------------------------------- | ---------------- | ---------------- | ---------------------------------------------------------- |
| `id`                                       | `String`       | requerido        | Identificador único del usuario                           |
| `nombre`, `apellido`                     | `String`       | requeridos       | Nombre y apellido                                          |
| `rol`                                      | `UserRole`     | requerido        | Rol canónico (ver §3)                                    |
| `estado`                                   | `String`       | requerido        | Estado del usuario (activo/inactivo)                       |
| `cedula`                                   | `String`       | requerido        | Documento de identidad                                     |
| `telefono`                                 | `String`       | requerido        | Usado como credencial de login                             |
| `avatarUrl`, `correo`, `institucionId` | `String?`      | opcionales       | —                                                         |
| `permisos`                                 | `List<String>` | default`[]`    | Permisos adicionales                                       |
| `ultimoAcceso`, `fechaRegistro`          | `DateTime?`    | opcionales       | Metadatos de auditoría                                    |
| `primerInicioSesion`                       | `bool`         | default`false` | Determina si se debe forzar el asistente de primer ingreso |

### Entidad `Curso` (`lib/features/cursos/domain/entities/curso.dart`)

| Campo                                                    | Tipo              | Restricción        | Descripción                                     |
| -------------------------------------------------------- | ----------------- | ------------------- | ------------------------------------------------ |
| `id`, `nombre`                                       | `String`        | requeridos          | —                                               |
| `descripcion`, `imagenUrl`, `docenteId`, `color` | `String?`       | opcionales          | `color` es un hexadecimal `#RGB`/`#RRGGBB` |
| `estado`                                               | `String`        | default`'activo'` | `'activo'` / `'archivado'`                   |
| `docente`                                              | `CursoDocente?` | opcional            | Docente titular embebido                         |
| `totalParticipantes`                                   | `int`           | default`0`        | —                                               |
| `fechaCreacion`                                        | `DateTime?`     | opcional            | —                                               |

### Entidad `Tarea` (`lib/features/tareas/domain/entities/tarea.dart`)

| Campo                                                        | Tipo                      | Restricción                       | Descripción                                                                        |
| ------------------------------------------------------------ | ------------------------- | ---------------------------------- | ----------------------------------------------------------------------------------- |
| `id`, `titulo`, `cursoId`                              | `String`                | requeridos                         | —                                                                                  |
| `estado`                                                   | `String`                | default`'publicada'`             | `'publicada'` / `'cerrada'`                                                     |
| `fechaEntrega`                                             | `DateTime?`             | opcional, debe ser futura al crear | Regla validada en formulario y en backend                                           |
| `asignacionTipo`                                           | `AsignacionTipo` (enum) | default`todos`                   | `todos` / `seleccionados`                                                       |
| `tipoEntrega`                                              | `TipoEntrega` (enum)    | default`archivo`                 | `archivo` / `texto` / `enlace` / `multimedia` / `presencial` / `grupal` |
| `archivos`                                                 | `List<Archivo>`         | default`[]`                      | Adjuntos de la tarea                                                                |
| `totalEntregas`, `totalPendientes`, `totalCalificadas` | `int`                   | default`0`                       | Contadores agregados                                                                |

### Entidad `Entrega` (`lib/features/entregas/domain/entities/entrega.dart`)

| Campo                            | Tipo              | Restricción          | Descripción                                                                                                       |
| -------------------------------- | ----------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`, `tareaId`, `padreId` | `String`        | requeridos            | —                                                                                                                 |
| `estado`                       | `String`        | default`'borrador'` | `'borrador'` / `'enviada'` / `'tarde'` (mutuamente excluyente de "calificada", que es un atributo ortogonal) |
| `calificacion`                 | `Calificacion?` | opcional              | `{valoracion: int (1-5), comentario, fechaCalificacion}`                                                         |
| `archivos`                     | `List<Archivo>` | default`[]`         | Adjuntos de la entrega                                                                                             |

### Relaciones entre entidades (a nivel de dominio, no de esquema relacional)

- `Institucion` 1─N `Curso` 1─N `Modulo` 1─N `Tarea` 1─N `Entrega`.
- `User` (rol `padreTutor`) 1─N `Entrega` (a través de `padreId`).
- `Curso` 1─1 `Foro` 1─N `MensajeForo` (autorreferenciado para respuestas).
- `User` (rol `padreTutor`) 1─N `PerfilFamiliar` (perfiles de hijos gestionados desde una sola cuenta).

**Estrategia de migración**: no aplica (no hay esquema de base de datos local que migrar). Los cambios de contrato de datos se gestionan mediante campos opcionales (`?`) en las entidades y modelos, tolerantes a la ausencia de campos nuevos del backend.

---

## 8. Estados y flujos de navegación

### 8.1 Grafo de navegación

La navegación se define de forma declarativa en `lib/core/router/app_router.dart` (`go_router` 17.3.0), con redirección centralizada según el estado de autenticación:

- Ruta inicial: `/` (Home pública, solo en Web) o `/splash` (Android/iOS).
- Rutas públicas (accesibles sin sesión): `/`, `/login`, `/forgot-password`, `/reset-password`.
- Lógica de `redirect` (evaluada en cada cambio de estado de `AuthController`):
  1. Si el estado de autenticación es `unknown` (verificación en curso): permite rutas públicas; cualquier otra redirige a `/splash`.
  2. Si no está autenticado: redirige a `/login`, salvo rutas públicas.
  3. Si está autenticado pero `primerInicioSesion == true`: fuerza `/wizard`.
  4. Si está autenticado, sin primer inicio pendiente, y se encuentra en `/splash`, `/wizard` o una ruta pública: redirige a la ruta de inicio de su rol (`homeRoute`).
- Rutas principales anidadas en un `ShellRoute` (con navegación persistente `Drawer`/`NavigationRail`): `/admin`, `/docente`, `/padre`.
- Rutas de negocio de nivel superior (con `AppBar`/botón atrás propio, alcanzadas por *push* desde el *shell*): `/institucion(es)`, `/usuarios`, `/docentes`, `/cursos/:id`, `/tareas/:id`, `/curso/:cursoId/foro/:foroId`, `/calendario`, `/eventos`, `/familia/perfiles`, `/familia/entregas`, `/buzon`, entre otras (ver listado completo de `GoRoute` en el archivo fuente).

### 8.2 Estados de UI relevantes

- **`AuthStatus`** (enum, `lib/features/auth/presentation/providers/auth_controller.dart`): `unknown` → `authenticating` → `authenticated` / `unauthenticated`. Gobierna íntegramente el `redirect` del router (no se usan *sealed classes* al estilo Kotlin por no aplicar al lenguaje Dart, pero el patrón de estado exhaustivo por `enum` + clase de estado inmutable —`AuthState`— cumple el mismo rol que un `UiState` sellado).
- Cada *feature* de datos remotos expone su propio estado de carga a través de los *providers* asíncronos de Riverpod (`FutureProvider`/`AsyncNotifier`), consumidos en pantalla con los estados estándar de Riverpod: `AsyncLoading`, `AsyncData`, `AsyncError`.

---

## 9. Funcionalidades y servicios

### 9.1 Flujo principal end-to-end

1. **Arranque** (`lib/main.dart`): inicialización de bindings de Flutter, inicialización *best-effort* de Firebase (`Firebase.initializeApp()`, tolerante a la ausencia de `google-services.json`), deshabilitación de descarga de tipografías en tiempo de ejecución, inicialización de locale `es_CO`, creación del `CookieJar` persistente (o en memoria en Web) y arranque de la app dentro de un `ProviderScope` (Riverpod).
2. **Restauración de sesión** (`AuthController._restoreSession()`): invoca `GET /auth/profile` de forma silenciosa al abrir la app; si hay sesión válida (cookie vigente), recupera el usuario y el perfil familiar activo y dispara el registro *best-effort* de notificaciones push; si falla, transiciona a `unauthenticated` sin mostrar error.
3. **Autenticación** (`login_screen.dart` → `LoginUseCase` → `AuthRepository`): login por teléfono + contraseña. Ante éxito, si `primerInicioSesion == true`, el router redirige automáticamente al asistente de primer ingreso.
4. **Navegación por rol**: el *shell* de la aplicación (`AppShell`) presenta el *dashboard* correspondiente al rol autenticado (`superadmin_dashboard.dart`, `admin_dashboard.dart` vía `AdminHomeRouter`, `docente_dashboard.dart`, `padre_dashboard.dart`), cada uno con sus indicadores propios (`dashboard_stats_grid.dart`).
5. **Ciclo académico**: un docente crea un curso (`curso_form_screen.dart`) → lo estructura en módulos (`modulos_tab.dart`) → publica tareas (`tarea_form_screen.dart`) → un padre/tutor entrega en nombre de su perfil activo (`realizar_entrega_screen.dart`) → el docente califica (`entregas_list_screen.dart`).
6. **Comunicación**: participación en foros por curso (`forum_screen.dart`), con reglas de moderación diferenciadas (docente solo modera mensajes de padres; un padre no puede responder a otro padre).
7. **Notificación**: cualquier evento relevante del backend (nueva tarea, calificación, respuesta de foro, evento próximo) llega como notificación push (FCM, con la app en segundo plano/cerrada) y/o notificación in-app (`notificaciones_screen.dart`).

### 9.2 Servicios y *managers* principales

- **`FcmService`** (`lib/core/notifications/fcm_service.dart`): registro de canal de notificaciones de Android, solicitud de token de dispositivo, registro/actualización del token en el backend (`PUT /users/me/fcm-token`), presentación de notificaciones en primer plano (`flutter_local_notifications`), y desregistro al cerrar sesión. Diseño **totalmente *best-effort***: cualquier fallo (Firebase no configurado, permiso denegado) se degrada en silencio sin afectar el resto de la aplicación.
- **`notification_permission_service.dart`**: solicitud del permiso nativo de notificaciones (Android 13+) una única vez por instalación, con bandera persistida en `shared_preferences`.
- **`ThemeModeController`** (Riverpod `Notifier`): gestión y persistencia local de la preferencia de tema (claro/oscuro/sistema), con sincronización *best-effort* hacia el backend (`updateModoOscuro`) cuando el modo no es "sistema".
- **`ConnectivityBanner`**: envoltorio global de la aplicación que muestra un aviso visual ante pérdida de conectividad (`connectivity_plus`).
- **No se usa `WorkManager`** ni ningún mecanismo de tareas en segundo plano programadas (no aplica/no encontrado): la única ejecución en segundo plano es el *handler* de mensajes FCM exigido por `firebase_messaging`, que no ejecuta lógica de negocio adicional (Android renderiza la notificación de forma nativa a partir del payload).

### 9.3 Módulos/pantallas principales

| Módulo (`lib/features/`)  | Función                                                                               |
| ---------------------------- | -------------------------------------------------------------------------------------- |
| `auth`                     | Login, recuperación de contraseña, asistente de primer ingreso, gestión de sesiones |
| `dashboard`                | Paneles de indicadores por rol                                                         |
| `instituciones`            | Alta y gestión de instituciones                                                       |
| `usuarios`                 | Gestión de usuarios del sistema                                                       |
| `docentes`                 | Alta y gestión de docentes                                                            |
| `cursos`                   | Gestión de cursos, módulos y participantes                                           |
| `tareas`                   | Publicación y gestión de tareas/"retos"                                              |
| `entregas`                 | Realización y calificación de entregas                                               |
| `foros`                    | Foros de discusión por curso y su panel de analíticas                                |
| `calendario` / `eventos` | Calendario consolidado y gestión de eventos institucionales                           |
| `perfiles`                 | Gestión de perfiles familiares                                                        |
| `notificaciones`           | Notificaciones in-app                                                                  |
| `buzon`                    | Buzón de contacto público y su bandeja administrativa                                |
| `perfil`                   | Perfil propio del usuario y preferencias                                               |
| `home`                     | Landing pública informativa (solo Web)                                                |

---

## 10. Algoritmos o lógica central

No se identificaron algoritmos de inteligencia artificial, aprendizaje automático o *scoring* predictivo en el repositorio (**no implementado**).

La lógica de negocio no trivial identificada es de agregación/derivación de datos en el cliente, no de modelos de IA:

- **Agregador de calendario** (`lib/features/calendario/data/calendario_aggregator.dart`): combina las entradas de calendario (`items`) devueltas por el endpoint `GET /calendario/...` en una estructura unificada de eventos por día para su presentación en `calendario_screen.dart`. No implementa un modelo predictivo, es una transformación determinista de datos ya resueltos por el backend.
- **Panel de analíticas de foro** (`ForoDashboardScreen`): renderiza un gráfico de barras de actividad de los últimos 7 días dibujado manualmente con widgets Flutter (sin librería de *charts* de terceros), a partir de estadísticas ya calculadas en el backend (`GET /foros/:id/dashboard`) — no hay cómputo estadístico adicional en el cliente más allá de la representación visual.
- **Reglas de negocio replicadas en cliente** (para UX, no como fuente de autoridad): p. ej. `Tarea.vencida` (fecha de entrega pasada y estado `publicada`), o la matriz de permisos por rol que determina qué acciones se muestran en cada pantalla — el backend es siempre la autoridad final de estas reglas.

---

## 11. Mecanismos de seguridad

- **Sesión y credenciales**: la sesión se maneja íntegramente por **cookies httpOnly** (`access_token`/`refresh_token` con rotación), gestionadas por el backend; el cliente Flutter nunca lee ni decodifica el contenido del token — solo persiste el archivo de cookies mediante `PersistCookieJar` (`cookie_jar` + `path_provider`), en el almacenamiento privado de la aplicación (*sandbox* de Android, no accesible a otras apps sin *root*). **No se usa `EncryptedSharedPreferences` ni Android Keystore** de forma explícita para las credenciales, dado que no hay credenciales de larga duración que la app deba cifrar por sí misma (la cookie httpOnly no es legible ni siquiera por el propio código Dart/JS).
- **Certificate pinning**: **no implementado** — no se encontró configuración de *pinning* de certificados TLS en `api_client.dart` ni en el manifiesto de red (`network_security_config.xml` no presente en el repositorio).
- **Ofuscación/minificación (ProGuard/R8)**: **no configurado explícitamente**. No se encontró `proguard-rules.pro` personalizado ni las propiedades `minifyEnabled`/`isMinifyEnabled`/`shrinkResources` en `android/app/build.gradle.kts`; el *build type* `release` solo define la configuración de firma (ver abajo), heredando el comportamiento por defecto del Android Gradle Plugin/Flutter Gradle Plugin.
- **Permisos sensibles y solicitud en tiempo de ejecución**:
  - `POST_NOTIFICATIONS` (Android 13+): solicitado explícitamente en tiempo de ejecución vía `permission_handler` (`Permission.notification.request()`), una única vez por instalación (`notification_permission_service.dart`).
  - `INTERNET`: permiso normal, no requiere solicitud en tiempo de ejecución.
  - Acceso a cámara/galería y almacenamiento para adjuntos: delegado a los *plugins* `image_picker`/`file_picker`, que gestionan sus propios diálogos de permiso del sistema operativo bajo demanda, sin permisos declarados de forma adicional en el manifiesto propio de la aplicación.
- **Firma de la aplicación**: configuración condicional en `android/app/build.gradle.kts` — si existe `android/key.properties` (presente en este repositorio, no versionado en control de código fuente por política del proyecto) y el *keystore* real `android/app/upload-keystore.jks`, el *build type* `release` firma con esas credenciales reales; en su ausencia, cae de vuelta a la firma de depuración (`debug`) para no romper compilaciones locales sin esos secretos.
- **Manejo de secretos de Firebase**: `google-services.json` (proyecto Firebase real `edumon-ae180`) está presente en el repositorio; el plugin de Google Services solo se aplica condicionalmente si ese archivo existe, permitiendo que el proyecto compile igualmente en un entorno sin ese archivo (sin notificaciones push).

---

## 12. Estándares y convenciones

- **Guía de estilo**: reglas de análisis estático de `package:flutter_lints` (versión 6.0.0), configuradas en `analysis_options.yaml`, sin reglas adicionales de `ktlint`/`detekt` (no aplican — no es un proyecto Kotlin/Java nativo).
- **Estructura de paquetes real** (por *feature*, no por capa transversal): ver §6 y §9.3. Módulos transversales agrupados en `lib/core/` (`theme`, `design_system`, `router`, `network`, `security`, `notifications`, `config`, `utils`).
- **Convención de nombres de recursos**: recursos gráficos como SVG bajo `assets/img/` con subcarpetas explícitas (`logo/`, `circulos/`, `recursos/`) — cada subcarpeta debe declararse individualmente en `pubspec.yaml` (la declaración de una carpeta en Flutter no es recursiva). Fuentes bajo `assets/fonts/`.
- **Sistema de diseño propio** (`lib/core/design_system/`, `lib/core/theme/`): tokens centralizados de color (`app_colors.dart`), tipografía (`app_typography.dart`, Fredoka + Poppins vía `google_fonts`), tema completo (`app_theme.dart`) y componentes reutilizables (`EdumonButton`, `EdumonTextField`, `EdumonCard`, `EdumonAvatar`, `EdumonDialog`), en lugar de estilos/colores embebidos por pantalla.
- **Convención de commits/ramas**: ramas descriptivas a partir de `main` (`feature/...`, `fix/...`); mensajes de commit en español describiendo el cambio (ver historial de Git).

---

## 13. Despliegue y configuración

### 13.1 Estructura de carpetas real

```
edumon_movil/
├── android/                # Proyecto de plataforma Android (Gradle)
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json
│   │   ├── upload-keystore.jks
│   │   └── src/main/AndroidManifest.xml
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── gradle.properties
│   ├── key.properties        # No versionado en git (secreto de firma)
│   └── local.properties      # No versionado en git (rutas locales de SDK)
├── ios/                     # Proyecto de plataforma iOS
├── web/                     # Punto de entrada Web
├── lib/
│   ├── core/                # Transversal: theme, design_system, router, network, security, notifications, config, utils
│   ├── features/            # Un folder por dominio funcional (data/domain/presentation)
│   ├── shared/models/        # Modelos compartidos entre features (ej. Archivo)
│   ├── app.dart
│   └── main.dart
├── assets/                  # Fuentes e imágenes (SVG) de marca
├── test/                    # Pruebas (flutter test)
├── docs/flutter-migration/BLUEPRINT.md   # Especificación técnica pantalla-por-pantalla
├── pubspec.yaml / pubspec.lock
└── README.md
```

No es un proyecto multi-módulo (un único módulo `:app` en `android/settings.gradle.kts`); la modularización real ocurre a nivel de *feature* dentro de `lib/`, no de módulos de Gradle independientes.

### 13.2 Pasos de build y ejecución local

```bash
flutter pub get                 # Resolver dependencias Dart
flutter run                     # Ejecutar en un dispositivo/emulador conectado
flutter run -d chrome            # Ejecutar en navegador (Web)
flutter test                     # Ejecutar la suite de pruebas
flutter analyze                  # Análisis estático (lints)
flutter build apk --release      # Generar APK de release para Android
flutter build appbundle          # Generar Android App Bundle (.aab) para Play Store
dart run flutter_launcher_icons  # Regenerar íconos de la app tras cambiar el logo
```

**Nota de entorno particular de este equipo de desarrollo**: si el repositorio reside dentro de una carpeta sincronizada por OneDrive en Windows, los *builds* de Gradle pueden fallar por interferencia del sincronizador de archivos; la mitigación documentada en el `README.md` es redirigir la carpeta `build/` a una ubicación fuera de OneDrive mediante un *junction* de Windows.

### 13.3 Firma de la aplicación y *build types*

- **Firma**: condicional sobre la existencia de `android/key.properties` (propiedades `storeFile`, `storePassword`, `keyAlias`, `keyPassword`) y el archivo *keystore* `android/app/upload-keystore.jks`. Con ambos presentes, el `buildType` `release` firma con la clave real de distribución; en su ausencia, firma con la clave de depuración de Android (fallback no destructivo).
- **Flavors**: **no implementados** — no se encontraron `productFlavors` en `build.gradle.kts`. Un único `applicationId` (`com.edumon.movil`) para todos los entornos; el entorno de backend se selecciona en tiempo de compilación vía `--dart-define=API_BASE_URL=...`, no vía *flavor*.
- **Build types**: los dos *build types* estándar de Android (`debug`, `release`), sin *build type* adicional (`staging`/`profile` no configurados fuera de los que provee el propio *Flutter Gradle Plugin*).

### 13.4 Variables de entorno / archivos de configuración sensibles

| Nombre                               | Obligatorio                                     | Descripción                                                                                                                                   |
| ------------------------------------ | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `API_BASE_URL` (`--dart-define`) | No (tiene*default*)                           | URL base del backend. Por defecto:`https://backend-edumon.onrender.com/api`                                                                  |
| `android/key.properties`           | No (fallback a firma debug)                     | Credenciales de firma de release (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). No versionado en control de código fuente |
| `android/app/upload-keystore.jks`  | No (fallback a firma debug)                     | *Keystore* real de firma de distribución. No versionado en control de código fuente                                                        |
| `android/app/google-services.json` | No (Firebase se degrada*best-effort* sin él) | Configuración del proyecto Firebase real (`edumon-ae180`) para notificaciones push (FCM)                                                    |
| `android/local.properties`         | Sí (generado por el IDE/Flutter)               | Ruta local del SDK de Android y del SDK de Flutter en la máquina de desarrollo. No versionado                                                 |

### 13.5 Proceso de publicación

**No implementado / no verificado en el repositorio**: no se encontró evidencia de configuración de *Google Play Console* (sin archivos de metadatos de *listing*, sin *fastlane*, sin *pipeline* de CI/CD de publicación) dentro de este repositorio. La aplicación cuenta con un *keystore* de distribución real (`upload-keystore.jks`) consistente con el flujo de firma de subida (*upload key*) que exige Play App Signing, lo que indica una intención de publicación en Google Play, pero el proceso de *internal testing* / *closed/open testing* / producción no está documentado ni automatizado en este repositorio y debe verificarse directamente en la consola de Google Play asociada al proyecto.

---

*Fin del documento.*
