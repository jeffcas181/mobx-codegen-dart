import 'package:mobx/src/core/observable.dart';
import 'package:mobx/src/core/reaction.dart';

class _GlobalState {
  int _batch = 0;

  static int _nextIdCounter = 0;

  Derivation _trackingDerivation;
  List<Reaction> _pendingReactions = [];
  bool _isRunningReactions = false;
  List<Atom> _pendingUnobservations = [];

  get nextId => ++_nextIdCounter;

  startBatch() {
    _batch++;
  }

  T trackDerivation<T>(Derivation d, T Function() fn) {
    var prevDerivation = _trackingDerivation;
    _trackingDerivation = d;

    _resetDerivationState(d);
    var result = fn();

    _trackingDerivation = prevDerivation;
    bindDependencies(d);

    return result;
  }

  reportObserved(Atom atom) {
    var derivation = _trackingDerivation;

    if (derivation != null) {
      derivation.newObservables.add(atom);
    }
  }

  endBatch() {
    if (--_batch == 0) {
      runReactions();

      for (var ob in _pendingUnobservations) {
        ob.isPendingUnobservation = false;
      }

      _pendingUnobservations.clear();
    }
  }

  bindDependencies(Derivation d) {
    var staleObservables = d.observables.difference(d.newObservables);
    var newObservables = d.newObservables.difference(d.observables);

    for (var ob in newObservables) {
      ob.addObserver(d);
    }

    for (var ob in staleObservables) {
      ob.removeObserver(d);
    }

    d.observables = d.newObservables;
  }

  addPendingReaction(Reaction reaction) {
    _pendingReactions.add(reaction);
  }

  runReactions() {
    if (_batch > 0 || _isRunningReactions) {
      return;
    }

    _isRunningReactions = true;

    for (var reaction in _pendingReactions) {
      reaction.run();
    }

    _pendingReactions = [];
    _isRunningReactions = false;
  }

  propagateChanged(Atom atom) {
    for (var observer in atom.observers) {
      observer.onBecomeStale();
    }
  }

  clearObservables(Derivation derivation) {
    var observables = derivation.observables;
    derivation.observables = Set();

    for (var x in observables) {
      x.removeObserver(derivation);
    }
  }

  void enqueueForUnobservation(Atom atom) {
    if (atom.isPendingUnobservation) {
      return;
    }

    atom.isPendingUnobservation = true;
    _pendingUnobservations.add(atom);
  }

  _resetDerivationState(Derivation d) {
    d.newObservables = Set();
  }

  bool shouldCompute(Reaction reaction) {
    return true;
  }
}

var global = _GlobalState();
