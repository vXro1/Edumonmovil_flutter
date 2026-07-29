import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/role.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import 'admin_dashboard.dart';
import 'superadmin_dashboard.dart';

/// /admin es la misma ruta para superadmin y administrador (BLUEPRINT.md
/// FASE 3.2.1 / 3.2.2) — el dashboard que se renderiza depende del rol real.
class AdminHomeRouter extends ConsumerWidget {
  const AdminHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(authControllerProvider).user?.rol;
    return rol == UserRole.superAdmin ? const SuperadminDashboard() : const AdminDashboard();
  }
}
