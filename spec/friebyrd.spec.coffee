root = this

test1 = () ->
  F.disj(
    F.disj(F.fail, F.succeed),
    F.conj(
      F.disj(((x) -> F.succeed(x + 1)),
             ((x) -> F.succeed(x + 10))),
      F.disj(F.succeed, F.succeed)))(100);

# test1();
#=> [100, 101, 101, 110, 110]
