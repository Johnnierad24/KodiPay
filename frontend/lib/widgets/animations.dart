import 'package:flutter/material.dart';

/// Motion primitives for KodiPay.
///
/// All widgets honour the OS "reduce motion" accessibility setting
/// (`MediaQuery.disableAnimations`) and degrade to an instant, static
/// render when it is enabled.

/// Fades and slides its [child] up into place once, on first build.
///
/// Use [delay] to stagger a column of items so they cascade in. Pair with
/// [stagger] on a list index for an even rhythm:
/// `FadeSlideIn(delay: FadeSlideIn.stagger(i), child: ...)`.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical distance (logical px) the child travels while fading in.
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 14,
  });

  /// Even cascade timing for the i-th item in a list.
  static Duration stagger(int index, {int stepMs = 60}) =>
      Duration(milliseconds: index * stepMs);

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offset / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    // Respect the user's reduce-motion preference: show final state at once.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps a tappable [child] and gently scales it down while pressed, giving a
/// tactile, physical feel to cards, tiles and buttons.
///
/// Press tracking uses a [Listener], which observes raw pointer events without
/// entering the gesture arena — so this can wrap a child that already has its
/// own `InkWell`/`onTap` (for the ripple) without stealing the tap. Provide
/// [onTap] only when the child has no tap handler of its own.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 110),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = (_pressed && !reduceMotion) ? widget.pressedScale : 1.0;

    Widget result = Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      result = GestureDetector(onTap: widget.onTap, child: result);
    }
    return result;
  }
}

/// The app's page transition: a soft fade + slide-up that matches the
/// in-screen motion language.
///
/// Register it once in [ThemeData.pageTransitionsTheme] so every
/// `MaterialPageRoute` across the app animates consistently:
///
/// ```dart
/// pageTransitionsTheme: PageTransitionsTheme(
///   builders: {
///     for (final p in TargetPlatform.values)
///       p: const KodiPageTransitionsBuilder(),
///   },
/// ),
/// ```
class KodiPageTransitionsBuilder extends PageTransitionsBuilder {
  const KodiPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
