// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assets_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AssetsState()';
}


}

/// @nodoc
class $AssetsStateCopyWith<$Res>  {
$AssetsStateCopyWith(AssetsState _, $Res Function(AssetsState) __);
}


/// Adds pattern-matching-related methods to [AssetsState].
extension AssetsStatePatterns on AssetsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Asset> assets,  AssetFilter filter,  String? selectedAssetId,  int totalCostMinor,  int totalBookValueMinor,  int insuredCount,  List<Project> linkedProjects,  Map<String, ProjectSummary> linkedSummaries,  Map<String, List<JournalEntry>> linkedEntries,  List<AssetAttachment> attachments,  String? validationError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.assets,_that.filter,_that.selectedAssetId,_that.totalCostMinor,_that.totalBookValueMinor,_that.insuredCount,_that.linkedProjects,_that.linkedSummaries,_that.linkedEntries,_that.attachments,_that.validationError);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Asset> assets,  AssetFilter filter,  String? selectedAssetId,  int totalCostMinor,  int totalBookValueMinor,  int insuredCount,  List<Project> linkedProjects,  Map<String, ProjectSummary> linkedSummaries,  Map<String, List<JournalEntry>> linkedEntries,  List<AssetAttachment> attachments,  String? validationError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.assets,_that.filter,_that.selectedAssetId,_that.totalCostMinor,_that.totalBookValueMinor,_that.insuredCount,_that.linkedProjects,_that.linkedSummaries,_that.linkedEntries,_that.attachments,_that.validationError);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Asset> assets,  AssetFilter filter,  String? selectedAssetId,  int totalCostMinor,  int totalBookValueMinor,  int insuredCount,  List<Project> linkedProjects,  Map<String, ProjectSummary> linkedSummaries,  Map<String, List<JournalEntry>> linkedEntries,  List<AssetAttachment> attachments,  String? validationError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.assets,_that.filter,_that.selectedAssetId,_that.totalCostMinor,_that.totalBookValueMinor,_that.insuredCount,_that.linkedProjects,_that.linkedSummaries,_that.linkedEntries,_that.attachments,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements AssetsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AssetsState.initial()';
}


}




/// @nodoc


class _Loading implements AssetsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AssetsState.loading()';
}


}




/// @nodoc


class _Loaded implements AssetsState {
  const _Loaded({required  List<Asset> assets, required this.filter, this.selectedAssetId, required this.totalCostMinor, required this.totalBookValueMinor, required this.insuredCount, required  List<Project> linkedProjects, required  Map<String, ProjectSummary> linkedSummaries, required  Map<String, List<JournalEntry>> linkedEntries, required  List<AssetAttachment> attachments, this.validationError}): _assets = assets,_linkedProjects = linkedProjects,_linkedSummaries = linkedSummaries,_linkedEntries = linkedEntries,_attachments = attachments;
  

 final  List<Asset> _assets;
 List<Asset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

 final  AssetFilter filter;
 final  String? selectedAssetId;
 final  int totalCostMinor;
 final  int totalBookValueMinor;
 final  int insuredCount;
 final  List<Project> _linkedProjects;
 List<Project> get linkedProjects {
  if (_linkedProjects is EqualUnmodifiableListView) return _linkedProjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedProjects);
}

 final  Map<String, ProjectSummary> _linkedSummaries;
 Map<String, ProjectSummary> get linkedSummaries {
  if (_linkedSummaries is EqualUnmodifiableMapView) return _linkedSummaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_linkedSummaries);
}

 final  Map<String, List<JournalEntry>> _linkedEntries;
 Map<String, List<JournalEntry>> get linkedEntries {
  if (_linkedEntries is EqualUnmodifiableMapView) return _linkedEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_linkedEntries);
}

 final  List<AssetAttachment> _attachments;
 List<AssetAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  String? validationError;

/// Create a copy of AssetsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.assets, _assets)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.selectedAssetId, selectedAssetId) || other.selectedAssetId == selectedAssetId)&&(identical(other.totalCostMinor, totalCostMinor) || other.totalCostMinor == totalCostMinor)&&(identical(other.totalBookValueMinor, totalBookValueMinor) || other.totalBookValueMinor == totalBookValueMinor)&&(identical(other.insuredCount, insuredCount) || other.insuredCount == insuredCount)&&const DeepCollectionEquality().equals(other.linkedProjects, _linkedProjects)&&const DeepCollectionEquality().equals(other.linkedSummaries, _linkedSummaries)&&const DeepCollectionEquality().equals(other.linkedEntries, _linkedEntries)&&const DeepCollectionEquality().equals(other.attachments, _attachments)&&(identical(other.validationError, validationError) || other.validationError == validationError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_assets),filter,selectedAssetId,totalCostMinor,totalBookValueMinor,insuredCount,const DeepCollectionEquality().hash(_linkedProjects),const DeepCollectionEquality().hash(_linkedSummaries),const DeepCollectionEquality().hash(_linkedEntries),const DeepCollectionEquality().hash(_attachments),validationError);
}

@override
String toString() {
    return 'AssetsState.loaded(assets: $assets, filter: $filter, selectedAssetId: $selectedAssetId, totalCostMinor: $totalCostMinor, totalBookValueMinor: $totalBookValueMinor, insuredCount: $insuredCount, linkedProjects: $linkedProjects, linkedSummaries: $linkedSummaries, linkedEntries: $linkedEntries, attachments: $attachments, validationError: $validationError)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $AssetsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Asset> assets, AssetFilter filter, String? selectedAssetId, int totalCostMinor, int totalBookValueMinor, int insuredCount, List<Project> linkedProjects, Map<String, ProjectSummary> linkedSummaries, Map<String, List<JournalEntry>> linkedEntries, List<AssetAttachment> attachments, String? validationError
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of AssetsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? assets = null,Object? filter = null,Object? selectedAssetId = freezed,Object? totalCostMinor = null,Object? totalBookValueMinor = null,Object? insuredCount = null,Object? linkedProjects = null,Object? linkedSummaries = null,Object? linkedEntries = null,Object? attachments = null,Object? validationError = freezed,}) {
  return _then(_Loaded(
assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AssetFilter,selectedAssetId: freezed == selectedAssetId ? _self.selectedAssetId : selectedAssetId // ignore: cast_nullable_to_non_nullable
as String?,totalCostMinor: null == totalCostMinor ? _self.totalCostMinor : totalCostMinor // ignore: cast_nullable_to_non_nullable
as int,totalBookValueMinor: null == totalBookValueMinor ? _self.totalBookValueMinor : totalBookValueMinor // ignore: cast_nullable_to_non_nullable
as int,insuredCount: null == insuredCount ? _self.insuredCount : insuredCount // ignore: cast_nullable_to_non_nullable
as int,linkedProjects: null == linkedProjects ? _self._linkedProjects : linkedProjects // ignore: cast_nullable_to_non_nullable
as List<Project>,linkedSummaries: null == linkedSummaries ? _self._linkedSummaries : linkedSummaries // ignore: cast_nullable_to_non_nullable
as Map<String, ProjectSummary>,linkedEntries: null == linkedEntries ? _self._linkedEntries : linkedEntries // ignore: cast_nullable_to_non_nullable
as Map<String, List<JournalEntry>>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AssetAttachment>,validationError: freezed == validationError ? _self.validationError : validationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements AssetsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of AssetsState
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
    return 'AssetsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $AssetsStateCopyWith<$Res> {
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

/// Create a copy of AssetsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
