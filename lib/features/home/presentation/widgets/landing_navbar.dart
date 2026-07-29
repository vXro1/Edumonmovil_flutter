import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Navbar fija (fuera del scroll) del Home web — solo logo (grande, área
/// segura) y el CTA de inicio de sesión. Sin links de texto ni wordmark: el
/// wordmark (titulo.svg) se reserva para el footer, donde tiene más sentido
/// junto al resto de la identidad de marca (pedido explícito).
class LandingNavbar extends StatelessWidget {
  const LandingNavbar({super.key, required this.onLogoTap, required this.onLogin});

  final VoidCallback onLogoTap;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final width = MediaQuery.sizeOf(context).width;
    // Logo grande y proporcional: SVG (vectorial, nunca pixela ni se
    // deforma), escalado según el ancho real disponible en vez de un
    // tamaño fijo — más grande en desktop, se reduce sin perder
    // legibilidad en móvil. logo.svg es 1:1, así que solo se fija la
    // altura y el ancho sigue la proporción real solo.
    final logoHeight = width < 400
        ? 40.0
        : width < 700
        ? 46.0
        : width < 1200
        ? 52.0
        : 60.0;
    // El botón se angosta en pasos en vez de desaparecer/ocultarse — nunca
    // debe perderse ni superponerse con el logo (área segura vía Spacer).
    final buttonSize = width < 360 ? EdumonButtonSize.xs : (width < 900 ? EdumonButtonSize.sm : EdumonButtonSize.md);
    final showButtonLabel = width >= 340;

    return Material(
      color: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderNormalDark : AppColors.neutral150)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: width < 400 ? AppSpacing.md : AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onLogoTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                // Área segura: el logo nunca queda pegado al borde ni al botón.
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SvgPicture.asset('assets/img/logo/logo.svg', height: logoHeight),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Spacer(),
            EdumonButton(
              label: showButtonLabel ? 'Iniciar sesión' : '',
              leftIcon: LucideIcons.logIn,
              size: buttonSize,
              onPressed: onLogin,
            ),
          ],
        ),
      ),
    );
  }
}
