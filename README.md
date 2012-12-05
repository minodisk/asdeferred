# ASDeferred

[JSDeferred](https://github.com/cho45/jsdeferred)をActionScript3.0に移植した。
同時にテストも移植して実行済み。

## JSDeferredとの違い

基本的にはJSDeferredを踏襲する方向で使えるように実装したが、言語仕様上実装が異なっている点がある。
下記に違いと代替手段をコードとともに説明する。

### `define`メソッドの存在

JSDeferredには`define`メソッドが存在し、globalにDeferredの静的メソッドのショートカットを作ることが可能だが、
AS3ではglobalにプロパティを追加することは不可能。
そこで、各メソッドをパッケージ空間に宣言しているのでこれをimportすることでショートカットを使用可能にしている。

### `register`メソッドの存在

JSDeferredには`register`メソッドが存在し、Deferredのprototypeに静的メソッドのコピーを作ることが可能だが、
AS3ではdynamicに追加したメソッドは処理速度が遅いと言われているので使用は慎重に。

### `chain`メソッドでerrorキャプチャを設定する方法

JSDeferredではerrorという名前の関数を設定することでエラーキャプチャすることが可能だったが、
AS3では`errorFunction`というメソッドをコールしながら設定するようになっている。


