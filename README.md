# volt ⚡️

Effortlessly manage asynchronous data fetching, caching, and real-time data delivery with minimal code.

# Install

```bash
flutter pub add volt
```

# Usage

```dart
final usersQuery = VoltQuery(
  box: "users",
  source: () => fetch("https://jsonplaceholder.typicode.com/users"),
  fromJson: Users.fromJson,
);

Widget build(BuildContext context) {
  final users = useVoltQuery(usersQuery);

  return users == null
      ? CircularProgressIndicator()
      : ListView.builder(
    itemCount: users.length,
    itemBuilder: (_, index) => ListTile(title: Text(users[index].name)),
  );
}
```