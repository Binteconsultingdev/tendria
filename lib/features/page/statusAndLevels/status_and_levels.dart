import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/controller/theme_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';

class StatusAndLevels extends StatefulWidget {
  const StatusAndLevels({Key? key}) : super(key: key);

  @override
  State<StatusAndLevels> createState() => _StatusAndLevelsScreenState();
}

class _StatusAndLevelsScreenState extends State<StatusAndLevels> {
  int _currentPage = 2;  

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      body: Obx(() {
        final mode = themeCtrl.themeMode.value; 
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ThemeColor.backgroundColor,
                ThemeColor.backgroundColor,
                ThemeColor.secondaryColor.withOpacity(0.6),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [ 
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tatendria VIP',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: ThemeColor.primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close_rounded,
                          color: ThemeColor.textPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
 
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: ThemeColor.textPrimary,
                            ),
                            children: [
                              const TextSpan(text: 'Tu nivel define\n'),
                              TextSpan(
                                text: 'tu acceso.',
                                style: TextStyle(
                                  color: ThemeColor.primaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'A medida que participas, desbloqueas beneficios, '
                          'contenido y experiencias únicas diseñadas para '
                          'los miembros más comprometidos.',
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _LevelCard(
                          icon: Icons.military_tech_rounded,
                          iconColor: const Color(0xFFB0B4BA),
                          title: 'Plata',
                          subtitle: 'NIVEL DE ENTRADA',
                          features: const [
                            'Acceso al feed general de creadores',
                            'Mensajería básica de comunidad',
                          ],
                        ),

                        const SizedBox(height: 20),

                        _LevelCard(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFD4AF37),
                          title: 'Oro',
                          subtitle: 'ESTATUS PREMIUM',
                          badge: 'MÁS POPULAR',
                          highlighted: true,
                          features: const [
                            'Contenido multimedia exclusivo (HD)',
                            'Chat prioritario con creadores VIP',
                            'Insignia de perfil dorada',
                          ],
                        ),

                        const SizedBox(height: 20),

                        _LevelCard(
                          icon: Icons.diamond_rounded,
                          iconColor: const Color(0xFF7FD8E8),
                          title: 'Diamante',
                          subtitle: 'EXPERIENCIA ÉLITE',
                          features: const [
                            'Acceso a eventos privados y streaming',
                            'Soporte dedicado 24/7 Concierge',
                          ],
                        ),

                        const SizedBox(height: 24),
 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? ThemeColor.primaryColor
                                    : ThemeColor.subtleBorder,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
 
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: GestureDetector(
                    onTap: () { 
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: ThemeColor.primaryColor,
                        borderRadius: ThemeColor.circularBorderRadius,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continuar',
                              style: ThemeColor.buttonText.copyWith(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final String? badge;
  final bool highlighted;

  const _LevelCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
    this.badge,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            borderRadius: ThemeColor.largeBorderRadius,
            border: Border.all(
              color: highlighted
                  ? ThemeColor.primaryColor.withOpacity(0.6)
                  : ThemeColor.subtleBorder,
              width: highlighted ? 1.4 : 1,
            ),
            boxShadow: [ThemeColor.cardShadow],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.12),
                  border: Border.all(color: iconColor.withOpacity(0.4)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: ThemeColor.headingSmall.copyWith(
                  color: ThemeColor.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: ThemeColor.caption.copyWith(
                  color: ThemeColor.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: ThemeColor.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: ThemeColor.bodyMedium.copyWith(
                            color: ThemeColor.textPrimary.withOpacity(0.85),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeColor.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}