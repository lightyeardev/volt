# volt ⚡️

Effortlessly manage asynchronous data fetching, caching, and real-time data delivery with minimal
code.

## Features

- ⚡️ Blazing-fast development with minimal boilerplate code
- 🚀 Fast in-memory caching for instant data access
- 💾 Robust disk caching for seamless offline support
- 🔄 Smart query deduplication to optimize network requests
- 🔮 Configurable auto-refetching to keep data fresh
- 📡 Real-time reactive updates across all listeners
- 🧩 Easy integration with existing Flutter projects
- 🧠 Compute isolate support for heavy deserialization tasks
- 📦 Simple and compact package for efficient state management
- 🔒 Built-in error handling, auto recovery and retry mechanisms

## Install

```bash
flutter pub add volt
```

## Usage

#### Listening to a query

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

#### Query prefetching

```dart
Future<void> deletePhoto(QueryClient queryClient, String id) async {
  await fetch('https://jsonplaceholder.typicode.com/photos/$id', method: 'DELETE');
  await queryClient.prefetchQuery(photoQuery(id));
}

Widget build(BuildContext context) {
  final queryClient = useQueryClient();

  return ElevatedButton(
    onPressed: () => deletePhoto(queryClient, '1'),
    child: const Text('Delete Photo'),
  );
}
```

#### Configuration

```dart
Widget build(BuildContext context) {
  final queryClient = useMemoized(() => QueryClient(
    keyTransformer: // useful to add environment and locale specific keys to the query
    persistor: // custom persistor for caching
    staleDuration: // default stale duration for queries
    isDebug: // enable debug logs
    listener: // custom event listener to volt state changes globally
  ));

  return QueryClientProvider(
    client: queryClient,
    child: MyApp(),
  );
}
```

## Credits

Volt's public API design was inspired by [React Query](https://tanstack.com/query/latest), a popular data-fetching and state management library for React applications.
