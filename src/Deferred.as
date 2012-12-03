/**
 * ASDeferred 0.0.1 Copyright (c) 2011 minodisk ( www.dsk.mn )
 * Ported from JSDeferred 0.4.0.
 *
 * JSDeferred 0.4.0 Copyright (c) 2007 cho45 ( www.lowreal.net )
 * See http://github.com/cho45/jsdeferred
 */
package {
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

  static public function chain():Deferred {
    var chain:Deferred = Deferred.next();
    for (var i:int = 0, len:int = arguments.length; i < len; i++) (function (obj:*):void {
      switch (typeof obj) {
        case "function":
          var name:String = null;
          try {
            name = obj.toString().match(/^\s*function\s+([^\s()]+)/)[1];
          } catch (e:Error) {
          }
          if (name != "error") {
            chain = chain.next(obj);
          } else {
            chain = chain.error(obj);
          }
          break;
        case "object":
          chain = chain.next(function ():Deferred {
            return Deferred.parallel(obj);
          });
          break;
        default:
          throw "unknown type in process chains";
      }
    })(arguments[i]);
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

  static public function parallel(dl:*):Deferred {
    var isArray:Boolean = false;
    if (arguments.length > 1) {
      dl = Array.prototype.slice.call(arguments);
      isArray = true;
    } else if (dl is Array) {
      isArray = true;
    }
    var ret:Deferred = new Deferred(), values:Object = {}, num:int = 0;
    for (var i:* in dl) if (dl.hasOwnProperty(i)) (function (d:*, i:*):void {
      if (d is Function) dl[i] = d = Deferred.next(d);
      d.next(function (v:*):void {
        values[i] = v;
        if (--num <= 0) {
          if (isArray) {
            values.length = dl.length;
            values = Array.prototype.slice.call(values, 0);
          }
          ret.call(values);
        }
      }).error(function (e:Error):void {
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

  static public function earlier(dl:*):Deferred {
    var isArray:Boolean = false;
    if (arguments.length > 1) {
      dl = Array.prototype.slice.call(arguments);
      isArray = true;
    } else if (dl is Array) {
      isArray = true;
    }
    var ret:Deferred = new Deferred(), values:Object = {}, num:int = 0;
    for (var i:* in dl) if (dl.hasOwnProperty(i)) (function (d:*, i:*):void {
      d.next(function (v:*):void {
        values[i] = v;
        if (isArray) {
          values.length = dl.length;
          values = Array.prototype.slice.call(values, 0);
        }
        ret.call(values);
        ret.canceller();
      }).error(function (e:Error):void {
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
    var o:Object = {
      begin: n.begin || 0,
      end  : (typeof n.end == "number") ? n.end : n - 1,
      step : n.step || 1,
      last : false,
      prev : null
    };
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
        /*ret = */fun(i++);
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

  static public function connect(funo:*, options:*):Function {
    var target:Object, func:Function, obj:Object;
    if (typeof arguments[1] == "string") {
      target = arguments[0];
      func = target[arguments[1]];
      obj = arguments[2] || {};
    } else {
      func = arguments[0];
      obj = arguments[1] || {};
      target = obj.target;
    }

    var partialArgs:Array = obj.args ? Array.prototype.slice.call(obj.args, 0) : [];
    var callbackArgIndex:int = isFinite(obj.ok) ? obj.ok : obj.args ? obj.args.length : undefined;
    var errorbackArgIndex:int = (obj.ng === null) ? -1 : obj.ng;

    return function ():Deferred {
      var d:Deferred = new Deferred().next(function (args:Arguments):void {
        var next:Function = this._next.callback.ok;
        this._next.callback.ok = function ():* {
          return next.apply(this, args.args);
        };
      });

      var args:Array = partialArgs.concat(Array.prototype.slice.call(arguments, 0));
      if (!(isFinite(callbackArgIndex) && callbackArgIndex !== -1)) {
        callbackArgIndex = args.length;
      }
      var callback:Function = function ():void {
        d.call(new Arguments(arguments))
      };
      args.splice(callbackArgIndex, 0, callback);
      if (isFinite(errorbackArgIndex) && errorbackArgIndex !== -1) {
        var errorback:Function = function ():void {
          d.fail(arguments)
        };
        args.splice(errorbackArgIndex, 0, errorback);
      }
      Deferred.next(function ():void {
        func.apply(target, args)
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
        next(function (mes:*) {
          d.call(mes);
        }).
        error(function (e:Error) {
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
    if (list === null) list = Deferred.methods;
//    if (obj === null)  obj = (function getGlobal() {
//      return this
//    })();
    for (var i:int = 0; i < list.length; i++) {
      var n:String = list[i];
      obj[n] = Deferred[n];
    }
    return Deferred;
  }


  public var loop:Function = Deferred.loop;
  public var wait:Function = Deferred.wait;

  public var callback:Object;
  public var canceller:Function;

  private var _id:uint = 0xe38286e381ae;
  private var _next:Deferred;

  public function Deferred() {
    init();
  }

  public function init() {
    _next = null;
    callback = {
      ok: Deferred.ok,
      ng: Deferred.ng
    };
    return this;
  }

  public function next(fun):Deferred {
    return _post("ok", fun);
  }

  public function error(fun):Deferred {
    return _post("ng", fun);
  }

  public function call(val:* = null):Deferred {
    return _fire("ok", val);
  }

  public function fail(err):Deferred {
    return _fire("ng", err);
  }

  public function cancel():Deferred {
    if (canceller) {
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
    } catch(e:Error) {
      next = "ng";
      value = e;
      if (onerror) onerror(e);
    } catch (e:*) {
      e = new Error(e);
      next = "ng";
      value = e;
      if (onerror) onerror(e);
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
  public var args:Array;

  public function Arguments(args) {
    this.args = Array.prototype.slice.call(args, 0)
  }
}