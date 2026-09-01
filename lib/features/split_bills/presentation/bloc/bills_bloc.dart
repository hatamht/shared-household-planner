import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/bill.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/add_bill_usecase.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';

part 'bills_event.dart';
part 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final GetBillsUseCase getBillsUseCase;
  final AddBillUseCase addBillUseCase;

  BillsBloc({
    required this.getBillsUseCase,
    required this.addBillUseCase,
  }) : super(BillsInitial()) {
    on<GetBillsEvent>(_onGetBills);
    on<AddBillEvent>(_onAddBill);
  }

  Future<void> _onGetBills(
    GetBillsEvent event,
    Emitter<BillsState> emit,
  ) async {
    emit(BillsLoading());
    final result = await getBillsUseCase(NoParams());
    result.fold(
      (failure) => emit(BillsError(failure: failure)),
      (bills) => emit(BillsLoaded(bills: bills)),
    );
  }

  Future<void> _onAddBill(
    AddBillEvent event,
    Emitter<BillsState> emit,
  ) async {
    final currentState = state;
    if (currentState is BillsLoaded) {
      emit(AddBillLoading());
      final result = await addBillUseCase(AddBillParams(bill: event.bill));
      result.fold(
        (failure) => emit(AddBillError(failure: failure)),
        (_) {
          // Reload bills after adding
          add(GetBillsEvent());
        },
      );
    }
  }
}
