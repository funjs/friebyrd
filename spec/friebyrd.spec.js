describe("friebyrd", function() {
    
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




