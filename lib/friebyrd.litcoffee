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
	              F.disj.apply(this, 
				  _.rest(arguments)))

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

One may think of regular variables as "certain knowledge": they give  names to definite values.  A logic variable then stands for "improvable ignorance".  An unbound logic variable represents no  knowledge at all; in other words, it represents the result of a measurement *before* we have done the measurement. A logic variable may be associated with a definite value, like 10. That means definite knowledge.  A logic variable may be associated with a semi-definite value, like `[$X]` where `$X` is an unbound variable. We know something about the original variable: it is associated with the array of one element.  We can't say though what that element is. A logic variable can be associated with another, unbound logic variable. In that case, we still don't know what precisely the original variable stands for. However, we can say that it represents the same thing as the other variable. So, our uncertainty is reduced.

I've chosen to represent logic variables with their own simple type.

    class LVar
      constructor: (@name) ->

I've also created a couple of helper functions for creating new variables and checking "variableness" to decouple the representation a bit.

    F.lvar = (name) -> new LVar(name)
    F.isLVar = (v) -> (v instanceof LVar)

I implement associations of logic variables and their values (aka, *bindings*) as a class holding a simple JavaScript object.  One may say that a substitution represents our current knowledge of the world.

    class Bindings
      constructor: (seed = {}) ->
        @binds = _.merge({}, seed)

There are actually two ways of implementing substitutions as associative list. If the variable `$x` is associated with `$y` and `$y` is associated with `1`, we could represent this knowledge as `{$x: 1, $y 1}`. It is easy to lookup the value associated with the variable then, via a simple access. OTH, if we have the binding `{$x:  $y}` and we wish to add the bindings of `$y` to `1`, we have to make rearrangements so to produce `{$x: 1, $y 1}`, or make the traversal on lookup (which we defer to `find` below).

However, if we use an association-list-like structure (arrays of pairs) then we can just record the associations as we learn them, without modifying the previous ones. If originally we knew `[[$x, $y]]` and later we learned that `$y` is associated with `1`, we can simply prepend the latter association, obtaining `[[$y, 1], [$x, $y]]`. So, adding new knowledge becomes fast. The lookup procedure becomes more complex though, as we have to chase the chains of variables. To obtain the value associated with `$x` in the latter substitution, we first lookup `$x`, obtain `$y` (another logic variable), then lookup `$y` finally obtaining `1`.  I prefer the object-representation since it's more idiomatic, but using an a-list provides an intuitively incremental way of representing knowledge: it is easier to backtrack if we later find out our knowledge leads to a contradiction.

      extend: (lvar, value) ->
        o = {}
        o[lvar.name] = value
        new Bindings(_.merge(@binds, o))
      has: (lvar) ->
        @binds.hasOwnProperty(lvar.name)

Find the value associated with `lvar` in the `Bindings` instance.  Return `lvar` itself if it is unbound. In miniKanren, this function is called `walk`.

    lookup: (lvar) ->
        return lvar if !F.isLVar(lvar)
        return this.lookup(@binds[lvar.name]) if this.has(lvar)
        lvar

Starting with an empty binding is akin to saying that we start with zero knowledge.

    F.ignorance = new Bindings()

For convenience I'll add a couple of readily accessible logic variables:

    F.$x = F.lvar("x")
    F.$y = F.lvar("y")

As mentioned, because we overwrite bindings as we discover them the lookup logic is a little pernicious in the face of logic variables bound to other logic variables.

    find = (v, bindings) ->
      lvar = bindings.lookup(v)
      return lvar if F.isLVar(v)
      if _.isArray(lvar)
        if _.isEmpty(lvar)
          return lvar
        else
          return _.cons(find(_.first(lvar), bindings),
                        find(_.rest(lvar), bindings))
      lvar


# Unification
# -----------

Unification is the process of improving knowledge: or, the process of measurement. That measurement may uncover a contradiction though (things are not what we thought them to be). To be precise, the unification is the statement that two terms are the same. For example, unification of `1` and `1` is successful -- `1` is indeed the same as `1`. That doesn't add however to our knowledge of the world. If the logic variable `$x` is associated with `1` in the current bindings, the unification of `$x` with `2` yields a contradiction (the new measurement is not consistent with the previous measurements / hypotheses). Unification of an unbound logic variable `$x` and `1` improves our knowledge: the "measurement" found that `$x` is actually `1`. We record that fact in the new substitution.

Return the new bindings, or `null` on contradiction:

    F.unify = (l, r, bindings) ->

Find out what `l` actually is given our knowledge contained in `bindings`:

      t1 = bindings.lookup(l)

Find out what `r` actually is given our knowledge contained in `bindings`:

      t2 = bindings.lookup(r)

If `l` and `r` are the same; no new knowledge:

      if _.isEqual(t1, t2)
        return bindings

`l` is an unbound variable:

      if F.isLVar(t1)
        return bindings.extend(t1, t2)

`r` is an unbound variable:

      if F.isLVar(t2)
        return bindings.extend(t2, t1)

If t1 is a pair, so must be `r`.  This means that I can only unify arrays of nested arrays bottoming out on values or objects.  I cannot unify objects at the moment.

      if _.isArray(t1) && _.isArray(t2)
        bindings = F.unify(_.first(t1), _.first(t2), bindings)
        bindings = if (bindings isnt null) then F.unify(_.rest(t1), _.rest(t2), bindings) else bindings
        return bindings
      return null

# Operational logic
# -----------------

Now we can combine non-deterministic functions (Part 1) and the representation of knowledge (Part 2) into a logic system.  We introduce a `goal` -- a non-deterministic function that takes a substitution and produces 0, 1 or more other bindings (new knowledge). In case the goal produces 0 bindings, we say that the goal failed. We will call any result produced by the goal an "outcome".

The functions `succeed` and `fail` defined earlier are obviously  goals.  The latter is the failing goal. OTH, `succeed` is the trivial successful goal, a tautology that doesn't improve our knowledge of the world. We can now add another primitive goal, the result of a "measurement".  The quantum-mechanical connotations of "the measurement" must be obvious by now.

    F.goal = (l, r) ->
      (bindings) ->
        result = F.unify(l, r, bindings)
        return F.succeed(result) if result isnt null
        return F.fail(bindings)

We also need a way to 'run' a goal, to see what knowledge we can obtain starting from sheer ignorance

    F.run = (goal) ->
      goal(F.ignorance)

# Logic programs
# --------------

We can build more complex goals using lambda-abstractions and previously defined combinators, `conj` and `disj`.  For example, we can define the function `choice` such that `choice(t1, array)` is a goal that succeeds if `t1` is an element of `array`.

    F.choice = ($v, list) ->
      return F.fail if _.isEmpty(list)

      F.disj(F.goal($v, _.first(list)),
                    F.choice($v, _.rest(list)))

The name `choice` should evoke [The Axiom of Choice](http://en.wikipedia.org/wiki/Axiom_of_choice), but I'll use a more common name:

      F.membero = F.choice

Now I can write a very primitive program: find an element that is common in two lists:

    F.commono = (l, r) ->
      $x = F.lvar("x")
      F.conj(F.choice($x, l),
             F.choice($x, r))

    F.conso = ($a, $b, list) -> F.goal(_.cons($a, $b), list)

    F.joino = ($a, $b, list) -> F.goal([$a, $b], list)


TODO - more examples

# Exports and sundries
# --------------------

	  if module?
	    module.exports = F
	  else
	    root.F = F

	)(this)
