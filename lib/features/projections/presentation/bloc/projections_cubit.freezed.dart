// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projections_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectionsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionsState()';
}


}

/// @nodoc
class $ProjectionsStateCopyWith<$Res>  {
$ProjectionsStateCopyWith(ProjectionsState _, $Res Function(ProjectionsState) __);
}


/// Adds pattern-matching-related methods to [ProjectionsState].
extension ProjectionsStatePatterns on ProjectionsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( int currentNetWorthMinor,  int monthlyIncomeMinor,  int monthlyExpensesMinor,  int incomeStreamCount,  bool expensesFromBudget,  List<LoanProjection> loanSchedules,  List<ProjectionPoint> projectionPoints,  int projectionMonths,  double incomeGrowthPct,  double expenseGrowthPct,  int savingsTargetMinor)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.currentNetWorthMinor,_that.monthlyIncomeMinor,_that.monthlyExpensesMinor,_that.incomeStreamCount,_that.expensesFromBudget,_that.loanSchedules,_that.projectionPoints,_that.projectionMonths,_that.incomeGrowthPct,_that.expenseGrowthPct,_that.savingsTargetMinor);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( int currentNetWorthMinor,  int monthlyIncomeMinor,  int monthlyExpensesMinor,  int incomeStreamCount,  bool expensesFromBudget,  List<LoanProjection> loanSchedules,  List<ProjectionPoint> projectionPoints,  int projectionMonths,  double incomeGrowthPct,  double expenseGrowthPct,  int savingsTargetMinor)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.currentNetWorthMinor,_that.monthlyIncomeMinor,_that.monthlyExpensesMinor,_that.incomeStreamCount,_that.expensesFromBudget,_that.loanSchedules,_that.projectionPoints,_that.projectionMonths,_that.incomeGrowthPct,_that.expenseGrowthPct,_that.savingsTargetMinor);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( int currentNetWorthMinor,  int monthlyIncomeMinor,  int monthlyExpensesMinor,  int incomeStreamCount,  bool expensesFromBudget,  List<LoanProjection> loanSchedules,  List<ProjectionPoint> projectionPoints,  int projectionMonths,  double incomeGrowthPct,  double expenseGrowthPct,  int savingsTargetMinor)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.currentNetWorthMinor,_that.monthlyIncomeMinor,_that.monthlyExpensesMinor,_that.incomeStreamCount,_that.expensesFromBudget,_that.loanSchedules,_that.projectionPoints,_that.projectionMonths,_that.incomeGrowthPct,_that.expenseGrowthPct,_that.savingsTargetMinor);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements ProjectionsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionsState.initial()';
}


}




/// @nodoc


class _Loading implements ProjectionsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionsState.loading()';
}


}




/// @nodoc


class _Loaded implements ProjectionsState {
  const _Loaded({required this.currentNetWorthMinor, required this.monthlyIncomeMinor, required this.monthlyExpensesMinor, required this.incomeStreamCount, required this.expensesFromBudget, required  List<LoanProjection> loanSchedules, required  List<ProjectionPoint> projectionPoints, required this.projectionMonths, required this.incomeGrowthPct, required this.expenseGrowthPct, required this.savingsTargetMinor}): _loanSchedules = loanSchedules,_projectionPoints = projectionPoints;
  

 final  int currentNetWorthMinor;
 final  int monthlyIncomeMinor;
 final  int monthlyExpensesMinor;
 final  int incomeStreamCount;
 final  bool expensesFromBudget;
 final  List<LoanProjection> _loanSchedules;
 List<LoanProjection> get loanSchedules {
  if (_loanSchedules is EqualUnmodifiableListView) return _loanSchedules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loanSchedules);
}

 final  List<ProjectionPoint> _projectionPoints;
 List<ProjectionPoint> get projectionPoints {
  if (_projectionPoints is EqualUnmodifiableListView) return _projectionPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projectionPoints);
}

 final  int projectionMonths;
 final  double incomeGrowthPct;
 final  double expenseGrowthPct;
 final  int savingsTargetMinor;

