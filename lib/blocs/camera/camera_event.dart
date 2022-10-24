part of 'camera_bloc.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

class CameraInitialized extends CameraEvent {}

class CameraStopped extends CameraEvent {}

class CameraCaptured extends CameraEvent {
  final int amountPicture;

  CameraCaptured({required this.amountPicture});
}

class CameraOnSnapshotWhileMoreThanOneEvent extends CameraEvent {
  final double progressValue;
  final int currentCollectImage;
  final Uint8List imageScan;

  const CameraOnSnapshotWhileMoreThanOneEvent(
      {required this.currentCollectImage,
      required this.progressValue,
      required this.imageScan});
}
