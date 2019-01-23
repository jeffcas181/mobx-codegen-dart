R Function(T) withIndex<R, T>(R Function(T, int) action, {int start = 0}) =>
    (T value) => action(value, start++);

abstract class CodegenError {
  bool get hasErrors;
  String get message;
}

class StoreClassCodegenErrors implements CodegenError {
  StoreClassCodegenErrors(this.name) {
    _errorCategories = [
      staticObservables,
      staticActions,
      finalObservables,
      asyncActions
    ];
  }

  final String name;

  final PropertyErrors finalObservables = FinalObservableFields();
  final PropertyErrors staticObservables = StaticObservableFields();
  final PropertyErrors staticActions = StaticActionMethods();
  final PropertyErrors asyncActions = AsyncActionMethods();

  List<CodegenError> _errorCategories;

  String get message {
    final errors = _errorCategories
        .where((category) => category.hasErrors)
        .map(withIndex((category, i) => '  $i. ${category.message}', start: 1))
        .join('\n');

    return 'Could not make class "$name" observable. Changes needed:\n$errors';
  }

  bool get hasErrors => _errorCategories.any((category) => category.hasErrors);
}

abstract class PropertyErrors implements CodegenError {
  final NameList _properties = NameList();

  bool addIf(bool condition, String propertyName) {
    if (condition) {
      _properties.add(propertyName);
    }
    return condition;
  }

  String get propertyList => _properties.toString();

  Pluralize propertyPlural = const Pluralize('the field', 'fields');

  String get property => propertyPlural(_properties.length);

  @override
  bool get hasErrors => _properties.isNotEmpty;
}

class FinalObservableFields extends PropertyErrors {
  @override
  String get message => 'Remove final modifier from $property $propertyList';
}

class StaticObservableFields extends PropertyErrors {
  @override
  String get message => 'Remove static modifier from $property $propertyList';
}

class AsyncActionMethods extends PropertyErrors {
  @override
  Pluralize propertyPlural = const Pluralize('the method', 'methods');

  @override
  String get message => 'Remove async modifier from $property $propertyList';
}

class StaticActionMethods extends PropertyErrors {
  @override
  Pluralize propertyPlural = const Pluralize('the method', 'methods');

  @override
  String get message => 'Remove static modifier from $property $propertyList';
}

class NameList {
  final List<String> _names = [];

  void add(String name) => _names.add(name);

  int get length => _names.length;

  bool get isNotEmpty => _names.isNotEmpty;

  @override
  String toString() {
    if (_names.length == 1) {
      return '"${_names[0]}"';
    }

    final buf = StringBuffer();
    for (int i = 0; i < _names.length; i++) {
      final name = _names[i];
      buf.write('"$name"');
      if (i < _names.length - 2) {
        buf.write(', ');
      } else if (i == _names.length - 2) {
        buf.write(' and ');
      }
    }
    return buf.toString();
  }
}

class Pluralize {
  const Pluralize(this._single, this._multiple);

  final String _single;
  final String _multiple;

  String call(int count) => count == 1 ? _single : _multiple;
}
