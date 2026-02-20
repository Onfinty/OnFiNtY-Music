import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class BeautifulDraggableScrollbar extends StatefulWidget {
  const BeautifulDraggableScrollbar({
    super.key,
    required this.controller,
    required this.child,
    required this.thumbColor,
    required this.trackColor,
    this.thumbGlowColor,
    this.rightPadding = 4,
    this.topBottomPadding = 10,
    this.minThumbExtent = 52,
    this.maxThumbExtent = 112,
  });

  final ScrollController controller;
  final Widget child;
  final Color thumbColor;
  final Color trackColor;
  final Color? thumbGlowColor;
  final double rightPadding;
  final double topBottomPadding;
  final double minThumbExtent;
  final double maxThumbExtent;

  @override
  State<BeautifulDraggableScrollbar> createState() =>
      _BeautifulDraggableScrollbarState();
}

class _BeautifulDraggableScrollbarState
    extends State<BeautifulDraggableScrollbar> {
  double _thumbProgress = 0.0;
  double _thumbExtent = 60.0;
  bool _thumbVisible = false;
  bool _dragging = false;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant BeautifulDraggableScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_syncFromController);
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _syncFromController() {
    if (!widget.controller.hasClients) {
      return;
    }
    final position = widget.controller.position;
    final maxScroll = position.maxScrollExtent;
    final viewport = position.viewportDimension;
    final totalExtent = maxScroll + viewport;

    final viewFraction = totalExtent > 0
        ? (viewport / totalExtent).clamp(0.0, 1.0)
        : 1.0;
    final thumbExtent = (viewport * viewFraction).clamp(
      widget.minThumbExtent,
      widget.maxThumbExtent,
    );

    final progress = maxScroll > 0
        ? (position.pixels / maxScroll).clamp(0.0, 1.0)
        : 0.0;

    if (!mounted) {
      return;
    }

    setState(() {
      _thumbExtent = thumbExtent.toDouble();
      _thumbProgress = progress.toDouble();
      _thumbVisible = true;
    });
    _scheduleFade();
  }

  void _scheduleFade() {
    if (_dragging) {
      return;
    }
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted || _dragging) {
        return;
      }
      setState(() {
        _thumbVisible = false;
      });
    });
  }

  void _onDragStart(DragStartDetails _) {
    _fadeTimer?.cancel();
    setState(() {
      _dragging = true;
      _thumbVisible = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double trackExtent) {
    if (!widget.controller.hasClients || trackExtent <= _thumbExtent) {
      return;
    }

    final availableTrack = trackExtent - _thumbExtent;
    final currentTop = _thumbProgress * availableTrack;
    final nextTop = (currentTop + details.delta.dy).clamp(0.0, availableTrack);
    final nextProgress = (nextTop / availableTrack).clamp(0.0, 1.0);

    final maxScroll = widget.controller.position.maxScrollExtent;
    final target = (maxScroll * nextProgress).clamp(0.0, maxScroll);
    widget.controller.jumpTo(target.toDouble());

    if (!mounted) {
      return;
    }
    setState(() {
      _thumbProgress = nextProgress.toDouble();
    });
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() {
      _dragging = false;
    });
    _scheduleFade();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackExtent = math.max(
          0.0,
          constraints.maxHeight - (widget.topBottomPadding * 2),
        );
        final availableTrack = math.max(1.0, trackExtent - _thumbExtent);
        final thumbTop =
            widget.topBottomPadding + (_thumbProgress * availableTrack);

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.vertical) {
                  _syncFromController();
                }
                return false;
              },
              child: widget.child,
            ),
            Positioned(
              top: widget.topBottomPadding,
              right: widget.rightPadding,
              bottom: widget.topBottomPadding,
              child: IgnorePointer(
                ignoring: !_thumbVisible && !_dragging,
                child: AnimatedOpacity(
                  opacity: (_thumbVisible || _dragging) ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: 26,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: widget.trackColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: thumbTop,
                          right: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: _onDragStart,
                            onVerticalDragUpdate: (details) {
                              _onDragUpdate(details, trackExtent);
                            },
                            onVerticalDragEnd: _onDragEnd,
                            onVerticalDragCancel: () {
                              setState(() {
                                _dragging = false;
                              });
                              _scheduleFade();
                            },
                            child: AnimatedContainer(
                              duration: _dragging
                                  ? Duration.zero
                                  : const Duration(milliseconds: 110),
                              curve: Curves.easeOutCubic,
                              width: 26,
                              height: _thumbExtent,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    widget.thumbColor.withValues(alpha: 0.98),
                                    widget.thumbColor.withValues(alpha: 0.82),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (widget.thumbGlowColor ??
                                                widget.thumbColor)
                                            .withValues(alpha: 0.38),
                                    blurRadius: _dragging ? 16 : 10,
                                    spreadRadius: _dragging ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
