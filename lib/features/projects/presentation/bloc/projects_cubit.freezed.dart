// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projects_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectsState()';
}


}

/// @nodoc
class $ProjectsStateCopyWith<$Res>  {
$ProjectsStateCopyWith(ProjectsState _, $Res Function(ProjectsState) __);
}


/// Adds pattern-matching-related methods to [ProjectsState].
extension ProjectsStatePatterns on ProjectsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Project> projects,  Map<String, ProjectSummary> summaries,  ProjectFilter filter,  String? selectedProjectId,  List<JournalEntry> selectedEntries,  List<Account> accounts,  int totalBudgetedMinor,  int totalSpentMinor,  int totalRevenueMinor,  int activeCount,  String? validationError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.projects,_that.summaries,_that.filter,_that.selectedProjectId,_that.selectedEntries,_that.accounts,_that.totalBudgetedMinor,_that.totalSpentMinor,_that.totalRevenueMinor,_that.activeCount,_that.validationError);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Project> projects,  Map<String, ProjectSummary> summaries,  ProjectFilter filter,  String? selectedProjectId,  List<JournalEntry> selectedEntries,  List<Account> accounts,  int totalBudgetedMinor,  int totalSpentMinor,  int totalRevenueMinor,  int activeCount,  String? validationError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.projects,_that.summaries,_that.filter,_that.selectedProjectId,_that.selectedEntries,_that.accounts,_that.totalBudgetedMinor,_that.totalSpentMinor,_that.totalRevenueMinor,_that.activeCount,_that.validationError);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Project> projects,  Map<String, ProjectSummary> summaries,  ProjectFilter filter,  String? selectedProjectId,  List<JournalEntry> selectedEntries,  List<Account> accounts,  int totalBudgetedMinor,  int totalSpentMinor,  int totalRevenueMinor,  int activeCount,  String? validationError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.projects,_that.summaries,_that.filter,_that.selectedProjectId,_that.selectedEntries,_that.accounts,_that.totalBudgetedMinor,_that.totalSpentMinor,_that.totalRevenueMinor,_that.activeCount,_that.validationError);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements ProjectsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectsState.initial()';
}


}




/// @nodoc


class _Loading implements ProjectsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectsState.loading()';
}


}




/// @nodoc


class _Loaded implements ProjectsState {
  const _Loaded({required  List<Project> projects, required  Map<String, ProjectSummary> summaries, required this.filter, this.selectedProjectId, required  List<JournalEntry> selectedEntries, required  List<Account> accounts, required this.totalBudgetedMinor, required this.totalSpentMinor, required this.totalRevenueMinor, required this.activeCount, this.validationError}): _projects = projects,_summaries = summaries,_selectedEntries = selectedEntries,_accounts = accounts;
  

 final  List<Project> _projects;
 List<Project> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}

 final  Map<String, ProjectSummary> _summaries;
 Map<String, ProjectSummary> get summaries {
  if (_summaries is EqualUnmodifiableMapView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_summaries);
}

 final  ProjectFilter filter;
 final  String? selectedProjectId;
 final  List<JournalEntry> _selectedEntries;
 List<JournalEntry> get selectedEntries {
  if (_selectedEntries is EqualUnmodifiableListView) return _selectedEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedEntries);
}

 final  List<Account> _accounts;
 List<Account> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

 final  int totalBudgetedMinor;
 final  int totalSpentMinor;
 final  int totalRevenueMinor;
 final  int activeCount;
 final  String? validationError;

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.projects, _projects)&&const DeepCollectionEquality().equals(other.summaries, _summaries)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.selectedProjectId, selectedProjectId) || other.selectedProjectId == selectedProjectId)&&const DeepCollectionEquality().equals(other.selectedEntries, _selectedEntries)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&(identical(other.totalBudgetedMinor, totalBudgetedMinor) || other.totalBudgetedMinor == totalBudgetedMinor)&&(identical(other.totalSpentMinor, totalSpentMinor) || other.totalSpentMinor == totalSpentMinor)&&(identical(other.totalRevenueMinor, totalRevenueMinor) || other.totalRevenueMinor == totalRevenueMinor)&&(identical(other.activeCount, activeCount) || other.activeCount == activeCount)&&(identical(other.validationError, validationError) || other.validationError == validationError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_projects),const DeepCollectionEquality().hash(_summaries),filter,selectedProjectId,const DeepCollectionEquality().hash(_selectedEntries),const DeepCollectionEquality().hash(_accounts),totalBudgetedMinor,totalSpentMinor,totalRevenueMinor,activeCount,validationError);
}

@override
String toString() {
    return 'ProjectsState.loaded(projects: $projects, summaries: $summaries, filter: $filter, selectedProjectId: $selectedProjectId, selectedEntries: $selectedEntries, accounts: $accounts, totalBudgetedMinor: $totalBudgetedMinor, totalSpentMinor: $totalSpentMinor, totalRevenueMinor: $totalRevenueMinor, activeCount: $activeCount, validationError: $validationError)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $ProjectsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Project> projects, Map<String, ProjectSummary> summaries, ProjectFilter filter, String? selectedProjectId, List<JournalEntry> selectedEntries, List<Account> accounts, int totalBudgetedMinor, int totalSpentMinor, int totalRevenueMinor, int activeCount, String? validationError
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projects = null,Object? summaries = null,Object? filter = null,Object? selectedProjectId = freezed,Object? selectedEntries = null,Object? accounts = null,Object? totalBudgetedMinor = null,Object? totalSpentMinor = null,Object? totalRevenueMinor = null,Object? activeCount = null,Object? validationError = freezed,}) {
  return _then(_Loaded(
projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<Project>,summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<String, ProjectSummary>,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as ProjectFilter,selectedProjectId: freezed == selectedProjectId ? _self.selectedProjectId : selectedProjectId // ignore: cast_nullable_to_non_nullable
as String?,selectedEntries: null == selectedEntries ? _self._selectedEntries : selectedEntries // ignore: cast_nullable_to_non_nullable
as List<JournalEntry>,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<Account>,totalBudgetedMinor: null == totalBudgetedMinor ? _self.totalBudgetedMinor : totalBudgetedMinor // ignore: cast_nullable_to_non_nullable
as int,totalSpentMinor: null == totalSpentMinor ? _self.totalSpentMinor : totalSpentMinor // ignore: cast_nullable_to_non_nullable
as int,totalRevenueMinor: null == totalRevenueMinor ? _self.totalRevenueMinor : totalRevenueMinor // ignore: cast_nullable_to_non_nullable
as int,activeCount: null == activeCount ? _self.activeCount : activeCount // ignore: cast_nullable_to_non_nullable
as int,validationError: freezed == validationError ? _self.validationError : validationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements ProjectsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of ProjectsState
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
    return 'ProjectsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $ProjectsStateCopyWith<$Res> {
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

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
