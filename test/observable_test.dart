import 'package:mobx/mobx.dart';
import 'package:mobx/src/api/observable.dart';
import 'package:mobx/src/core/atom_derivation.dart';
import 'package:mobx/src/core/observable.dart';
import "package:test/test.dart";

void main() {
  test('Basic observable<T>', () {
    var x = observable<int>(null);
    expect(x.value, equals(null));

    x.value = 100;
    expect(x.value, equals(100));

    expect(x.name, startsWith('Observable@'));

    var str = observable('hello', name: 'greeting');
    expect(str is ObservableValue<String>, isTrue);
    expect(str.value, equals('hello'));
    expect(str.name, equals('greeting'));

    str.value = 'mobx';
    expect(str.value, equals('mobx'));
  });

  test('Raw observables', () {
    var x = ObservableValue(1000);
    expect(x is ObservableValue<int>, isTrue);

    expect(x.value, equals(1000));

    var x1 = ObservableValue<int>(null);
    expect(x1.value, isNull);

    var y = ObservableValue('Hello', name: 'greeting');
    expect(y.value, equals('Hello'));
    expect(y.name, equals('greeting'));
  });

  test('Atom can be used directly', () {
    var executionCount = 0;
    var a = Atom('test', onObserve: () {
      executionCount++;
    }, onUnobserve: () {
      executionCount++;
    });

    var d = autorun((_) {
      a.reportObserved();
    });

    expect(executionCount, equals(1)); // onBecomeObserved gets called

    d();
    expect(executionCount, equals(2)); // onBecomeUnobserved gets called
  });
}
