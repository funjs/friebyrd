((root) ->
  root = this
  _ = root._ || require 'underscore'

  F = {}

  F.succeed = (result) -> [result]
  F.fail = () -> []
  
  # exports and sundries

  if module?
    module.exports = F
  else
    root.F = F

)(this)



