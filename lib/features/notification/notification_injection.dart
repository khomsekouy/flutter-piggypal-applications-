import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:flutter_piggypal_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/delete_notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/mark_all_notifications_read.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/mark_notification_read.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/save_notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/watch_notification_list.dart';
import 'package:flutter_piggypal_app/features/notification/presentation/bloc/notification_bloc.dart';

/// Wires the notification feature into the service locator.
/// Called once from [initDependencies].
void initNotification() {
  sl
    // Bloc — fresh per screen. The bell makes its own too, so a header badge
    // stays live on screens that know nothing about the centre.
    ..registerFactory(
      () => NotificationBloc(
        watchNotificationList: sl(),
        deleteNotification: sl(),
        saveNotification: sl(),
        markNotificationRead: sl(),
        markAllNotificationsRead: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => WatchNotificationList(sl()))
    ..registerLazySingleton(() => SaveNotification(sl()))
    ..registerLazySingleton(() => DeleteNotification(sl()))
    ..registerLazySingleton(() => MarkNotificationRead(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsRead(sl()))
    // Repository.
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl()),
    )
    // Data source.
    ..registerLazySingleton<NotificationLocalDataSource>(
      () => NotificationLocalDataSourceImpl(sl()),
    );
}
