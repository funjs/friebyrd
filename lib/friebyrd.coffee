((root) ->
  root = this
  _ = root._ || require 'underscore'
  F = {}

  # Non-determinism
  # ---------------

  F.succeed = (result) -> [result]
  F.fail = _.always []

  disjunction = (l, r) ->
    (x) -> _.cat(l(x), r(x))
  conjunction = (l, r) ->
    (x) -> _.mapcat(l(x), r)

  F.disj = () ->
    return F.fail if _.isEmpty(arguments)
    disjunction(_.first(arguments), F.disj.apply(this, _.rest(arguments)))

  F.conj = () ->
    clauses = _.toArray(arguments)
    return F.succeed if _.isEmpty(clauses)
    return _.first(clauses) if _.size(clauses) is 1
    conjunction(_.first(clauses),
                (s) -> F.conj.apply(null, _.rest(clauses))(s))

  # Knowledge representation
  # ------------------------

  class LVar
    constructor: (@name) ->

  F.lvar = (name) -> new LVar(name)
  F.isLVar = (v) -> (v instanceof LVar)

  find = (v, bindings) ->
    lvar = bindings.lookup(v)
    return lvar if F.isLVar(v)
    if _.isArray(lvar)
      if _.isEmpty(lvar)
        return lvar
      else
        return _.cons(find(_.first(lvar), bindings), find(_.rest(lvar), bindings))
    lvar

  class Bindings
    constructor: (seed = {}) ->
      @binds = _.merge({}, seed)
    extend: (lvar, value) ->
      o = {}
      o[lvar.name] = value
      new Bindings(_.merge(@binds, o))
    has: (lvar) ->
      @binds.hasOwnProperty(lvar.name)
    lookup: (lvar) ->
      return lvar if !F.isLVar(lvar)
      return this.lookup(@binds[lvar.name]) if this.has(lvar)
      lvar

  F.ignorance = new Bindings()

  # Unification
  # -----------

  F.unify = (l, r, bindings) ->
    t1 = bindings.lookup(l)
    t2 = bindings.lookup(r)

    if _.isEqual(t1, t2)
      return bindings
    if F.isLVar(t1)
      return bindings.extend(t1, t2)
    if F.isLVar(t2)
      return bindings.extend(t2, t1)
    if _.isArray(t1) && _.isArray(t2)
      bindings = F.unify(_.first(t1), _.first(t2), bindings)
      bindings = if (bindings isnt null) then F.unify(_.rest(t1), _.rest(t2), bindings) else bindings
      return bindings
    return null

  # Operational logic
  # -----------------

  F.goal = (l, r) ->
    (bindings) ->
      result = F.unify(l, r, bindings)
      return F.succeed(result) if result isnt null
      return F.fail(bindings)

  F.run = (goal) ->
    goal(F.ignorance)

  # Logico
  # ------

  F.choice = ($v, list) ->
    return F.fail if _.isEmpty(list)

    F.disj(F.goal($v, _.first(list)),
                  F.choice($v, _.rest(list)))

  F.membero = F.choice

  F.commono = (l, r) ->
    $x = F.lvar("x")
    F.conj(F.choice($x, l),
           F.choice($x, r))

  F.conso = ($a, $b, list) -> F.goal(_.cons($a, $b), list)

  F.joino = ($a, $b, list) -> F.goal([$a, $b], list)

  # Exports and sundries
  # --------------------

  if module?
    module.exports = F
  else
    root.F = F

)(this)
