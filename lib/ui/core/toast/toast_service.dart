import 'dart:async';

enum ToastType {
  info,
  success,
  error,
}

class ToastMessage {
  final String id;
  final String title;
  final String? description;
  final ToastType type;
  final Duration duration;

  ToastMessage({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.duration = const Duration(seconds: 4),
  });
}

class ToastService {
  final _toastController = StreamController<ToastMessage>.broadcast();

  Stream<ToastMessage> get onToast => _toastController.stream;

  void show({
    required String title,
    String? description,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _toastController.add(
      ToastMessage(
        id: id,
        title: title,
        description: description,
        type: type,
        duration: duration,
      ),
    );
  }

  void dispose() {
    _toastController.close();
  }
}
