// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'setup_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SetupState {

 SetupStep get step; List<AccountDraft> get accounts; List<IncomeStreamDraft> get incomeStreams; List<LoanDraft> get loans; String get strategyId; bool get isSubmitting; String? get error;
/// Create a copy of SetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupStateCopyWith<SetupState> get copyWith => _$SetupStateCopyWithImpl<SetupState>(this as SetupState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SetupState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupState&&(identical(other.step, _this.step) || other.step == _this.step)&&const DeepCollectionEquality().equals(other.accounts, _this.accounts)&&const DeepCollectionEquality().equals(other.incomeStreams, _this.incomeStreams)&&const DeepCollectionEquality().equals(other.loans, _this.loans)&&(identical(other.strategyId, _this.strategyId) || other.strategyId == _this.strategyId)&&(identical(other.isSubmitting, _this.isSubmitting) || other.isSubmitting == _this.isSubmitting)&&(identical(other.error, _this.error) || other.error == _this.error));
}


@override
int get hashCode {
  final _this = this as SetupState;
  return Object.hash(runtimeType,_this.step,const DeepCollectionEquality().hash(_this.accounts),const DeepCollectionEquality().hash(_this.incomeStreams),const DeepCollectionEquality().hash(_this.loans),_this.strategyId,_this.isSubmitting,_this.error);
}

@override
String toString() {
  final _this = this as SetupState;
  return 'SetupState(step: ${_this.step}, accounts: ${_this.accounts}, incomeStreams: ${_this.incomeStreams}, loans: ${_this.loans}, strategyId: ${_this.strategyId}, isSubmitting: ${_this.isSubmitting}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $SetupStateCopyWith<$Res>  {
  factory $SetupStateCopyWith(SetupState value, $Res Function(SetupState) _then) = _$SetupStateCopyWithImpl;
@useResult
$Res call({
 SetupStep step, List<AccountDraft> accounts, List<IncomeStreamDraft> incomeStreams, List<LoanDraft> loans, String strategyId, bool isSubmitting, String? error
});




}
/// @nodoc
class _$SetupStateCopyWithImpl<$Res>
    implements $SetupStateCopyWith<$Res> {
  _$SetupStateCopyWithImpl(this._self, this._then);

  final SetupState _self;
  final $Res Function(SetupState) _then;

/// Create a copy of SetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? accounts = null,Object? incomeStreams = null,Object? loans = null,Object? strategyId = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(SetupState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as SetupStep,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<AccountDraft>,incomeStreams: null == incomeStreams ? _self.incomeStreams : incomeStreams // ignore: cast_nullable_to_non_nullable
as List<IncomeStreamDraft>,loans: null == loans ? _self.loans : loans // ignore: cast_nullable_to_non_nullable
as List<LoanDraft>,strategyId: null == strategyId ? _self.strategyId : strategyId // ignore: cast_nullable_to_non_nullable
as String,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SetupState].
extension SetupStatePatterns on SetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetupState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetupState value)  $default,){
final _that = this;
switch (_that) {
case _SetupState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetupState value)?  $default,){
final _that = this;
switch (_that) {
case _SetupState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SetupStep step,  List<AccountDraft> accounts,  List<IncomeStreamDraft> incomeStreams,  List<LoanDraft> loans,  String strategyId,  bool isSubmitting,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetupState() when $default != null:
return $default(_that.step,_that.accounts,_that.incomeStreams,_that.loans,_that.strategyId,_that.isSubmitting,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SetupStep step,  List<AccountDraft> accounts,  List<IncomeStreamDraft> incomeStreams,  List<LoanDraft> loans,  String strategyId,  bool isSubmitting,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SetupState():
return $default(_that.step,_that.accounts,_that.incomeStreams,_that.loans,_that.strategyId,_that.isSubmitting,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SetupStep step,  List<AccountDraft> accounts,  List<IncomeStreamDraft> incomeStreams,  List<LoanDraft> loans,  String strategyId,  bool isSubmitting,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SetupState() when $default != null:
return $default(_that.step,_that.accounts,_that.incomeStreams,_that.loans,_that.strategyId,_that.isSubmitting,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _SetupState implements SetupState {
  const _SetupState({this.step = SetupStep.welcome,  List<AccountDraft> accounts = const [],  List<IncomeStreamDraft> incomeStreams = const [],  List<LoanDraft> loans = const [], this.strategyId = 'commitments_first', this.isSubmitting = false, this.error}): _accounts = accounts,_incomeStreams = incomeStreams,_loans = loans;
  

@override@JsonKey() final  SetupStep step;
 final  List<AccountDraft> _accounts;
@override@JsonKey() List<AccountDraft> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  List<IncomeStreamDraft> _incomeStreams;
@override@JsonKey() List<IncomeStreamDraft> get incomeStreams {
  if (_incomeStreams is EqualUnmodifiableListView) return _incomeStreams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incomeStreams);
}

 final  List<LoanDraft> _loans;
@override@JsonKey() List<LoanDraft> get loans {
  if (_loans is EqualUnmodifiableListView) return _loans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loans);
}

@override@JsonKey() final  String strategyId;
@override@JsonKey() final  bool isSubmitting;
@override final  String? error;

/// Create a copy of SetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetupStateCopyWith<_SetupState> get copyWith => __$SetupStateCopyWithImpl<_SetupState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetupState&&(identical(other.step, step) || other.step == step)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.incomeStreams, _incomeStreams)&&const DeepCollectionEquality().equals(other.loans, _loans)&&(identical(other.strategyId, strategyId) || other.strategyId == strategyId)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,step,const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_incomeStreams),const DeepCollectionEquality().hash(_loans),strategyId,isSubmitting,error);
}

@override
String toString() {
    return 'SetupState(step: $step, accounts: $accounts, incomeStreams: $incomeStreams, loans: $loans, strategyId: $strategyId, isSubmitting: $isSubmitting, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SetupStateCopyWith<$Res> implements $SetupStateCopyWith<$Res> {
  factory _$SetupStateCopyWith(_SetupState value, $Res Function(_SetupState) _then) = __$SetupStateCopyWithImpl;
@override @useResult
$Res call({
 SetupStep step, List<AccountDraft> accounts, List<IncomeStreamDraft> incomeStreams, List<LoanDraft> loans, String strategyId, bool isSubmitting, String? error
});




}
/// @nodoc
class __$SetupStateCopyWithImpl<$Res>
    implements _$SetupStateCopyWith<$Res> {
  __$SetupStateCopyWithImpl(this._self, this._then);

  final _SetupState _self;
  final $Res Function(_SetupState) _then;

/// Create a copy of SetupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? accounts = null,Object? incomeStreams = null,Object? loans = null,Object? strategyId = null,Object? isSubmitting = null,Object? error = freezed,}) {
  return _then(_SetupState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as SetupStep,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<AccountDraft>,incomeStreams: null == incomeStreams ? _self._incomeStreams : incomeStreams // ignore: cast_nullable_to_non_nullable
as List<IncomeStreamDraft>,loans: null == loans ? _self._loans : loans // ignore: cast_nullable_to_non_nullable
as List<LoanDraft>,strategyId: null == strategyId ? _self.strategyId : strategyId // ignore: cast_nullable_to_non_nullable
as String,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
