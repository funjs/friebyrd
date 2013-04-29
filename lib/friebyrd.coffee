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

  # exports and sundries

  if module?
    module.exports = F
  else
    root.F = F

)(this)



