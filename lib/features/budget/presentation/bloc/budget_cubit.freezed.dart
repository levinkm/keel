// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BudgetState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BudgetState()';
}


}

/// @nodoc
class $BudgetStateCopyWith<$Res>  {
$BudgetStateCopyWith(BudgetState _, $Res Function(BudgetState) __);
}


/// Adds pattern-matching-related methods to [BudgetState].
extension BudgetStatePatterns on BudgetState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<String> periods,  String selectedPeriod,  BudgetPlan? plan,  Map<String, int> actuals,  Map<String, int> prevActuals,  List<Account> expenseAccounts,  int totalIncomeMinor,  List<BudgetPlan> templates,  String? selectedLineId,  List<BudgetLineSparkline> sparklines,  String activeStrategyId,  String activeStrategyName)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.periods,_that.selectedPeriod,_that.plan,_that.actuals,_that.prevActuals,_that.expenseAccounts,_that.totalIncomeMinor,_that.templates,_that.selectedLineId,_that.sparklines,_that.activeStrategyId,_that.activeStrategyName);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<String> periods,  String selectedPeriod,  BudgetPlan? plan,  Map<String, int> actuals,  Map<String, int> prevActuals,  List<Account> expenseAccounts,  int totalIncomeMinor,  List<BudgetPlan> templates,  String? selectedLineId,  List<BudgetLineSparkline> sparklines,  String activeStrategyId,  String activeStrategyName)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.periods,_that.selectedPeriod,_that.plan,_that.actuals,_that.prevActuals,_that.expenseAccounts,_that.totalIncomeMinor,_that.templates,_that.selectedLineId,_that.sparklines,_that.activeStrategyId,_that.activeStrategyName);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<String> periods,  String selectedPeriod,  BudgetPlan? plan,  Map<String, int> actuals,  Map<String, int> prevActuals,  List<Account> expenseAccounts,  int totalIncomeMinor,  List<BudgetPlan> templates,  String? selectedLineId,  List<BudgetLineSparkline> sparklines,  String activeStrategyId,  String activeStrategyName)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.periods,_that.selectedPeriod,_that.plan,_that.actuals,_that.prevActuals,_that.expenseAccounts,_that.totalIncomeMinor,_that.templates,_that.selectedLineId,_that.sparklines,_that.activeStrategyId,_that.activeStrategyName);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements BudgetState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BudgetState.initial()';
}


}




/// @nodoc


class _Loading implements BudgetState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BudgetState.loading()';
}


}




/// @nodoc


class _Loaded implements BudgetState {
  const _Loaded({required  List<String> periods, required this.selectedPeriod, required this.plan, required  Map<String, int> actuals, required  Map<String, int> prevActuals, required  List<Account> expenseAccounts, required this.totalIncomeMinor, required  List<BudgetPlan> templates, this.selectedLineId, required  List<BudgetLineSparkline> sparklines, required this.activeStrategyId, required this.activeStrategyName}): _periods = periods,_actuals = actuals,_prevActuals = prevActuals,_expenseAccounts = expenseAccounts,_templates = templates,_sparklines = sparklines;
  

