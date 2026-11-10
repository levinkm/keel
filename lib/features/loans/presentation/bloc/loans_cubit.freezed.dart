// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'loans_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoansState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoansState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'LoansState()';
}


}

/// @nodoc
class $LoansStateCopyWith<$Res>  {
$LoansStateCopyWith(LoansState _, $Res Function(LoansState) __);
}


/// Adds pattern-matching-related methods to [LoansState].
extension LoansStatePatterns on LoansState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Loan> loans,  Map<String, LoanSummary> summaries,  LoanFilter filter,  String? selectedLoanId,  List<LoanEvent> selectedEvents,  int totalBorrowedOutstandingMinor,  int totalLentOutstandingMinor,  int monthlyBurdenMinor,  DateTime? nextDueDate,  String? validationError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.loans,_that.summaries,_that.filter,_that.selectedLoanId,_that.selectedEvents,_that.totalBorrowedOutstandingMinor,_that.totalLentOutstandingMinor,_that.monthlyBurdenMinor,_that.nextDueDate,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Loan> loans,  Map<String, LoanSummary> summaries,  LoanFilter filter,  String? selectedLoanId,  List<LoanEvent> selectedEvents,  int totalBorrowedOutstandingMinor,  int totalLentOutstandingMinor,  int monthlyBurdenMinor,  DateTime? nextDueDate,  String? validationError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.loans,_that.summaries,_that.filter,_that.selectedLoanId,_that.selectedEvents,_that.totalBorrowedOutstandingMinor,_that.totalLentOutstandingMinor,_that.monthlyBurdenMinor,_that.nextDueDate,_that.validationError);case _Error():
return error(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Loan> loans,  Map<String, LoanSummary> summaries,  LoanFilter filter,  String? selectedLoanId,  List<LoanEvent> selectedEvents,  int totalBorrowedOutstandingMinor,  int totalLentOutstandingMinor,  int monthlyBurdenMinor,  DateTime? nextDueDate,  String? validationError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.loans,_that.summaries,_that.filter,_that.selectedLoanId,_that.selectedEvents,_that.totalBorrowedOutstandingMinor,_that.totalLentOutstandingMinor,_that.monthlyBurdenMinor,_that.nextDueDate,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements LoansState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'LoansState.initial()';
}


}




/// @nodoc


class _Loading implements LoansState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'LoansState.loading()';
}


}




/// @nodoc


class _Loaded implements LoansState {
  const _Loaded({required  List<Loan> loans, required  Map<String, LoanSummary> summaries, required this.filter, this.selectedLoanId, required  List<LoanEvent> selectedEvents, required this.totalBorrowedOutstandingMinor, required this.totalLentOutstandingMinor, required this.monthlyBurdenMinor, required this.nextDueDate, this.validationError}): _loans = loans,_summaries = summaries,_selectedEvents = selectedEvents;
  

 final  List<Loan> _loans;
 List<Loan> get loans {
  if (_loans is EqualUnmodifiableListView) return _loans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loans);
}

 final  Map<String, LoanSummary> _summaries;
 Map<String, LoanSummary> get summaries {
  if (_summaries is EqualUnmodifiableMapView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_summaries);
}

 final  LoanFilter filter;
 final  String? selectedLoanId;
 final  List<LoanEvent> _selectedEvents;
 List<LoanEvent> get selectedEvents {
  if (_selectedEvents is EqualUnmodifiableListView) return _selectedEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedEvents);
}

 final  int totalBorrowedOutstandingMinor;
 final  int totalLentOutstandingMinor;
 final  int monthlyBurdenMinor;
 final  DateTime? nextDueDate;
 final  String? validationError;

/// Create a copy of LoansState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.loans, _loans)&&const DeepCollectionEquality().equals(other.summaries, _summaries)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.selectedLoanId, selectedLoanId) || other.selectedLoanId == selectedLoanId)&&const DeepCollectionEquality().equals(other.selectedEvents, _selectedEvents)&&(identical(other.totalBorrowedOutstandingMinor, totalBorrowedOutstandingMinor) || other.totalBorrowedOutstandingMinor == totalBorrowedOutstandingMinor)&&(identical(other.totalLentOutstandingMinor, totalLentOutstandingMinor) || other.totalLentOutstandingMinor == totalLentOutstandingMinor)&&(identical(other.monthlyBurdenMinor, monthlyBurdenMinor) || other.monthlyBurdenMinor == monthlyBurdenMinor)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.validationError, validationError) || other.validationError == validationError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_loans),const DeepCollectionEquality().hash(_summaries),filter,selectedLoanId,const DeepCollectionEquality().hash(_selectedEvents),totalBorrowedOutstandingMinor,totalLentOutstandingMinor,monthlyBurdenMinor,nextDueDate,validationError);
}

@override
String toString() {
    return 'LoansState.loaded(loans: $loans, summaries: $summaries, filter: $filter, selectedLoanId: $selectedLoanId, selectedEvents: $selectedEvents, totalBorrowedOutstandingMinor: $totalBorrowedOutstandingMinor, totalLentOutstandingMinor: $totalLentOutstandingMinor, monthlyBurdenMinor: $monthlyBurdenMinor, nextDueDate: $nextDueDate, validationError: $validationError)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $LoansStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Loan> loans, Map<String, LoanSummary> summaries, LoanFilter filter, String? selectedLoanId, List<LoanEvent> selectedEvents, int totalBorrowedOutstandingMinor, int totalLentOutstandingMinor, int monthlyBurdenMinor, DateTime? nextDueDate, String? validationError
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of LoansState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? loans = null,Object? summaries = null,Object? filter = null,Object? selectedLoanId = freezed,Object? selectedEvents = null,Object? totalBorrowedOutstandingMinor = null,Object? totalLentOutstandingMinor = null,Object? monthlyBurdenMinor = null,Object? nextDueDate = freezed,Object? validationError = freezed,}) {
  return _then(_Loaded(
loans: null == loans ? _self._loans : loans // ignore: cast_nullable_to_non_nullable
as List<Loan>,summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<String, LoanSummary>,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as LoanFilter,selectedLoanId: freezed == selectedLoanId ? _self.selectedLoanId : selectedLoanId // ignore: cast_nullable_to_non_nullable
as String?,selectedEvents: null == selectedEvents ? _self._selectedEvents : selectedEvents // ignore: cast_nullable_to_non_nullable
as List<LoanEvent>,totalBorrowedOutstandingMinor: null == totalBorrowedOutstandingMinor ? _self.totalBorrowedOutstandingMinor : totalBorrowedOutstandingMinor // ignore: cast_nullable_to_non_nullable
as int,totalLentOutstandingMinor: null == totalLentOutstandingMinor ? _self.totalLentOutstandingMinor : totalLentOutstandingMinor // ignore: cast_nullable_to_non_nullable
as int,monthlyBurdenMinor: null == monthlyBurdenMinor ? _self.monthlyBurdenMinor : monthlyBurdenMinor // ignore: cast_nullable_to_non_nullable
as int,nextDueDate: freezed == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,validationError: freezed == validationError ? _self.validationError : validationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements LoansState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of LoansState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'LoansState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $LoansStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of LoansState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
