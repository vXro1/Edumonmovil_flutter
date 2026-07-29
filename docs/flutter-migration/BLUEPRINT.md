# EDUMON — Blueprint técnico de migración a Flutter (Android)

**Versión**: 1.0 · **Fecha**: 2026-07-09 · **Fuente**: ingeniería inversa completa de `EDUMON WEB` (React 19 + Vite + Tailwind v4), rama `refactor/design-system`.

**Equipo autor**: Software Architect Senior · Senior Flutter Developer · Senior UI/UX Designer · Product Manager · Mobile Application Architect · Clean Architecture Expert · Material Design 3 Specialist · Firebase & REST API Expert.

**Cómo leer este documento**: está organizado en 16 capítulos que corresponden 1:1 a un LMS (Learning Management System) educativo multi-tenant, multi-rol. Cada capítulo es autocontenido y referencia el código fuente real de la web (rutas, componentes, servicios) para que el equipo Flutter no dependa de volver a leer el frontend original. Todos los hallazgos de deuda técnica, código muerto y bugs del sistema actual están marcados explícitamente con **⚠️** para decidir si se replican, se corrigen o se descartan en la nueva app.

> **Estado de este documento**: FASES 1-16 completas.

---

## Índice

1. Análisis general del sistema
2. Análisis de diseño UI/UX
3. Análisis completo de cada pantalla
4. Mapa de navegación
5. Arquitectura Flutter
6. Componentes reutilizables
7. Análisis responsive
8. Estados de la aplicación
9. Modelos de datos
10. Endpoints necesarios *(pendiente)*
11. Seguridad *(pendiente)*
12. Animaciones *(pendiente)*
13. Optimización *(pendiente)*
14. Plan de desarrollo *(pendiente)*
15. Librerías Flutter *(pendiente)*
16. Checklist final *(pendiente)*

---

## FASE 1 — Análisis general del sistema

### 1.1 Objetivo de la plataforma

EDUMON es un **LMS (Learning Management System) educativo multi-tenant** dirigido a instituciones escolares (colegios). Conecta a cuatro tipos de actores alrededor de un curso: **super-administrador** (dueño de la plataforma, gestiona instituciones), **administrador de institución** (gestiona su colegio: docentes, cursos, usuarios), **docente** (crea cursos, módulos, tareas/"retos", foros, califica entregas) y **padre/tutor** (consume contenido y **entrega tareas en nombre de su hijo**). Existe un quinto rol, `estudiante`, contemplado en el modelo de permisos pero **sin flujo de login propio activo** — hoy el estudiante es representado por su padre/tutor en el sistema.

### 1.2 Tipo de aplicación

SPA (Single Page Application) de gestión académica — **no es una app de contenido de consumo pasivo**, es una herramienta operativa de trabajo diario (backoffice + portal educativo), con estética "gamificada" (paleta vibrante, componentes estilo Duolingo) pero funcionalidad de **panel de administración educativo real** (CRUD de cursos, calificación de entregas, mensajería, calendario institucional).

### 1.3 Público objetivo

- **Super-administradores**: operadores de la plataforma SaaS, gestionan altas de colegios clientes.
- **Administradores de institución**: personal directivo/administrativo de un colegio.
- **Docentes**: profesores que imparten cursos y califican.
- **Padres/tutores**: usuarios finales masivos, probablemente el perfil con menor alfabetización digital — la app debe priorizar simplicidad extrema para este rol (de ahí el estilo "Duolingo" 3D/gamificado, pensado para reducir fricción).

### 1.4 Casos de uso principales

1. Un colegio se da de alta (superadmin crea institución + admin inicial).
2. El admin de institución registra docentes (individual o CSV masivo) y crea cursos asignándolos a un docente.
3. El docente estructura el curso en **módulos**, publica **tareas ("retos")** con archivos/instrucciones, asignadas a todos o a un subconjunto de participantes.
4. El padre/tutor **entrega** la tarea (texto y/o archivos) en nombre de su hijo; el docente **califica con 1-5 estrellas + comentario**.
5. Docentes y padres interactúan en **foros** por curso (mensajería tipo chat con hilos, likes y adjuntos).
6. Se gestiona un **calendario institucional** (eventos, tareas) por curso y agregado por usuario.
7. Notificaciones in-app y (parcialmente implementado) push vía FCM.
8. Un padre puede gestionar **múltiples perfiles familiares** (varios hijos) bajo una sola cuenta, cambiando de "perfil activo" sin cerrar sesión completa.

### 1.5 Funcionalidades principales (inventario)

| Dominio | Capacidad |
|---|---|
| Autenticación | Login por teléfono+contraseña, recuperación de contraseña (correo o WhatsApp/SMS), gestión de sesiones activas, cambio de contraseña obligatorio en primer login (parcialmente roto hoy, ver §3) |
| Multi-tenant | Instituciones como entidad de primer nivel, cada una con su propio admin/docentes/cursos/usuarios |
| Cursos | CRUD de cursos, portada, participantes, módulos, importación CSV de participantes/módulos |
| Tareas ("Retos") | CRUD, asignación total/parcial, adjuntos, tipos de entrega, cierre |
| Entregas | Ciclo de vida borrador→enviada→calificada, calificación 1-5 estrellas + comentario |
| Foros | Foros por curso, hilos de mensajes, likes, adjuntos multimedia, roles con colores |
| Calendario | Vista mensual agregada (todos los cursos) y por curso, eventos con categoría |
| Eventos | CRUD completo con imagen de portada, adjunto, asociación a cursos |
| Notificaciones | In-app con conteo de no leídas, push FCM (dormido/no activado hoy) |
| Buzón | Bandeja de contacto público (landing) gestionada por superadmin |
| Perfiles familiares | Multi-perfil por cuenta padre, selección de perfil activo con reemplazo de token |
| Usuarios | CRUD con roles, suspensión/activación (soft delete), import CSV de docentes |
| Perfil propio | Edición de datos, avatar, cambio de contraseña, secciones específicas por rol |

### 1.6 Flujo general de navegación (alto nivel)

```
Landing pública ──► Login ──► Home según rol
                                 ├─ superadmin → /admin (gestión instituciones/usuarios)
                                 ├─ administrador → /admin (gestión institución/docentes/cursos)
                                 ├─ docente → /docente (mis cursos/retos/foros/calendario)
                                 └─ padre/tutor → /padre (cursos hijos/retos/entregas/foros)
```

### 1.7 Arquitectura del frontend actual (referencia)

- **Stack**: React 19.1 + Vite 7 + React Router DOM v7 + Zustand 5 (un solo store) + TanStack Query v5 (adopción parcial) + Firebase 12 (solo FCM, no inicializado) + Tailwind CSS v4 + `jwt-decode`.
- **Patrón**: Feature-first (`src/features/<dominio>/{pages,components,services,hooks,context}`) + capa `services/core` compartida (cliente HTTP, interceptores, gestor de sesión). Es el patrón que se recomienda **replicar conceptualmente** en Flutter (Clean Architecture + Feature-First, ver FASE 5).
- **Autenticación**: JWT Bearer simple sin refresh token, almacenado en `localStorage`, expiración controlada 100% client-side + timeout de inactividad de 30 min.
- **Autorización**: matriz de permisos por rol evaluada en el cliente (`roleMatrix.js`) — **solo para UI**, debe asumirse que el backend también valida (o debería).

### 1.8 Experiencia de usuario

Estilo dual: **Claymorfismo/Soft-UI** (sombras apiladas con reflejo interior) para tarjetas y contenedores de dashboard, y **"Duolingo 3D-press"** (sombra inferior sólida que se "hunde" al presionar) para botones, inputs y badges. Paleta vibrante de marca (morado `#8C38F0` como primario) con acentos temáticos por sección (cada módulo del sidebar tiene su propio color). Prioriza feedback inmediato, mensajes en español coloquial ("Retos" en vez de "Tareas"), y formularios con validación en tiempo real con mensajes claros.

### 1.9 Complejidad del sistema

**Alta.** ~14 features de negocio, 2 taxonomías de rol que conviven, navegación por tabs vía query param, sistema de permisos granular de 23 permisos, ciclo de vida de entidades con estados derivados en cliente (tareas "vencidas", por ejemplo), y una feature de "perfiles familiares" con lógica de sesión no trivial (cambio de token sin logout). Se detectó **deuda técnica significativa**: código muerto (guards, tabs, modales duplicados), features a medio conectar (FCM, primer-login), e inconsistencias de contrato API (`valoracion` vs `nota`) — documentadas explícitamente en cada capítulo para que el equipo Flutter decida conscientemente qué heredar y qué corregir.

---

## FASE 2 — Análisis de diseño UI/UX

### 2.1 Estilo visual

**Híbrido deliberado de dos lenguajes**:
1. **Claymorfismo / Soft-UI** — para `Card`, `.curso-card`, stat cards del dashboard: sombras apiladas (`0 Npx Mpx rgba(0,0,0,.08-.12)`) + reflejo interior superior (`inset 0 1px 0 rgba(255,255,255,.8-.9)`) que simula un relieve suave.
2. **"Duolingo 3D-press"** — para `Button`, `Input`, `Badge`, `Toggle`: borde grueso (2-2.5px), sombra inferior **sólida** de color (no difusa) que actúa como "base 3D" y se "hunde" (offset 0 + `translateY`) al presionar.

Es también **Card-based**, **Mobile-first** en sus breakpoints (aunque el producto original es web/desktop-first en jerarquía visual del dashboard), con **Dashboard** como patrón dominante de home, y un **Design System propio** con tokens CSS custom properties (no Material Design ni un framework de terceros) — el mapeo a Flutter debe ser un **ThemeData de Material 3 fuertemente personalizado**, no un M3 "de fábrica".

### 2.2 Paleta de colores

**Colores de marca (raw)**

| Token | Hex | Uso |
|---|---|---|
| `edu-purple` | `#8C38F0` | Primario |
| `edu-pink` | `#F23D7F` | Secundario |
| `edu-cyan` | `#05C7F2` | Acento / Info |
| `edu-green` | `#41D958` | Éxito |
| `edu-yellow` | `#FCBD00` | Advertencia / XP-gamificación |
| `edu-cream` | `#FCF7ED` | Fondo suave |
| `edu-dark` | `#0D0D0D` | Texto principal / sidebar oscuro |
| `edu-white` | `#FFFFFF` | Fondo / superficie |

**Escalas de color (50→900)**

