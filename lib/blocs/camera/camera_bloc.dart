import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:my_photos/utils/camera_utils.dart';

part 'camera_event.dart';

part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraUtils cameraUtils;
  final ResolutionPreset resolutionPreset;
  final CameraLensDirection cameraLensDirection;

  CameraController? _controller;

  CameraBloc({
    required this.cameraUtils,
    this.resolutionPreset = ResolutionPreset.medium,
    this.cameraLensDirection = CameraLensDirection.back,
  }) : super(CameraInitial());

  CameraController getController() => _controller!;

  bool isInitialized() => _controller!.value.isInitialized;

  List<Uint8List> collectedPhoto = []; // collected photos for take more than once

  StreamController<Uint8List> controllerImage =
      StreamController<Uint8List>.broadcast();
  late StreamSubscription<Uint8List> _subscription;


  int counterSnapshot = 0;
  late int amountCollectWillBe;
  late double progressValue;
  @override
  Stream<CameraState> mapEventToState(
    CameraEvent event,
  ) async* {
    if (event is CameraInitialized)
      yield* _mapCameraInitializedToState(event);
    else if (event is CameraCaptured) {
      if (event.amountPicture > 1) {
        progressValue = 1 / event.amountPicture;
        amountCollectWillBe = event.amountPicture;
        yield* _mapCameraCapturedMoreThanOneToState(progressValue);
      } else {
        yield* _mapCameraCapturedToState();
      }
    } else if (event is CameraStopped)
      yield* _mapCameraStoppedToState(event);
    else if (event is CameraOnSnapshotWhileMoreThanOneEvent) {
      if (event.currentCollectImage == amountCollectWillBe) {
        _subscription.cancel();
        _controller?.stopImageStream();
        yield CameraCaptureSuccess(collectedPhoto, null);
      } else {
        print("current collect image ${event.currentCollectImage}");
        collectedPhoto.add(event.imageScan);
        yield CameraCaptureInProgress(progressValue: event.progressValue);
      }
    }
  }

  Stream<CameraState> _mapCameraInitializedToState(
      CameraInitialized event) async* {
    try {
      _controller = await cameraUtils.getCameraController(
          resolutionPreset, cameraLensDirection);
      await _controller?.initialize();
      await _controller?.lockCaptureOrientation();
      if (cameraLensDirection == CameraLensDirection.back) {
        await _controller?.setFlashMode(FlashMode.off);
      }
      yield CameraReady();
    } on CameraException catch (error) {
      _controller?.dispose();
      yield CameraFailure(error: error.description!);
    } catch (error) {
      yield CameraFailure(error: error.toString());
    }
  }

  Stream<CameraState> _mapCameraCapturedToState() async* {
    if (state is CameraReady) {
      yield CameraCaptureInProgress();
      try {
        XFile resultPicture = await _controller!.takePicture();
        yield CameraCaptureSuccess(null, resultPicture.path);
      } on CameraException catch (error) {
        yield CameraCaptureFailure(error: error.description!);
      }
    }
  }

  Stream<CameraState> _mapCameraCapturedMoreThanOneToState(double progressAdd) async* {
    if (state is CameraReady) {
      try {
        _controller?.startImageStream((CameraImage image) {
          print('anuilah');
          controllerImage.add(image.planes[0].bytes);
        });

        Stream<Uint8List> stream = controllerImage.stream;

        _subscription = stream.listen((imageScanned) {
          add(CameraOnSnapshotWhileMoreThanOneEvent(
              currentCollectImage: counterSnapshot,
              progressValue: progressValue,
              imageScan: imageScanned));
          counterSnapshot++;
          progressValue += progressAdd;
        });
      } on CameraException catch (error) {
        yield CameraCaptureFailure(error: error.description!);
      }
    }
  }

  Stream<CameraState> _mapCameraStoppedToState(CameraStopped event) async* {
    _controller?.dispose();
    yield CameraInitial();
  }

  @override
  Future<void> close() {
    _controller?.dispose();
    return super.close();
  }
}
