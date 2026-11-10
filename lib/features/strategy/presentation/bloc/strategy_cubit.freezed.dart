// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strategy_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrategyState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrategyState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrategyState()';
}


}

/// @nodoc
class $StrategyStateCopyWith<$Res>  {
$StrategyStateCopyWith(StrategyState _, $Res Function(StrategyState) __);
}


/// Adds pattern-matching-related methods to [StrategyState].
extension StrategyStatePatterns on StrategyState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Strategy activeStrategy,  List<StrategyBucket> buckets,  List<Strategy> allStrategies,  List<Account> expenseAccounts,  List<Account> assetAccounts,  int monthlyIncomeMinor,  String? validationError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.activeStrategy,_that.buckets,_that.allStrategies,_that.expenseAccounts,_that.assetAccounts,_that.monthlyIncomeMinor,_that.validationError);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Strategy activeStrategy,  List<StrategyBucket> buckets,  List<Strategy> allStrategies,  List<Account> expenseAccounts,  List<Account> assetAccounts,  int monthlyIncomeMinor,  String? validationError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.activeStrategy,_that.buckets,_that.allStrategies,_that.expenseAccounts,_that.assetAccounts,_that.monthlyIncomeMinor,_that.validationError);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Strategy activeStrategy,  List<StrategyBucket> buckets,  List<Strategy> allStrategies,  List<Account> expenseAccounts,  List<Account> assetAccounts,  int monthlyIncomeMinor,  String? validationError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.activeStrategy,_that.buckets,_that.allStrategies,_that.expenseAccounts,_that.assetAccounts,_that.monthlyIncomeMinor,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements StrategyState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrategyState.initial()';
}


}




/// @nodoc


class _Loading implements StrategyState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrategyState.loading()';
}


}




/// @nodoc


class _Loaded implements StrategyState {
  const _Loaded({required this.activeStrategy, required  List<StrategyBucket> buckets, required  List<Strategy> allStrategies, required  List<Account> expenseAccounts, required  List<Account> assetAccounts, required this.monthlyIncomeMinor, this.validationError}): _buckets = buckets,_allStrategies = allStrategies,_expenseAccounts = expenseAccounts,_assetAccounts = assetAccounts;
  

 final  Strategy activeStrategy;
 final  List<StrategyBucket> _buckets;
 List<StrategyBucket> get buckets {
  if (_buckets is EqualUnmodifiableListView) return _buckets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buckets);
}

 final  List<Strategy> _allStrategies;
 List<Strategy> get allStrategies {
  if (_allStrategies is EqualUnmodifiableListView) return _allStrategies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allStrategies);
}

 final  List<Account> _expenseAccounts;
 List<Account> get expenseAccounts {
  if (_expenseAccounts is EqualUnmodifiableListView) return _expenseAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenseAccounts);
}

 final  List<Account> _assetAccounts;
 List<Account> get assetAccounts {
  if (_assetAccounts is EqualUnmodifiableListView) return _assetAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assetAccounts);
}

 final  int monthlyIncomeMinor;
 final  String? validationError;

/// Create a copy of StrategyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.activeStrategy, activeStrategy) || other.activeStrategy == activeStrategy)&&const DeepCollectionEquality().equals(other.buckets, _buckets)&&const DeepCollectionEquality().equals(other.allStrategies, _allStrategies)&&const DeepCollectionEquality().equals(other.expenseAccounts, _expenseAccounts)&&const DeepCollectionEquality().equals(other.assetAccounts, _assetAccounts)&&(identical(other.monthlyIncomeMinor, monthlyIncomeMinor) || other.monthlyIncomeMinor == monthlyIncomeMinor)&&(identical(other.validationError, validationError) || other.validationError == validationError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activeStrategy,const DeepCollectionEquality().hash(_buckets),const DeepCollectionEquality().hash(_allStrategies),const DeepCollectionEquality().hash(_expenseAccounts),const DeepCollectionEquality().hash(_assetAccounts),monthlyIncomeMinor,validationError);
}

@override
String toString() {
    return 'StrategyState.loaded(activeStrategy: $activeStrategy, buckets: $buckets, allStrategies: $allStrategies, expenseAccounts: $expenseAccounts, assetAccounts: $assetAccounts, monthlyIncomeMinor: $monthlyIncomeMinor, validationError: $validationError)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $StrategyStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 Strategy activeStrategy, List<StrategyBucket> buckets, List<Strategy> allStrategies, List<Account> expenseAccounts, List<Account> assetAccounts, int monthlyIncomeMinor, String? validationError
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of StrategyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? activeStrategy = null,Object? buckets = null,Object? allStrategies = null,Object? expenseAccounts = null,Object? assetAccounts = null,Object? monthlyIncomeMinor = null,Object? validationError = freezed,}) {
  return _then(_Loaded(
activeStrategy: null == activeStrategy ? _self.activeStrategy : activeStrategy // ignore: cast_nullable_to_non_nullable
as Strategy,buckets: null == buckets ? _self._buckets : buckets // ignore: cast_nullable_to_non_nullable
as List<StrategyBucket>,allStrategies: null == allStrategies ? _self._allStrategies : allStrategies // ignore: cast_nullable_to_non_nullable
as List<Strategy>,expenseAccounts: null == expenseAccounts ? _self._expenseAccounts : expenseAccounts // ignore: cast_nullable_to_non_nullable
as List<Account>,assetAccounts: null == assetAccounts ? _self._assetAccounts : assetAccounts // ignore: cast_nullable_to_non_nullable
as List<Account>,monthlyIncomeMinor: null == monthlyIncomeMinor ? _self.monthlyIncomeMinor : monthlyIncomeMinor // ignore: cast_nullable_to_non_nullable
as int,validationError: freezed == validationError ? _self.validationError : validationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements StrategyState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of StrategyState
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
    return 'StrategyState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $StrategyStateCopyWith<$Res> {
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

/// Create a copy of StrategyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