| Escala | 50 | 100 | 200 | 300 | 400 | 500 (base) | 600 | 700 | 800 | 900 |
|---|---|---|---|---|---|---|---|---|---|---|
| Purple | `#F7F0FE` | `#EDD9FC` | `#D4ADF9` | `#B87AF5` | `#A057F2` | `#8C38F0` | `#7826D8` | `#621BB8` | `#4D1392` | `#360B6B` |
| Pink | `#FEF0F5` | `#FDD9E9` | `#FAA8CC` | `#F675AF` | `#F45194` | `#F23D7F` | `#D42B68` | `#B01B52` | — | — |
| Cyan | `#F0FBFE` | `#D4F4FD` | `#A0E8FB` | `#5DD7F8` | `#25CEF5` | `#05C7F2` | `#04AED6` | `#0392B4` | — | — |
| Green | `#F0FDF4` | `#D5F7DC` | `#A7EEB5` | `#71E287` | `#55DC6D` | `#41D958` | `#2FBD45` | `#229D35` | — | — |
| Yellow | `#FFFBEB` | `#FEF5C7` | `#FDE88A` | `#FDD64D` | `#FCC925` | `#FCBD00` | `#DFA300` | `#B88600` | — | — |
| Neutral | `#FAFAFA`(50) | `#F5F5F5`(100) | `#E8E8E8`(200) | `#D4D4D4`(300) | `#A3A3A3`(400) | `#737373`(500) | `#525252`(600) | `#404040`(700) | `#262626`(800) | `#171717`(900) |

Neutral incluye además `0`=`#FFFFFF` y `150`=`#EFEFEF`.

**Tokens semánticos**

| Rol | Base | Hover | Light (bg) |
|---|---|---|---|
| Primary | `#8C38F0` | `#7826D8` | `#F7F0FE` |
| Secondary | `#F23D7F` | `#D42B68` | `#FEF0F5` |
| Accent/Info | `#05C7F2` | `#04AED6` | `#F0FBFE` |
| Success | `#41D958` | `#2FBD45` | `#F0FDF4` |
| Warning | `#FCBD00` | `#DFA300` | `#FFFBEB` |
| Error | `#EF4444` | `#DC2626` | `#FEF2F2` (independiente de la escala de marca) |

**Fondos/Superficies**: `background #FFFFFF`, `bg-soft #FCF7ED` (crema), `bg-muted #FAFAFA`, `surface #FFFFFF`, `surface-2 #FAFAFA`, `surface-3 #F5F5F5`.

**Texto**: primario `#0D0D0D`, muted `#737373`, subtle `#A3A3A3`, inverso `#FFFFFF`.

**Bordes**: normal `#E8E8E8`, fuerte `#D4D4D4`, foco `#A057F2`.

**Sidebar (oscuro)**: `bg #0D0D0D`, texto `rgba(255,255,255,.8)`, activo `#8C38F0`.

**Color por sección**:

| Sección | Color |
|---|---|
| Inicio | `#8C38F0` (morado) |
| Cursos | `#05C7F2` (cian) |
| Tareas/Retos | `#41D958` (verde) |
| Foros | `#F23D7F` (rosa) |
| Calendario | `#FCBD00` (amarillo) |

**⚠️ Inconsistencias detectadas a resolver antes de portar**: `LoadingScreen.jsx` y `CalendarWidget.jsx` usan azules hardcoded (`#0C6AC4`, `#1D4ED8`, `#2196F3`) ajenos a la paleta `edu-*`. Recomendación: unificar a `edu-purple`/`edu-cyan` en Flutter, no portar el azul suelto.

### 2.3 Tipografía

- **Cuerpo de texto**: **Inter** (variable, 100-900, incluye itálica).
- **Encabezados/Display**: **Poppins** (400/500/600/700/800).
- Fallback system: `system-ui, -apple-system, "Segoe UI", sans-serif`.
- **En Flutter**: usar `google_fonts` o assets locales con `Inter` (cuerpo) y `Poppins` (headings), pesos 400/500/600/700/800.

**Escala de tamaños**:

| Token | px | Uso sugerido M3 |
|---|---|---|
| `2xs` | 10 | overline/labelSmall |
| `xs` | 12 | labelMedium |
| `sm` | 14 | bodySmall |
| `base/md` | 16 | bodyMedium |
| `lg` | 18 | bodyLarge |
| `xl` | 20 | titleLarge |
| `2xl` | 24 | headlineSmall |
| `3xl` | 30 | headlineMedium |
| `4xl` | 36 | headlineLarge |
| `5xl` | 48 | displaySmall |
| `6xl` | 60 | displayMedium |
| `7xl` | 72 | displayLarge |

**Pesos**: 100(thin)…900(black), uso principal 400/500/600/700/800. **Line-heights**: tight 1.15, snug 1.3, normal 1.5, relaxed 1.65. **Letter-spacing**: de `-0.045em` a `0.12em`.

### 2.4 Espaciados

Escala base 4px: `1(4px) 2(8px) 3(12px) 4(16px) 5(20px) 6(24px) 7(28px) 8(32px) 10(40px) 12(48px) 14(56px) 16(64px) 20(80px) 24(96px) 32(128px)`.

### 2.5 Border-radius

| Token | px | Uso |
|---|---|---|
| xs | 4 | chips pequeños |
| sm | 8 | inputs compactos, iconButtons |
| md | 12 | inputs, botones pequeños |
| lg | 16 | botones estándar, inputs Duolingo |
| xl | 24 | Cards |
| 2xl | 32 | Cards grandes, banners |
| 3xl | 40 | Heros |
| full | 9999 | pills, avatares, badges |

### 2.6 Sombras y elevaciones

**Genéricas**: `xs 0 1px 2px/.05` → `2xl 0 40px 80px/.18` (6 niveles).
**De marca**: brand/primary/secondary/accent/success — sombra difusa tintada (`0 4px 16-20px rgba(color, .22-.30)`).
**De componente**: `card`, `card-hover`, `modal`, `dropdown`.
**Botones 3D**: `btn-primary 0 5px 0 #621BB8`, `btn-success 0 5px 0 #229D35`, `btn-danger 0 5px 0 #B91C1C`, `btn-warning 0 5px 0 #B88600` — en Flutter: `Container` con `List<BoxShadow>` fija (sin blur, offset vertical puro), animar `translateY` + reducir sombra a 0 en press.
**Claymorfismo**: simular `inset` con `Container` decorado + `Positioned` con gradiente translúcido, o `flutter_inset_box_shadow`.

### 2.7 Iconografía

**Lucide** (`lucide-react`, 59 archivos). Flutter: `lucide_icons_flutter` (o `lucide_icons`) para mapeo 1:1, o Material Symbols Outlined con stroke-width ~1.5-2.5, 24×24.

### 2.8 Animaciones y transiciones

| Patrón | Duración | Curva CSS | Curva Flutter equivalente |
|---|---|---|---|
| Entrada fade+scale | 0.2s | `ease` | `Curves.easeOut` |
| Overshoot/rebote elástico | 0.3-0.55s | `cubic-bezier(0.34,1.56,0.64,1)` | `Cubic(0.34,1.56,0.64,1)` custom |
| Micro hover/press | 90-120ms | `ease` | `Curves.easeInOut` |
| Spinner | 0.7-0.8s | `linear infinite` | `Curves.linear` + loop |
| Shimmer skeleton | 1.4s | `ease-in-out infinite` | `shimmer` package |
| Shake (error) | 0.45s | `cubic-bezier(0.36,.07,.19,.97)` | `Cubic(0.36,0.07,0.19,0.97)` |
| Bottom sheet (modal móvil) | 0.3s | overshoot | `Curves.easeOutBack`/`Cubic` custom |

### 2.9 Microinteracciones destacadas a replicar

- Botones: `translateY(-1px)` en hover, `translateY(+4px)` + sombra a 0 en press.
- Badge de entrada: bounce (scale .6→1.15→.95→1).
- Toggle: pulgar con `cubic-bezier` elástico 250ms.
- Input con error: shake horizontal.
- Input con éxito: check-pop animado.
- Toast: slide-in desde la derecha con leve overshoot, barra de progreso de auto-dismiss.
- Modal en móvil: bottom-sheet con "handle" y overshoot al abrir.

### 2.10 Jerarquía visual, consistencia y grid

- Grids helper: `grid-auto`, `grid-stats` (2→4 cols), `layout-split` (1 col móvil → 1.6-1.7fr/1fr desktop).
- Jerarquía tipográfica: Poppins Bold para títulos, Inter Regular/Medium para cuerpo, Inter SemiBold para labels/badges.
- Z-index: base(0) < navbar/sidebar(10-20) < dropdown(50-150) < modal(100-300) < toast(máximo).

### 2.11 Responsive / breakpoints

Escala oficial: **480 · 768 · 1024 · 1280 · 1440+**. Ver desarrollo completo en FASE 7.

### 2.12 Sistema de componentes / Design tokens

El proyecto tiene un Design System propio y maduro (tokens CSS + `src/components/ui/`), **no usa Material Design ni UI kit de terceros** — 100% custom. Para Flutter: **no adoptar Material 3 "de fábrica"**, construir un `ThemeData` completamente personalizado + `lib/core/design_system/` con widgets base equivalentes a `src/components/ui/*` (ver FASE 6).

**Hallazgo transversal**: dos sistemas de formulario paralelos en CSS (`.input`/Duolingo vs `.form-input`/genérico) — solo el primero está en uso real. Portar únicamente el estilo Duolingo como `InputDecorationTheme`.

---

## FASE 3 — Análisis completo de cada pantalla

> Convención: cada pantalla indica **Rol(es)**, **Ruta web equivalente**, **Objetivo**, **Datos**, **Acciones/CRUD**, **Componentes Flutter recomendados**, **Estados**, **Validaciones/Reglas de negocio**. Las pantallas **[LEGACY — no portar]** son código muerto en la web actual.

### 3.1 Autenticación

#### 3.1.1 Landing pública
- **Rol**: público. **Ruta**: `/`.
- Página de marketing con formulario de contacto que alimenta el Buzón.
- **Recomendación**: no portar 1:1, la app Android debería abrir directo en Login/Splash.

#### 3.1.2 Login
- **Rol**: público. **Ruta**: `/login`.
- Autenticar por teléfono (10 dígitos, prefijo fijo `+57`) + contraseña (mín. 6).
- Banner "sesión expirada" si `?expired=1`; checkbox "Recordarme" (⚠️ sin efecto funcional en la web).
- Acciones: submit login, "¿Olvidaste tu contraseña?", "Volver al inicio".
- Widgets: `TextFormField` prefijo fijo "+57", password con toggle visibility, `ElevatedButton` con loading, `MaterialBanner` dismissible.
- Validaciones: teléfono `^\d{10}$`; password ≥6 caracteres.
- Reglas: `primerInicioSesion:true` → Wizard Primer Login (**⚠️ en la web esta ruta no existe, es un bug — en Flutter SÍ debe implementarse**); si no, redirige a `ROLE_HOME`.
- Estados: loading, error ("Teléfono o contraseña incorrectos"), success (toast + navegación).

