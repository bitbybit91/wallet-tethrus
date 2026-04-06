import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/blocs/auth/auth_bloc.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  static const int _pinLength = 6;

  String _pin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  String? _errorText;

  void _onDigitPressed(int digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit.toString();
      _errorText = null;
    });

    if (_pin.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  void _onPinComplete() {
    if (!_isConfirming) {
      // First entry — move to confirmation step
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
    } else {
      // Confirmation step
      if (_pin == _firstPin) {
        context.read<AuthBloc>().add(AuthPinSet(pin: _pin));
      } else {
        setState(() {
          _pin = '';
          _errorText = "PINs don't match";
        });
      }
    }
  }

  void _resetPin() {
    setState(() {
      _pin = '';
      _firstPin = '';
      _isConfirming = false;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/market');
        } else if (state is AuthError) {
          setState(() => _errorText = state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Title
              Text(
                _isConfirming ? 'Confirm Your PIN' : 'Set Your PIN',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Enter your PIN again to confirm'
                    : 'Choose a 6-digit PIN to secure your wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final filled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              // Error text
              const SizedBox(height: 20),
              SizedBox(
                height: 20,
                child: _errorText != null
                    ? GestureDetector(
                        onTap: _resetPin,
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Number pad
              _buildNumberPad(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildRow(row),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRow(int row) {
    if (row < 3) {
      // Rows 0–2: digits 1–9
      return List.generate(3, (col) {
        final digit = row * 3 + col + 1;
        return _digitButton(digit);
      });
    }
    // Bottom row: empty, 0, backspace
    return [
      const SizedBox(width: 72, height: 72),
      _digitButton(0),
      _backspaceButton(),
    ];
  }

  Widget _digitButton(int digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: () => _onDigitPressed(digit),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: AppColors.darkSurface,
        ),
        child: Text(
          '$digit',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: _onBackspace,
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: const Icon(
          Icons.backspace_outlined,
          color: AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
