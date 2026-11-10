// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reports_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReportsState()';
}


}

/// @nodoc
class $ReportsStateCopyWith<$Res>  {
$ReportsStateCopyWith(ReportsState _, $Res Function(ReportsState) __);
}


/// Adds pattern-matching-related methods to [ReportsState].
extension ReportsStatePatterns on ReportsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<MonthlyPnL> monthlyPnL,  List<ExpenseCategory> expenseCategories,  List<PayeeRow> topPayees,  List<BudgetVsActual> budgetVsActual,  List<LoanReportRow> loanRows,  List<Holding> holdings,  List<Asset> assets,  List<Account> accounts,  List<JournalEntry> allEntries,  Map<String, int> accountBalances)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.monthlyPnL,_that.expenseCategories,_that.topPayees,_that.budgetVsActual,_that.loanRows,_that.holdings,_that.assets,_that.accounts,_that.allEntries,_that.accountBalances);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<MonthlyPnL> monthlyPnL,  List<ExpenseCategory> expenseCategories,  List<PayeeRow> topPayees,  List<BudgetVsActual> budgetVsActual,  List<LoanReportRow> loanRows,  List<Holding> holdings,  List<Asset> assets,  List<Account> accounts,  List<JournalEntry> allEntries,  Map<String, int> accountBalances)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.monthlyPnL,_that.expenseCategories,_that.topPayees,_that.budgetVsActual,_that.loanRows,_that.holdings,_that.assets,_that.accounts,_that.allEntries,_that.accountBalances);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<MonthlyPnL> monthlyPnL,  List<ExpenseCategory> expenseCategories,  List<PayeeRow> topPayees,  List<BudgetVsActual> budgetVsActual,  List<LoanReportRow> loanRows,  List<Holding> holdings,  List<Asset> assets,  List<Account> accounts,  List<JournalEntry> allEntries,  Map<String, int> accountBalances)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.monthlyPnL,_that.expenseCategories,_that.topPayees,_that.budgetVsActual,_that.loanRows,_that.holdings,_that.assets,_that.accounts,_that.allEntries,_that.accountBalances);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements ReportsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReportsState.initial()';
}


}




/// @nodoc


class _Loading implements ReportsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReportsState.loading()';
}


}




/// @nodoc


class _Loaded implements ReportsState {
  const _Loaded({required  List<MonthlyPnL> monthlyPnL, required  List<ExpenseCategory> expenseCategories, required  List<PayeeRow> topPayees, required  List<BudgetVsActual> budgetVsActual, required  List<LoanReportRow> loanRows, required  List<Holding> holdings, required  List<Asset> assets, required  List<Account> accounts, required  List<JournalEntry> allEntries, required  Map<String, int> accountBalances}): _monthlyPnL = monthlyPnL,_expenseCategories = expenseCategories,_topPayees = topPayees,_budgetVsActual = budgetVsActual,_loanRows = loanRows,_holdings = holdings,_assets = assets,_accounts = accounts,_allEntries = allEntries,_accountBalances = accountBalances;
  

 final  List<MonthlyPnL> _monthlyPnL;
 List<MonthlyPnL> get monthlyPnL {
  if (_monthlyPnL is EqualUnmodifiableListView) return _monthlyPnL;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyPnL);
}

 final  List<ExpenseCategory> _expenseCategories;
 List<ExpenseCategory> get expenseCategories {
  if (_expenseCategories is EqualUnmodifiableListView) return _expenseCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenseCategories);
}

 final  List<PayeeRow> _topPayees;
 List<PayeeRow> get topPayees {
  if (_topPayees is EqualUnmodifiableListView) return _topPayees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topPayees);
}

 final  List<BudgetVsActual> _budgetVsActual;
 List<BudgetVsActual> get budgetVsActual {
  if (_budgetVsActual is EqualUnmodifiableListView) return _budgetVsActual;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_budgetVsActual);
}

 final  List<LoanReportRow> _loanRows;
 List<LoanReportRow> get loanRows {
  if (_loanRows is EqualUnmodifiableListView) return _loanRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loanRows);
}

 final  List<Holding> _holdings;
 List<Holding> get holdings {
  if (_holdings is EqualUnmodifiableListView) return _holdings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holdings);
}

 final  List<Asset> _assets;
 List<Asset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

 final  List<Account> _accounts;
 List<Account> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  List<JournalEntry> _allEntries;
 List<JournalEntry> get allEntries {
  if (_allEntries is EqualUnmodifiableListView) return _allEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allEntries);
}

 final  Map<String, int> _accountBalances;
 Map<String, int> get accountBalances {
  if (_accountBalances is EqualUnmodifiableMapView) return _accountBalances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_accountBalances);
}