#### 3.1.3 Recuperar contraseña
- **Ruta**: `/forgot-password`. Solicitar código por **correo** o **WhatsApp/teléfono** (toggle).
- Validaciones: email regex estándar; teléfono `^\+?\d{7,15}$`.
- Widgets: `SegmentedButton`, `AnimatedSwitcher`.

#### 3.1.4 Reset password / Wizard primer login
- **Ruta**: `/reset-password` (recibe `correo|telefono, method`).
- Código (4-8 dígitos) + nueva contraseña + confirmación. Éxito → botón "Ir a iniciar sesión".
- **Wizard primer login** (3 pasos, **⚠️ hoy desconectado en la web — implementar completo en Flutter**):
  1. Selección de foto (avatares predeterminados o subida propia).
  2. Datos personales (nombre, apellido, correo, nueva contraseña con medidor de fuerza).
  3. Confirmación + redirect automático al home.
  - Widgets: `Stepper`/PageView custom, `LinearProgressIndicator` medidor de fuerza, `PopScope` para bloquear "atrás".

#### 3.1.5 Sesiones activas
- **Ruta**: `/sesiones` (universal). Lista últimas sesiones (dispositivo, IP, ciudad, fechas), paginado de 8.
- Widgets: `ListView.builder` con `SessionCard`, primera fila primera página "ACTUAL" (heurística).
- No hay endpoint de revocar sesión — solo lectura.

### 3.2 Dashboards (Home por rol)

#### 3.2.1 Superadmin Dashboard
- **Ruta**: `/admin` (superadmin). Banner gradiente; 4 stat cards (Instituciones activas, Usuarios totales, Administradores, Docentes registrados); 4 quick actions; **Buzón embebido**; lista de instituciones recientes.
- Widgets: `GridView` de `StatCard`, `ListTile` buzón con `Badge` "Nuevo".

#### 3.2.2 Admin (institución) Dashboard
- **Ruta**: `/admin` (administrador). Banner nombre institución; 4 stat cards (Cursos activos, Docentes asignados, Eventos hoy, Notificaciones nuevas); 4 quick actions; cursos recientes; eventos de hoy.

#### 3.2.3 Docente Home
- **Ruta**: `/docente`. Saludo dinámico por hora; chips resumen; 4 stat cards (Mis cursos, Estudiantes, Retos activos, Eventos hoy); grid `CursoCard`; retos activos; eventos de hoy.
- Acciones rápidas: Crear curso, Nuevo reto, Ver calendario.
- Regla: total estudiantes se calcula sumando participantes en cliente — replicar o pedir agregado al backend.

#### 3.2.4 Padre Home
- **Ruta**: `/padre`. Banner "Padre/Tutor"; 4 stat cards (Cursos activos, Eventos hoy, **Notificaciones y Entregas pendientes son placeholders "—"** ⚠️); grid cursos de hijos; eventos de hoy.
- Vacío: "Aún no hay cursos asignados".

### 3.3 Gestión institucional (superadmin/admin)

#### 3.3.1 Instituciones (superadmin)
- **Ruta**: `/instituciones`. Tabla (Institución, NIT/Código, Contacto, Dirección, Acciones).
- Acciones: buscar (client-side), crear institución + admin inicial en un solo formulario (contraseña inicial = cédula), editar (solo datos institución), ver detalle.
- Widgets: `DataTable`/`ListView` filas expandibles, formulario 2 secciones.

#### 3.3.2 Mi institución (admin, solo lectura)
- **Ruta**: `/institucion`. 4 stat cards (2 hardcoded: Estudiantes "—", Administradores "1" ⚠️), card info institucional, "tu cuenta", "estado del sistema" (Estado/Plan hardcoded "Activo"/"Profesional" ⚠️). Sin edición.

#### 3.3.3 Docentes (admin)
- **Ruta**: `/docentes`. Tabla (avatar+nombre+cédula, correo, teléfono, estado).
- Acciones: búsqueda (debounce 350ms), crear individual, **importar CSV** (drag-drop propio, distinto de `CsvUploadModal` compartido — unificar en Flutter), paginación 15/página.

#### 3.3.4 Usuarios (superadmin/admin)
- **Ruta**: `/usuarios`. Tabla (Usuario+último acceso, Contacto, Cédula, Rol badge color, Estado, Acciones).
- Acciones: crear (rol condicionado, institución obligatoria), editar, ver detalle, **suspender** (soft-delete `usersDelete`), **activar**.
- Reglas: cédula 6-10 dígitos; teléfono exactamente 10 dígitos (sin +57); contraseña inicial `"Cc" + cédula`; mapeo rol UI↔API (`"padre/tutor"` ↔ `"padre"`).
- Errores backend (`err.validationErrors[]`) mapeados campo a campo.

### 3.4 Cursos (LMS core)

#### 3.4.1 Lista de cursos
- **Ruta**: `/cursos` (superadmin, administrador, docente). Tabla (portada+nombre, docente, participantes, estado, acciones).
- CRUD: crear (nombre*, descripción, docente* [si no-docente], imagen portada), editar, **archivar** (soft-delete, sin reactivar en UI), gestionar participantes (agregar individual: nombre/apellido/cédula/teléfono, contraseña=cédula).
- Widgets: `GridView`/`ListView` de `CourseListTile`, `BottomSheet`/`Dialog`, `ImagePicker`.

#### 3.4.2 Hub de curso (contenedor con tabs)
- **Ruta**: `/cursos/:id?tab=...`. 5 tabs por permiso: **Módulos** (siempre), **Tareas**, **Calendario**, **Foros**, **Participantes** (oculto padre).
- Navegación: query param en web; Flutter → `TabBar`/`TabBarView` local.

#### 3.4.3 Tab Módulos
- Lista numerada, título, descripción truncada.
- Acciones (`canManage`=docente/admin): crear/editar (título*, descripción), eliminar, **importar CSV 100% client-side** (sin endpoint masivo — iterar `POST /modulos`).
- Estados: loading skeleton, empty por rol.

#### 3.4.4 Tab Tareas ("Retos")
- Tarjeta por tarea (ícono rojo si vencida), título, fecha entrega, badge módulo.
- Formulario: título*, descripción, módulo (opcional), fecha entrega, **tipo de entrega** (archivo/texto/enlace/multimedia/presencial/grupal), **asignación** (todos/seleccionados — mínimo 1), archivos adjuntos multi, enlaces referencia dinámicos.
- Detalle: badges (Vencida/Activa, Para todos/Seleccionados), participantes asignados, archivos, enlaces. Footer: docente/admin → "Ver entregas"; padre → "Ver mi entrega".
- Regla central: "vencida" calculada en cliente (`fechaEntrega < ahora`).

#### 3.4.5 Sub-tab Entregas
- Docente: todas + stats. Padre: solo la propia.
- Datos: avatar+nombre (oculto padre), preview respuesta, **valoración 1-5 estrellas**, comentario docente, badge estado (borrador/enviada/tarde/calificada).
- Acciones: docente → Calificar/Editar; padre con borrador → Enviar (PATCH); padre sin entrega → Nueva/Realizar.
- Regla: solo una entrega "activa" por tarea vía UI.

#### 3.4.6 Sub-tab Calificar entrega
- `StarPicker` **1-5 estrellas** (sin 0, sin decimales, sin nota 0-100 pese a `puntajeMaximo`), comentario opcional.
- Validación: valoración > 0 requerida. Widget: `flutter_rating_bar`.

#### 3.4.7 Sub-tab Realizar entrega
- Texto respuesta + hasta 5 archivos (imagen/PDF/Word/Excel/PPT).
- Dos acciones: "Guardar borrador" (sin validación mínima) vs "Enviar entrega" (requiere texto O ≥1 archivo; crea borrador y transiciona con segunda llamada).
- **⚠️ Bug web**: callback de éxito no siempre conectado — en Flutter asegurar cierre de diálogo + refresh siempre.

#### 3.4.8 Tab Foros (dentro de curso)
- Tarjetas con ícono (candado si cerrado), título, badge, descripción, conteo mensajes.
- Crear foro (`canCreate`): título 5-200, descripción 10-2000, adjuntos (imagen/video/PDF, máx 5). Regla: foros desde curso siempre `publico:false`.

#### 3.4.9 Tab Participantes
- Oculto para padre. Avatar, nombre, etiqueta/rol, badge "Docente" (no removible).
- Acciones: agregar individual (contraseña=cédula), **importar CSV** (endpoint masivo real `POST /cursos/:id/usuarios-masivo`, parseo server-side — a diferencia de Módulos), eliminar (excepto docente titular).

#### 3.4.10 Tab Calendario (dentro de curso)
- Categorías: `escuela_padres`, `tarea`, `institucional` (default).
- Formulario: título*, descripción, fecha inicio* (fin default = inicio), hora, categoría, ubicación.
- Mismo permiso que Tareas gestiona Calendario del curso.

### 3.5 Calendario global (agregado)

- **Ruta**: `/calendario` (docente/admin/padre). Vista agregada de tareas+eventos de todos los cursos.
- `CalendarWidget` con stats (total tareas, total eventos, vencidas, próximas).
- Acciones (`canManage`=docente/admin): crear (requiere seleccionar curso), editar, eliminar. Padre: solo lectura.
- Widgets: `table_calendar` o custom `GridView` 7 columnas, dots por día (hasta 3 + contador).

### 3.6 Eventos (gestión completa)

- **Ruta**: `/eventos` (docente/admin). CRUD con `FormData` (imagen/adjunto), a diferencia del modal simple JSON del calendario.
- Formulario: título, descripción, fecha inicio/fin, hora, ubicación, categoría, **imagen portada**, **archivo adjunto**, **cursos asociados** (multi-checkbox).
- **⚠️ Nota**: toggle lista/calendario existe en imports pero vista calendario-grid no implementada — decidir si se completa en Flutter.

### 3.7 Familia (rol padre/tutor)

#### 3.7.1 Perfiles familiares
- **Ruta**: `/familia/perfiles`. Gestionar hasta 5 perfiles secundarios + titular, **cambiar perfil activo**.
- Acciones: crear/editar/eliminar (nombre + avatar, 11 avatares locales + backend), **seleccionar perfil activo** (`perfilesSeleccionar` devuelve nuevo JWT sin logout — replicar cuidadosamente), actualizar FCM token por perfil.
- Regla: máx 5 perfiles secundarios; eliminar perfil activo → fallback a titular.

#### 3.7.2 Cursos de mis hijos
- **Ruta**: `/familia/cursos`. Grid con buscador local (nombre/docente).

#### 3.7.3 Retos (solo lectura)
- **Ruta**: `/familia/tareas`. Lista con estado (abierta/cerrada/vencida), filtro, búsqueda, deep-link `?tareaId=`.

