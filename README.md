# volt ⚡️

Effortlessly manage asynchronous data fetching, caching, and real-time data delivery with minimal
code.

## Features
- In-memory caching for faster access to frequently used data
- Persistent disk caching for offline support and reduced network calls
- Query deduplication to prevent redundant requests for the same resource
- Automatic data refetching & polling to keep resources up-to-date
- Reactive data sharing, ensuring all listeners receive live updates

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
  final client = useMemoized(() => QueryClient(...));
  
  return QueryClientProvider(
    client: client,
    child: MyApp(),
  );
}
```