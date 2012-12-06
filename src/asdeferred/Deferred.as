/**
 * ASDeferred 0.0.1 Copyright (c) 2011 minodisk ( www.dsk.mn )
 * Ported from JSDeferred 0.4.0.
 *
 * JSDeferred 0.4.0 Copyright (c) 2007 cho45 ( www.lowreal.net )
 * See http://github.com/cho45/jsdeferred
 */
package asdeferred {
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

public class Deferred {
  static public const methods:Array = ["parallel", "wait", "next", "call", "loop", "repeat", "chain"];

  static public var onerror:Function;

  static public function ok(x:*):* {
    return x;
  }

  static public function ng(x:*):void {
    throw  x;
  }

  static public function isDeferred(obj:* = null):Boolean {
    return obj is Deferred;
  }

  static public function next(fun:Function = null):Deferred {
    var d:Deferred = new Deferred();
    var id:uint = setTimeout(function ():void {
      d.call();
    }, 0);
    d.canceller = function ():void {
      clearTimeout(id);
    };
    if (fun !== null) {
      d.callback.ok = fun;
    }
    return d;
  }

  static public function chain(...args:Array):Deferred {
    var chain:Deferred = Deferred.next();
    for (var i:int = 0, len:int = args.length; i < len; i++) (function (obj:*):void {
      if (obj is ErrorFunction) {
        chain = chain.error((obj as ErrorFunction).fun);
      } else {
        switch (typeof obj) {
          case "function":
            // AS では関数名を取得することができない
//          var name:String = null;
//          try {
//            name = obj.toString().match(/^\s*function\s+([^\s()]+)/)[1];
//          } catch (e:*) {
//          }
//          if (name != "error") {
            chain = chain.next(obj);
//          } else {
//            chain = chain.error(obj);
//          }
            break;
          case "object":
            chain = chain.next(function ():Deferred {
              return Deferred.parallel(obj);
            });
            break;
          default:
            throw "unknown type in process chains";
        }
      }
    })(args[i]);
    return chain;
  }

  static public function wait(n:Number):Deferred {
    var d:Deferred = new Deferred(), t:Date = new Date();
    var id:uint = setTimeout(function ():void {
      d.call((new Date()).getTime() - t.getTime());
    }, n * 1000);
    d.canceller = function ():void {
      clearTimeout(id)
    };
    return d;
  }

  static public function call(fun:Function, ...args:Array):Deferred {
    return Deferred.next(function ():* {
      return fun.apply(this, args);
    });
  }

  static public function parallel(...args:Array):Deferred {
    var dl:* = args.length > 1 ? args : args[0];
    var isArray:Boolean = dl is Array;
    var ret:Deferred = new Deferred(), values:* = isArray ? [] : {}, num:int = 0;
    for (var i:* in dl) if (dl.hasOwnProperty(i)) (function (d:*, i:*):void {
      if (d is Function) dl[i] = d = Deferred.next(d);
      d.next(function (v:*):void {
        values[i] = v;
        if (--num <= 0) {
//          if (isArray) {
//            values.length = dl.length;
//            values = Array.prototype.slice.call(values, 0);
//          }
          ret.call(values);
        }
      }).error(function (e:*):void {
          ret.fail(e);
        });
      num++;
    })(dl[i], i);

    if (!num) Deferred.next(function ():void {
      ret.call();
    });
    ret.canceller = function ():void {
      for (var i:* in dl) if (dl.hasOwnProperty(i)) {
        dl[i].cancel();
      }
    };
    return ret;
  }

  static public function earlier(...args:Array):Deferred {
    var dl:* = args.length > 1 ? args : args[0];
    var isArray:Boolean = dl is Array;
    var ret:Deferred = new Deferred(), values:* = isArray ? [] : {}, num:int = 0;
    for (var i:* in dl) if (dl.hasOwnProperty(i)) (function (d:*, i:*):void {
      d.next(function (v:*):void {
        values[i] = v;
//        if (isArray) {
//          values.length = dl.length;
//          values = Array.prototype.slice.call(values, 0);
//        }
        ret.call(values);
        ret.canceller();
      }).error(function (e:*):void {
          ret.fail(e);
        });
      num++;
    })(dl[i], i);

    if (!num) Deferred.next(function ():void {
      ret.call()
    });
    ret.canceller = function ():void {
      for (var i:* in dl) if (dl.hasOwnProperty(i)) {
        dl[i].cancel();
      }
    };
    return ret;
  }

  static public function loop(n:*, fun:Function):Deferred {
    var o:Object
    if (n is Number) {
      o = {
        begin:0,
        end:n - 1,
        step:1,
        last:false,
        prev:null
      };
    } else {
      if (!(n.end is Number)) throw new TypeError("n.end isn't number");
      o = {
        begin:n.begin || 0,
        end:n.end,
        step:n.step || 1,
        last:false,
        prev:null
      };
    }
    var ret:*, step:int = o.step;
    return Deferred.next(function ():Deferred {
      function _loop(i:int):* {
        if (i <= o.end) {
          if ((i + step) > o.end) {
            o.last = true;
            o.step = o.end - i + 1;
          }
          o.prev = ret;
          ret = fun.call(this, i, o);
          if (Deferred.isDeferred(ret)) {
            return ret.next(function (r:*):Deferred {
              ret = r;
              return Deferred.call(_loop, i + step);
            });
          } else {
            return Deferred.call(_loop, i + step);
          }
        } else {
          return ret;
        }
      }

      return (o.begin <= o.end) ? Deferred.call(_loop, o.begin) : null;
    });
  }

  static public function repeat(n:int, fun:Function):Deferred {
    var i:int = 0/*, end = {}, ret = null*/;

    function next():Deferred {
      var t:Number = (new Date()).getTime();
      do {
        if (i >= n) return null;
        /*ret = */
        fun(i++);
      } while ((new Date()).getTime() - t < 20);
      return Deferred.call(next);
    }

    return Deferred.next(next);
  }

//  static public function register(name, fun) {
//    this.prototype[name] = function () {
//      var a = arguments;
//      return this.next(function () {
//        return fun.apply(this, a);
//      });
//    };
//  }
//  Deferred.register("loop", Deferred.loop);
//  Deferred.register("wait", Deferred.wait);

  static public function connect(funo:*, options:* = null, obj:Object = null):Function {
    var target:*, func:Function;
    if (typeof options == "string") {
      target = funo;
      func = target[options];
      obj = obj || {};
    } else {
      func = funo;
      obj = options || {};
      target = obj.target;
    }

    var partialArgs:Array = obj.args ? obj.args : [];
    var callbackArgIndex:int = (obj.ok != null) ? obj.ok : obj.args ? obj.args.length : -1;
    var errorbackArgIndex:int = (obj.ng != null) ? obj.ng : -1;

    return function (...args:Array):Deferred {
      var d:Deferred = new Deferred().next(function (args:Arguments):void {
        var next:Function = this._next.callback.ok;
        this._next.callback.ok = function ():* {
          return next.apply(this, args.args);
        };
      });

      args = partialArgs.concat(args);
      if (callbackArgIndex === -1) {
        callbackArgIndex = args.length;
      }
      var callback:Function = function ():void {
        d.call(new Arguments(arguments));
      };
      args.splice(callbackArgIndex, 0, callback);
      if (errorbackArgIndex !== -1) {
        var errorback:Function = function ():void {
          d.fail(arguments);
        };
        args.splice(errorbackArgIndex, 0, errorback);
      }
      Deferred.next(function ():void {
        func.apply(target, args);
      });
      return d;
    };
  }

  static public function retry(retryCount:int, funcDeferred:Function, options:Object = null):Deferred {
    if (options === null) options = {};

    var wait:Number = options.wait || 0;
    var d:Deferred = new Deferred();
    var retry:Function = function ():void {
      var m:Deferred = funcDeferred(retryCount);
      m.
        next(function (mes:*):void {
          d.call(mes);
        }).
        error(function (e:*):void {
          if (--retryCount <= 0) {
            d.fail(['retry failed', e]);
          } else {
            setTimeout(retry, wait * 1000);
          }
        });
    };
    setTimeout(retry, 0);
    return d;
  }

  static public function define(obj:Object, list:Array = null):Class {
    if (list == null) list = Deferred.methods;
//    if (obj === null)  obj = (function getGlobal() {
//      return this
//    })();
    for (var i:int = 0; i < list.length; i++) {
      var n:String = list[i];
      obj[n] = Deferred[n];
    }
    return Deferred;
  }

  static public function errorFunction(fun:Function):ErrorFunction {
    return new ErrorFunction(fun);
  }


  public var loop:Function = Deferred.loop;
  public var wait:Function = Deferred.wait;

  public var callback:Object;
  public var canceller:Function;

  private var _id:uint = 0xe38286e381ae;
  internal var _next:Deferred;

  public function Deferred() {
    init();
  }

  public function init():Deferred {
    _next = null;
    callback = {
      ok:Deferred.ok,
      ng:Deferred.ng
    };
    return this;
  }

  public function next(fun:Function):Deferred {
    return _post("ok", fun);
  }

  public function error(fun:Function):Deferred {
    return _post("ng", fun);
  }

  public function call(val:* = null):Deferred {
    return _fire("ok", val);
  }

  public function fail(err:*):Deferred {
    return _fire("ng", err);
  }

  public function cancel():Deferred {
    if (canceller != null) {
      canceller();
    }
    return init();
  }

  public function _post(okng:String, fun:Function):Deferred {
    _next = new Deferred();
    _next.callback[okng] = fun;
    return _next;
  }

  public function _fire(okng:String, value:*):Deferred {
    var next:String = "ok";
    try {
      value = callback[okng].call(this, value);
    } catch (e:*) {
      next = "ng";
      value = e;
      if (onerror != null) onerror(e);
    }
    if (isDeferred(value)) {
      value._next = _next;
    } else {
      if (_next) _next._fire(next, value);
    }
    return this;
  }

}
}

internal class Arguments {
  public var args:Object;

  public function Arguments(args:Object) {
    this.args = args;
  }
}

internal class ErrorFunction {
  public var fun:Function;

  public function ErrorFunction(fun:Function) {
    this.fun = fun;
  }
}