#### 3.7.4 Entregas (crear/editar/enviar)
- **Ruta**: `/familia/entregas`. Cards expandibles: estado, rating estrellas + comentario docente, texto respuesta, archivos. `canEdit` solo si no hay entrega o borrador; `canSend` solo si borrador.

#### 3.7.5 Foros (rol padre) **[revisar duplicidad]**
- **Ruta**: `/familia/foros`. **⚠️ Implementación paralela más simple** a la vista canónica — **usar 3.8.3 para TODOS los roles, no replicar esta versión**.

#### 3.7.6 Calendario (rol padre)
- **Ruta**: `/familia/calendario`. **⚠️ Nota**: el sidebar de padre en la web en realidad apunta a `/calendario` — decidir una sola pantalla de calendario para padre en Flutter.

### 3.8 Foros (sistema global)

#### 3.8.2 Detalle de foro **[LEGACY — no portar]**
`ForoDetallePage` (ruta antigua `/foros/:id`) — no portar, usar 3.8.3.

#### 3.8.3 Vista canónica de Foro — **ForumPage** (referencia de diseño)
- **Ruta**: `/curso/:cursoId/foro/:foroId` — todos los roles usan esta misma página.
- Layout 3 columnas (Discord-like): sidebar izq (foros del curso), centro (mensajes+compositor), panel derecho (actividad/stats). Responsive: colapsa sidebar en móvil (overlay), oculta panel actividad en tablet.
- Mensajes con hilos anidados, likes, adjuntos con preview; **polling cada 60s**.
- Acciones: enviar mensaje/respuesta (adjuntos máx 5), like, eliminar propio (o cualquiera si `MANAGE_FORO`, confirmación 2 pasos), editar propio inline, alternar abierto/cerrado (`canManageForum`), crear foro desde sidebar.
- RoleBadge por autor: docente morado, estudiante azul, padre/tutor verde, admin ámbar, superadmin rojo; borde lateral si staff.
- Panel actividad: stats en cliente (mensajes, respuestas, participantes, archivos), participantes únicos (hasta 8 + "+N"), archivos recientes (últimos 8).
- Validación crear foro: título 5-200, descripción 10-2000, contador en vivo.

### 3.9 Buzón (mensajería pública, superadmin/admin)

- **Ruta**: `/buzon`. Mensajes de contacto público (formulario anónimo, no vinculado a usuario).
- Datos: nombre, correo, teléfono, institución (texto libre), mensaje, fecha, leído/no leído.
- Acciones: filtro tabs (Todos/Sin leer/Leídos con contadores), abrir detalle, marcar leído.
- **⚠️ No tiene entrada de menú en la web** — considerar entrada de nav en Flutter.

### 3.10 Notificaciones

- **Ruta**: `/notificaciones` (universal). Badge conteo no leídas ("9+" si >9), lista paginada (15/página), tipo (info/éxito/warning/error/bienvenida), fecha relativa.
- Acciones: filtro tab, marcar individual/todas leídas, eliminar. Leídas con opacidad reducida.

### 3.11 Perfil propio

- **Ruta**: `/perfil` (universal). Avatar grande + cambio, nombre, badge rol, badge estado, correo/teléfono/institución, "miembro desde".
- Sección por rol: padre → "Perfiles de mis hijos" + "Cursos de mis hijos"; docente → "Mis cursos"; estudiante → "Información académica"; admin/superadmin → "Permisos y acceso" (chips).
- Seguridad: modal cambiar contraseña (actual + nueva + confirmar).

### 3.12 Retos/Tareas (vista global de gestión, docente)

- **Ruta**: `/tareas` (docente). Gestión global (creación/cierre/eliminación; calificación en Entregas).
- `TareaCard` con badges estado/tipo asignación, curso, módulo, vencimiento, conteo adjuntos.
- Formulario idéntico a 3.4.4 + selector de curso explícito (carga dinámica módulos/participantes).
- Acción "Cerrar": `confirm()` nativo en web → `AlertDialog` en Flutter.

### 3.13 Entregas — vista de calificación (docente, global)

- **Ruta**: `/tareas/:id/entregas`. 4 stat cards (Total, Enviadas, Tarde, Calificadas), lista expandible por padre.
- Enriquecimiento: fetch adicional deduplicado por padre único (`usersGetById`) — patrón N+1 a evitar si el backend puede poblar la relación.
- **⚠️ Validación calificación 0-100 en esta vista** vs 1-5 estrellas en 3.4.6 — **inconsistencia de UX a resolver/unificar en Flutter**.

---

## FASE 4 — Mapa de navegación

### 4.1 Diagrama completo

```
Splash / Chequeo de sesión
  │
  ├─ Sin token / expirado ──► Landing (opcional en Flutter: ir directo a Login)
  │                              │
  │                              └─ Login
  │                                  ├─ credenciales OK + primerInicioSesion:true
  │                                  │      └─► Wizard Primer Login (3 pasos) ──► Home según rol
  │                                  ├─ credenciales OK normal ──► Home según rol
  │                                  ├─ ¿Olvidaste tu contraseña? ──► Forgot Password
  │                                  │      └─ enviado ──► Reset Password ──► Login
  │                                  └─ Volver al inicio ──► Landing
  │
  └─ Token válido ──► Shell principal (Sidebar/Drawer + AppBar + contenido)
        │
        ├─ HOME (según rol)
        │    ├─ superadmin/administrador → /admin
        │    ├─ docente                  → /docente
        │    └─ padre/tutor              → /padre
        │
        ├─ [superadmin] Instituciones ──► Detalle institución
        ├─ [superadmin] Usuarios ──► Detalle usuario
        ├─ [administrador] Mi institución (solo lectura)
        ├─ [administrador] Docentes ──► CRUD + import CSV
        ├─ [administrador/docente] Cursos ──► Hub de curso
        │         │
        │         └─ Hub de curso (tabs)
        │              ├─ Módulos ──► Detalle módulo
        │              ├─ Tareas ──► Detalle tarea ──► Entregas ──► Calificar / Realizar entrega
        │              ├─ Calendario (del curso)
        │              ├─ Foros ──► Foro (vista canónica, 3 columnas)
        │              └─ Participantes (oculto para padre)
        │
        ├─ [docente] Retos (gestión global) ──► Entregas (calificación global)
        ├─ [docente/admin] Foros (listado por curso, redirige al canónico)
        ├─ [docente/admin] Eventos (CRUD multimedia)
        ├─ [docente/admin/padre] Calendario (agregado, global)
        ├─ [padre] Familia
        │     ├─ Perfiles (cambio de perfil activo)
        │     ├─ Cursos
        │     ├─ Retos (solo lectura)
        │     ├─ Entregas (crear/editar/enviar)
        │     ├─ Foros (usar vista canónica en Flutter)
        │     └─ Calendario
        │
        ├─ Notificaciones (universal)
        ├─ Perfil (universal)
        ├─ Sesiones activas (universal)
        └─ [superadmin/admin] Buzón

Logout (desde cualquier pantalla)
  └─► limpia token/caché ──► Login
```

### 4.2 Tabla de rutas por rol

| Ruta lógica | superadmin | administrador | docente | padre/tutor | En nav |
|---|:---:|:---:|:---:|:---:|---|
| Home | ✔ (/admin) | ✔ (/admin) | ✔ (/docente) | ✔ (/padre) | Sí |
| Instituciones | ✔ | | | | Sí |
| Mi institución | ✔ | ✔ | | | Sí (admin) |
| Usuarios | ✔ | ✔ | | | Sí |
| Docentes | ✔ | ✔ | | | Sí (admin) |
| Cursos (lista) | ✔ | ✔ | ✔ | | Sí |
| Hub de curso | ✔ | ✔ | ✔ | ✔ (vía lista propia) | No |
| Foros (listado) | ✔ | ✔ | ✔ | | Sí (docente) |
| Foro (canónico) | ✔ | ✔ | ✔ | ✔ | No |
| Retos (gestión) | | | ✔ | | Sí ("Retos") |
| Entregas (calificación) | ✔ | ✔ | ✔ | | No |
| Eventos | ✔ | ✔ | ✔ | | No (gap de nav en web) |
| Calendario | ✔ | ✔ | ✔ | ✔ | Sí |
| Familia · Perfiles | | | | ✔ | Sí |
| Familia · Cursos | | | | ✔ | Sí |
| Familia · Retos | | | | ✔ | Sí ("Retos") |
| Familia · Entregas | | | | ✔ | Sí |
| Familia · Foros | | | | ✔ | Sí (usar canónico) |
| Familia · Calendario | | | | ✔ | Sí |
| Perfil | ✔ | ✔ | ✔ | ✔ | Sí (menú avatar) |
| Notificaciones | ✔ | ✔ | ✔ | ✔ | Sí |
| Buzón | ✔ | ✔ | | | No (gap de nav en web) |
| Sesiones | ✔ | ✔ | ✔ | ✔ | No (recomendado añadir en Perfil) |

**Nota rol `estudiante`**: existe en matriz de permisos pero sin home/nav/login propio. Recomendación: mantenerlo como "actor representado por su padre", no construir dashboard de estudiante en v1.

### 4.3 Navegación por tabs dentro del Hub de curso

Web usa query param `?tab=`. Flutter: `TabBarView` con estado local (`PageStorage`/`IndexedStack`); opcionalmente reflejar tab activo en query param con `go_router` si se quiere paridad de deep-linking (menor prioridad que en web).

---

## FASE 5 — Arquitectura Flutter

### 5.1 Enfoque arquitectónico

**Clean Architecture + Feature-First**, tres capas por feature (`data / domain / presentation`), con un `core/` compartido.

- **`domain`**: entidades puras (Dart classes inmutables, sin dependencias de Flutter/HTTP), casos de uso (`UseCase` con método `call()`), interfaces de repositorio (abstract).
- **`data`**: implementación de repositorios, data sources (remoto vía Dio, local vía Hive/SharedPreferences), DTOs/modelos con `fromJson`/`toJson` (via `freezed`+`json_serializable`).
- **`presentation`**: widgets, providers/notifiers de estado (Riverpod), controllers.

### 5.2 Gestión de estado — Riverpod (recomendado)

| Opción | A favor | En contra para este proyecto |
|---|---|---|
| **Riverpod** | Compile-safe, sin `BuildContext` para leer estado, excelente para DI (reemplaza `get_it`), soporta `AsyncNotifier` que mapea 1:1 al patrón `useQuery` de TanStack Query ya usado en la web (foros), testing sencillo, code-gen opcional | Curva de aprendizaje inicial media |
| Bloc/Cubit | Muy explícito, buen boilerplate para equipos grandes con convención estricta | Boilerplate alto para ~14 features y muchos CRUDs repetitivos; manejo de streams (polling foros, invalidación cruzada) más verboso que Riverpod |
| Provider | Simple, liviano | Deprecado en favor de Riverpod por su propio autor; menos herramientas de caché/invalidación |

