var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

(function(root) {
  var Bindings, F, LVar, _;

  root = this;
  _ = root._ || require('underscore');
  F = {};
  F.succeed = function(result) {
    return [result];
  };
  F.fail = _.always([]);
  F.disj = function(l, r) {
    return function(x) {
      return _.cat(l(x), r(x));
    };
  };
  F.conj = function(l, r) {
    return function(x) {
      return _.mapcat(l(x), r);
    };
  };
  F.test1 = function() {
    return F.disj(F.disj(F.fail, F.succeed), F.conj(F.disj((function(x) {
      return F.succeed(x + 1);
    }), (function(x) {
      return F.succeed(x + 10);
    })), F.disj(F.succeed, F.succeed)))(100);
  };
  LVar = (function() {
    function LVar(name) {
      this.name = name;
    }

    return LVar;

  })();
  F.lvar = function(name) {
    return new LVar(name);
  };
  F.isLVar = function(v) {
    return v instanceof LVar;
  };
  F.testLVar = function() {
    var v;

    v = F.lvar("foo");
    return F.isLVar(v);
  };
  Bindings = (function() {
    function Bindings(seed) {
      if (seed == null) {
        seed = {};
      }
      this.extend = __bind(this.extend, this);
      this.binds = _.merge({}, seed);
    }

    Bindings.prototype.extend = function(lvar, value) {
      this.binds[lvar.name] = value;
      return this;
    };

    return Bindings;

  })();
  F.emptyness = function() {
    return new Bindings();
  };
  if (typeof module !== "undefined" && module !== null) {
    return module.exports = F;
  } else {
    return root.F = F;
  }
})(this);
