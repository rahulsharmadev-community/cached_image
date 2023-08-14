import 'package:hydrated_bloc/hydrated_bloc.dart';

class CachedStorage extends BlocBase<Map<String, dynamic>>
    with HydratedMixin<Map<String, dynamic>> {
  CachedStorage(super.state);

  void add(Map<String, dynamic> map) => emit({...state, ...map});

  void clearAll() {
    clear();
    emit({});
  }

  void remove(List<String> keys) {
    final ref = state;
    for (var key in keys) {
      ref.remove(key);
    }

    emit(ref);
  }

  @override
  Map<String, dynamic>? fromJson(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic>? toJson(Map<String, dynamic> state) => state;
}