/// Create a copy of ProjectionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.currentNetWorthMinor, currentNetWorthMinor) || other.currentNetWorthMinor == currentNetWorthMinor)&&(identical(other.monthlyIncomeMinor, monthlyIncomeMinor) || other.monthlyIncomeMinor == monthlyIncomeMinor)&&(identical(other.monthlyExpensesMinor, monthlyExpensesMinor) || other.monthlyExpensesMinor == monthlyExpensesMinor)&&(identical(other.incomeStreamCount, incomeStreamCount) || other.incomeStreamCount == incomeStreamCount)&&(identical(other.expensesFromBudget, expensesFromBudget) || other.expensesFromBudget == expensesFromBudget)&&const DeepCollectionEquality().equals(other.loanSchedules, _loanSchedules)&&const DeepCollectionEquality().equals(other.projectionPoints, _projectionPoints)&&(identical(other.projectionMonths, projectionMonths) || other.projectionMonths == projectionMonths)&&(identical(other.incomeGrowthPct, incomeGrowthPct) || other.incomeGrowthPct == incomeGrowthPct)&&(identical(other.expenseGrowthPct, expenseGrowthPct) || other.expenseGrowthPct == expenseGrowthPct)&&(identical(other.savingsTargetMinor, savingsTargetMinor) || other.savingsTargetMinor == savingsTargetMinor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,currentNetWorthMinor,monthlyIncomeMinor,monthlyExpensesMinor,incomeStreamCount,expensesFromBudget,const DeepCollectionEquality().hash(_loanSchedules),const DeepCollectionEquality().hash(_projectionPoints),projectionMonths,incomeGrowthPct,expenseGrowthPct,savingsTargetMinor);
}

@override
String toString() {
    return 'ProjectionsState.loaded(currentNetWorthMinor: $currentNetWorthMinor, monthlyIncomeMinor: $monthlyIncomeMinor, monthlyExpensesMinor: $monthlyExpensesMinor, incomeStreamCount: $incomeStreamCount, expensesFromBudget: $expensesFromBudget, loanSchedules: $loanSchedules, projectionPoints: $projectionPoints, projectionMonths: $projectionMonths, incomeGrowthPct: $incomeGrowthPct, expenseGrowthPct: $expenseGrowthPct, savingsTargetMinor: $savingsTargetMinor)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $ProjectionsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 int currentNetWorthMinor, int monthlyIncomeMinor, int monthlyExpensesMinor, int incomeStreamCount, bool expensesFromBudget, List<LoanProjection> loanSchedules, List<ProjectionPoint> projectionPoints, int projectionMonths, double incomeGrowthPct, double expenseGrowthPct, int savingsTargetMinor
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of ProjectionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currentNetWorthMinor = null,Object? monthlyIncomeMinor = null,Object? monthlyExpensesMinor = null,Object? incomeStreamCount = null,Object? expensesFromBudget = null,Object? loanSchedules = null,Object? projectionPoints = null,Object? projectionMonths = null,Object? incomeGrowthPct = null,Object? expenseGrowthPct = null,Object? savingsTargetMinor = null,}) {
  return _then(_Loaded(
currentNetWorthMinor: null == currentNetWorthMinor ? _self.currentNetWorthMinor : currentNetWorthMinor // ignore: cast_nullable_to_non_nullable
as int,monthlyIncomeMinor: null == monthlyIncomeMinor ? _self.monthlyIncomeMinor : monthlyIncomeMinor // ignore: cast_nullable_to_non_nullable
as int,monthlyExpensesMinor: null == monthlyExpensesMinor ? _self.monthlyExpensesMinor : monthlyExpensesMinor // ignore: cast_nullable_to_non_nullable
as int,incomeStreamCount: null == incomeStreamCount ? _self.incomeStreamCount : incomeStreamCount // ignore: cast_nullable_to_non_nullable
as int,expensesFromBudget: null == expensesFromBudget ? _self.expensesFromBudget : expensesFromBudget // ignore: cast_nullable_to_non_nullable
as bool,loanSchedules: null == loanSchedules ? _self._loanSchedules : loanSchedules // ignore: cast_nullable_to_non_nullable
as List<LoanProjection>,projectionPoints: null == projectionPoints ? _self._projectionPoints : projectionPoints // ignore: cast_nullable_to_non_nullable
as List<ProjectionPoint>,projectionMonths: null == projectionMonths ? _self.projectionMonths : projectionMonths // ignore: cast_nullable_to_non_nullable
as int,incomeGrowthPct: null == incomeGrowthPct ? _self.incomeGrowthPct : incomeGrowthPct // ignore: cast_nullable_to_non_nullable
as double,expenseGrowthPct: null == expenseGrowthPct ? _self.expenseGrowthPct : expenseGrowthPct // ignore: cast_nullable_to_non_nullable
as double,savingsTargetMinor: null == savingsTargetMinor ? _self.savingsTargetMinor : savingsTargetMinor // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Error implements ProjectionsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of ProjectionsState
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
    return 'ProjectionsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $ProjectionsStateCopyWith<$Res> {
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

/// Create a copy of ProjectionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
