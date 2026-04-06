import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthMnemonicGenerated extends AuthEvent {
  const AuthMnemonicGenerated();
}

class AuthIdentityCreated extends AuthEvent {
  final List<String> mnemonic;
  final String nickname;
  const AuthIdentityCreated({required this.mnemonic, required this.nickname});
  @override
  List<Object?> get props => [mnemonic, nickname];
}

class AuthPinSet extends AuthEvent {
  final String pin;
  const AuthPinSet({required this.pin});
  @override
  List<Object?> get props => [pin];
}

class AuthPinVerified extends AuthEvent {
  final String pin;
  const AuthPinVerified({required this.pin});
  @override
  List<Object?> get props => [pin];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthMnemonicReady extends AuthState {
  final List<String> mnemonic;
  const AuthMnemonicReady({required this.mnemonic});
  @override
  List<Object?> get props => [mnemonic];
}

class AuthNeedPin extends AuthState {
  const AuthNeedPin();
}

class AuthAuthenticated extends AuthState {
  final String? nickname;
  const AuthAuthenticated({this.nickname});
  @override
  List<Object?> get props => [nickname];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthMnemonicGenerated>(_onMnemonicGenerated);
    on<AuthIdentityCreated>(_onIdentityCreated);
    on<AuthPinSet>(_onPinSet);
    on<AuthPinVerified>(_onPinVerified);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final nickname = await authRepository.getNickname();
        emit(AuthAuthenticated(nickname: nickname));
      } else {
        final hasIdentity = await authRepository.hasIdentity();
        if (hasIdentity) {
          emit(const AuthNeedPin());
        } else {
          emit(const AuthUnauthenticated());
        }
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onMnemonicGenerated(
    AuthMnemonicGenerated event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final mnemonic = await authRepository.generateMnemonic();
      emit(AuthMnemonicReady(mnemonic: mnemonic));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onIdentityCreated(
    AuthIdentityCreated event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.createIdentity(
        mnemonic: event.mnemonic,
        nickname: event.nickname,
      );
      emit(const AuthNeedPin());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onPinSet(AuthPinSet event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await authRepository.setPin(event.pin);
      final nickname = await authRepository.getNickname();
      emit(AuthAuthenticated(nickname: nickname));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onPinVerified(
    AuthPinVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final valid = await authRepository.verifyPin(event.pin);
      if (valid) {
        final nickname = await authRepository.getNickname();
        emit(AuthAuthenticated(nickname: nickname));
      } else {
        emit(const AuthError(message: 'Invalid PIN'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
