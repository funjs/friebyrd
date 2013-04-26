((root) ->
  root = this
  _ = root._ || require 'underscore'

  F = {}

  fail = () -> []
  succeed = (result) -> [result]

  
  # exports and sundries

  if module?
    module.exports = F
  else
    root.F = F

)(this)



