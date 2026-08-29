import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Puts a picture on the signed-in account.
class UpdateProfilePhoto extends UseCase<AuthUser, UpdateProfilePhotoParams> {
  const UpdateProfilePhoto(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<AuthUser> call(UpdateProfilePhotoParams params) =>
      _repository.updateProfilePhoto(
        avatar: params.avatar,
        avatarFileName: params.avatarFileName,
      );
}

class UpdateProfilePhotoParams extends Equatable {
  const UpdateProfilePhotoParams({required this.avatar, this.avatarFileName});

  final Uint8List avatar;

  /// Forwarded as the multipart part's filename so the server stores the file
  /// with the right extension.
  final String? avatarFileName;

  @override
  List<Object?> get props => [avatar, avatarFileName];
}
