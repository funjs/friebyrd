We always start with the JavaScript-like magic scoping mojo!

    ((root) ->
      root = this
      _ = root._ || require 'underscore'
      F = {}

Non-determinism
---------------

Non-deterministic functions are functions that can have more (or less) than one result.  As known from logic, a binary relation xRy (where x ∈ X, y ∈ Y) can be represented by a *function*  `X -> PowerSet{Y}`. As usual in computer science, we interpret the set `PowerSet{Y}` as a multi-set (realized as a regular scheme list). Compare with SQL, which likewise uses multisets and sequences were sets are properly called for. Also compare with [Wadler's "representing failure as a list of successes."](http://citeseer.uark.edu:8080/citeseerx/showciting;jsessionid=FF5F5EAA9D94B1A8618C49C37451D762?cid=377301).

Thus, we represent a 'relation' (aka `non-deterministic function') as a regular CoffeeScript function that returns an array of possible results.

First, we define two primitive non-deterministic functions; one of them yields no result whatsoever for any argument; the other merely returns its argument as the sole result.

    F.succeed = (result) -> [result]
    F.fail = _.always []

We build more complex non-deterministic functions by combining the existing ones with the help of the following two combinators.

`(disjunction l r)` returns all the results of `l` and all the results of `r`, or returns no results only if neither `l` nor `r` returned any.  In that sense, it is analogous to the logical disjunctionunction.

    disjunction = (l, r) ->
      (x) -> _.cat(l(x), r(x))

`(conjunction l r)` looks like a functional composition of `r` and `l`.  Only `(l x)` may return several results, so we have to apply `r` to each of them.  Obviously `(conjunction fail f)` and `(conjunction f fail)` are both equivalent to `fail`: they return no results, ever. It that sense, `conjunction` is analogous to the logical conjunction.

    conjunction = (l, r) ->
      (x) -> _.mapcat(l(x), r)

JavaScript allows you to pass any number of arguments to a function.  Therefore, we can make a function `disj` that takes any number of arguments and performs a logical disjunction over each.  This makes this version of Sokuza Kanren a bit more flexible in that it allows you to nest any number of relations therein.

    F.disj = () ->
      return F.fail if _.isEmpty(arguments)
      disjunction(_.first(arguments), 
	              F.disj.apply(this, _.rest(arguments)))

Likewise, the `conj` function accepts any number of clauses, nit just two as in the original Sokuza.

    F.conj = () ->
      clauses = _.toArray(arguments)
      return F.succeed if _.isEmpty(clauses)
      return _.first(clauses) if _.size(clauses) is 1
      conjunction(_.first(clauses),
                  (s) -> F.conj.apply(null, _.rest(clauses))(s))

And that's all that there is for the built-in non-deterministic functions.

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
      return s
    if F.isLVar(t1)
      return bindings.extend(t1, t2)
    if F.isLVar(t2)
      return bindings.extend(t2, t1)
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

  # Exports and sundries
  # --------------------

  if module?
    module.exports = F
  else
    root.F = F

)(this)
