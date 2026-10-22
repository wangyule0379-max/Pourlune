import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Presentation only. These never gate a save or dispatch a game action.
abstract final class KnitMotion {
  static const press = Duration(milliseconds: 75);
  static const release = Duration(milliseconds: 150);
  static const page = Duration(milliseconds: 260);
  static const board = Duration(milliseconds: 290);
  static const shortFade = Duration(milliseconds: 120);
  static const reveal = Duration(milliseconds: 700);
  static const success = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
}

enum KnitPageTransition { fadeThrough, horizontal, scaled }

/// Two visual pages at most. The outgoing page cannot receive any input/focus
/// or contribute semantics. No animation callback performs navigation.
class PageMotion extends StatefulWidget {
  const PageMotion({
    super.key,
    required this.page,
    required this.child,
    this.back = false,
    this.transition = KnitPageTransition.fadeThrough,
    this.animateInitial = false,
    this.immediate = false,
    this.retainPrevious = true,
  });
  final Object page;
  final KnitPageTransition transition;
  final bool animateInitial;
  final Widget child;
  final bool back, immediate, retainPrevious;
  @override
  State<PageMotion> createState() => _PageMotionState();
}

class _PageMotionState extends State<PageMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation =
      AnimationController(vsync: this, duration: KnitMotion.page, value: 1)
        ..addStatusListener((status) {
          if ((status == AnimationStatus.completed ||
                  status == AnimationStatus.dismissed) &&
              _outgoing != null &&
              mounted) {
            setState(() => _outgoing = null);
          }
        });
  Widget? _outgoing;
  Object? _oldPage;
  bool _reduced = false, _back = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.animateInitial) {
      _animation.duration = KnitMotion.shortFade;
      _animation.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced || widget.immediate) _finish();
  }

  void _finish() {
    _outgoing = null;
    _animation.value = _back ? 0 : 1;
  }

  @override
  void didUpdateWidget(covariant PageMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.immediate || _reduced) {
      _finish();
    } else if (oldWidget.page != widget.page) {
      _outgoing = null;
      _oldPage = oldWidget.page;
      _back = widget.back;
      _animation.duration = KnitMotion.page;
      if (_back) {
        _animation.reverse(from: 1);
      } else {
        _animation.forward(from: 0);
      }
      _outgoing = widget.retainPrevious ? oldWidget.child : null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) setState(_finish);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  Widget _transition(Widget child, {required bool incoming}) {
    // Same primary/secondary contract as a pushed/popped PageRoute. We keep a
    // bounded host because PageTransitionSwitcher may retain many old children.
    final Animation<double> primary = _back
        ? (incoming ? kAlwaysCompleteAnimation : _animation)
        : (incoming ? _animation : kAlwaysCompleteAnimation);
    final Animation<double> secondary = _back
        ? (incoming ? _animation : kAlwaysDismissedAnimation)
        : (incoming ? kAlwaysDismissedAnimation : _animation);
    if (widget.transition == KnitPageTransition.fadeThrough) {
      return FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        fillColor: Colors.transparent,
        child: child,
      );
    }
    return SharedAxisTransition(
      animation: primary,
      secondaryAnimation: secondary,
      transitionType: widget.transition == KnitPageTransition.horizontal
          ? SharedAxisTransitionType.horizontal
          : SharedAxisTransitionType.scaled,
      fillColor: Colors.transparent,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (_outgoing != null)
        IgnorePointer(
          key: const Key('page-outgoing'),
          child: ExcludeSemantics(
            child: ExcludeFocus(
              child: TickerMode(
                enabled: false,
                child: _transition(
                  KeyedSubtree(key: ValueKey(_oldPage), child: _outgoing!),
                  incoming: false,
                ),
              ),
            ),
          ),
        ),
      FocusScope(
        key: ValueKey(widget.page),
        autofocus: true,
        child: KeyedSubtree(
          key: const Key('page-enter'),
          child: _transition(widget.child, incoming: true),
        ),
      ),
    ],
  );
}

final _dialogOpen = Expando<bool>();

Future<T?> showKnitDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  // A repeated confirmation must not dispatch the same action twice.
  if (_dialogOpen[navigator] == true) return null;
  _dialogOpen[navigator] = true;
  try {
    return await navigator.push<T>(
      _KnitDialogRoute<T>(
        context: context,
        builder: builder,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
      ),
    );
  } finally {
    _dialogOpen[navigator] = null;
  }
}

class _KnitDialogRoute<T> extends DialogRoute<T> {
  _KnitDialogRoute({
    required super.context,
    required super.builder,
    required super.themes,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
         animationStyle: const AnimationStyle(
           duration: Duration(milliseconds: 220),
           reverseDuration: Duration(milliseconds: 150),
         ),
       );
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeScaleTransition(animation: animation, child: child);
  }
}

/// Covers framework-owned routes (licenses and license detail) without migrating
/// the existing Material widgets to material_ui or adding a second navigation.
class KnitRouteTransitions extends PageTransitionsBuilder {
  const KnitRouteTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}
