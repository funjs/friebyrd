(function(root) {
  var F, _;

  root = this;
  _ = root._ || require('underscore');
  F = {};
  F.succeed = function(result) {
    return [result];
  };
  F.fail = _.always([]);
  if (typeof module !== "undefined" && module !== null) {
    return module.exports = F;
  } else {
    return root.F = F;
  }
})(this);