**Recomendación de mecánica de invalidación**: replicar `queryKeys.js` como `lib/core/network/query_keys.dart` con constantes/funciones para claves de `ref.invalidate`, evitando strings mágicos.

### 5.3 Router — go_router

- Reemplaza React Router v7. Rutas anidadas con `ShellRoute` (equivalente `MainLayout` con `<Outlet/>`), guards vía `redirect`, deep-linking.
- **Guard de autenticación**: `redirect` global en `GoRouter` leyendo `authProvider` (Riverpod) — no autenticado + ruta protegida → `/login`; autenticado + ruta pública → home del rol. Replica `ProtectedRoute`/`PublicOnlyRoute`/`RoleRedirect`, **sin los guards muertos** (`RoleGuard`/`RequireRole`/`RequireAuth` no se portan).
- **Guard de rol por ruta**: cada `GoRoute` protegida valida `allowedRoles.contains(currentRole)` en su `redirect`, cayendo al home del rol si no matchea.

### 5.4 Inyección de dependencias

Riverpod actúa como contenedor de DI (providers de repositorios/datasources), evitando `get_it` salvo convención previa del equipo.

### 5.5 Repository Pattern

Cada dominio expone `XRepository` (interfaz, `domain/repositories/`) y `XRepositoryImpl` (`data/repositories/`) que orquesta: (a) llamada HTTP vía `ApiClient` (Dio), (b) mapeo DTO→Entity, (c) opcionalmente caché local (Hive) para listados frecuentes (replicando `useUserStore` de Zustand).

### 5.6 Estructura de carpetas propuesta

```
lib/
├── main.dart
├── app.dart                          # MaterialApp.router + ThemeData
├── core/
│   ├── config/
│   │   ├── env.dart                  # VITE_API_URL equivalente (--dart-define)
│   │   └── constants.dart
│   ├── theme/
│   │   ├── app_colors.dart           # tokens de la FASE 2
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_shadows.dart
│   │   └── app_theme.dart            # ThemeData(colorScheme, textTheme, ...)
│   ├── design_system/                # equivalente a components/ui/*
│   │   ├── buttons/edumon_button.dart
│   │   ├── inputs/edumon_text_field.dart
│   │   ├── cards/edumon_card.dart
│   │   ├── modals/app_modal.dart
│   │   ├── badges/edumon_badge.dart
│   │   ├── avatar/user_avatar.dart
│   │   ├── toast/edumon_toast.dart
│   │   ├── loading/loading_screen.dart
│   │   ├── calendar/calendar_widget.dart
│   │   └── csv/csv_upload_sheet.dart
│   ├── network/
│   │   ├── api_client.dart           # Dio + interceptors
│   │   ├── auth_interceptor.dart     # bearer token + 401 handling
│   │   ├── query_keys.dart
│   │   └── network_exceptions.dart
│   ├── security/
│   │   ├── role.dart                 # enum UserRole único y canónico
│   │   ├── permissions.dart          # enum Permission + matriz rol→permisos
│   │   └── permission_gate.dart      # widget condicional por permiso
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_guards.dart
│   ├── storage/
│   │   ├── secure_storage.dart       # flutter_secure_storage (token)
│   │   └── local_cache.dart          # Hive boxes (usuarios, etc.)
│   └── utils/
│       ├── date_formatters.dart
│       ├── phone_formatter.dart      # normalización +57
│       └── error_humanizer.dart
├── features/
│   ├── auth/
│   │   ├── data/{models,datasources,repositories}
│   │   ├── domain/{entities,repositories,usecases}
│   │   └── presentation/{screens,widgets,providers}
│   │       screens: login_screen.dart, forgot_password_screen.dart,
│   │                reset_password_screen.dart, first_login_wizard_screen.dart,
│   │                sessions_screen.dart
│   ├── dashboard/
│   │   presentation/screens: superadmin_dashboard.dart, admin_dashboard.dart,
│   │                          docente_dashboard.dart, padre_dashboard.dart
│   ├── instituciones/
│   ├── usuarios/
│   ├── docentes/
│   ├── cursos/
│   │   presentation/screens: cursos_list_screen.dart, curso_hub_screen.dart
│   │   presentation/widgets/tabs: modulos_tab.dart, tareas_tab.dart,
│   │       calendario_tab.dart, foros_tab.dart, participantes_tab.dart
│   ├── tareas/                        # gestión global de retos (docente)
│   ├── entregas/
│   ├── foros/                         # vista canónica (ForumScreen 3 columnas)
│   ├── calendario/                    # agregado global
│   ├── eventos/
│   ├── familia/
│   │   presentation/screens: perfiles_screen.dart, familia_cursos_screen.dart,
│   │       familia_tareas_screen.dart, familia_entregas_screen.dart,
│   │       (foros → reutiliza feature foros canónico)
│   ├── notificaciones/
│   ├── buzon/
│   └── perfil/
├── shared/
│   ├── widgets/                      # EmptyState, Skeleton, StatCard, SectionHeader...
│   └── models/                       # Archivo (adjunto), Pagination, etc.
└── l10n/                             # es_CO como locale principal
```

### 5.7 Mapeo Context/Zustand → Riverpod

| Web | Flutter |
|---|---|
| `AuthContext` (React Context, dos niveles user/full) | `authProvider` (NotifierProvider/AsyncNotifierProvider) — expone `user`, `isAuthenticated`, `login()`, `logout()`, `switchProfile()` |
| `CursoContext` (React Query + Context por curso) | `cursoProvider(cursoId)` (`FutureProvider.family`/`AsyncNotifierProvider.family`) + `cursoPermissionsProvider` derivado |
| `useUserStore` (Zustand + persist) | `userCacheProvider` respaldado por Hive box `users` |
| `SearchContext` (plugin de handlers) | Opcional: `searchProvider` con `Map<String, SearchHandler>`, o `SearchDelegate` por pantalla |
| `ToastContext` | `ScaffoldMessenger` + `showEdumonToast(context, message, type)`, u `overlayProvider` |
| `usePermission`/`roleMatrix.js` | `lib/core/security/permissions.dart` — `hasPermission(Role, Permission)` puro, consumido por `Provider.family` |

---

## FASE 6 — Componentes reutilizables

Inventario 1:1 de `src/components/ui/*` → widget Flutter equivalente:

| Componente web | Widget Flutter | Notas de comportamiento a preservar |
|---|---|---|
| Button (12 variantes) | `EdumonButton` (enum `EdumonButtonVariant`) | Efecto "3D press": `AnimatedContainer` baja translateY y colapsa sombra a 0 en `onTapDown`, restaura en `onTapUp`/`onTapCancel`. Tamaños xs/sm/md/lg/xl. `loading` (spinner + `Semantics(busy: true)`), `leftIcon`/`rightIcon`, `fullWidth` |
| Card (+Badge/Progress/Avatar/StatCard) | `EdumonCard`, `EdumonStatCard`, `ProgressBar` | Borde con gradiente animado en hover no aplica en móvil — usar como estado "seleccionado"/"presionado" |
| Input/Textarea/Select/Toggle/Checkbox/Radio | `EdumonTextField`, `EdumonDropdown`, `EdumonSwitch`, `EdumonCheckbox`, `EdumonRadio` | Estados error (shake+borde rojo), success (check-pop+borde verde), ícono izq/der, password toggle automático |
| Modal/AppModal (compound) | `AppModalSheet` — `showModalBottomSheet` (móvil, handle de arrastre) / `showDialog` (tablet/desktop) según ancho | Focus-trap nativo vía `FocusScope`; back button Android = Escape en web |
| Toast/ToastContext | `EdumonToast` vía `OverlayEntry` o `ScaffoldMessenger.showSnackBar` custom | 4 variantes, máx 5 simultáneos, auto-dismiss, barra de progreso |
| UserAvatar | `UserAvatarWidget` | Color determinístico por hash del nombre (paleta fija 8), borde por rol, dot online/offline |
| Avatar (genérico) | `SimpleAvatar` | src/initials/fallback a logo |
| Badge (+NotifBadge/XpBadge) | `EdumonBadge`, `NotifBadge`, `XpBadge` | Bounce de entrada, sombra inferior por tamaño, variantes semánticas |
| Dropdown (EdumonDropdown) | `EdumonMenuButton` | Navegación por teclado no aplica en móvil; sí header+opciones+danger variant |
| FileUpload (compact/full) | `FileUploadWidget` | Modo compacto (chat/foros) vs completo (`file_picker` + preview) |
| IconActionButton | `IconActionButton` | 32×32, radius 8, hover→pressed |
| LoadingScreen | `LoadingScreenWidget` | Full-screen, spinner doble anillo |
| CalendarWidget | `CalendarWidget` (`table_calendar` o custom) | Grid mensual, dots categoría, modal detalle por día |
| CsvUploadModal | `CsvUploadSheet` | Máquina de estados IDLE→UPLOADING→SUCCESS/ERROR, panel resultado con contadores |
| Footer | No aplica en app nativa | |

### 6.1 Design tokens como código

Crear `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppDurations` (constantes Dart) derivados directamente de la tabla de FASE 2 — única fuente de verdad, evitando "colores mágicos" dispersos.

---

## FASE 7 — Análisis responsive

Web declara: **480 · 768 · 1024 · 1280 · 1440+**. Para Android nativo:

| Clase de dispositivo | Ancho lógico (dp) | Layout |
|---|---|---|
| Teléfono pequeño | < 360dp | 1 columna, Drawer, BottomNavigationBar opcional (4-5 accesos), listas en vez de tablas |
| Teléfono mediano | 360-410dp | Igual, más padding horizontal (16→20dp) |
| Teléfono grande/phablet | 410-480dp | Igual, cards 2 columnas en grids de baja densidad (stat cards 2×2) |
| Tablet 7-8" | 600-840dp (shortestSide) | `NavigationRail`, 2 columnas (`Row` con `Expanded(flex:...)`), modales como `Dialog` centrado |
| Tablet 10"+/plegables desplegados | > 840dp | `NavigationRail` extendido o `NavigationDrawer` fijo, grids 3-4 columnas, Hub de curso con sidebar de foro visible (3 columnas) |
| Plegables (fold) | `MediaQuery`+Hinge/DisplayFeature (`flutter_hinge`/dual_screen) | Evitar contenido bajo el pliegue; `Row` de 2 paneles al desplegar |
| Landscape | cualquier ancho > alto | `NavigationRail` sobre Drawer si ancho lógico ≥600dp en landscape |

