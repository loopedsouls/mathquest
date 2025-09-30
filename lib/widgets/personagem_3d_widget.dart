import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vm;
import '../theme/app_theme.dart';
import 'visual_effects.dart';

class Personagem3DWidget extends StatefulWidget {
  final Map<String, String> itensEquipados;
  final double width;
  final double height;
  final bool interactive;
  final String? nome;

  const Personagem3DWidget({
    super.key,
    required this.itensEquipados,
    this.width = 200,
    this.height = 300,
    this.interactive = true,
    this.nome,
  });

  @override
  State<Personagem3DWidget> createState() => _Personagem3DWidgetState();
}

class _Personagem3DWidgetState extends State<Personagem3DWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bobbingController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bobbingAnimation;

  double _userRotation = 0.0;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();

    // Animação de rotação suave
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Animação de "respiração" sutil
    _bobbingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _bobbingAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _bobbingController,
      curve: Curves.easeInOut,
    ));

    if (widget.interactive) {
      _rotationController.repeat();
    }
    _bobbingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bobbingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background com partículas
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: ParticleSystem(
            particleCount: 15,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            size: 2.0,
            duration: const Duration(seconds: 8),
          ),
        ),
        // Container principal do personagem
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.5),
              radius: 1.5,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.15),
                AppTheme.darkBackgroundColor.withValues(alpha: 0.8),
                AppTheme.darkBackgroundColor,
              ],
            ),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              onPanUpdate: widget.interactive ? _handlePanUpdate : null,
              onPanStart: widget.interactive ? _handlePanStart : null,
              onPanEnd: widget.interactive ? _handlePanEnd : null,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_rotationAnimation, _bobbingAnimation]),
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspectiva
                      ..translateByVector3(vm.Vector3(0.0, _bobbingAnimation.value, 0.0))
                      ..rotateY(widget.interactive && !_isRotating
                          ? _rotationAnimation.value + _userRotation
                          : _userRotation),
                    child: _buildPersonagem(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _isRotating = true;
    _rotationController.stop();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _userRotation += details.delta.dx * 0.01;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _isRotating = false;
    if (widget.interactive) {
      _rotationController.repeat();
    }
  }

  Widget _buildPersonagem() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base/Sombra
        Positioned(
          bottom: 20,
          child: Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        // Personagem principal
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cabeça
            _buildCabeca(),
            const SizedBox(height: 8),
            // Corpo
            _buildCorpo(),
            const SizedBox(height: 4),
            // Braços
            _buildBracos(),
            const SizedBox(height: 8),
            // Pernas
            _buildPernas(),
          ],
        ),
        // Acessórios flutuantes
        ..._buildAcessorios(),
        // Nome do personagem
        if (widget.nome != null)
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                widget.nome!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCabeca() {
    final itemCabeca = widget.itensEquipados['cabeca'];
    final corCabeca = _getCorItem(itemCabeca, const Color(0xFFFFB74D));

    return AnimatedBuilder(
      animation: _bobbingAnimation,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: corCabeca.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              corCabeca,
              corCabeca.withValues(alpha: 0.8),
              corCabeca.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Face highlight
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // Olhos com piscada
            Positioned(
              top: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOlho(),
                  const SizedBox(width: 10),
                  _buildOlho(),
                ],
              ),
            ),
            // Boca sorridente
            Positioned(
              top: 38,
              child: Container(
                width: 14,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.red[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Chapéu/Cabelo se equipado
            if (itemCabeca != null) ...[
              Positioned(
                top: -8,
                child: Container(
                  width: 75,
                  height: 25,
                  decoration: BoxDecoration(
                    color: _getCorSecundaria(itemCabeca),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCorSecundaria(itemCabeca).withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getCorItem(itemCabeca, Colors.amber),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(math.sin(_bobbingAnimation.value * 0.1) * 1, 0),
          child: child,
        );
      },
    );
  }

  Widget _buildOlho() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final shouldBlink = (_rotationController.value * 50) % 20 < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 8,
          height: shouldBlink ? 2 : 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: shouldBlink ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: shouldBlink ? BorderRadius.circular(1) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
              ),
            ],
          ),
          child: !shouldBlink
              ? Center(
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildCorpo() {
    final itemCorpo = widget.itensEquipados['corpo'];
    final corCorpo = _getCorItem(itemCorpo, AppTheme.primaryColor);

    return Container(
      width: 55,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: corCorpo.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            corCorpo,
            corCorpo.withValues(alpha: 0.9),
            corCorpo.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Highlight no topo
          Positioned(
            top: 5,
            left: 5,
            right: 15,
            child: Container(
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Detalhes da roupa se equipada
          if (itemCorpo != null) ...[
            // Logo/emblema central
            Positioned(
              top: 25,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getCorSecundaria(itemCorpo),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
            // Listras decorativas
            Positioned(
              top: 15,
              left: 8,
              right: 8,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: _getCorSecundaria(itemCorpo),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 8,
              right: 8,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: _getCorSecundaria(itemCorpo),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            // Botões
            ...List.generate(3, (index) {
              return Positioned(
                top: 50 + (index * 8.0),
                left: 22,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getCorSecundaria(itemCorpo),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            // Detalhes básicos se não tiver roupa
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBracos() {
    final itemCorpo = widget.itensEquipados['corpo'];
    final corBraco = _getCorItem(itemCorpo, AppTheme.primaryColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Braço esquerdo
        Container(
          width: 15,
          height: 60,
          decoration: BoxDecoration(
            color: corBraco,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 50), // Espaço do corpo
        // Braço direito
        Container(
          width: 15,
          height: 60,
          decoration: BoxDecoration(
            color: corBraco,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPernas() {
    final itemPernas = widget.itensEquipados['pernas'];
    final corPerna = _getCorItem(itemPernas, Colors.indigo);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Perna esquerda
        Container(
          width: 20,
          height: 70,
          decoration: BoxDecoration(
            color: corPerna,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: corPerna.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: itemPernas != null
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: _getCorSecundaria(itemPernas),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: _getCorSecundaria(itemPernas),
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(width: 10),
        // Perna direita
        Container(
          width: 20,
          height: 70,
          decoration: BoxDecoration(
            color: corPerna,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: corPerna.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: itemPernas != null
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: _getCorSecundaria(itemPernas),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: _getCorSecundaria(itemPernas),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  List<Widget> _buildAcessorios() {
    final itemAcessorio = widget.itensEquipados['acessorio'];
    if (itemAcessorio == null) return [];

    return [
      // Acessório principal (ex: capa, wings, etc)
      Positioned(
        right: 30,
        top: 120,
        child: AnimatedBuilder(
          animation: _bobbingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bobbingAnimation.value * 2),
              child: Container(
                width: 30,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCorItem(itemAcessorio, Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getCorItem(itemAcessorio, Colors.amber)
                          .withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
      ),
      // Partículas mágicas
      ...List.generate(5, (index) {
        return Positioned(
          left: 20 + (index * 30.0),
          top: 80 + (math.sin(index) * 20),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi + index,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getCorItem(itemAcessorio, Colors.amber)
                        .withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getCorItem(itemAcessorio, Colors.amber),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    ];
  }

  Color _getCorItem(String? itemId, Color defaultColor) {
    if (itemId == null) return defaultColor;

    // Gera cores baseadas no hash do ID do item
    final hash = itemId.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();
  }

  Color _getCorSecundaria(String itemId) {
    final corPrimaria = _getCorItem(itemId, Colors.grey);
    final hsv = HSVColor.fromColor(corPrimaria);
    return hsv
        .withSaturation((hsv.saturation * 0.5).clamp(0.0, 1.0))
        .withValue((hsv.value * 1.2).clamp(0.0, 1.0))
        .toColor();
  }
}
