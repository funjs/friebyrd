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

    Bindings.prototype.lookup = function(lvar) {
      if (!F.isLVar(lvar)) {
        return lvar;
      }
      if (this.binds.hasOwnProperty(lvar.name)) {
        return this.lookup(this.binds[lvar.name]);
      }
      return lvar;
    };

    return Bindings;

  })();
  F.emptyness = function() {
    return new Bindings();
  };
  F.unify = function(l, r, bindings) {
    var s, t1, t2;

    t1 = bindings.lookup(l);
    t2 = bindings.lookup(r);
    if (_.isEqual(t1, t2)) {
      return s;
    }
    if (F.isLVar(t1)) {
      return bindings.extend(t1, t2);
    }
    if (F.isLVar(t2)) {
      return bindings.extend(t2, t1);
    }
    if (_.isArray(t1) && _.isArray(t2)) {
      s = F.unify(_.first(t1), _.first(t2), bindings);
      if (_.exists(s)) {
        s = F.unify(_.rest(t1), _.rest(t2), bindings);
      }
      return s;
    }
    return null;
  };
  if (typeof module !== "undefined" && module !== null) {
    return module.exports = F;
  } else {
    return root.F = F;
  }
})(this);
