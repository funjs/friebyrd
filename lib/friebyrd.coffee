((root) ->
  root = this
  _ = root._ || require 'underscore'

  F = {}

  F.succeed = (result) -> [result]
  F.fail = _.always []

  F.disj = (l, r) ->
    (x) -> _.cat(l(x), r(x))

  F.conj = (l, r) ->
    (x) -> _.mapcat(l(x), r)

  F.test1 = () ->
    F.disj(
      F.disj(F.fail, F.succeed),
      F.conj(
        F.disj(((x) -> F.succeed(x + 1)),
               ((x) -> F.succeed(x + 10))),
        F.disj(F.succeed, F.succeed)))(100);

  # F.test1();
  #=> [100, 101, 101, 110, 110]

  # exports and sundries

  if module?
    module.exports = F
  else
    root.F = F

)(this)
