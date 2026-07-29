import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/landing_aprende_section.dart';
import '../widgets/landing_contacto_section.dart';
import '../widgets/landing_footer.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/landing_pilares_section.dart';
import '../widgets/landing_quienes_section.dart';

/// Home pública — BLUEPRINT: Home web de Edumont para padres/madres de
/// familia. Reconstruida desde cero en Flutter Web a partir del diseño
/// previo en React (misma distribución/UX de referencia, identidad visual
/// completamente nueva: paleta AppColors, tipografía Fredoka/Poppins ya
/// establecidas en el resto de la app — ver design_system).
/// Solo se registra/muestra en web (ver `app_router.dart`, `kIsWeb`).
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _scrollController = ScrollController();
  final _inicioKey = GlobalKey();
  final _pilaresKey = GlobalKey();
  final _aprendeKey = GlobalKey();
  final _quienesKey = GlobalKey();
  final _contactoKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          LandingNavbar(
            onLogoTap: () => _scrollTo(_inicioKey),
            onLogin: () => context.go('/login'),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: _inicioKey,
                    child: LandingHero(
                      onPrimaryCta: () => _scrollTo(_contactoKey),
                      onSecondaryCta: () => _scrollTo(_aprendeKey),
                    ),
                  ),
                  KeyedSubtree(key: _pilaresKey, child: const LandingPilaresSection()),
                  KeyedSubtree(key: _aprendeKey, child: const LandingAprendeSection()),
                  KeyedSubtree(key: _quienesKey, child: const LandingQuienesSection()),
                  KeyedSubtree(key: _contactoKey, child: const LandingContactoSection()),
                  const LandingFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
