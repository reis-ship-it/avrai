import 'package:get_storage/get_storage.dart';

abstract interface class MeshRuntimeStateStore {
  T? read<T>(String key);

  Future<void> write(String key, dynamic value);

  Future<void> remove(String key);
}

class GetStorageMeshRuntimeStateStore implements MeshRuntimeStateStore {
  GetStorageMeshRuntimeStateStore({
    String boxName = 'mesh_runtime_state',
  }) : _box = GetStorage(boxName);

  final GetStorage _box;

  @override
  T? read<T>(String key) => _box.read<T>(key);

  @override
  Future<void> write(String key, dynamic value) => _box.write(key, value);

  @override
  Future<void> remove(String key) => _box.remove(key);
}

class InMemoryMeshRuntimeStateStore implements MeshRuntimeStateStore {
  InMemoryMeshRuntimeStateStore([Map<String, dynamic>? initialState])
      : _state = initialState ?? <String, dynamic>{};

  final Map<String, dynamic> _state;

  @override
  T? read<T>(String key) => _state[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    _state[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _state.remove(key);
  }
}
