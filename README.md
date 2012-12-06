# ASDeferred

[cho45/jsdeferred](https://github.com/cho45/jsdeferred)をActionScript3.0に移植した。
テストも移植して実行している。

## チュートリアルとかAPIリファレンス

[JSDeferred - Asynchronous library in JavaScript. Standalone and Compact](http://cho45.stfuawsc.com/jsdeferred/)参照。
ただし、使い方の異なる点があるので[JSDeferredとの違い](#jsdeferredJSDeferredとの違い)も参照。

## JSDeferredとの違い

基本的にはJSDeferredの使い勝手を維持できるように移植したが、言語仕様上実装や使用方法が異なっている点がある。
まず大きな違いとしては型を指定しなければならないわけだが、この辺りは当然の事なので割愛し、重要な違いと代替手段を下記に説明する。
コード例の一部を[JSDeferred - Asynchronous library in JavaScript. Standalone and Compact](http://cho45.stfuawsc.com/jsdeferred/)
から抜粋して比較している。

### `define`メソッド

JSDeferredには`define`メソッドが存在し、引数を与えずに実行した場合global(windowオブジェクト)にDeferredの静的メソッドのショートカットを作ることが可能だが、
ASDeferredではasdeferredパッケージ空間のショートカットメソッドをimportする必要がある。
AS3の言語仕様上globalにプロパティを追加することはできないため。

JavaScript

    Deferred.define();

    next(function () {
      console.log("Hello!");
      return wait(5);
    }).
    next(function () {
      console.log("World!");
    });

ActionScript

    import asdeferred.next;
    import asdeferred.wait;

    next(function ():Deferred {
      trace("Hello!");
      return wait(5);
    }).
    next(function ():void {
      trace("World!");
    });

ASDeferredにも`define`メソッドは存在するが第一引数は必須で、オブジェクトに静的メソッドの参照をプロパティとして追加することはできるが、
globalにプロパティを追加できない以上は、使用するシチュエーションはあまりないと思われる。

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

### `register`メソッドの存在

JSDeferredには`register`メソッドが存在し、Deferredのprototypeに静的メソッドのコピーを作ることが可能だが、
AS3ではdynamicに追加したメソッドは処理速度が遅いと言われているので使用は慎重に。

    // Deferred.register("loop", loop);

    // Global Deferred function
    loop(10, function (n) {
        print(n);
    }).
    // Registered Deferred.prototype.loop
    loop(10, function (n) {
        print(n);
    });

### `chain`メソッドでerrorキャプチャを設定する方法

JSDeferredではerrorという名前の関数を設定することでエラーキャプチャすることが可能だったが、
ASDeferredでは`errorFunction`というメソッドの引数として設定する必要がある。
AS3では関数名を取得する手段がないため、`ErrorFunction`インスタンスを返すファクトリメソッドの`errorFunction`を使うことで
`chain`内部で型判定をしてエラーキャプチャとして解釈する実装になっている。

JavaScript

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
        foo: wait(1),
        bar: wait(1)
      },
      function (result) {
        console.log(result.foo, result.bar);
      },
      function error (e) {
        console.log(e);
      }
    );

ActionScript

    chain(
      function ():Deferred {
        return wait(0.5);
      },
      function (w):void {
        throw "foo";
      },
      errorFunction(function (e:*):void { // <- errorFunction(
        trace(e);
      }),                                 // <- )
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
        foo: wait(1),
        bar: wait(1)
      },
      function (result:Object):void {
        trace(result.foo, result.bar);
      },
      errorFunction(function (e:*):void { // <- errorFunction(
        trace(e);
      })                                  // <- )
    );
