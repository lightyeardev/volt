# volt ⚡️

Effortlessly manage asynchronous data fetching, caching, and real-time data delivery with minimal
code.

## Features

- ⚡️ Minimal boilerplate code for faster development
- 📡 Reactive updates for data consistency between components
- 🚀 In-memory caching for instant data access
- 💾 Disk caching with offline support
- 🔄 Query deduplication to reduce network requests
- 🔮 Configurable auto-refetching for fresh data
- 🧩 Easy integration with Flutter projects
- 🧠 Compute isolate support for heavy operations
- 📦 Lightweight package with minimal dependencies
- 🔒 Error handling with automatic retry mechanisms

## Install

```bash
flutter pub add volt
```

## Usage

#### Query

```dart
VoltQuery<Photo> photoQuery(String id) => VoltQuery(
      queryKey: ['photo', id],
      queryFn: () => fetch('https://jsonplaceholder.typicode.com/photos/$id'),
      select: Photo.fromJson,
    );

Widget build(BuildContext context) {
  final photo = useQuery(photoQuery('1'));

  return photo == null ? CircularProgressIndicator() : Text('Photo: ${photo.title}');
}
```

#### Mutation

```dart
VoltMutation<String> useDeletePhotoMutation() {
  final queryClient = useQueryClient();

  return useMutation(
    mutationFn: (photoId) => fetch(
      'https://jsonplaceholder.typicode.com/photos/$photoId',
      method: 'DELETE',
    ),
    onSuccess: (photoId) => queryClient.prefetchQuery(photoQuery(photoId)),
  );
}

Widget build(BuildContext context) {
  final deletePhotoMutation = useDeletePhotoMutation();

  return deletePhotoMutation.state.isLoading
      ? const CircularProgressIndicator()
      : ElevatedButton(
          onPressed: () => deletePhotoMutation.mutate('1'),
          child: const Text('Delete Photo'),
        );
}
```

#### Configuration

```dart
Widget build(BuildContext context) {
  final queryClient = useMemoized(() => QueryClient(
    // Transforms query keys (useful for cache segmentation by environment/locale)
    keyTransformer: (keys) => keys,

    // Custom persistor for memory and disk caching
    persistor: FileVoltPersistor(),

    // Global default stale duration
    staleDuration: const Duration(hours: 1),

    // Enable debug mode for extra logging and stats
    isDebug: false,

    // Listener for query events (cache hits, network errors, etc.)
    listener: null,
  ));

  return QueryClientProvider(
    client: queryClient,
    child: MyApp(),
  );
}
```

#### Query dependencies

A `null` queryFn acts the same as `enabled: false`

```dart
final accountQuery = VoltQuery(
  queryKey: ['account'],
  queryFn: () async => fetch('https://jsonplaceholder.typicode.com/account/1'),
  select: Account.fromJson,
);

VoltQuery<Photos> photosQuery(Account? account) =>
    VoltQuery(
      queryKey: ['photos', account?.id],
      queryFn: account == null
          ? null
          : () async => fetch('https://jsonplaceholder.typicode.com/account/${account.id}/photos/'),
      select: Photos.fromJson,
    );

Widget build(BuildContext context) {
  final account = useQuery(accountQuery);
  final photos = useQuery(photosQuery(account));

  ...
}
```

## Best Practices

### Response Object Equality

Response objects should implement equality to ensure proper change detection and prevent unnecessary rebuilds. Use [`equatable`](https://pub.dev/packages/equatable), [`freezed`](https://pub.dev/packages/freezed), or implement equality manually.

### Query Key Structure

Use consistent, hierarchical query keys. Start with a general identifier and add specifics:

```dart
// Good
['users']
['users', userId]
['users', userId, 'posts']
['users', userId, 'posts', postId]

// Avoid
['getUser123']
[userId, 'users']  // inconsistent order
```

### Extract Query Definitions

Define queries as functions outside widgets for reusability and testability:

```dart
// Good - reusable across the app
VoltQuery<User> userQuery(String id) => VoltQuery(
  queryKey: ['user', id],
  queryFn: () => fetchUser(id),
  select: User.fromJson,
);

// Avoid - inline queries are harder to reuse
useQuery(VoltQuery(queryKey: ['user', id], ...));
```

### Cache segmentation

Use `keyTransformer` in `QueryClient` to automatically segment cache by environment (production, staging, etc.)/locale (en, es, etc.) for all queries:

```dart
final queryClient = QueryClient(
  keyTransformer: (keys) => [
    isProduction ? 'production' : 'staging',
    locale,
    ...keys
    ],
);
```

This ensures cache isolation between environments and prevents data conflicts.

### Persistence

By default, Volt persists data to disk using the `FileVoltPersistor`. Which relies on no heavy dependencies and is very fast (uses the file system). Although, this can be overridden with a custom persister in the `QueryClient` constructor.

## Credits

Volt's public API design was inspired by [React Query](https://tanstack.com/query/latest), a popular data-fetching and state management library for React applications.

Special thanks to [flutter_hooks](https://pub.dev/packages/flutter_hooks) for bringing React-style hooks to Flutter, which made this package possible.
