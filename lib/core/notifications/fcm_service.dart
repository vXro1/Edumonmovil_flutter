import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Debe coincidir con el meta-data
/// `com.google.firebase.messaging.default_notification_channel_id` en
/// AndroidManifest.xml — así los mensajes que llegan con la app en
/// background/cerrada (donde no corre nada de Dart) usan el mismo canal que
/// los que se muestran a mano en foreground acá abajo.
const _channelId = 'notificaciones_generales';
const _channelName = 'Notificaciones';
const _channelDescription = 'Tareas, entregas, calificaciones, foros y eventos de Edumon';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Handler de mensajes en background — FCM lo ejecuta en un isolate propio,
/// aislado del estado de la app (por eso tiene que ser una función de nivel
/// superior con `@pragma('vm:entry-point')`, nunca un método de instancia).
/// No hace falta mostrar la notificación a mano acá: Android ya la renderiza
/// solo con que el payload traiga `notification` (ver FCMStrategy.js en el
/// backend real) — este handler solo existe porque firebase_messaging exige
/// registrar uno para que el sistema entregue mensajes en background/cerrado
/// en primer lugar.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Registro de notificaciones push (FCM) — deja la app lista para recibir
/// notificaciones reales del backend incluso con la app cerrada.
///
/// Requiere que `android/app/google-services.json` exista (descargado desde
/// un proyecto real de Firebase Console) y que el backend tenga configuradas
/// FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY — sin eso,
/// cada método acá se degrada solo (try/catch silencioso) en vez de romper
/// el arranque de la app, mismo criterio defensivo que ya usa
/// notificacionService.js del lado del backend para este mismo canal.
class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  /// Llamar una sola vez al arrancar la app (antes de runApp), independiente
  /// de si hay sesión iniciada — deja el canal de Android y el listener de
  /// foreground listos. No pide permiso ni registra token todavía (eso
  /// requiere sesión, ver [registerForCurrentUser]).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } catch (e) {
      // Firebase no configurado todavía en este build (falta
      // google-services.json) — la app sigue funcionando normal, solo sin
      // notificaciones push.
      debugPrint('[FCM] init() no disponible: $e');
    }
  }

  /// FCM no muestra ninguna notificación de sistema cuando el mensaje llega
  /// con la app EN FOREGROUND (a diferencia de background/cerrado, que
  /// Android resuelve solo) — hay que mostrarla a mano acá.
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[FCM] No se pudo mostrar la notificación en foreground: $e');
    }
  }

  /// Pide el permiso de notificaciones (iOS lo requiere explícito vía FCM;
  /// Android 13+ ya lo pide notification_permission_service.dart aparte),
  /// obtiene el token del dispositivo y lo registra en el backend
  /// (PUT /users/me/fcm-token) — llamar después de un login exitoso o de
  /// restaurar sesión, nunca antes (el endpoint requiere estar autenticado).
  /// Best-effort total: cualquier fallo se traga en silencio, igual que el
  /// resto de canales best-effort de la app (logout, sync de modo oscuro).
  Future<void> registerForCurrentUser() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(profileRepositoryProvider).updateFcmToken(token);
      }

      // El token puede rotar en cualquier momento (reinstalación, limpieza
      // de datos de Play Services, etc.) — hay que re-registrar cada vez.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _ref.read(profileRepositoryProvider).updateFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('[FCM] registerForCurrentUser() no disponible: $e');
    }
  }

  /// Llamar al hacer logout — sin esto, el token del dispositivo sigue
  /// registrado a nombre del usuario anterior y seguiría recibiendo sus
  /// notificaciones tras cerrar sesión.
  Future<void> unregister() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));