Reglas de adaptación clave:
- `grid-stats`: 2 columnas móvil, 4 en ≥1024px → `GridView.count(crossAxisCount: width >= 840 ? 4 : 2)`.
- `layout-split`: 1 columna móvil, split 1.6fr/1fr desde 768px → `LayoutBuilder` + `Row`/`Column` condicional.
- Sidebar: `Drawer` (móvil), `NavigationRail` solo-iconos (tablet), expandido (desktop) — sin modo "collapsed" manual necesario en Android nativo.
- Tamaño táctil mínimo 44dp (WCAG 2.5.8) — regla dura, `minimumSize: Size(44,44)` en `ButtonStyle`.

**Recomendación de implementación**: `lib/core/utils/responsive.dart` con breakpoints constantes (compact <600, medium 600-839, expanded ≥840, alineado a Window Size Classes M3) y `Breakpoint.of(context)`.

---

## FASE 8 — Estados de la aplicación

| Estado | Cuándo ocurre | Tratamiento recomendado |
|---|---|---|
| Loading | Fetch inicial de cualquier pantalla/tab | Skeletons (`shimmer`/`skeletonizer`), nunca spinner de página completa salvo arranque de app |
| Success | Datos cargados | Render normal |
| Error | Fallo de red/servidor | Mensaje humanizado (§11) + botón "Reintentar"; nunca catch silencioso (⚠️ Docente Home traga errores hoy — no replicar, mostrar toast) |
| Empty | Lista vacía tras carga exitosa | `EmptyState` con ícono + mensaje contextual por rol + CTA si aplica |
| Offline | Sin conectividad | Banner persistente ("Sin conexión") vía `connectivity_plus` — mejora real, no existe en la web |
| Unauthorized (401) | Token expirado/inválido | Logout forzado + redirect a Login ("Tu sesión expiró") |
| Forbidden (403/rol incorrecto) | Acceso a ruta sin permiso | Redirect al home del propio rol (opcionalmente snackbar explicativo antes) |
| Maintenance | Backend 503 explícito | Pantalla de mantenimiento simple (mejora, no existe en la web) |
| No Internet/Retry | Timeout de red | `RetryWidget` genérico reutilizable |
| Validación de formulario | Input inválido antes de submit | Inline en tiempo real (error bajo el campo + shake) |
| Guardando/Enviando | Mutación en curso | Deshabilitar botón + spinner inline (nunca bloquear toda la pantalla) |

---

## FASE 9 — Modelos de datos

Basados en los normalizadores reales de la web (`src/lib/normalizers/*`), que revelan el shape verdadero que produce el backend (MongoDB + Cloudinary). Documentados como entidades de dominio Dart (inmutables, `freezed` recomendado) — **(⚠️)** marca inconsistencias de contrato detectadas en el código fuente a confirmar contra el backend real antes de fijar el DTO definitivo.

### 9.1 User

```dart
class User {
  final String id;
  final String nombre;
  final String apellido;
  String get nombreCompleto => '$nombre $apellido';
  final UserRole rol;               // admin|superadmin|docente|padre|estudiante
  final String estado;              // activo|suspendido
  final String? avatarUrl;
  final String? genero;
  final DateTime? fechaNacimiento;
  final String? correo;
  final String cedula;
  final String telefono;
  final String? direccion, ciudad, pais;
  final String? codigoEstudiante, grado;
  final String? institucionId;
  final DateTime? ultimoAcceso;
  final DateTime? fechaRegistro;
  final List<String> permisos;      // solo relevante para admin/superadmin
}
```

### 9.2 Institucion

```dart
class Institucion {
  final String id;
  final String nombre, nit, direccion, telefono, correo;
  final String? adminId;
}
```

### 9.3 Curso

```dart
class Curso {
  final String id, nombre;
  final String? descripcion, codigo;
  final String estado;              // activo|archivado
  final String? imagenUrl;          // alias imagen/fotoPortada/fotoPortadaUrl unificados
  final User? docente;
  final String? docenteId;
  final List<User> participantes;
  final int totalParticipantes;
  final String? categoria, nivel, grado, seccion;
  final DateTime? fechaInicio, fechaFin;
}
```

### 9.4 Modulo

```dart
class Modulo {
  final String id, cursoId, titulo;
  final String? descripcion;
  final int? orden;
}
```

### 9.5 Tarea (Reto)

```dart
class Tarea {
  final String id, titulo;
  final String? descripcion, instrucciones;
  final TareaEstado estado;          // activa|vencida(derivado)|cerrada — backend usa "publicada"→"activa"
  final String prioridad;            // default "media"
  final DateTime? fechaEntrega, fechaPublicacion;
  final String cursoId; final String? cursoNombre;
  final String docenteId; final User? docente;
  final AsignacionTipo asignacionTipo; // todos|seleccionados
  final TipoEntrega tipoEntrega;       // archivo|texto|enlace|multimedia|presencial|grupal
  final bool permiteEntregaTardia, visible;
  final int puntajeMaximo;             // default 100 — (⚠️) no usado en el flujo real de calificación por estrellas
  final List<Archivo> archivos;
  final List<CriterioRubrica> criterios; // (⚠️) sin UI de creación encontrada — posible feature backend-only/incompleta
  final int totalEntregas, totalPendientes, totalCalificadas;
  final String? moduloId;
  final List<String> etiquetas;
}
// Regla de negocio a portar SIEMPRE en el cliente:
// "vencida" = estado == activa && fechaEntrega < DateTime.now()
```

### 9.6 Entrega

```dart
class Entrega {
  final String id, tareaId, padreId;
  final User? padre; final Tarea? tarea;
  final String? textoRespuesta, comentario;
  final EntregaEstado estado;         // borrador|enviada|tarde|calificada
  final List<Archivo> archivos;
  final DateTime? fechaEnvio;
  final Calificacion? calificacion;   // null hasta que se califique
}
class Calificacion {
  final int valoracion;               // 1-5 (⚠️ el service real envía/lee "valoracion"; el normalizer legacy espera "nota" — VERIFICAR contrato backend antes de fijar el DTO)
  final String? comentario;
  final DateTime? fechaCalificacion;
  final User? docente;
}
```

### 9.7 Archivo (adjunto — patrón compartido tarea/entrega/foro/evento)

```dart
class Archivo {
  final String id;               // alias publicId
  final String url;              // Cloudinary secure_url
  final String nombre;           // alias nombreOriginal/original_filename
  final String? publicId;        // Cloudinary public_id
  final String? tipo;            // mimetype
  final int? tamanoBytes;        // bytes
}
```

### 9.8 Foro

```dart
class Foro {
  final String id, titulo;
  final String? descripcion, categoria;
  final String estado;          // activo|cerrado
  final String cursoId; final String? creadorId;
  final int totalMensajes;
  final bool publico, fijado, cerrado;
}
```

### 9.9 MensajeForo

```dart
class MensajeForo {
  final String id, foroId, contenido;
  final User? autor; final String? autorId;
  final DateTime fecha;
  final int totalLikes; final bool yaLeDioLike;
  final List<Archivo> archivos;
  final String? respuestaA;          // id del mensaje padre (hilo)
  final List<MensajeForo> respuestas;
  final bool editado, fijado;
}
```

### 9.10 Evento

```dart
class Evento {
  final String id, titulo;
  final String? descripcion;
  final DateTime fechaInicio; final DateTime? fechaFin;
  final String? hora, ubicacion;
  final EventoCategoria categoria;   // escuela_padres|tarea|institucional (+institucional variantes en EventosPage: reunion/actividad/otro)
  final List<String> cursosIds;
  final Archivo? imagenPortada, adjunto;
}
```

### 9.11 Notificacion

```dart
class Notificacion {
  final String id, titulo, mensaje;
  final NotificacionTipo tipo;   // info|exito|warning|error|bienvenida
  final bool leida;
  final DateTime createdAt;
}
```

### 9.12 MensajeBuzon

```dart
class MensajeBuzon {
  final String id, nombre, correo, mensaje;
  final String? telefono, institucion;
  final bool leido;
  final DateTime createdAt;
}
```

### 9.13 Perfil (familia)

```dart
class Perfil {
  final String id, nombre;
  final String? avatarUrl;
  final bool esTitular;
  final bool esActivo;
}
```

### 9.14 Sesion (dispositivo)

```dart
class SesionDispositivo {
  final String ip, userAgent;
  final DateTime fechaInicio, ultimaActividad;
  final String? pais, ciudad;
}
```

### 9.15 Relaciones entre entidades

```
Institucion 1───N User (admin/docente/padre pertenecen a una institución)
User (docente) 1───N Curso
Curso 1───N Modulo
Curso N───N User (participantes, vía tabla puente con "etiqueta": docente|padre)
Modulo 1───N Tarea (opcional, una tarea puede no tener módulo)
Curso 1───N Tarea
Tarea 1───N Entrega
User (padre) 1───N Entrega
Entrega 1───1 Calificacion (opcional)
Curso 1───N Foro
Foro 1───N MensajeForo (con auto-referencia para hilos: respuestaA)
User 1───N MensajeForo (autor)
Curso N───N Evento (cursosIds)
User (padre) 1───N Perfil (perfiles familiares)
User 1───N Notificacion
User 1───N SesionDispositivo
```

---

## FASE 10 — Endpoints necesarios

**Base URL real**: `https://backend-edumon.onrender.com/api` (producción, Render) — confirmar con backend si Flutter apuntará al mismo servicio o a uno propio. Prefijo `/api` en todos los paths listados abajo (omitido por brevedad). Todas las respuestas son JSON; las mutaciones con archivos usan `multipart/form-data`.

### 10.1 Auth

| Método | Endpoint | Body | Response | Errores |
|---|---|---|---|---|
| POST | `/auth/login` | `{telefono, contraseña}` | `{token, user, primerInicioSesion?}` | 401 credenciales inválidas |
| POST | `/auth/register` | libre | — | — |
| GET | `/auth/profile` | — (Bearer) | `{user}` | 401 |
| POST | `/auth/change-password` | `{contrasenaActual, contrasenaNueva}` | — | 400 |
| POST | `/auth/logout` | — | — | (best-effort) |
| POST | `/auth/forgot-password` | `{correo}` | — | 404 correo no existe |
| POST | `/auth/reset-password` | `{correo, codigo, contrasenaNueva}` | — | 400 código inválido |
| POST | `/auth/forgot-password-phone` | `{telefono}` | — | — |
| POST | `/auth/reset-password-phone` | `{telefono, codigo, contraseñaNueva}` | — | 400 |
| POST | `/auth/completar-registro` | libre | — | (no consumido hoy en UI) |

### 10.2 Usuarios

