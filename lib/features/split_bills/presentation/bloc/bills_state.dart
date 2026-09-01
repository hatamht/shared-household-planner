part of 'bills_bloc.dart';

abstract class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => [];
}

class BillsInitial extends BillsState {
  const BillsInitial();
}

class BillsLoading extends BillsState {
  const BillsLoading();
}

class BillsLoaded extends BillsState {
  final List<Bill> bills;

  const BillsLoaded({required this.bills});

  @override
  List<Object?> get props => [bills];
}

class BillsError extends BillsState {
  final Failure failure;

  const BillsError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class AddBillLoading extends BillsState {
  const AddBillLoading();
}

class AddBillError extends BillsState {
  final Failure failure;

  const AddBillError({required this.failure});

  @override
  List<Object?> get props => [failure];
}