 final  List<String> _periods;
 List<String> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}

 final  String selectedPeriod;
 final  BudgetPlan? plan;
 final  Map<String, int> _actuals;
 Map<String, int> get actuals {
  if (_actuals is EqualUnmodifiableMapView) return _actuals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_actuals);
}

 final  Map<String, int> _prevActuals;
 Map<String, int> get prevActuals {
  if (_prevActuals is EqualUnmodifiableMapView) return _prevActuals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_prevActuals);
}

 final  List<Account> _expenseAccounts;
 List<Account> get expenseAccounts {
  if (_expenseAccounts is EqualUnmodifiableListView) return _expenseAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenseAccounts);
}

 final  int totalIncomeMinor;
 final  List<BudgetPlan> _templates;
 List<BudgetPlan> get templates {
  if (_templates is EqualUnmodifiableListView) return _templates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_templates);
}

 final  String? selectedLineId;
 final  List<BudgetLineSparkline> _sparklines;
 List<BudgetLineSparkline> get sparklines {
  if (_sparklines is EqualUnmodifiableListView) return _sparklines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sparklines);
}

 final  String activeStrategyId;
 final  String activeStrategyName;

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.periods, _periods)&&(identical(other.selectedPeriod, selectedPeriod) || other.selectedPeriod == selectedPeriod)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other.actuals, _actuals)&&const DeepCollectionEquality().equals(other.prevActuals, _prevActuals)&&const DeepCollectionEquality().equals(other.expenseAccounts, _expenseAccounts)&&(identical(other.totalIncomeMinor, totalIncomeMinor) || other.totalIncomeMinor == totalIncomeMinor)&&const DeepCollectionEquality().equals(other.templates, _templates)&&(identical(other.selectedLineId, selectedLineId) || other.selectedLineId == selectedLineId)&&const DeepCollectionEquality().equals(other.sparklines, _sparklines)&&(identical(other.activeStrategyId, activeStrategyId) || other.activeStrategyId == activeStrategyId)&&(identical(other.activeStrategyName, activeStrategyName) || other.activeStrategyName == activeStrategyName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_periods),selectedPeriod,plan,const DeepCollectionEquality().hash(_actuals),const DeepCollectionEquality().hash(_prevActuals),const DeepCollectionEquality().hash(_expenseAccounts),totalIncomeMinor,const DeepCollectionEquality().hash(_templates),selectedLineId,const DeepCollectionEquality().hash(_sparklines),activeStrategyId,activeStrategyName);
}

@override
String toString() {
    return 'BudgetState.loaded(periods: $periods, selectedPeriod: $selectedPeriod, plan: $plan, actuals: $actuals, prevActuals: $prevActuals, expenseAccounts: $expenseAccounts, totalIncomeMinor: $totalIncomeMinor, templates: $templates, selectedLineId: $selectedLineId, sparklines: $sparklines, activeStrategyId: $activeStrategyId, activeStrategyName: $activeStrategyName)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $BudgetStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<String> periods, String selectedPeriod, BudgetPlan? plan, Map<String, int> actuals, Map<String, int> prevActuals, List<Account> expenseAccounts, int totalIncomeMinor, List<BudgetPlan> templates, String? selectedLineId, List<BudgetLineSparkline> sparklines, String activeStrategyId, String activeStrategyName
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? periods = null,Object? selectedPeriod = null,Object? plan = freezed,Object? actuals = null,Object? prevActuals = null,Object? expenseAccounts = null,Object? totalIncomeMinor = null,Object? templates = null,Object? selectedLineId = freezed,Object? sparklines = null,Object? activeStrategyId = null,Object? activeStrategyName = null,}) {
  return _then(_Loaded(
periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<String>,selectedPeriod: null == selectedPeriod ? _self.selectedPeriod : selectedPeriod // ignore: cast_nullable_to_non_nullable
as String,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as BudgetPlan?,actuals: null == actuals ? _self._actuals : actuals // ignore: cast_nullable_to_non_nullable
as Map<String, int>,prevActuals: null == prevActuals ? _self._prevActuals : prevActuals // ignore: cast_nullable_to_non_nullable
as Map<String, int>,expenseAccounts: null == expenseAccounts ? _self._expenseAccounts : expenseAccounts // ignore: cast_nullable_to_non_nullable
as List<Account>,totalIncomeMinor: null == totalIncomeMinor ? _self.totalIncomeMinor : totalIncomeMinor // ignore: cast_nullable_to_non_nullable
as int,templates: null == templates ? _self._templates : templates // ignore: cast_nullable_to_non_nullable
as List<BudgetPlan>,selectedLineId: freezed == selectedLineId ? _self.selectedLineId : selectedLineId // ignore: cast_nullable_to_non_nullable
as String?,sparklines: null == sparklines ? _self._sparklines : sparklines // ignore: cast_nullable_to_non_nullable
as List<BudgetLineSparkline>,activeStrategyId: null == activeStrategyId ? _self.activeStrategyId : activeStrategyId // ignore: cast_nullable_to_non_nullable
as String,activeStrategyName: null == activeStrategyName ? _self.activeStrategyName : activeStrategyName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Error implements BudgetState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of BudgetState
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
    return 'BudgetState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BudgetStateCopyWith<$Res> {
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

/// Create a copy of BudgetState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
