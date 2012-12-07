# ASDeferred

[cho45/jsdeferred](https://github.com/cho45/jsdeferred)のActionScript3.0移植。テストも移植して実行。
lib/asdeferrd.swc か src/asdeferred を読み込んで使用。

## チュートリアルとかAPIリファレンス

[JSDeferred - Asynchronous library in JavaScript. Standalone and Compact](http://cho45.stfuawsc.com/jsdeferred/)参照。
使い方の異なる点があるので[JSDeferredとの違い](#jsdeferredとの違い)も参照。

## JSDeferredとの違い

言語仕様の違いから使用方法が異なっている点がある。
重要な違いと代替手段を下記に説明する。
コード例の一部を[JSDeferred - Asynchronous library in JavaScript. Standalone and Compact](http://cho45.stfuawsc.com/jsdeferred/)
から抜粋して比較している。

### `define`メソッド

JSDeferredには`define`メソッドが存在し、引数を与えずに実行した場合global(windowオブジェクト)にDeferredの静的メソッドのショートカットを作ることが可能だが、
ASDeferredではasdeferredパッケージ空間のショートカットメソッドをimportする必要がある。
AS3の言語仕様上globalにプロパティを追加することはできないため。

JSDeferred
```javascript
Deferred.define();

next(function () {
  console.log("Hello!");
  return wait(5);
}).
next(function () {
  console.log("World!");
});
```

ASDeferred
```actionscript
import asdeferred.next;
import asdeferred.wait;

next(function ():Deferred {
  trace("Hello!");
  return wait(5);
}).
next(function ():void {
  trace("World!");
});
```

ASDeferredにも`define`メソッドは存在するが第一引数は必須で、オブジェクトに静的メソッドの参照をプロパティとして追加することはできるが、
globalにプロパティを追加できない以上は使用するシチュエーションはあまりないと思われる。

```actionscript
var obj:Object = {};
define(obj, ['next', 'wait']);
obj.
  next(function ():Deferred {
    trace("Hello!");
    return obj.wait(5);
  }).
  next(function ():void {
    trace("World!");
  });
```

### `register`メソッドの存在

JSDeferredには`register`メソッドが存在し、Deferredのprototypeに静的メソッドのコピーを作ることが可能だが、
ASDeferredには存在しない。

### `chain`メソッドでエラーをキャッチする方法

JSDeferredではerrorという名前の関数を`chain`の引数にすることでエラーを処理する関数を設定することが可能だが、
ASDeferredでは`catcher`という`Catcher`インスタンスを返すファクトリメソッドの引数としてエラーを処理する関数を設定する必要がある。
AS3では関数名を取得する手段がないため、`chain`の引数を走査する際に`Catcher`インスタンスかを判定し、エラーを処理する関数を判別する実装になっている。

JavaScript
```javascript
chain(
  function () {
    return wait(0.5);
  },
  function (w) {
    throw "foo";
  },
  function error (e) {
    console.log(e);
  },
  [
    function () {
      return wait(1);
    },
    function () {
      return wait(2);
    }
  ],
  function (result) {
    console.log(result[0], result[1]);
  },
  {
    foo: function () {
      return wait(1);
    },
    bar: function () {
      return wait(1);
    }
  },
  function (result) {
    console.log(result.foo, result.bar);
  },
  function error (e) {
    console.log(e);
  }
);
```

ActionScript
```javascript
chain(
  function ():Deferred {
    return wait(0.5);
  },
  function (w):void {
    throw "foo";
  },
  catcher(function (e:*):void {
    trace(e);
  }),
  [
    function ():Deferred {
      return wait(1);
    },
    function ():Deferred {
      return wait(2);
    }
  ],
  function (result:Array):void {
    trace(result[0], result[1]);
  },
  {
    foo: functino ():void {
      return wait(1);
    },
    bar: functino ():void {
      return wait(1);
    }
  },
  function (result:Object):void {
    trace(result.foo, result.bar);
  },
  catcher(function (e:*):void {
    trace(e);
  })
);
```
