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

  F.lvar = (name) -> "_." + name

  F.isLVar = (v) ->
    _.isString(v) && v.slice(0,2) == "_."

  F.ignorance = {}

  F.extend = (variable, value, bindings) ->
    nu = {}
    nu[variable] = value
    _.merge(bindings, nu)

  F.lookup = (variable, bindings) ->
    return variable if !F.isLVar(variable)
    return F.lookup(bindings[variable], bindings) if bindings.hasOwnProperty(variable) # check this line in orig
    return variable

  # Unification
  # -----------

  F.unify = (l, r, bindings) ->
    t1 = F.lookup(l, bindings)
    t2 = F.lookup(r, bindings)

    if _.isEqual(t1, t2)
      return s
    if F.isLVar(t1)
      return F.extend(t1, t2, bindings)
    if F.isLVar(t2)
      return F.extend(t2, t1, bindings)
    if _.isArray(t1) && _.isArray(t2)
      s = F.unify(_.first(t1), _.first(t2), bindings)
      s = if (s isnt null) then F.unify(_.rest(t1), _.rest(t2), bindings) else s
      return s
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
