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

```dart
VoltQuery<Post> postQuery(String id) => VoltQuery(
      queryKey: ["post", id],
      queryFn: () => fetch("https://jsonplaceholder.typicode.com/posts/$id"),
      select: Post.fromJson,
    );

Widget build(BuildContext context) {
  final post = useQuery(postQuery("1"));

  return post == null ? CircularProgressIndicator() : Text("Post: ${post.title}");
}
```

## Configuration

```dart
Widget build(BuildContext context) {
  final queryClient = useMemoized(() => VoltQueryClient(
    // configuration options
  ));
  
  return VoltQueryClientProvider(
    client: queryClient,
    child: MyApp(),
  );
}
```