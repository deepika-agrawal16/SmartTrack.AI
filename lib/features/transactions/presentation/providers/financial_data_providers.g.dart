// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionFirestoreServiceHash() =>
    r'98d013bfe3cb7d16a257c8967b171848bd183df7';

/// See also [transactionFirestoreService].
@ProviderFor(transactionFirestoreService)
final transactionFirestoreServiceProvider =
    Provider<TransactionFirestoreService>.internal(
  transactionFirestoreService,
  name: r'transactionFirestoreServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionFirestoreServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionFirestoreServiceRef
    = ProviderRef<TransactionFirestoreService>;
String _$authStateChangesHash() => r'7d19a09ab07e281ad2c02f13028c917dd8923292';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = StreamProvider<User?>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = StreamProviderRef<User?>;
String _$userTransactionsHash() => r'2f79046541fb9b042adb0d8fc8bd7d4146d68b42';

/// See also [userTransactions].
@ProviderFor(userTransactions)
final userTransactionsProvider = StreamProvider<List<Transaction>>.internal(
  userTransactions,
  name: r'userTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserTransactionsRef = StreamProviderRef<List<Transaction>>;
String _$currentUserProfileHash() =>
    r'ecd5d0e46f6d7c976418c5e97cee483fbc2adfb1';

/// See also [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider =
    StreamProvider<Map<String, dynamic>?>.internal(
  currentUserProfile,
  name: r'currentUserProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = StreamProviderRef<Map<String, dynamic>?>;
String _$filteredTransactionsHash() =>
    r'791ec4acfc547addb52b2601e290ab52bc1ddfe8';

/// See also [filteredTransactions].
@ProviderFor(filteredTransactions)
final filteredTransactionsProvider = StreamProvider<List<Transaction>>.internal(
  filteredTransactions,
  name: r'filteredTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredTransactionsRef = StreamProviderRef<List<Transaction>>;
String _$selectedTimePeriodNotifierHash() =>
    r'0d11fd0a703437f623e5c94a628f04878ea497ac';

/// See also [SelectedTimePeriodNotifier].
@ProviderFor(SelectedTimePeriodNotifier)
final selectedTimePeriodNotifierProvider =
    NotifierProvider<SelectedTimePeriodNotifier, TimePeriod>.internal(
  SelectedTimePeriodNotifier.new,
  name: r'selectedTimePeriodNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedTimePeriodNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedTimePeriodNotifier = Notifier<TimePeriod>;
String _$filteredPeriodSummaryNotifierHash() =>
    r'78dcef570e0a56e5c43ff2c84cc6f8bfe07f48f8';

/// See also [FilteredPeriodSummaryNotifier].
@ProviderFor(FilteredPeriodSummaryNotifier)
final filteredPeriodSummaryNotifierProvider =
    NotifierProvider<FilteredPeriodSummaryNotifier, PeriodSummary>.internal(
  FilteredPeriodSummaryNotifier.new,
  name: r'filteredPeriodSummaryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredPeriodSummaryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FilteredPeriodSummaryNotifier = Notifier<PeriodSummary>;
String _$financialDataNotifierHash() =>
    r'39ae9d4dfe8b155b8a9295cb4fc41455d9434958';

/// See also [FinancialDataNotifier].
@ProviderFor(FinancialDataNotifier)
final financialDataNotifierProvider =
    NotifierProvider<FinancialDataNotifier, FinancialState>.internal(
  FinancialDataNotifier.new,
  name: r'financialDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$financialDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FinancialDataNotifier = Notifier<FinancialState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
