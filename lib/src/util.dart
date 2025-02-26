/// A token that can be used to skip a query, used in queryFn.
///
/// This is used to skip a query when the query is not needed, behaves the same as enabled = false.
T skipToken<T>() => throw UnsupportedError(
      'skipToken should not actually be invoked. Only used for type checking.',
    );