| Método | Endpoint | Body/Params |
|---|---|---|
| POST | `/users` | `{nombre,apellido,cedula,correo,rol,contraseña,telefono?,institucionId?}` |
| GET | `/users?<page,limit,rol,estado,search>` | — |
| GET | `/users/me/profile` | — |
| PUT | `/users/me/foto-perfil` | multipart archivo |
| GET | `/users/fotos-predeterminadas` | — |
| PATCH | `/users/foto-perfil` | `{fotoPredeterminadaUrl}` o multipart file |
| GET | `/users/:id` | — |
| GET | `/users/padre/:padreId/info` | — |
| PUT | `/users/:id` | `{nombre?,apellido?,cedula?,correo?,rol?,telefono?,estado?}` |
| DELETE | `/users/:id` | (soft = suspender) |
| PUT | `/users/me/fcm-token` | `{fcmToken}` |
| GET | `/users/sesiones/ultimas?page&limit` | — |

### 10.3 Instituciones

| Método | Endpoint | Body |
|---|---|---|
| POST | `/instituciones` | `{nombre,nit,direccion,telefono,correo,adminNombre,adminApellido,adminCedula,adminCorreo,adminTelefono}` |
| GET | `/instituciones` | — |
| PUT | `/instituciones/:id` | `{nombre,direccion,telefono,correo}` |
| GET | `/instituciones/mi-institucion` | — |
| POST | `/instituciones/docentes` | `{nombre,apellido,cedula,telefono,correo}` |
| POST | `/instituciones/docentes/csv` | multipart archivoCSV |

### 10.4 Cursos / Módulos

| Método | Endpoint | Body |
|---|---|---|
| POST | `/cursos` | multipart `{nombre,descripcion?,docenteId,fotoPortada?}` |
| GET | `/cursos?<page,limit,search>` | — |
| GET | `/cursos/mis-cursos?<page,limit>` | — |
| GET | `/cursos/:id` | — |
| GET | `/cursos/:id/participantes?<limit>` | — |
| PUT | `/cursos/:id` | multipart |
| DELETE | `/cursos/:id` | (archivar) |
| POST | `/cursos/:id/participantes` | `{nombre,apellido,cedula,telefono,contrasena}` |
| DELETE | `/cursos/:cursoId/participantes/:usuarioId` | — |
| POST | `/cursos/:id/usuarios-masivo` | multipart archivoCSV (parseo server-side) |
| POST | `/modulos` | `{titulo,descripcion,cursoId}` |
| GET | `/modulos?<query>` / `/modulos/curso/:cursoId` / `/modulos/:id` | — |
| PUT | `/modulos/:id` | `{titulo,descripcion}` |
| DELETE | `/modulos/:id` | — |
| PATCH | `/modulos/:id/restore` | — |

### 10.5 Tareas / Entregas

| Método | Endpoint | Body |
|---|---|---|
| POST | `/tareas` | multipart `{titulo,descripcion,cursoId,moduloId?,fechaEntrega?,asignacionTipo,tipoEntrega,docenteId,participantesSeleccionados[]?,archivos[],enlaces(json)}` |
| GET | `/tareas?<cursoId,limit>` / `/tareas/:id` | — |
| PUT | `/tareas/:id` | multipart + archivosAEliminar[] |
| PATCH | `/tareas/:id/cerrar` | — |
| DELETE | `/tareas/:id` | — |
| POST | `/entregas` | multipart `{tareaId,padreId,textoRespuesta,estado:"borrador",archivos[]}` |
| GET | `/entregas?<query>` / `/entregas/tarea/:tareaId` / `/entregas/padre/:padreId` / `/entregas/mis-entregas/:tareaId` / `/entregas/:id` | — |
| PUT | `/entregas/:id` | multipart |
| PATCH | `/entregas/:id/enviar` | — |
| PATCH | `/entregas/:id/calificar` | `{valoracion, comentario}` (⚠️ verificar contra backend: la web usa "valoracion" 1-5, el normalizer legacy espera "nota") |
| DELETE | `/entregas/:id` / `/entregas/:entregaId/archivos/:archivoId` | — |

### 10.6 Foros / Mensajes

| Método | Endpoint | Body |
|---|---|---|
| POST | `/foros` | multipart `{titulo,descripcion,cursoId,publico,archivos[]?}` |
| GET | `/foros/curso/:cursoId` / `/foros/:id` / `/foros/:id/dashboard` | — |
| PUT | `/foros/:id` | JSON |
| PATCH | `/foros/:id/estado` | `{estado}` |
| DELETE | `/foros/:id` | — |
| POST | `/mensajes-foro` | multipart `{foroId,contenido,respuestaA?,archivos[]?}` |
| GET | `/mensajes-foro/foro/:foroId` | — |
| POST | `/mensajes-foro/:id/like` | — (toggle) |
| PUT | `/mensajes-foro/:id` | `{contenido}` |
| DELETE | `/mensajes-foro/:id` | — |

### 10.7 Calendario / Eventos

| Método | Endpoint | Body |
|---|---|---|
| GET | `/calendario/:cursoId?<query>` / `/calendario/:cursoId/dia` / `/calendario/:cursoId/proximos` | — |
| POST | `/eventos` | multipart o JSON `{titulo,descripcion,fechaInicio,fechaFin,hora,ubicacion,categoria,cursosIds[],imagenPortada?,adjunto?}` |
| GET | `/eventos?<query>` / `/eventos/hoy` / `/eventos/:id` | — |
| PUT | `/eventos/:id` | multipart o JSON |
| DELETE | `/eventos/:id` | — |

### 10.8 Notificaciones / Buzón / Familia

| Método | Endpoint | Body |
|---|---|---|
| POST | `/notificaciones` | JSON |
| GET | `/notificaciones?<page,limit,leido>` / `/notificaciones/conteo-no-leidas` / `/notificaciones/:id` | — |
| PATCH | `/notificaciones/:id/leer` / `/notificaciones/leer-multiples` / `/notificaciones/leer-todas` | — |
| DELETE | `/notificaciones/:id` / `/notificaciones/limpiar/antiguas?<dias>` | — |
| POST | `/buzon` | JSON (formulario público) |
| GET | `/buzon?<limit>` | — |
| PATCH | `/buzon/:id/leido` | — |
| GET | `/perfiles` | — |
| POST | `/perfiles` | JSON |
| POST | `/perfiles/seleccionar` | `{perfilId}` → nuevo JWT |
| PUT | `/perfiles/:id` | JSON |
| DELETE | `/perfiles/:id` | — |
| POST | `/perfiles/fcm-token` | `{fcmToken}` |

Total ≈ 68 endpoints únicos. Todos requieren header `Authorization: Bearer <token>` salvo `/auth/login`, `/auth/register`, `/auth/forgot-password*`, `/auth/reset-password*` y `/buzon` (POST, contacto público).

Formato de error estándar observado: `{message: string}` o `{error: string}` o `{errors: [{field, message}]}` (validación) — el cliente Flutter debe intentar parsear las 3 formas.

---

## FASE 11 — Seguridad

### 11.1 JWT

- El backend emite un JWT simple, sin claims de rol explotados por el cliente (el rol se obtiene siempre de la respuesta REST `/auth/login`/`/auth/profile`, no del payload del token).
- No hay refresh token en el sistema actual — el JWT expira y fuerza logout completo. Recomendación: si el backend permanece igual, replicar el mismo modelo; si se planea evolucionar el backend, este es el momento ideal para introducir refresh tokens.
- Verificación de expiración: decodificar el JWT localmente (`jwt_decoder`) comparando `exp` con la hora actual + margen de gracia de 30s. La validación de firma es responsabilidad exclusiva del backend.

### 11.2 Almacenamiento seguro

- Web actual: token en `localStorage` plano — no aceptable en Android.
- Flutter: usar `flutter_secure_storage` (Keystore en Android) para el token JWT. El caché no sensible (usuarios vistos, preferencias UI) puede ir en `shared_preferences`/Hive sin cifrar.

### 11.3 Biometría

No existe en la web. Oportunidad de mejora real: desbloqueo por huella/rostro (`local_auth`) como capa adicional tras reabrir la app, sin reemplazar el login JWT.

### 11.4 Gestión de sesión

- Expiración por inactividad: 30 minutos sin interacción, aviso a los 28 minutos. Replicar con un `Timer` global gestionado por el `authProvider`, reiniciado con un `Listener`/`GestureDetector` global en `MaterialApp.builder`.
- Verificación periódica: cada 5 minutos, chequeo local del `exp` del JWT.
- 401 centralizado: cualquier respuesta 401 (salvo login) dispara logout automático — implementar como interceptor de Dio.

### 11.5 Permisos y protección de rutas

Matriz de 23 permisos por rol — autorización hoy solo client-side en la web; el backend debe ser la autoridad final. Replicar la matriz para UX (ocultar botones) pero nunca asumir que eso basta como seguridad.

Enum único de rol recomendado (a diferencia de la web, que tiene 2 taxonomías divergentes puenteadas por heurística de substring):

```dart
enum UserRole { superAdmin, administrador, docente, padreTutor, estudiante }
```

con mapeo explícito y exhaustivo desde el string del backend (`fromApiString`), sin `.contains()`/substring matching.

### 11.6 Validaciones replicadas de la web

- Teléfono: exactamente 10 dígitos, se antepone `+57` solo al enviar.
- Cédula: 6-10 dígitos numéricos.
- Email: regex estándar `^[^\s@]+@[^\s@]+\.[^\s@]+$`.
- Contraseña: mínimo 6 caracteres (primer login exige además mayúscula+minúscula+número).
- Código de recuperación: 4-8 dígitos.

### 11.7 Cloudinary (almacenamiento de archivos)

Toda evidencia indica que el backend usa Cloudinary para adjuntos. Flutter debe subir vía `multipart/form-data` al propio backend (no directo a Cloudinary desde el cliente), replicando el patrón actual, salvo que se decida optimizar con unsigned upload directo en una fase futura.

---

## FASE 12 — Animaciones

| Necesidad | Mecanismo Flutter |
|---|---|
| Botón "3D press" (hundimiento al tocar) | `GestureDetector.onTapDown/onTapUp/onTapCancel` + `AnimatedContainer` (100-120ms) animando `Transform.translate` y la lista de `BoxShadow` |
| Transición de pantalla (push) | `go_router` con `CustomTransitionPage` — fade/slide estándar de Android |
| Entrada de modal (bottom sheet) | `showModalBottomSheet` con curva custom `Cubic(0.34,1.56,0.64,1)` (overshoot, replica `edu-modal-in`) |
| Toast/Snackbar | `AnimatedSlide` desde el borde + `LinearProgressIndicator` de auto-dismiss |
| Shimmer de skeleton | Paquete `shimmer` o `skeletonizer`, 1.4s loop |
| Spinner de carga | `CircularProgressIndicator` custom con doble anillo (`CustomPainter` para fidelidad exacta) |
| Shake de error en formulario | `AnimatedBuilder` con `Tween<Offset>` oscilante, curva `Cubic(0.36,0.07,0.19,0.97)`, 450ms |
| Check-pop de éxito en input | `AnimatedScale` con overshoot al validar campo |
| Badge bounce de entrada | `TweenSequence` de scale: .6→1.15→.95→1 |
| Toggle con pulgar elástico | `AnimatedAlign`/`AnimatedPositioned` + curva overshoot 250ms |
| Hero de imagen (portada de curso → hub) | `Hero` widget nativo — mejora real disponible en Flutter que la web no tiene |
| Pull-to-refresh (listas: cursos, notificaciones, entregas) | `RefreshIndicator` — funcionalidad nueva a añadir, no existe en la web |
| Página de foro (mensajes nuevos) | `AnimatedList`/implicit animations al insertar mensaje entrante del polling |

