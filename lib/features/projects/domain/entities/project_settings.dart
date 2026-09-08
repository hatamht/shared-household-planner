import 'package:equatable/equatable.dart';

/// Project settings containing currency configuration.
class ProjectSettings extends Equatable {
  final String defaultCurrency;
  final List<String> availableCurrencies;

  const ProjectSettings({
    this.defaultCurrency = 'VND',
    this.availableCurrencies = const [
      'VND',
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'SGD',
      'THB',
    ],
  });

  @override
  List<Object?> get props => [defaultCurrency, availableCurrencies];
}
