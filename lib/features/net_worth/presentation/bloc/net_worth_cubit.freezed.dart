// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_worth_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NetWorthState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NetWorthState()';
}


}

/// @nodoc
class $NetWorthStateCopyWith<$Res>  {
$NetWorthStateCopyWith(NetWorthState _, $Res Function(NetWorthState) __);
}


/// Adds pattern-matching-related methods to [NetWorthState].
extension NetWorthStatePatterns on NetWorthState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( int netWorthMinor,  int totalAssetsMinor,  int totalLiabilitiesMinor,  int liquidMinor,  int totalCashMinor,  int totalPhysicalMinor,  int totalInvestmentsMinor,  List<AccountBalance> cashAccounts,  List<Asset> physicalAssets,  List<Holding> activeHoldings,  List<LoanBalance> loanBalances)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.netWorthMinor,_that.totalAssetsMinor,_that.totalLiabilitiesMinor,_that.liquidMinor,_that.totalCashMinor,_that.totalPhysicalMinor,_that.totalInvestmentsMinor,_that.cashAccounts,_that.physicalAssets,_that.activeHoldings,_that.loanBalances);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( int netWorthMinor,  int totalAssetsMinor,  int totalLiabilitiesMinor,  int liquidMinor,  int totalCashMinor,  int totalPhysicalMinor,  int totalInvestmentsMinor,  List<AccountBalance> cashAccounts,  List<Asset> physicalAssets,  List<Holding> activeHoldings,  List<LoanBalance> loanBalances)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.netWorthMinor,_that.totalAssetsMinor,_that.totalLiabilitiesMinor,_that.liquidMinor,_that.totalCashMinor,_that.totalPhysicalMinor,_that.totalInvestmentsMinor,_that.cashAccounts,_that.physicalAssets,_that.activeHoldings,_that.loanBalances);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( int netWorthMinor,  int totalAssetsMinor,  int totalLiabilitiesMinor,  int liquidMinor,  int totalCashMinor,  int totalPhysicalMinor,  int totalInvestmentsMinor,  List<AccountBalance> cashAccounts,  List<Asset> physicalAssets,  List<Holding> activeHoldings,  List<LoanBalance> loanBalances)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.netWorthMinor,_that.totalAssetsMinor,_that.totalLiabilitiesMinor,_that.liquidMinor,_that.totalCashMinor,_that.totalPhysicalMinor,_that.totalInvestmentsMinor,_that.cashAccounts,_that.physicalAssets,_that.activeHoldings,_that.loanBalances);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements NetWorthState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NetWorthState.initial()';
}


}




/// @nodoc


class _Loading implements NetWorthState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NetWorthState.loading()';
}


}




/// @nodoc


class _Loaded implements NetWorthState {
  const _Loaded({required this.netWorthMinor, required this.totalAssetsMinor, required this.totalLiabilitiesMinor, required this.liquidMinor, required this.totalCashMinor, required this.totalPhysicalMinor, required this.totalInvestmentsMinor, required  List<AccountBalance> cashAccounts, required  List<Asset> physicalAssets, required  List<Holding> activeHoldings, required  List<LoanBalance> loanBalances}): _cashAccounts = cashAccounts,_physicalAssets = physicalAssets,_activeHoldings = activeHoldings,_loanBalances = loanBalances;
  

 final  int netWorthMinor;
 final  int totalAssetsMinor;
 final  int totalLiabilitiesMinor;
 final  int liquidMinor;
 final  int totalCashMinor;
 final  int totalPhysicalMinor;
 final  int totalInvestmentsMinor;
 final  List<AccountBalance> _cashAccounts;
 List<AccountBalance> get cashAccounts {
  if (_cashAccounts is EqualUnmodifiableListView) return _cashAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cashAccounts);
}

 final  List<Asset> _physicalAssets;
 List<Asset> get physicalAssets {
  if (_physicalAssets is EqualUnmodifiableListView) return _physicalAssets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_physicalAssets);
}

 final  List<Holding> _activeHoldings;
 List<Holding> get activeHoldings {
  if (_activeHoldings is EqualUnmodifiableListView) return _activeHoldings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeHoldings);
}

 final  List<LoanBalance> _loanBalances;
 List<LoanBalance> get loanBalances {
  if (_loanBalances is EqualUnmodifiableListView) return _loanBalances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loanBalances);
}


