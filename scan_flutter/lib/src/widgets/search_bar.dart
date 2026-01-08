import 'package:flutter/material.dart';
import '../style/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchPressed;
  final TextEditingController? controller;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? cursorColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? textStyle;
  final InputBorder? border;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool showClearButton;
  final VoidCallback? onClearPressed;

  const CustomSearchBar({
    Key? key,
    this.hintText = 'Rechercher',
    this.onChanged,
    this.onSearchPressed,
    this.controller,
    this.autofocus = false,
    this.contentPadding,
    this.height = 44.0,
    this.borderRadius = 24.0,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.textColor = const Color(0xFF2E3135),
    this.hintColor = const Color(0xFF9E9E9E),
    this.cursorColor = AppColors.primary,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.border,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.showClearButton = false,
    this.onClearPressed,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? _controller;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? _focusNode;
    }
  }

  void _onSubmitted(String value) {
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(value);
    } else if (widget.onSearchPressed != null) {
      widget.onSearchPressed!();
    } else {
      // Default behavior: unfocus the keyboard
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if it was created locally
    if (widget.controller == null) {
      _controller.dispose();
    }
    // Only dispose the focus node if it was created locally
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 24.0),
        ),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction ?? TextInputAction.search,
          onChanged: widget.onChanged,
          onSubmitted: _onSubmitted,
          style:
              widget.textStyle ??
              const TextStyle(
                color: Color(0xFF2E3135),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
          cursorColor: widget.cursorColor,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon:
                widget.suffixIcon ??
                const Icon(Icons.search, color: AppColors.iconMuted, size: 24),
            isDense: true,
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
