package {
import flash.display.Sprite;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.fscommand;
import flash.utils.setTimeout;

public class Test extends Sprite {
  private var loader:URLLoader;
  private var data:String;
  private var testfuns:Array;
  private var expects:int;

  public function Test() {
    loader = new URLLoader();
    loader.addEventListener(Event.COMPLETE, loaded);
    loader.load(new URLRequest('../test/Test.as'));
  }


  // assertion

  private function show(okng:String, msg:String, expect:*, result:*):void {
    var out:Array = [];
    out.push(color(46, "[", [expects - testfuns.length, expects].join("/"), "]"));
    if (okng == "skip") {
      out.push(" ", color(33, "skipped " + expect + " tests: " + msg));
      trace(out.join(""));
      while (expect--) testfuns.pop();
    } else if (okng == "ng") {
      testfuns.pop();
      expect = (typeof expect == "function") ? uneval(expect).match(/[^{]+/) + "..." : uneval(expect);
      result = (typeof result == "function") ? uneval(result).match(/[^{]+/) + "..." : uneval(result);
      out.push(["NG Test::", msg, expect, result].join("\n"));
      trace(out.join(""));
//      process.exit(1);
      exit();
    } else {
      testfuns.pop();
      out.push(" ", color(32, "ok"));
      trace(out.join(""));
    }
  }

  private function ok(msg:String, expect:* = null, result:* = null):Boolean {
    show("ok", msg, expect, result);
    return true;
  }

  private function ng(msg:String, expect:* = null, result:* = null):Boolean {
    show("ng", msg, expect, result);
    return true;
  }

  private function skip(msg:String, expect:* = null, result:* = null):Boolean {
    show("skip", msg, expect, result);
    return true;
  }

  private function expect(msg:String, expect:* = null, result:* = null):Boolean {
    if (expect == result) {
      show("ok", msg, expect, result);
    } else {
      show("ng", msg, expect, result);
    }
    return true;
  }


  // logger

  function msg(m):void {
    trace(m);
  }

  function log(m):void {
    trace(m);
  }

  function print(m):void {
    trace(m);
  }


  // utilities

  function color(col:uint, ...msgs:Array):String {
    return msgs.join(' ');
  }

  function uneval(o:Object) {
    switch (typeof o) {
      case "undefined" :
        return "(void 0)";
      case "boolean"   :
        return String(o);
      case "number"    :
        return String(o);
      case "string"    :
        return '"' + o.replace(/"/g, '\\"') + '"';
      case "function"  :
        return "(" + o.toString() + ")";
      case "object"    :
        if (o == null) return "null";
        var type = {}.toString.call(o).match(/\[object (.+)\]/);
        if (!type) throw TypeError("unknown type:" + o);
        switch (type[1]) {
          case "Array":
            var ret = [];
            for (var i = 0; i < o.length; i++) ret.push(arguments.callee(o[i]));
            return "[" + ret.join(", ") + "]";
          case "Object":
            var ret = [];
            for (var i in o) {
              if (!o.hasOwnProperty(i)) continue;
              ret.push(arguments.callee(i) + ":" + arguments.callee(o[i]));
            }
            return "({" + ret.join(", ") + "})";
          case "Number":
            return "(new Number(" + o + "))";
          case "String":
            return "(new String(" + arguments.callee(o) + "))";
          case "Date":
            return "(new Date(" + o.getTime() + "))";
          default:
            if (o.toSource) return o.toSource();
            throw TypeError("unknown type:" + o);
        }
    }
    return null;
  }

  function keys(obj:Object):Array {
    var keys:Array = []
      , key:String
      ;
    for (key in obj) {
      keys.push(key);
    }
    return keys;
  }

  function calcAccuracy():Deferred {
    var d:Deferred = new Deferred();
    var r:Array = [];
    var i:int = 30;
    var t:Number = new Date().getTime();
    setTimeout(function ():void {
      if (i-- > 0) {
        var n:Number = new Date().getTime();
        r.push(n - t);
        t = n;
        setTimeout(arguments.callee, 0);
      } else {
        d.call(r);
      }
    }, 0);
    return d;
  }


  // complete to load this file
  private function loaded(e:Event):void {
    data = loader.data;
    data = data.match(/\/\/ ::Test::Start::([\s\S]+)::Test::End::/)[1];
    testfuns = [];
    data.replace(/(ok|expect)\(.+/g, function (m) {
      testfuns.push(m);
      return m;
    });
    expects = testfuns.length;
    run();
  }

  private function run():void {
    // ::Test::Start::

//    Deferred.define();

    function calcAccuracy() {
      var d = new Deferred();
      var r = [];
      var i = 30;
      var t = new Date().getTime();
      setTimeout(function () {
        if (i-- > 0) {
          var n = new Date().getTime();
          r.push(n - t);
          t = n;
          setTimeout(arguments.callee, 0);
        } else {
          d.call(r);
        }
      }, 0);
      return d;
    }

    msg("Loaded " + testfuns.length + " tests;");
    // AS では Deferred.next の実装を環境によって分けていない
//    log("Deferred.next Mode:" + uneval({
//      _faster_way_Image: !!Deferred.next_faster_way_Image,
//      _faster_way_readystatechange: !!Deferred.next_faster_way_readystatechange
//    }));
    log(String(Deferred.next));

    msg("Basic Tests::");

    expect("new Deferred", true, (new Deferred) instanceof Deferred);
    skip("Deferred()", 1); // AS では new なしのコールは型変換と取られる

    new function () {
      var testobj = {};
      Deferred.define(testobj);
      expect("define() next", Deferred.next, testobj.next);
      expect("define() loop", Deferred.loop, testobj.loop);
    };

    new function () {
      var testobj = {};
      Deferred.define(testobj, ["next"]);
      expect("define() next", Deferred.next, testobj.next);
      expect("define() loop (must not be exported)", undefined, testobj.loop);
    };

    new function () {
      var d = next(function () {
        ng("Must not be called!!");
      });
      d.cancel();
    };

    new function () {
      var d = new Deferred();
      d.callback.ok = function () {
        ng("Must not be called!!");
      };
      d.cancel();
      d.call();
    };

    new function () {
      var d = new Deferred();
      var r = undefined;
      Deferred.onerror = function (e) {
        r = e;
      };
      d.fail("error");
      expect("Deferred.onerror", "error", r);

      r = undefined;
      Deferred.onerror = null; // AS ではメンバを delete できないので null を代入する
      d.fail("error");
      expect("Deferred.onerror", undefined, r);
    };

    new function () {
      expect("Deferred.isDeferred(new Deferred())", true, Deferred.isDeferred(new Deferred()));

      expect("TEST CONDITION", true, new _Deferred() instanceof Deferred); // AS版では extends で実装しているため true になる
      expect("Deferred.isDeferred(new _Deferred())", true, Deferred.isDeferred(new _Deferred()));

      expect("Deferred.isDeferred()", false, Deferred.isDeferred());
      expect("Deferred.isDeferred(null)", false, Deferred.isDeferred(null));
      expect("Deferred.isDeferred(true)", false, Deferred.isDeferred(true));
      expect("Deferred.isDeferred('')", false, Deferred.isDeferred(''));
      expect("Deferred.isDeferred(0)", false, Deferred.isDeferred(0));
      expect("Deferred.isDeferred(undefined)", false, Deferred.isDeferred(undefined));
      expect("Deferred.isDeferred({})", false, Deferred.isDeferred({}));
    };

    Deferred.onerror = function (e) {
      log("DEBUG: Errorback will invoke:" + e);
      if (e is Error) {
        trace((e as Error).getStackTrace());
      }
    };

// Start Main Test
    msg("Start Main Tests::");
    next(function () {
      msg("Information");
      return calcAccuracy().next(function (r) {
        print('setTimeout Accuracy: ' + uneval(r));
      });
    }).
      next(function () {
        msg("Process sequence");

        var vs = [];
        var d = next(function () {
          vs.push("1");
        }).
          next(function () {
            vs.push("2");
            expect("Process sequence", "0,1,2", vs.join(","));
          });

        vs.push("0");

        return d;
      }).
      next(function () {
        msg("Process sequence (Complex)");

        var vs = [];
        return next(function () {
          expect("Process sequence (Complex)", "", vs.join(","));
          vs.push("1");
          return next(function () {
            expect("Process sequence (Complex)", "1", vs.join(","));
            vs.push("2");
          });
        }).
          next(function () {
            expect("Process sequence (Complex)", "1,2", vs.join(","));
          });
      }).
      next(function () {
        msg("Test Callback, Errorback chain::");
        return next(function () {
          throw "Error";
        }).
          error(function (e) {
            expect("Errorback called", "Error", e);
            return e;
          }).
          next(function (e) {
            expect("Callback called", "Error", e);
            throw "Error2";
          }).
          next(function (e) {
            ng("Must not be called!!");
          }).
          error(function (e) {
            expect("Errorback called", "Error2", e);
          });
      }).
      next(function () {
//        delete Deferred.prototype.wait;
//        Deferred.register("wait", wait);
        return next(function () {
          msg("register test");
        }).
          next(function () {
            msg("registered wait")
          }).
          wait(0.1).
          next(function () {
            msg("registered loop")
          }).
          loop(1,function () {
          }).
          next(function (n) {
            ok("register test");
          }).
          error(function (e) {
            ng(e);
          });
      }).
      next(function () {
        var a, b;
        return next(function () {
          function pow(x, n) {
            expect("child deferred chain", a._next, b._next);
            function _pow(n, r) {
              print(uneval([n, r]));
              if (n == 0) return r;
              return call(_pow, n - 1, x * r);
            }

            return call(_pow, n, 1);
          }

          a = this;
          b = call(pow, 2, 10);
          return b;
        }).
          next(function (r) {
            expect("pow calculate", 1024, r);
          }).
          error(function (e) {
            ng("Error on pow", "", e);
          });
      }).
      error(function (e) {
        ng("Error on Test Callback, Errorback chain", "", e);
      }).
      next(function () {
        msg("Utility Functions Tests::");

        return next(function () {
          return wait(0).next(function (i) {
            ok("wait(0) called", "1000ms >", i);
          });
        }).
          next(function () {
          }).
          error(function (e) {
            ng("Error on wait Tests", "", e);
          }).
          next(function () {
            return call(function (test) {
              expect("call test1", 10, test);
              return call(function (t, u) {
                expect("call test2", 10, t);
                expect("call test2", 20, u);
              }, 10, 20);
            }, 10);
          }).
          next(function () {
            var t = 0;
            return loop(5,function (i) {
              expect("loop num", t++, i);
              /* dummy for expects
               * expect()
               * expect()
               * expect()
               * expect()
               */
              return "ok";
            }).next(function (r) {
                expect("loop num. result", "ok", r);
                expect("loop num. result", 5, t);
              });
          }).
          next(function () {
            var t = 0;
            return loop(2,function (i) {
              expect("loop num", t++, i);
              /* dummy for expects
               * expect()
               */
              return "ok";
            }).next(function (r) {
                expect("loop num. result", "ok", r);
                expect("loop num. result", 2, t);
              });
          }).
          next(function () {
            var t = 0;
            return loop(1,function (i) {
              expect("loop num", t++, i);
              return "ok";
            }).next(function (r) {
                expect("loop num. result", "ok", r);
                expect("loop num. result", 1, t);
              });
          }).
          next(function () {
            var t = 0;
            return loop(0,function (i) {
              t++;
            }).next(function () {
                expect("loop num 0 to 0. result", 0, t);
              });
          }).
          next(function () {
            var t = 0;
            return loop({begin:0, end:0},function (i) {
              t++;
            }).next(function () {
                expect("loop num begin:0 to end:0. result", 1, t);
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:1},function (n, o) {
              print(uneval(o));
              r.push(n);
              l.push(o.last);
              return r;
            }).next(function (r) {
                expect("loop end:10, step:1", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:1 last?", [false, false, false, false, false, false, false, false, false, false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:2},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:2", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:2 last?", [false, false, false, false, false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:3},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:3", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:3 last?", [false, false, false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:5},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:5", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:5 last?", [false, false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:9},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:9", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:9 last?", [false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:10},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:10", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:10 last?", [false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({end:10, step:11},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop end:10, step:11", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop end:10, step:11 last?", [true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            var l = [];
            return loop({begin:1, end:10, step:3},function (n, o) {
              print(uneval(o));
              l.push(o.last);
              for (var i = 0; i < o.step; i++) {
                r.push(n + i);
              }
              return r;
            }).next(function (r) {
                expect("loop begin:1, end:10, step:3", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].join(), r.join());
                expect("loop begin:1, end:10, step:3 last?", [false, false, false, true].join(), l.join());
              });
          }).
          next(function () {
            var r = [];
            return repeat(0,function (i) {
              r.push(i);
            }).
              next(function (ret) {
                expect("repeat 0 ret val", undefined, ret);
                expect("repeat 0", [].join(), r.join());
              });
          }).
          next(function () {
            var r = [];
            return repeat(10,function (i) {
              r.push(i);
            }).
              next(function (ret) {
                expect("repeat 10", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].join(), r.join());
              });
          }).
          next(function () {
            return parallel([]).
              next(function () {
                ok("parallel no values");
              });
          }).
          next(function () {
            return parallel([next(function () {
              return 0
            }), next(function () {
              return 1
            })]).
              next(function (values) {
                print(uneval(values));
                expect("parallel values 0", 0, values[0]);
                expect("parallel values 1", 1, values[1]);
              });
          }).
          next(function () {
            return parallel({foo:next(function () {
              return 0
            }), bar:next(function () {
              return 1
            })}).
              next(function (values) {
                print(uneval(values));
                expect("parallel named values foo", 0, values.foo);
                expect("parallel named values bar", 1, values.bar);
              });
          }).
          next(function () {
            return parallel(next(function () {
              return 0
            }), next(function () {
              return 1
            })).
              next(function (values) {
                print(uneval(values));
                expect("parallel values 0", 0, values[0]);
                expect("parallel values 1", 1, values[1]);
              });
          }).
          next(function () {
            return parallel([
              function () {
                return 0;
              },
              function () {
                return 1;
              }
            ]).
              next(function (values) {
                print(uneval(values));
                expect("parallel values 0", 0, values[0]);
                expect("parallel values 1", 1, values[1]);
              });
          }).
          next(function () {
            var d = parallel([
              function () {
                return 0;
              },
              function () {
                return 1;
              }
            ]);

            d.cancel();
          }).
          next(function () {
            return Deferred.earlier([
              wait(0).next(function () {
                return 1
              }),
              wait(1).next(function () {
                return 2
              })
            ]).
              next(function (values) {
                print(uneval(values));
                expect("earlier named values 0", 1, values[0]);
                expect("earlier named values 1", undefined, values[1]);
              });
          }).
          next(function () {
            return Deferred.earlier([
              wait(1).next(function () {
                return 1
              }),
              wait(0).next(function () {
                return 2
              })
            ]).
              next(function (values) {
                print(uneval(values));
                expect("earlier named values 0", undefined, values[0]);
                expect("earlier named values 1", 2, values[1]);
              });
          }).
          next(function () {
            return Deferred.earlier(
              wait(1).next(function () {
                return 1
              }),
              wait(0).next(function () {
                return 2
              })
            ).
              next(function (values) {
                print(uneval(values));
                expect("earlier named values 0", undefined, values[0]);
                expect("earlier named values 1", 2, values[1]);
              });
          }).
          next(function () {
            return Deferred.earlier({
              foo:wait(0).next(function () {
                return 1
              }),
              bar:wait(1).next(function () {
                return 2
              })
            }).
              next(function (values) {
                print(uneval(values));
                expect("earlier named values foo", 1, values.foo);
                expect("earlier named values bar", undefined, values.bar);
              });
          }).
          next(function () {
            return Deferred.earlier({
              foo:wait(1).next(function () {
                return 1
              }),
              bar:wait(0).next(function () {
                return 2
              })
            }).
              next(function (values) {
                print(uneval(values));
                expect("earlier named values foo", undefined, values.foo);
                expect("earlier named values bar", 2, values.bar);
              });
          }).
          error(function (e) {
            trace(e);
            ng("Error on Tests", "", e);
          });
      }).
      next(function () {
        return Deferred.chain(
          function () {
            ok("called");
            return wait(0.5);
          },
          function (w) {
            ok("called");
            throw "error";
          },
          // AS では関数名を取得することができないので ErrorFunction インスタンスのファクトリメソッドを使うことにする
          errorFunction(function error(e) {
            ok("error called: " + e);
          }),
          [
            function () {
              ok("callled");
              return next(function () {
                return 1
              });
            },
            function () {
              ok("callled");
              return next(function () {
                return 2
              });
            }
          ],
          function (result) {
            expect("array is run in parallel", result[0], 1);
            expect("array is run in parallel", result[1], 2);
          },
          {
            foo:function () {
              return 1
            },
            bar:function () {
              return 2
            }
          },
          function (result) {
            expect("object is run in parallel", result.foo, 1);
            expect("object is run in parallel", result.bar, 2);
          },
          // AS では関数名を取得することができないので ErrorFunction インスタンスのファクトリメソッドを使うことにする
          errorFunction(function error(e) {
            ng(e);
          })
        );
      }).
      next(function () {
        msg("Connect Tests::");
        return next(function () {
          var f = function (arg1, arg2, callback) {
            callback(arg1 + arg2);
          }
          var fd = Deferred.connect(f, { ok:2 });
          return fd(2, 3).next(function (r) {
            expect('connect f 2 arguments', 5, r);
          });
        }).
          next(function () {
            var obj = {
              f:function (arg1, arg2, callback) {
                callback(this.plus(arg1, arg2));
              },

              plus:function (a, b) {
                return a + b;
              }
            };
            var fd = Deferred.connect(obj, "f", { ok:2 });
            return fd(2, 3).next(function (r) {
              expect('connect f target, "method"', 5, r);
            });
          }).
          next(function () {
            var obj = {
              f:function (arg1, arg2, callback) {
                callback(this.plus(arg1, arg2));
              },

              plus:function (a, b) {
                return a + b;
              }
            };
            var fd = Deferred.connect(obj, "f");
            return fd(2, 3).next(function (r) {
              expect('connect f target, "method"', 5, r);
            });
          }).
          next(function () {
            var f = function (arg1, arg2, callback) {
              callback(arg1 + arg2);
            }
            var fd = Deferred.connect(f, { args:[2, 3] });

            return fd().next(function (r) {
              expect('connect f bind args', 5, r);
            });
          }).
          next(function () {
            var f = function (arg1, arg2, callback) {
              callback(arg1 + arg2);
            }
            var fd = Deferred.connect(f, { args:[2, 3] });

            return fd(undefined).next(function (r) {
              expect('connect f bind args', 5, r);
            });
          }).
          next(function () {
            var f = function (arg1, arg2, arg3, callback) {
              callback(arg1 + arg2 + arg3);
            }
            var fd = Deferred.connect(f, { ok:3, args:[2, 3] });

            return fd(5).next(function (r) {
              expect('connect f bind args', 10, r);
            });
          }).
          next(function () {
            var obj = {
              f:function (arg1, arg2, callback) {
                callback(this.plus(arg1, arg2));
              },

              plus:function (a, b) {
                return a + b;
              }
            };
            var fd = Deferred.connect(obj, "f", { args:[2, 3] });
            return fd().next(function (r) {
              expect('connect f bind args 2', 5, r);
            });
          }).
          next(function () {
            var timeout = Deferred.connect(function (n, cb) {
              setTimeout(cb, n);
            });

            return timeout(1).next(function () {
              ok('connect setTimeout');
            });
          }).
          next(function () {
            var timeout = Deferred.connect(function (n, cb) {
              setTimeout(cb, n);
            });

            var seq = [0];
            return timeout(1).next(function () {
              expect('sequence of connect', '0', seq.join(','));
              seq.push(1);
              return next(function () {
                expect('sequence of connect', '0,1', seq.join(','));
                seq.push(2);
              });
            }).
              next(function () {
                expect('sequence of connect', '0,1,2', seq.join(','));
              });
          }).
          next(function () {
            var f = Deferred.connect(function (cb) {
              setTimeout(function () {
                cb(0, 1, 2);
              }, 0);
            });
            return f().next(function (a, b, c) {
              expect('connected function pass multiple arguments to callback', '0,1,2', [a, b, c].join(','));
              return f();
            }).
              next(function (a, b, c) {
                expect('connected function pass multiple arguments to callback (child)', '0,1,2', [a, b, c].join(','));
              });
          });
      }).
      next(function () {
        var f = function (arg1, arg2, callback) {
          setTimeout(function () {
            callback(arg1, arg2);
          }, 10);
        }
        var fd = Deferred.connect(f, { ok:2 });
        return fd(2, 3).next(function (r0, r1) {
          expect('connect f callback multiple values', 2, r0);
          expect('connect f callback multiple values', 3, r1);
        });
      }).
      next(function () {
        var f = function (arg1, arg2, callback) {
          setTimeout(function () {
            callback(arg1 + arg2);
          }, 10);
        }
        var fd = Deferred.connect(f);
        return fd(2, 3).next(function (r) {
          expect('connect unset callbackArgIndex', 5, r);
        });
      }).
      next(function () {
        var f = function (arg1, arg2, callback, errorback, arg3) {
          setTimeout(function () {
            errorback(arg1, arg2, arg3);
          }, 10);
        }
        var fd = Deferred.connect(f, { ok:2, ng:3 });
        return fd(2, 3, 4).error(function (r) {
          expect('connect f errorback', 2, r[0]);
          expect('connect f errorback', 3, r[1]);
          expect('connect f errorback', 4, r[2]);
        });
      }).
      next(function () {
        var _this = new Object();
        var f = function (callback) {
          var self = this;
          setTimeout(function () {
            callback(_this === self);
          }, 10);
        };
        var fd = Deferred.connect(f, { target:_this, ok:0 });
        return fd().next(function (r) {
          expect("connect this", true, r);
        });
      }).
      next(function () {
        var count = 0;
        var successThird = function () {
          var deferred = new Deferred;
          setTimeout(function () {
            var c = ++count;
            if (c == 3) {
              deferred.call('third');
            } else {
              deferred.fail('no third');
            }
          }, 10);
          return deferred;
        }

        return next(function () {
          return Deferred.retry(4, successThird).next(function (mes) {
            expect('retry third called', 'third', mes);
            expect('retry third called', 3, count);
            count = 0;
          }).
            error(function (e) {
              ng(e);
            });
        }).
          next(function () {
            return Deferred.retry(3, successThird).next(function (mes) {
              expect('retry third called', 'third', mes);
              expect('retry third called', 3, count);
              count = 0;
            }).
              error(function (e) {
                ng(e);
              });
          }).
          next(function () {
            return Deferred.retry(2, successThird).next(function (e) {
              ng(e);
            }).
              error(function (mes) {
                ok('retry over');
              });
          }).
          error(function (e) {
            ng(e);
          });
      }).
      next(function () {
        msg("Stack over flow test: check not waste stack.");
        if (skip("too heavy", 1)) return;

        var num = 10001;
        return loop(num,function (n) {
          if (n % 500 == 0) print(n);
          return n;
        }).
          next(function (r) {
            expect("Long long loop", num - 1, r);
          }).
          error(function (e) {
            ng(e);
          });
      }).
      next(function () {
        msg("Done Main.");
      }).
      next(function () {
        msg("jQuery binding test")
        var Global = {}, $, document;
        if (Global.navigator && !/Rhino/.test(Global.navigator.userAgent)) {
          return next(function () {
            expect("$.ajax#toJSDeferred() should return deferred", true, $.ajax({ url:"./test.html" }).toJSDeferred() instanceof Deferred);
            expect("$.get#toJSDeferred() should return deferred", true, $.get("./test.html").toJSDeferred()           instanceof Deferred);
            expect("$.post#toJSDeferred() should return deferred", true, $.post("./test.html").toJSDeferred()          instanceof Deferred);
            expect("$.getJSON#toJSDeferred() should return deferred", true, $.getJSON("./test.html").toJSDeferred()       instanceof Deferred);
            expect("Deferred()#toJSDeferred() should return deferred", true, $.Deferred().toJSDeferred()       instanceof Deferred);

            expect("$.ajax should implement next()", true, !!$.ajax({ url:"./test.html" }).next);
            expect("$.ajax should implement error()", true, !!$.ajax({ url:"./test.html" }).error);
            expect("$.Deferred should implement next()", true, !!$.Deferred().next);
            expect("$.Deferred should implement error()", true, !!$.Deferred().error);
          }).
            next(function () {
              return $.ajax({
                url:"./test.html",
                success:function () {
                  ok("$.ajax#success 1");
                },
                error:function () {
                  ng("$.ajax#success 1");
                }
              }).
                next(function () {
                  ok("$.ajax#success 2");
                }).
                error(function (e) {
                  ng("$.ajax#success 2");
                });
            }).
            next(function () {
              return $.ajax({
                url:"error-404" + Math.random(),
                success:function () {
                  ng("$.ajax#error 1");
                },
                error:function () {
                  ok("$.ajax#error 1", "You may see error on console but it is correct.");
                }
              }).
                next(function () {
                  ng("$.ajax#error 2");
                }).
                error(function (e) {
                  ok("$.ajax#error 2");
                });
            }).
            next(function () {
              return next(function () {
                return $.get("./test.html");
              }).
                next(function () {
                  ok("$.get#success");
                }).
                error(function (e) {
                  ng("$.get#success");
                });
            }).
            next(function () {
              return next(function () {
                return $(document.body).fadeTo(100, 0).fadeTo(100, 1).promise().next(function () {
                  ok("promise()");
                });
              }).
                error(function (e) {
                  ng("promise()");
                });
            }).
            next(function () {
              return next(function () {
                var d = $.Deferred();
                setTimeout(function () {
                  d.resolve('ok');
                }, 10);
                return d;
              }).
                next(function (e) {
                  ok("$.Deferred " + e);
                }).
                error(function (e) {
                  ng("$.Deferred");
                });
            }).
            error(function (e) {
              ng("Error on jQuery Test:", "", e);
            });
        } else {
          skip("Not in browser", 16);
        }
        return null;
      }).
      next(function () {
        msg("Canceling Test:");
        return next(function () {
          return next(function () {
            msg("Calceling... No more tests below...");
            ok("Done");
            exit();
            this.cancel();
          }).
            next(function () {
              ng("Must not be called!! calceled");
            });
        });
      }).
      next(function () {
        ng("Must not be called!! calceled");
      }).
      error(function (e) {
        ng(e);
      });


// ::Test::End::
  }

  private function exit():void {
    if (expects - testfuns.length == expects) {
      print(color(32, "All tests passed"));
    } else {
      print(color(31, "Some tests failed..."));
//      process.exit(1);
      fscommand('quit');
    }
  }


}
}

// Make different origin Deferred class;
internal class _Deferred extends Deferred {
  function _Deferred() {
  }
}
