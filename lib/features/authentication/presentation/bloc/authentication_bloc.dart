import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/authentication.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/delete_authentication.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/watch_authentication_list.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// Drives the authentication use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required WatchAuthenticationList watchAuthenticationList,
    required DeleteAuthentication deleteAuthentication,
  }) : _watchAuthenticationList = watchAuthenticationList,
       _deleteAuthentication = deleteAuthentication,
       super(const AuthenticationState()) {
    on<AuthenticationSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthenticationDeleted>(_onDeleted);
  }

  final WatchAuthenticationList _watchAuthenticationList;
  final DeleteAuthentication _deleteAuthentication;

  Future<void> _onSubscriptionRequested(
    AuthenticationSubscriptionRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    await emit.forEach<List<Authentication>>(
      _watchAuthenticationList(const NoParams()),
      onData: (items) => state.copyWith(
        status: AuthenticationStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: AuthenticationStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    AuthenticationDeleted event,
    Emitter<AuthenticationState> emit,
  ) async {
    final result = await _deleteAuthentication(
      DeleteAuthenticationParams(event.id),
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          status: AuthenticationStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
