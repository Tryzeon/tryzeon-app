import 'package:equatable/equatable.dart';
import 'tryon_mode.dart';

class TryonResult extends Equatable {
  const TryonResult({this.imageBase64, this.videoPath, this.mode = TryOnMode.photo});

  final String? imageBase64;
  final String? videoPath;
  final TryOnMode mode;

  @override
  List<Object?> get props => [imageBase64, videoPath, mode];
}
