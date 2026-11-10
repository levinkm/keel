// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'income_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IncomeState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'IncomeState()';
}


}

/// @nodoc
class $IncomeStateCopyWith<$Res>  {
$IncomeStateCopyWith(IncomeState _, $Res Function(IncomeState) __);
}


/// Adds pattern-matching-related methods to [IncomeState].
extension IncomeStatePatterns on IncomeState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<IncomeStream> streams,  String selectedPeriod,  IncomeStats stats,  Map<String, int> receivedByStream,  List<Account> incomeAccounts,  String? selectedStreamId,  List<StreamActivity> sparkline,  List<JournalEntry> paymentHistory,  String? validationError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.streams,_that.selectedPeriod,_that.stats,_that.receivedByStream,_that.incomeAccounts,_that.selectedStreamId,_that.sparkline,_that.paymentHistory,_that.validationError);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<IncomeStream> streams,  String selectedPeriod,  IncomeStats stats,  Map<String, int> receivedByStream,  List<Account> incomeAccounts,  String? selectedStreamId,  List<StreamActivity> sparkline,  List<JournalEntry> paymentHistory,  String? validationError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.streams,_that.selectedPeriod,_that.stats,_that.receivedByStream,_that.incomeAccounts,_that.selectedStreamId,_that.sparkline,_that.paymentHistory,_that.validationError);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<IncomeStream> streams,  String selectedPeriod,  IncomeStats stats,  Map<String, int> receivedByStream,  List<Account> incomeAccounts,  String? selectedStreamId,  List<StreamActivity> sparkline,  List<JournalEntry> paymentHistory,  String? validationError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.streams,_that.selectedPeriod,_that.stats,_that.receivedByStream,_that.incomeAccounts,_that.selectedStreamId,_that.sparkline,_that.paymentHistory,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements IncomeState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'IncomeState.initial()';
}


}




/// @nodoc


class _Loading implements IncomeState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'IncomeState.loading()';
}


}




/// @nodoc


class _Loaded implements IncomeState {
  const _Loaded({required  List<IncomeStream> streams, required this.selectedPeriod, required this.stats, required  Map<String, int> receivedByStream, required  List<Account> incomeAccounts, this.selectedStreamId, required  List<StreamActivity> sparkline, required  List<JournalEntry> paymentHistory, this.validationError}): _streams = streams,_receivedByStream = receivedByStream,_incomeAccounts = incomeAccounts,_sparkline = sparkline,_paymentHistory = paymentHistory;
  

 final  List<IncomeStream> _streams;
 List<IncomeStream> get streams {
  if (_streams is EqualUnmodifiableListView) return _streams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_streams);
}

 final  String selectedPeriod;
 final  IncomeStats stats;
 final  Map<String, int> _receivedByStream;
 Map<String, int> get receivedByStream {
  if (_receivedByStream is EqualUnmodifiableMapView) return _receivedByStream;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_receivedByStream);
}

 final  List<Account> _incomeAccounts;
 List<Account> get incomeAccounts {
  if (_incomeAccounts is EqualUnmodifiableListView) return _incomeAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incomeAccounts);
}

 final  String? selectedStreamId;
 final  List<StreamActivity> _sparkline;
 List<StreamActivity> get sparkline {
  if (_sparkline is EqualUnmodifiableListView) return _sparkline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sparkline);
}

 final  List<JournalEntry> _paymentHistory;
 List<JournalEntry> get paymentHistory {
  if (_paymentHistory is EqualUnmodifiableListView) return _paymentHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paymentHistory);
}

 final  String? validationError;

/// Create a copy of IncomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.streams, _streams)&&(identical(other.selectedPeriod, selectedPeriod) || other.selectedPeriod == selectedPeriod)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other.receivedByStream, _receivedByStream)&&const DeepCollectionEquality().equals(other.incomeAccounts, _incomeAccounts)&&(identical(other.selectedStreamId, selectedStreamId) || other.selectedStreamId == selectedStreamId)&&const DeepCollectionEquality().equals(other.sparkline, _sparkline)&&const DeepCollectionEquality().equals(other.paymentHistory, _paymentHistory)&&(identical(other.validationError, validationError) || other.validationError == validationError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_streams),selectedPeriod,stats,const DeepCollectionEquality().hash(_receivedByStream),const DeepCollectionEquality().hash(_incomeAccounts),selectedStreamId,const DeepCollectionEquality().hash(_sparkline),const DeepCollectionEquality().hash(_paymentHistory),validationError);
}

@override
String toString() {
    return 'IncomeState.loaded(streams: $streams, selectedPeriod: $selectedPeriod, stats: $stats, receivedByStream: $receivedByStream, incomeAccounts: $incomeAccounts, selectedStreamId: $selectedStreamId, sparkline: $sparkline, paymentHistory: $paymentHistory, validationError: $validationError)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $IncomeStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<IncomeStream> streams, String selectedPeriod, IncomeStats stats, Map<String, int> receivedByStream, List<Account> incomeAccounts, String? selectedStreamId, List<StreamActivity> sparkline, List<JournalEntry> paymentHistory, String? validationError
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of IncomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? streams = null,Object? selectedPeriod = null,Object? stats = null,Object? receivedByStream = null,Object? incomeAccounts = null,Object? selectedStreamId = freezed,Object? sparkline = null,Object? paymentHistory = null,Object? validationError = freezed,}) {
  return _then(_Loaded(
streams: null == streams ? _self._streams : streams // ignore: cast_nullable_to_non_nullable
as List<IncomeStream>,selectedPeriod: null == selectedPeriod ? _self.selectedPeriod : selectedPeriod // ignore: cast_nullable_to_non_nullable
as String,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as IncomeStats,receivedByStream: null == receivedByStream ? _self._receivedByStream : receivedByStream // ignore: cast_nullable_to_non_nullable
as Map<String, int>,incomeAccounts: null == incomeAccounts ? _self._incomeAccounts : incomeAccounts // ignore: cast_nullable_to_non_nullable
as List<Account>,selectedStreamId: freezed == selectedStreamId ? _self.selectedStreamId : selectedStreamId // ignore: cast_nullable_to_non_nullable
as String?,sparkline: null == sparkline ? _self._sparkline : sparkline // ignore: cast_nullable_to_non_nullable
as List<StreamActivity>,paymentHistory: null == paymentHistory ? _self._paymentHistory : paymentHistory // ignore: cast_nullable_to_non_nullable
as List<JournalEntry>,validationError: freezed == validationError ? _self.validationError : validationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements IncomeState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of IncomeState
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
    return 'IncomeState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $IncomeStateCopyWith<$Res> {
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

/// Create a copy of IncomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
