import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/models.dart';
import '../repository/notification_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class LoadMoreNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsRead extends NotificationEvent {}

// States
abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, currentPage, totalPages, isLoadingMore];
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllNotificationsRead>(_onMarkAllNotificationsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final result = await notificationRepository.getNotifications();
      emit(NotificationsLoaded(
        notifications: result['notifications'],
        unreadCount: result['unreadCount'],
        currentPage: 1,
        totalPages: result['totalPages'],
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      if (currentState.currentPage >= currentState.totalPages) return;
      if (currentState.isLoadingMore) return;

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final result = await notificationRepository.getNotifications(
          page: currentState.currentPage + 1,
        );

        final newNotifications = [
          ...currentState.notifications,
          ...result['notifications'] as List<NotificationModel>,
        ];

        emit(currentState.copyWith(
          notifications: newNotifications,
          currentPage: currentState.currentPage + 1,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      try {
        await notificationRepository.markAsRead(event.notificationId);

        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.notificationId) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: currentState.unreadCount - 1,
        ));
      } catch (e) {
        // Silently fail
      }
    }
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      try {
        await notificationRepository.markAllAsRead();

        final updatedNotifications = currentState.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            type: n.type,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      } catch (e) {
        // Silently fail
      }
    }
  }
}
