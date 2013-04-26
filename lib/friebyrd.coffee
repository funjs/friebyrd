((root) ->
  root = this
  _ = root._ || require 'underscore'

  fail = () -> []
  succeed = (result) -> [result]

)(this)



