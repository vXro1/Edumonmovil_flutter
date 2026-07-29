import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/design_system/buttons/edumon_button.dart';
import '../../../../core/design_system/inputs/edumon_text_field.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../buzon/presentation/providers/buzon_providers.dart';
import 'landing_decor.dart';
import 'landing_quienes_section.dart' show LandingSectionHeaderLeft;
import 'scroll_reveal.dart';

/// "Contáctanos" — formulario real (POST a /buzon, ver
/// buzon_publico_remote_datasource.dart) con la imagen "Soporte Edumont"
/// (assets/img/recursos/Buzonsoporte.svg). Copy reformulado hacia
/// padres/madres en vez del enfoque institucional del diseño anterior.
class LandingContactoSection extends ConsumerStatefulWidget {
  const LandingContactoSection({super.key});

  @override
  ConsumerState<LandingContactoSection> createState() => _LandingContactoSectionState();
}

class _LandingContactoSectionState extends ConsumerState<LandingContactoSection> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _institucionController = TextEditingController();
  final _mensajeController = TextEditingController();

  String? _nombreError, _correoError, _mensajeError;
  bool _loading = false;
  bool _success = false;
  String? _generalError;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _institucionController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final mensaje = _mensajeController.text.trim();

    setState(() {
      _nombreError = nombre.isEmpty ? 'Contanos tu nombre.' : null;
      _correoError = AppConstants.emailRegex.hasMatch(correo) ? null : 'Ingresá un correo válido.';
      _mensajeError = mensaje.isEmpty ? 'Escribinos tu mensaje.' : null;
      _generalError = null;
    });
    if (_nombreError != null || _correoError != null || _mensajeError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(buzonPublicoRepositoryProvider).enviarMensaje(
            nombre: nombre,
            correo: correo,
            telefono: _telefonoController.text.trim(),
            institucion: _institucionController.text.trim(),
            mensaje: mensaje,
          );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generalError = e is AppException ? e.message : 'No se pudo enviar el mensaje. Intentá de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final breakpoint = Breakpoint.of(context);
    // Edumont Soporte necesita protagonismo real (pedido explícito) — antes
    // era un ícono chico de 180-220px perdido al final de la columna de
    // texto; ahora ocupa un espacio comparable al del propio título.
    final soporteSize = breakpoint.isCompact ? 220.0 : (breakpoint.isMedium ? 260.0 : 320.0);

    final infoColumn = Column(
      crossAxisAlignment: breakpoint.isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const LandingSectionHeaderLeft(eyebrow: 'Hablemos'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '¿Querés saber más\nsobre Edumont?',
          textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: breakpoint.isCompact ? 26 : 32,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'Escribinos y te contamos cómo empezar a usar Edumont con tu '
            'familia, o cómo llevarlo a tu institución.',
            textAlign: breakpoint.isCompact ? TextAlign.center : TextAlign.start,
            style: TextStyle(fontSize: 15, height: 1.7, color: AppColors.mutedText(context)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // "Edumont Soporte" es uno de los elementos visuales principales de
        // la sección — debe sentirse como el personaje acompañando/
        // orientando a la familia, no un ícono decorativo perdido. El halo
        // de color detrás (sin blur, solo opacidad) le da profundidad barato
        // en rendimiento y refuerza que "está ahí, presente". LayoutBuilder
        // en vez de confiar solo en el breakpoint global: el ancho real de
        // esta columna depende del flex que le tocó dentro del Row (5/11), y
        // ese ancho puede ser menor que soporteSize cerca de los bordes de
        // cada breakpoint — así nunca se desborda de su columna.
        LayoutBuilder(
          builder: (context, constraints) {
            final maxAvailable = constraints.maxWidth.isFinite ? constraints.maxWidth : soporteSize * 1.2;
            final haloSize = (soporteSize * 1.2).clamp(0.0, maxAvailable);
            final imgSize = haloSize / 1.2;
            return SizedBox(
              width: haloSize,
              height: haloSize * (1.15 / 1.2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: haloSize * (1.1 / 1.2),
                    height: haloSize * (1.1 / 1.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.eduCyan.withValues(alpha: isDark ? 0.16 : 0.09),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/img/recursos/Buzonsoporte.svg',
                    width: imgSize,
                    // Un asset roto/desincronizado con pubspec.yaml no debe
                    // tumbar el resto de la sección — se vio pasar
                    // exactamente esto (excepción sin capturar durante el
                    // build de esta sección dejaba en blanco toda la página
                    // al hacer scroll).
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    final formCard = ScrollReveal(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: isDark ? Border.all(color: AppColors.borderNormalDark) : null,
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: _success ? _SuccessState(onReset: () => setState(() => _success = false)) : _buildForm(isDark),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: ScatteredCircles(
            specs: const [
              DecorCircleSpec(asset: 'circulo3.svg', sizeFactor: 0.04, top: 0.02, left: 0.04, opacity: 0.28),
              DecorCircleSpec(asset: 'circulo9.svg', sizeFactor: 0.03, top: 0.3, right: 0.05, opacity: 0.25),
              DecorCircleSpec(asset: 'circulo2.svg', sizeFactor: 0.045, bottom: 0.03, right: 0.1, opacity: 0.3),
              DecorCircleSpec(asset: 'circulo7.svg', sizeFactor: 0.025, bottom: 0.2, left: 0.15, opacity: 0.22),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: breakpoint.isCompact ? AppSpacing.lg : AppSpacing.s24,
            vertical: AppSpacing.s24,
          ),
          child: breakpoint.isCompact
              ? Column(children: [infoColumn, const SizedBox(height: AppSpacing.xl), formCard])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: infoColumn),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 6, child: formCard),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Solicitar información',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text('Completá el formulario y te contactamos pronto.', style: TextStyle(color: AppColors.mutedText(context))),
        const SizedBox(height: AppSpacing.md),
        if (_generalError != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.errorSurface(isDark),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(_generalError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        EdumonTextField(controller: _nombreController, label: 'Nombre completo', errorText: _nombreError),
        EdumonTextField(
          controller: _correoController,
          label: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
          errorText: _correoError,
        ),
        EdumonTextField(controller: _telefonoController, label: 'Teléfono (opcional)', keyboardType: TextInputType.phone),
        EdumonTextField(controller: _institucionController, label: 'Institución (opcional)'),
        EdumonTextField(
          controller: _mensajeController,
          label: '¿Cómo podemos ayudarte?',
          maxLines: 4,
          minLines: 3,
          errorText: _mensajeError,
        ),
        const SizedBox(height: AppSpacing.sm),
        EdumonButton(
          label: _loading ? 'Enviando…' : 'Enviar mensaje',
          leftIcon: LucideIcons.send,
          fullWidth: true,
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu información es confidencial y nunca se comparte.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.subtleText(context)),
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.circleCheck, size: 48, color: AppColors.success),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '¡Mensaje enviado!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Te contactaremos pronto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: AppSpacing.md),
        EdumonButton(label: 'Enviar otro mensaje', variant: EdumonButtonVariant.outline, onPressed: onReset),
      ],
    );
  }
}
