import 'package:volt/volt.dart';

T? useLazyQuery<T, P>(
  VoltQuery<T> Function(P param) queryBuilder,
  P? param, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = param == null ? NoOpVoltQuery() : queryBuilder(param);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery2<T, P1, P2>(
  VoltQuery<T> Function(P1, P2) queryBuilder,
  P1? p1,
  P2? p2, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = p1 == null || p2 == null ? NoOpVoltQuery() : queryBuilder(p1, p2);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery3<T, P1, P2, P3>(
  VoltQuery<T> Function(P1, P2, P3) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3, {
  bool enabled = true,
}) {
  final VoltQuery<T> query =
      p1 == null || p2 == null || p3 == null ? NoOpVoltQuery() : queryBuilder(p1, p2, p3);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery4<T, P1, P2, P3, P4>(
  VoltQuery<T> Function(P1, P2, P3, P4) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = p1 == null || p2 == null || p3 == null || p4 == null
      ? NoOpVoltQuery()
      : queryBuilder(p1, p2, p3, p4);
  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery5<T, P1, P2, P3, P4, P5>(
  VoltQuery<T> Function(P1, P2, P3, P4, P5) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4,
  P5? p5, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = p1 == null || p2 == null || p3 == null || p4 == null || p5 == null
      ? NoOpVoltQuery()
      : queryBuilder(p1, p2, p3, p4, p5);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery6<T, P1, P2, P3, P4, P5, P6>(
  VoltQuery<T> Function(P1, P2, P3, P4, P5, P6) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4,
  P5? p5,
  P6? p6, {
  bool enabled = true,
}) {
  final VoltQuery<T> query =
      p1 == null || p2 == null || p3 == null || p4 == null || p5 == null || p6 == null
          ? NoOpVoltQuery()
          : queryBuilder(p1, p2, p3, p4, p5, p6);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery7<T, P1, P2, P3, P4, P5, P6, P7>(
  VoltQuery<T> Function(P1, P2, P3, P4, P5, P6, P7) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4,
  P5? p5,
  P6? p6,
  P7? p7, {
  bool enabled = true,
}) {
  final VoltQuery<T> query =
      p1 == null || p2 == null || p3 == null || p4 == null || p5 == null || p6 == null || p7 == null
          ? NoOpVoltQuery()
          : queryBuilder(p1, p2, p3, p4, p5, p6, p7);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery8<T, P1, P2, P3, P4, P5, P6, P7, P8>(
  VoltQuery<T> Function(P1, P2, P3, P4, P5, P6, P7, P8) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4,
  P5? p5,
  P6? p6,
  P7? p7,
  P8? p8, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = p1 == null ||
          p2 == null ||
          p3 == null ||
          p4 == null ||
          p5 == null ||
          p6 == null ||
          p7 == null ||
          p8 == null
      ? NoOpVoltQuery()
      : queryBuilder(p1, p2, p3, p4, p5, p6, p7, p8);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

T? useLazyQuery9<T, P1, P2, P3, P4, P5, P6, P7, P8, P9>(
  VoltQuery<T> Function(P1, P2, P3, P4, P5, P6, P7, P8, P9) queryBuilder,
  P1? p1,
  P2? p2,
  P3? p3,
  P4? p4,
  P5? p5,
  P6? p6,
  P7? p7,
  P8? p8,
  P9? p9, {
  bool enabled = true,
}) {
  final VoltQuery<T> query = p1 == null ||
          p2 == null ||
          p3 == null ||
          p4 == null ||
          p5 == null ||
          p6 == null ||
          p7 == null ||
          p8 == null ||
          p9 == null
      ? NoOpVoltQuery()
      : queryBuilder(p1, p2, p3, p4, p5, p6, p7, p8, p9);

  return useQuery(query, enabled: query is NoOpVoltQuery ? false : enabled);
}

class NoOpVoltQuery<T> extends VoltQuery<T> {
  NoOpVoltQuery()
      : super(
          queryKey: [],
          queryFn: () async => null,
          select: (data) => data,
        );
}
