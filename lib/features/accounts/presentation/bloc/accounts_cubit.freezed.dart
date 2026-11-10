// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounts_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountsState()';
}


}

/// @nodoc
class $AccountsStateCopyWith<$Res>  {
$AccountsStateCopyWith(AccountsState _, $Res Function(AccountsState) __);
}


/// Adds pattern-matching-related methods to [AccountsState].
extension AccountsStatePatterns on AccountsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Account> accounts,  Map<String, int> balances,  AccountFilter filter,  String? selectedAccountId,  List<JournalEntry> selectedHistory,  List<MonthlyBalance> selectedSparkline)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.accounts,_that.balances,_that.filter,_that.selectedAccountId,_that.selectedHistory,_that.selectedSparkline);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Account> accounts,  Map<String, int> balances,  AccountFilter filter,  String? selectedAccountId,  List<JournalEntry> selectedHistory,  List<MonthlyBalance> selectedSparkline)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.accounts,_that.balances,_that.filter,_that.selectedAccountId,_that.selectedHistory,_that.selectedSparkline);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Account> accounts,  Map<String, int> balances,  AccountFilter filter,  String? selectedAccountId,  List<JournalEntry> selectedHistory,  List<MonthlyBalance> selectedSparkline)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.accounts,_that.balances,_that.filter,_that.selectedAccountId,_that.selectedHistory,_that.selectedSparkline);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements AccountsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountsState.initial()';
}


}




/// @nodoc


class _Loading implements AccountsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountsState.loading()';
}


}




/// @nodoc


class _Loaded implements AccountsState {
  const _Loaded({required  List<Account> accounts, required  Map<String, int> balances, required this.filter, this.selectedAccountId, required  List<JournalEntry> selectedHistory, required  List<MonthlyBalance> selectedSparkline}): _accounts = accounts,_balances = balances,_selectedHistory = selectedHistory,_selectedSparkline = selectedSparkline;
  

 final  List<Account> _accounts;
 List<Account> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  Map<String, int> _balances;
 Map<String, int> get balances {
  if (_balances is EqualUnmodifiableMapView) return _balances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_balances);
}

 final  AccountFilter filter;
 final  String? selectedAccountId;
 final  List<JournalEntry> _selectedHistory;
 List<JournalEntry> get selectedHistory {
  if (_selectedHistory is EqualUnmodifiableListView) return _selectedHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedHistory);
}

 final  List<MonthlyBalance> _selectedSparkline;
 List<MonthlyBalance> get selectedSparkline {
  if (_selectedSparkline is EqualUnmodifiableListView) return _selectedSparkline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedSparkline);
}


/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.balances, _balances)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.selectedAccountId, selectedAccountId) || other.selectedAccountId == selectedAccountId)&&const DeepCollectionEquality().equals(other.selectedHistory, _selectedHistory)&&const DeepCollectionEquality().equals(other.selectedSparkline, _selectedSparkline));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_balances),filter,selectedAccountId,const DeepCollectionEquality().hash(_selectedHistory),const DeepCollectionEquality().hash(_selectedSparkline));
}

@override
String toString() {
    return 'AccountsState.loaded(accounts: $accounts, balances: $balances, filter: $filter, selectedAccountId: $selectedAccountId, selectedHistory: $selectedHistory, selectedSparkline: $selectedSparkline)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $AccountsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Account> accounts, Map<String, int> balances, AccountFilter filter, String? selectedAccountId, List<JournalEntry> selectedHistory, List<MonthlyBalance> selectedSparkline
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accounts = null,Object? balances = null,Object? filter = null,Object? selectedAccountId = freezed,Object? selectedHistory = null,Object? selectedSparkline = null,}) {
  return _then(_Loaded(
accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<Account>,balances: null == balances ? _self._balances : balances // ignore: cast_nullable_to_non_nullable
as Map<String, int>,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AccountFilter,selectedAccountId: freezed == selectedAccountId ? _self.selectedAccountId : selectedAccountId // ignore: cast_nullable_to_non_nullable
as String?,selectedHistory: null == selectedHistory ? _self._selectedHistory : selectedHistory // ignore: cast_nullable_to_non_nullable
as List<JournalEntry>,selectedSparkline: null == selectedSparkline ? _self._selectedSparkline : selectedSparkline // ignore: cast_nullable_to_non_nullable
as List<MonthlyBalance>,
  ));
}


}

/// @nodoc


class _Error implements AccountsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of AccountsState
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
    return 'AccountsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $AccountsStateCopyWith<$Res> {
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

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