/// Create a copy of NetWorthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.netWorthMinor, netWorthMinor) || other.netWorthMinor == netWorthMinor)&&(identical(other.totalAssetsMinor, totalAssetsMinor) || other.totalAssetsMinor == totalAssetsMinor)&&(identical(other.totalLiabilitiesMinor, totalLiabilitiesMinor) || other.totalLiabilitiesMinor == totalLiabilitiesMinor)&&(identical(other.liquidMinor, liquidMinor) || other.liquidMinor == liquidMinor)&&(identical(other.totalCashMinor, totalCashMinor) || other.totalCashMinor == totalCashMinor)&&(identical(other.totalPhysicalMinor, totalPhysicalMinor) || other.totalPhysicalMinor == totalPhysicalMinor)&&(identical(other.totalInvestmentsMinor, totalInvestmentsMinor) || other.totalInvestmentsMinor == totalInvestmentsMinor)&&const DeepCollectionEquality().equals(other.cashAccounts, _cashAccounts)&&const DeepCollectionEquality().equals(other.physicalAssets, _physicalAssets)&&const DeepCollectionEquality().equals(other.activeHoldings, _activeHoldings)&&const DeepCollectionEquality().equals(other.loanBalances, _loanBalances));
}


@override
int get hashCode {
    return Object.hash(runtimeType,netWorthMinor,totalAssetsMinor,totalLiabilitiesMinor,liquidMinor,totalCashMinor,totalPhysicalMinor,totalInvestmentsMinor,const DeepCollectionEquality().hash(_cashAccounts),const DeepCollectionEquality().hash(_physicalAssets),const DeepCollectionEquality().hash(_activeHoldings),const DeepCollectionEquality().hash(_loanBalances));
}

@override
String toString() {
    return 'NetWorthState.loaded(netWorthMinor: $netWorthMinor, totalAssetsMinor: $totalAssetsMinor, totalLiabilitiesMinor: $totalLiabilitiesMinor, liquidMinor: $liquidMinor, totalCashMinor: $totalCashMinor, totalPhysicalMinor: $totalPhysicalMinor, totalInvestmentsMinor: $totalInvestmentsMinor, cashAccounts: $cashAccounts, physicalAssets: $physicalAssets, activeHoldings: $activeHoldings, loanBalances: $loanBalances)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $NetWorthStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 int netWorthMinor, int totalAssetsMinor, int totalLiabilitiesMinor, int liquidMinor, int totalCashMinor, int totalPhysicalMinor, int totalInvestmentsMinor, List<AccountBalance> cashAccounts, List<Asset> physicalAssets, List<Holding> activeHoldings, List<LoanBalance> loanBalances
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of NetWorthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? netWorthMinor = null,Object? totalAssetsMinor = null,Object? totalLiabilitiesMinor = null,Object? liquidMinor = null,Object? totalCashMinor = null,Object? totalPhysicalMinor = null,Object? totalInvestmentsMinor = null,Object? cashAccounts = null,Object? physicalAssets = null,Object? activeHoldings = null,Object? loanBalances = null,}) {
  return _then(_Loaded(
netWorthMinor: null == netWorthMinor ? _self.netWorthMinor : netWorthMinor // ignore: cast_nullable_to_non_nullable
as int,totalAssetsMinor: null == totalAssetsMinor ? _self.totalAssetsMinor : totalAssetsMinor // ignore: cast_nullable_to_non_nullable
as int,totalLiabilitiesMinor: null == totalLiabilitiesMinor ? _self.totalLiabilitiesMinor : totalLiabilitiesMinor // ignore: cast_nullable_to_non_nullable
as int,liquidMinor: null == liquidMinor ? _self.liquidMinor : liquidMinor // ignore: cast_nullable_to_non_nullable
as int,totalCashMinor: null == totalCashMinor ? _self.totalCashMinor : totalCashMinor // ignore: cast_nullable_to_non_nullable
as int,totalPhysicalMinor: null == totalPhysicalMinor ? _self.totalPhysicalMinor : totalPhysicalMinor // ignore: cast_nullable_to_non_nullable
as int,totalInvestmentsMinor: null == totalInvestmentsMinor ? _self.totalInvestmentsMinor : totalInvestmentsMinor // ignore: cast_nullable_to_non_nullable
as int,cashAccounts: null == cashAccounts ? _self._cashAccounts : cashAccounts // ignore: cast_nullable_to_non_nullable
as List<AccountBalance>,physicalAssets: null == physicalAssets ? _self._physicalAssets : physicalAssets // ignore: cast_nullable_to_non_nullable
as List<Asset>,activeHoldings: null == activeHoldings ? _self._activeHoldings : activeHoldings // ignore: cast_nullable_to_non_nullable
as List<Holding>,loanBalances: null == loanBalances ? _self._loanBalances : loanBalances // ignore: cast_nullable_to_non_nullable
as List<LoanBalance>,
  ));
}


}

/// @nodoc


class _Error implements NetWorthState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of NetWorthState
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
    return 'NetWorthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $NetWorthStateCopyWith<$Res> {
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

/// Create a copy of NetWorthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