Duraciones estándar (constantes `AppDurations`): fast=120ms, base=200ms, slow=300ms, spring=280-350ms con curva overshoot — unificar la inconsistencia 120ms/150ms de la web a un único valor (150ms).

---

## FASE 13 — Optimización

### 13.1 Listas y paginación

Paginación real del backend (`page`/`limit`) con `ListView.builder` + scroll infinito (`infinite_scroll_pagination`). No replicar el antipatrón web de "traer 1000 registros y filtrar en cliente" al buscar — usar búsqueda server-side o filtrar sobre datos ya paginados localmente.

### 13.2 Cache de imágenes

`cached_network_image` para portadas, avatares y adjuntos Cloudinary.

### 13.3 Cache de datos / invalidación

Replicar `staleTime: 60s` de TanStack Query con Riverpod (`FutureProvider`/`AsyncNotifierProvider` + `ref.invalidate()` tras mutaciones). El polling de 60s en Foros se replica con `Timer.periodic`; evaluar WebSocket real a futuro.

### 13.4 Memoria y render

`const` widgets en componentes de diseño puro, `RepaintBoundary` alrededor de animaciones frecuentes, `ListView.builder` siempre (nunca `Column`+`map()` para listas grandes).

### 13.5 Optimización de Foros (polling)

Pausar el `Timer` cuando la pantalla no está visible (`didChangeAppLifecycleState`) para ahorrar batería/datos — mejora real sobre el comportamiento web.

### 13.6 N+1 a evitar

La web enriquece entregas/cursos con fetches adicionales por item (padre, tarea, docente). Pedir al backend que pueble (populate) las relaciones en listados, evitando este patrón en móvil.

### 13.7 Tamaño de imágenes subidas

Comprimir/redimensionar (`flutter_image_compress`) portadas y adjuntos antes de subir desde cámara — relevante en Android donde es común subir fotos directo de la cámara (varios MB).

---

## FASE 14 — Plan de desarrollo

Sprints de 2 semanas, equipo de referencia: 2 Flutter devs + 1 diseñador part-time + 1 QA part-time.

**Sprint 1 — Fundaciones (crítico)**
Setup del proyecto, estructura Clean Architecture, `core/theme` completo, `core/design_system` (Button, TextField, Card, Badge, Avatar, LoadingScreen, EmptyState, Toast), `core/network` (Dio + interceptores), `core/security` (rol único, permisos), esqueleto de `go_router`. Feature Auth completa: Login, Forgot/Reset Password, storage seguro, gestión de sesión/inactividad, Wizard de primer login funcional.

**Sprint 2 — Shell + Dashboards**
`ShellRoute` con Drawer/NavigationRail responsivo, AppBar con búsqueda/notificaciones/perfil. 4 dashboards (Superadmin/Admin/Docente/Padre). Notificaciones. Perfil propio. Sesiones activas.

**Sprint 3 — Gestión institucional**
Instituciones (CRUD superadmin). Usuarios (CRUD + suspender/activar). Docentes (CRUD + CSV unificado). Mi Institución (solo lectura — decidir si se conectan datos hoy hardcoded).

**Sprint 4 — Cursos core**
Lista de cursos, Hub de curso (shell + tabs con permisos dinámicos), Tab Módulos (CRUD + CSV client-side), Tab Participantes (CRUD + CSV server-side).

**Sprint 5 — Tareas y Entregas**
Tab Tareas (CRUD completo), sub-flujo Entregas (listar/calificar/realizar/enviar — corrigiendo el bug de callback de la web), gestión global de Retos + calificación global (unificar antes la escala de calificación 1-5 vs 0-100).

**Sprint 6 — Foros (canónico) + Calendario/Eventos**
ForumScreen completo (3 columnas, polling, likes, hilos, permisos). Calendario agregado + por curso. Eventos (CRUD multimedia).

**Sprint 7 — Familia + Buzón**
Perfiles familiares (multi-perfil + cambio de sesión). Cursos/Retos/Entregas/Calendario de familia (reutilizando componentes ya construidos). Foros de familia → reutilizar ForumScreen canónico. Buzón.

**Sprint 8 — Pulido, offline, performance, QA**
Estados offline/retry, pull-to-refresh en todas las listas. Push notifications FCM reales (desde cero). Auditoría de accesibilidad. Pruebas end-to-end de flujos críticos. Beta cerrada + correcciones.

---

## FASE 15 — Librerías Flutter

| Categoría | Paquete | Uso |
|---|---|---|
| Routing | `go_router` | Navegación declarativa + guards |
| Estado | `flutter_riverpod` (+ `riverpod_generator` opcional) | Providers, DI, cache |
| HTTP | `dio` | Cliente HTTP + interceptores |
| Serialización | `freezed` + `json_serializable` | Entidades inmutables + DTOs |
| Almacenamiento seguro | `flutter_secure_storage` | Token JWT |
| Cache local | `hive` / `hive_flutter` | Caché de usuarios, borradores offline |
| Preferencias simples | `shared_preferences` | Flags de UI no sensibles |
| JWT | `jwt_decoder` | Lectura de `exp` |
| Imágenes remotas | `cached_network_image` | Portadas, avatares, adjuntos |
| Selección de archivos | `file_picker`, `image_picker` | CSV, portadas, adjuntos |
| Compresión de imágenes | `flutter_image_compress` | Antes de subir fotos desde cámara |
| Iconografía | `lucide_icons_flutter` (⚠️ no `lucide_icons`: ese paquete extiende `IconData`, que pasó a ser `final` en SDKs recientes de Flutter, y no compila) | Paridad con lucide-react |
| Fuentes | `google_fonts` (Inter + Poppins) | Tipografía de marca |
| Calendario | `table_calendar` | Vista mensual |
| Rating | `flutter_rating_bar` | Calificación 1-5 estrellas |
| Shimmer/Skeleton | `shimmer` o `skeletonizer` | Estados de carga |
| Paginación infinita | `infinite_scroll_pagination` | Listas grandes |
| Conectividad | `connectivity_plus` | Estado offline |
| Push notifications | `firebase_core`, `firebase_messaging` | FCM (desde cero) |
| Biometría | `local_auth` | Desbloqueo por huella/rostro |
| Fechas/locale | `intl` | Formateo es-CO |
| Logging | `logger` | Debug estructurado |
| Deep link / URL launcher | `url_launcher` | Abrir adjuntos/enlaces externos |
| Permisos de sistema | `permission_handler` | Cámara, almacenamiento, notificaciones |
| Testing | `mocktail`, `flutter_test`, `integration_test` | Unit/widget/e2e |

---

## FASE 16 — Checklist final

**Pantallas (33)**
Login · Forgot Password · Reset Password · Wizard Primer Login · Sesiones activas · Dashboard Superadmin · Dashboard Admin · Dashboard Docente · Dashboard Padre · Instituciones · Mi Institución · Usuarios · Docentes · Cursos (lista) · Hub de Curso · Tab Módulos · Tab Tareas · Tab Calendario (curso) · Tab Foros (curso) · Tab Participantes · Entregas (listar) · Calificar Entrega · Realizar Entrega · Retos (global) · Entregas (calificación global) · Calendario (agregado) · Eventos · Familia: Perfiles/Cursos/Retos/Entregas · Foro (canónico) · Notificaciones · Buzón · Perfil propio.

**Widgets del design system (17)**
EdumonButton · EdumonTextField/Textarea/Select/Toggle/Checkbox/Radio · EdumonCard/StatCard · AppModalSheet · EdumonToast · UserAvatar/SimpleAvatar · EdumonBadge/NotifBadge/XpBadge · EdumonMenuButton · FileUploadWidget · IconActionButton · LoadingScreenWidget · CalendarWidget · CsvUploadSheet · EmptyState · Skeleton/Shimmer · SectionHeader · StarRating.

**APIs (~68 — detalle completo en FASE 10)**
Auth (10) · Usuarios (11) · Instituciones (6) · Cursos/Módulos (14) · Tareas/Entregas (13) · Foros/Mensajes (10) · Calendario/Eventos (8) · Notificaciones/Buzón/Familia (11).

**Modelos (15)**
User · Institucion · Curso · Modulo · Tarea · Entrega · Calificacion · Archivo · Foro · MensajeForo · Evento · Notificacion · MensajeBuzon · Perfil · SesionDispositivo.

**Repositorios / Providers**
AuthRepository, UserRepository, InstitucionRepository, CursoRepository, ModuloRepository, TareaRepository, EntregaRepository, ForoRepository, MensajeForoRepository, CalendarioRepository, EventoRepository, NotificacionRepository, BuzonRepository, PerfilFamiliarRepository, SesionRepository, FcmRepository — cada uno con su provider Riverpod correspondiente (`authProvider`, `roleProvider`, `cursoProvider.family`, `tareasProvider.family`, `entregasProvider.family`, `foroProvider.family`+`mensajesForoProvider.family` con polling, `notificacionesProvider`, `userCacheProvider`, `perfilesFamiliaresProvider`).

**Casos de uso críticos a testear**
Login + primer login + recuperación de contraseña · Docente: crear curso→módulo→tarea→calificar · Padre: ver curso del hijo→realizar entrega→ver calificación · Participar en foro (mensaje/respuesta/like) · Admin: crear institución+admin inicial, crear docente vía CSV · Padre: crear perfil familiar y cambiar de perfil activo · Expiración de sesión (JWT+inactividad)→logout forzado.

**Decisiones de producto pendientes (bloqueantes)**
¿Se activa el rol estudiante como login propio? · ¿Se unifica la escala de calificación (1-5 vs 0-100)? · ¿Se conectan los datos hardcoded de "Mi Institución" o se retira esa sección? · ¿Sistema de planes/suscripción real? · ¿Nav para Buzón/Eventos/Sesiones? · ¿WebSocket real para foros en vez de polling? · Confirmar contrato real de `entregasCalificar` (valoracion vs nota) con backend.
</content>
