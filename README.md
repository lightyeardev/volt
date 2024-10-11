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
VoltQuery<User> userQuery(String id) => VoltQuery(
      queryKey: ["user", id],
      queryFn: () => fetch("https://jsonplaceholder.typicode.com/users/$id"),
      select: User.fromJson,
    );

Widget build(BuildContext context) {
  final user = useQuery(userQuery("1"));

  return user == null ? CircularProgressIndicator() : Text("User: ${user.name}");
}
```

## Configuration

```dart
final client = useMemoized(() => QueryClient( ... ));
QueryClientProvider(
  client: client,
  child: MyApp(),
);
```