/// Create a copy of ReportsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.monthlyPnL, _monthlyPnL)&&const DeepCollectionEquality().equals(other.expenseCategories, _expenseCategories)&&const DeepCollectionEquality().equals(other.topPayees, _topPayees)&&const DeepCollectionEquality().equals(other.budgetVsActual, _budgetVsActual)&&const DeepCollectionEquality().equals(other.loanRows, _loanRows)&&const DeepCollectionEquality().equals(other.holdings, _holdings)&&const DeepCollectionEquality().equals(other.assets, _assets)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.allEntries, _allEntries)&&const DeepCollectionEquality().equals(other.accountBalances, _accountBalances));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_monthlyPnL),const DeepCollectionEquality().hash(_expenseCategories),const DeepCollectionEquality().hash(_topPayees),const DeepCollectionEquality().hash(_budgetVsActual),const DeepCollectionEquality().hash(_loanRows),const DeepCollectionEquality().hash(_holdings),const DeepCollectionEquality().hash(_assets),const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_allEntries),const DeepCollectionEquality().hash(_accountBalances));
}

@override
String toString() {
    return 'ReportsState.loaded(monthlyPnL: $monthlyPnL, expenseCategories: $expenseCategories, topPayees: $topPayees, budgetVsActual: $budgetVsActual, loanRows: $loanRows, holdings: $holdings, assets: $assets, accounts: $accounts, allEntries: $allEntries, accountBalances: $accountBalances)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $ReportsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<MonthlyPnL> monthlyPnL, List<ExpenseCategory> expenseCategories, List<PayeeRow> topPayees, List<BudgetVsActual> budgetVsActual, List<LoanReportRow> loanRows, List<Holding> holdings, List<Asset> assets, List<Account> accounts, List<JournalEntry> allEntries, Map<String, int> accountBalances
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of ReportsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? monthlyPnL = null,Object? expenseCategories = null,Object? topPayees = null,Object? budgetVsActual = null,Object? loanRows = null,Object? holdings = null,Object? assets = null,Object? accounts = null,Object? allEntries = null,Object? accountBalances = null,}) {
  return _then(_Loaded(
monthlyPnL: null == monthlyPnL ? _self._monthlyPnL : monthlyPnL // ignore: cast_nullable_to_non_nullable
as List<MonthlyPnL>,expenseCategories: null == expenseCategories ? _self._expenseCategories : expenseCategories // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategory>,topPayees: null == topPayees ? _self._topPayees : topPayees // ignore: cast_nullable_to_non_nullable
as List<PayeeRow>,budgetVsActual: null == budgetVsActual ? _self._budgetVsActual : budgetVsActual // ignore: cast_nullable_to_non_nullable
as List<BudgetVsActual>,loanRows: null == loanRows ? _self._loanRows : loanRows // ignore: cast_nullable_to_non_nullable
as List<LoanReportRow>,holdings: null == holdings ? _self._holdings : holdings // ignore: cast_nullable_to_non_nullable
as List<Holding>,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<Account>,allEntries: null == allEntries ? _self._allEntries : allEntries // ignore: cast_nullable_to_non_nullable
as List<JournalEntry>,accountBalances: null == accountBalances ? _self._accountBalances : accountBalances // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

/// @nodoc


class _Error implements ReportsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of ReportsState
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
    return 'ReportsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $ReportsStateCopyWith<$Res> {
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

/// Create a copy of ReportsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
