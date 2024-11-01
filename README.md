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
    // configuration options
  ));

  return QueryClientProvider(
    client: queryClient,
    child: MyApp(),
  );
}
```

## Credits

Volt's public API design was inspired by [React Query](https://tanstack.com/query/latest), a popular data-fetching and state management library for React applications.
