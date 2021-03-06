dofile("index.nut", true);

/**
 * Glorious testing suite
 */
__passed <- 0;
__total  <- 0;

function describe(ent, data) {
    ::print("\n Testing " + ent + ":\n");
    data(function(condition, exp) {
        try {
            assert(exp); __passed++;
            ::print("  \x1B[32m[✓]\x1B[0m " + ent + " " + condition + " - passed\n");
        } catch (e) {
            ::print("  \x1B[31m[✗]\x1B[0m " + ent + " " + condition + " - failed\n");
        }
        return __total++;
    });
}

::print("Starting test for squirrel-orm:\n");

/**
 * Actual test cases
 */
describe("Global namespace", function(it) {
    it("should have ORM.Query defined", ORM.Query);
    it("should have ORM.Entity defined", ORM.Entity);
    it("should have ORM.Field.Basic defined", ORM.Field.Basic);
});

describe("ORM.Driver", function(it) {
    ORM.Driver.configure({
        provider = "sqlite"
    });

    it("should be able to switch provider", ORM.Driver.storage.provider == "sqlite");

    ORM.Driver.setProxy(function(query, cb) {
        cb(null, true);
    });

    ORM.Driver.query("", function(err, result) {
        it("should be able to response to proxy", result);
    });
})

describe("ORM.Query", function(it) {

    local q = ORM.Query("select * from table").compile();
    it("should compile plain expressions", q == "select * from table");

    local q = ORM.Query("select * from table where a = :param").setParameter("param", 2).compile();
    it("should compile expressions with parameters", q == "select * from table where a = 2");

    // local q = ORM.Query("select * from table where a = :param").setParameter("param", "somestr").compile();
    // is("Query able to escape string parameter", q == "select * from table where a = 'somestr'");

    class TestingOne extends ORM.Entity {
        static classname = "Testing";
        static table = "tbl_tst";
    }

    local q = ORM.Query("select * from @TestingOne").compile();
    it("should compile expressions with entity names", q == "select * from tbl_tst");

    ORM.Driver.setProxy(function(query, cb) {
        return cb(null, [{single = true}, {multiple = true}]);
    });

    ORM.Query("select * from tbl").getSingleResult(function(err, obj) {
        it("should return single result after query", obj.single == true);
    });

    ORM.Query("select * from tbl").getResult(function(err, obj) {
        it("should return multiple results after query", (obj.len() == 2) && (obj[1].multiple == true));
    });

    class TestingTwo extends ORM.Entity {
        static classname = "TestingTwo";
        static table = "tbl";
        static fields = [ ORM.Field.Integer({ name = "other", value = 1 }) ];
    }

    ORM.Driver.setProxy(function(q, cb) {
        cb(null, [
            { id = 1, _entity = "TestingTwo", other = 124 }
        ]);
    });

    ORM.Query("select * from tbl").getSingleResult(function(err, results) {
        it("should be able to build entity object from plain data", 
            (results instanceof TestingTwo) &&
            (results instanceof ORM.Entity) &&
            (results.get("id") == 1) &&
            (results.get("other") == 124)
        );
    });
});

describe("ORM.Fields", function(it) {

});

describe("ORM.Entity", function(it) {
    ORM.Driver.setProxy(function(q, cb) {
        cb(null, [{id = 1}]);
    });

    class TestA extends ORM.Entity {
        static classname = "TestA";
        static table = "tbl_a";

        static fields = [
            ORM.Field.Integer({name = "foo"})
        ];
    }

    class TestB extends ORM.Entity {
        static classname = "TestB";
        static table = "tbl_b";
    }

    local a = TestA();
    local b = TestB();

    a.foo = 15;

    it("should have field foo", a.fields[2].__name == "foo");
    // print(b.fields[0].__name);
    // 
});

/**
 * Results
 */
::print(format("\nTotal passed %d/%d, total failed %d.\n", __passed, __total, __total - __passed));
