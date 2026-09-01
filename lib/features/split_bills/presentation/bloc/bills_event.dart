part of 'bills_bloc.dart';

abstract class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => [];
}

class GetBillsEvent extends BillsEvent {
  const GetBillsEvent();
}

class AddBillEvent extends BillsEvent {
  final Bill bill;

  const AddBillEvent({required this.bill});

  @override
  List<Object?> get props => [bill];
}
