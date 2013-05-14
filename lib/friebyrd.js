(function(root) {
  var Bindings, F, LVar, conjunction, disjunction, find, _;

  root = this;
  _ = root._ || require('underscore');
  F = {};
  F.succeed = function(result) {
    return [result];
  };
  F.fail = _.always([]);
  disjunction = function(l, r) {
    return function(x) {
      return _.cat(l(x), r(x));
    };
  };
  conjunction = function(l, r) {
    return function(x) {
      return _.mapcat(l(x), r);
    };
  };
  F.disj = function() {
    if (_.isEmpty(arguments)) {
      return F.fail;
    }
    return disjunction(_.first(arguments), F.disj.apply(this, _.rest(arguments)));
  };
  F.conj = function() {
    var clauses;

    clauses = _.toArray(arguments);
    if (_.isEmpty(clauses)) {
      return F.succeed;
    }
    if (_.size(clauses) === 1) {
      return _.first(clauses);
    }
    return conjunction(_.first(clauses), function(s) {
      return F.conj.apply(null, _.rest(clauses))(s);
    });
  };
  F.lvar = function(name) {
    return "_." + name;
  };
  F.isLVar = function(v) {
    return _.isString(v) && v.slice(0, 2) === "_.";
  };
  F.ignorance = {};
  F.$x = F.lvar("x");
  F.$y = F.lvar("y");
  F.extend = function(variable, value, bindings) {
    var nu;

    nu = {};
    nu[variable] = value;
    return _.merge(bindings, nu);
  };
  F.lookup = function(variable, bindings) {
    if (!F.isLVar(variable)) {
      return variable;
    }
    if (bindings.hasOwnProperty(variable)) {
      return F.lookup(bindings[variable], bindings);
    }
    return variable;
  };
  F.unify = function(l, r, bindings) {
    var s, t1, t2;

    t1 = F.lookup(l, bindings);
    t2 = F.lookup(r, bindings);
    if (_.isEqual(t1, t2)) {
      return s;
    }
    if (F.isLVar(t1)) {
      return F.extend(t1, t2, bindings);
    }
    if (F.isLVar(t2)) {
      return F.extend(t2, t1, bindings);
    }
    if (_.isArray(t1) && _.isArray(t2)) {
      s = F.unify(_.first(t1), _.first(t2), bindings);
      s = s !== null ? F.unify(_.rest(t1), _.rest(t2), bindings) : s;
      return s;
    }
    return null;
  };
  F.goal = function(l, r) {
    return function(bindings) {
      var result;

      result = F.unify(l, r, bindings);
      if (result !== null) {
        return F.succeed(result);
      }
      return F.fail(bindings);
    };
  };
  F.run = function(goal) {
    return goal(F.ignorance);
  };
  F.choice = function($v, list) {
    if (_.isEmpty(list)) {
      return F.fail;
    }
    return F.disj(F.goal($v, _.first(list)), F.choice($v, _.rest(list)));
  };
  F.commono = function(l, r) {
    var $x;

    $x = F.lvar("x");
    return F.conj(F.choice($x, l), F.choice($x, r));
  };
  F.conso = function($a, $b, list) {
    return F.goal(_.cons($a, $b), list);
  };
  F.joino = function($a, $b, list) {
    return F.goal([$a, $b], list);
  };
  if (typeof module !== "undefined" && module !== null) {
    return module.exports = F;
  } else {
    return root.F = F;
  }
})(this);
