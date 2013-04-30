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

  # Logic variables and bindings
  # ----------------------------

  class LVar
    constructor: (name) ->
      @name = name

  F.lvar = (name) -> new LVar(name)

  F.isLVar = (v) -> (v instanceof LVar)

  F.testLVar = () ->
    v = F.lvar("foo")
    F.isLVar(v)

  class Bindings
    constructor: (seed = {}) ->
      @binds = _.merge({}, seed)
    extend: (lvar, value) =>
      @binds[lvar.name] = value
      this
    lookup: (lvar) ->
      if !F.isLvar(lvar)
        return lvar
      if @binds.hasOwnProperty(lvar.name)
        return this.lookup(@binds[lvar.name])
      lvar

  F.emptyness = () -> new Bindings()

  # Unification
  # -----------

  F.unify = (l, r, bindings) ->
    t1 = bindings.lookup(l)
    t2 = bindings.lookup(r)

    if _.isEqual(t1, t2)
      return s
    if isLVar(t1)
      return bindings.extend(t1, t2)
    if isLVar(t2)
      return bindings.extend(t2, t1)
    if _.isArray(t1) && _.isArray(t2)
      s = unify(_.first(t1), _.first(t2), bindings)
      s = unify(_.rest(t1), _.rest(t2), bindings) if _.exists(s)
      return s
    return null

  # exports and sundries

  if module?
    module.exports = F
  else
    root.F = F

)(this)
