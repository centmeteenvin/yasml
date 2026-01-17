import 'dart:async';

class SampleStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration interval;

  SampleStreamTransformer(this.interval);

  @override
  Stream<T> bind(Stream<T> stream) {
    // Determine if we should create a broadcast controller
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast(sync: false)
        : StreamController<T>(sync: false);

    StreamSubscription<T>? subscription;
    Timer? timer;
    T? latestValue;
    bool hasValue = false;

    controller.onListen = () {
      subscription = stream.listen(
        (data) {
          latestValue = data;
          hasValue = true;

          if (timer == null || !timer!.isActive) {
            timer = Timer.periodic(interval, (t) {
              if (hasValue && !controller.isClosed) {
                controller.add(latestValue as T);
                hasValue = false;
              }
            });
          }
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    };

    // For broadcast streams, we must handle onCancel properly
    controller.onCancel = () {
      timer?.cancel();
      subscription?.cancel();
    };

    return controller.stream;
  }
}
