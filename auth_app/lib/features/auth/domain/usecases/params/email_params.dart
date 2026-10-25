import 'package:equatable/equatable.dart';

/// Email-only input for use cases such as resending confirmation.
class EmailParams extends Equatable {
  /// Creates the params.
  const EmailParams({required this.email});

  /// Email address.
  final String email;

  @override
  List<Object?> get props => [email];
}
