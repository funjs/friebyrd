(function(root) {
  var F, _;

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
  if (typeof module !== "undefined" && module !== null) {
    return module.exports = F;
  } else {
    return root.F = F;
  }
})(this);
