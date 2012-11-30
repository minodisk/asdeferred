var Deferred = require('./jsdeferred').Deferred
  ;

Deferred
  .repeat(10, function (i) {
    console.log(i);
  })
  .next(function () {
    console.log('complete');
  });
