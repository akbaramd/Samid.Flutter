import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class NovTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final int maxLength;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const NovTextField({
    Key? key,
    this.hintText,
    this.labelText,
    required this.maxLength,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
  }) : super(key: key);

  @override
  _NovTextFieldState createState() => _NovTextFieldState();
}

class _NovTextFieldState extends State<NovTextField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  List<bool> _enabledStates = [];
  List<String> _values = [];
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.maxLength, (_) => TextEditingController());
    _focusNodes = List.generate(widget.maxLength, (_) => FocusNode());
    _enabledStates = List.generate(widget.maxLength, (index) => index == 0); // Only the first field is enabled initially
    _values = List.generate(widget.maxLength, (_) => '');

    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        setState(() {});
      });
    }

    Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleKeyPress(int index, String value) {
    setState(() {
      _values[index] = value;
    });

    if (value.isNotEmpty && index < widget.maxLength - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      setState(() {
        _enabledStates[index] = false;
        _enabledStates[index + 1] = true;
      });
    }

    if (widget.onChanged != null) {
      widget.onChanged!(_values.join());
    }
  }

  void _handleDelete(int index) {
    if (index > 0) {
      setState(() {
        _values[index - 1] = '';
        _controllers[index - 1].clear();
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        _enabledStates[index] = false;
        _enabledStates[index - 1] = true;
      });
    }
  }

  void _handleKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty) {
          _handleDelete(index);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.labelText!,
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.maxLength, (index) {
                return RawKeyboardListener(
                  focusNode: FocusNode(), // Unique FocusNode for each RawKeyboardListener
                  onKey: (event) => _handleKeyEvent(event, index),
                  child: Container(
                    width: 24.0,
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: widget.keyboardType,
                          obscureText: widget.obscureText,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          enabled: _enabledStates[index], // Enable or disable the TextField based on the enabled state
                          style: TextStyle(
                            color: Colors.green, // Inputted text color
                            letterSpacing: 0, // Prevent extra space between characters
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none, // Remove default border
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (value) => _handleKeyPress(index, value),
                          onSubmitted: (value) {
                            if (widget.onSubmitted != null) {
                              widget.onSubmitted!(_values.join());
                            }
                          },
                          cursorColor: Colors.transparent, // Disable default cursor
                          onEditingComplete: () {
                            if (index < widget.maxLength - 1) {
                              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                              setState(() {
                                _enabledStates[index] = false;
                                _enabledStates[index + 1] = true;
                              });
                            }
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                          ],
                        ),
                        if (_focusNodes[index].hasFocus && _showCursor && (index != widget.maxLength - 1 || _values[index].isEmpty))
                          Positioned(
                            child: Container(
                              width: 16.0,
                              height: 2.0,
                              color: Colors.green,
                            ),
                          ),
                        if (!_focusNodes[index].hasFocus && _values[index].isEmpty)
                          Positioned(
                            child: Container(
                              width: 16.0,
                              height: 2.0,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
