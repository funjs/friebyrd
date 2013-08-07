describe("friebyrd", function() {
    
    describe("non-deterministic functions", function() {
        function f1(x) { return F.succeed(x + " f1"); }
        function f2(x) { return F.succeed(x + " f2"); }
        function f3(x) { return F.succeed(x + " f3"); }
        function no(x) { return []; }
        describe("disj", function() {
            it("returns all the results of f1 and all the rsults of f2", function() {
                var rv = F.disj(f1, f2)("test1");
                expect(rv).toEqual(["test1 f1", "test1 f2"]);
            });
            
            it("returns no results only if neither f1 nor f2 returned any results", function() {
                var rv = F.disj(F.fail, F.fail)("test2");
                expect(rv).toEqual([]);
                rv = F.disj(F.fail, F.succeed)("test2");
                expect(rv).toEqual(["test2"]);
                rv = F.disj(F.succeed, F.fail)("test2");
                expect(rv).toEqual(["test2"]);
            });
        });
        
        describe("conj", function() {
            it("returns the result of f2 applied to output of f1(x)", function() {
                var rv = F.conj(f1, f2)("test3");
                expect(rv).toEqual(["test3 f1 f2"]);
            });
            
            it("returns no results if any of its arguments fails", function() {
                expect(F.conj(F.succeed, F.fail)("test4")).toEqual([]);
                expect(F.conj(F.fail, F.succeed)("test4")).toEqual([]);
            });
        });
    });
    
    describe("Goals", function() {

        describe("fail", function() {
            it("returns an empty list for any arguments", function() {
                expect(F.fail(5)).toEqual([]);
            });
        });

        describe("succeed", function() {
            it("returns a list containing its (first) argument", function() {
                expect(F.succeed(5)).toEqual([5]);
            });
        });
        
        describe("unify", function() {
            it("returns the substitution object on success", function() {
                var q = F.lvar("q");
                var b = F.unify(true, q, F.ignorance);
                expect(b.binds).toEqual({q: true});
            });
            
            it("can bind lvar to another lvar", function() {
                var q = F.lvar("q");
                var p = F.lvar("p");
                var b = F.unify(p, q, F.ignorance);
                expect(b.binds.p).toEqual(q);
            });
            
            it("can bind an lvar to a value", function() {
                var q = F.lvar("q");
                var p = F.lvar("p");
                var b = F.unify(p, q, F.ignorance);
                var b = F.unify(q, 1, b);
                expect(b.binds.q).toEqual(1);
            });
            
            it("can be composed with itself", function() {
                var q = F.lvar("q");
                var p = F.lvar("p");
                var b = F.unify(p, 1, F.unify(p, q, F.ignorance));
                expect(b.lookup(q)).toBe(1); 
            });
        });
        
        describe("goal method", function() {
            it("takes two arguments", function() {
                expect(F.goal.length).toBe(2);
            });
            it("returns a function", function() {
                var g = F.goal(1,2);
                expect(typeof g).toBe("function");                
            });
            describe("the function returned from F.goal", function() {
                it("returns a list of bindings (substitutions)", function() {
                    var q = F.lvar("q");
                    var g = F.goal(q, true);
                    var r = g(F.ignorance);
                    expect(r instanceof Array).toBe(true);
                    expect(r[0].binds).toEqual({q: true});
                });
            });
            
        });
    });

    describe("Logic Engine", function() {
        describe("run", function() {
            it("returns an empty list if its goal fails", function() {
                var q = F.lvar("q");
                var p = F.lvar("p");
                expect(F.run(F.fail)).toEqual([]);
                expect(F.run(F.goal(1, false))).toEqual([]);
                expect(F.run(F.goal(1, null))).toEqual([]);
                expect(F.run(F.goal(false, 1))).toEqual([]);
                expect(F.run(F.goal(null, 1))).toEqual([]);
                expect(F.run(F.goal(2, 1))).toEqual([]);
            });
            
            it("returns a non-empty list if its goal succeeds", function() {
                var q = F.lvar("q");
                var b = F.run(F.succeed);
                expect(b instanceof Array).toBe(true);
                expect(b[0].binds).toEqual({});
                b = F.run(F.goal(q, true));
                expect(b instanceof Array).toBe(true);
                expect(b[0].binds).toEqual({q: true});
            });

/**/            
        });
    });
/**/
});




