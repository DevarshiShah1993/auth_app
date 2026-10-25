import 'package:equatable/equatable.dart';

/// Marker for use cases that take no input.
class NoParams extends Equatable {
  /// Creates the marker.
  const NoParams();

  @override
  List<Object?> get props => [];
}
