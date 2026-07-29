import 'package:flutter/widgets.dart';

class FloatingList extends StatefulWidget {
  const FloatingList({
    super.key,
    required this.controller,
    required this.targetBuilder,
    required this.overlayBuilder,
    this.onClose,
  });

  final OverlayPortalController controller;
  final Widget Function(BuildContext context) targetBuilder;
  final Widget Function(BuildContext context) overlayBuilder;
  final VoidCallback? onClose;

  @override
  State<FloatingList> createState() => _FloatingListState();
}

class _FloatingListState extends State<FloatingList> {
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: widget.controller,
            overlayChildBuilder: (context) {
              return Positioned(
                width: constraints.maxWidth,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.topLeft,
                  followerAnchor: Alignment.bottomLeft,
                  offset: const Offset(0, -8),
                  child: TapRegion(
                    groupId: widget.controller,
                    onTapOutside: (event) {
                      if (widget.controller.isShowing) {
                        widget.controller.hide();
                        widget.onClose?.call();
                      }
                    },
                    child: widget.overlayBuilder(context),
                  ),
                ),
              );
            },
            child: TapRegion(
              groupId: widget.controller,
              child: widget.targetBuilder(context),
            ),
          ),
        );
      },
    );
  }
}
