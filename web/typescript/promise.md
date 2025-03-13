### promise

promise的需求是：用户知道有一个在未来某个时间点执行的行为，并有一个结果.

```typescript
const myPromise = new Promise((resolve, reject) => {
    // 异步操作
    setTimeout(() => {
        const success = Math.random() > 0.5;
        
        if (success) {
            resolve("操作成功！"); // 状态变为 fulfilled
        } else {
            reject("操作失败！"); // 状态变为 rejected
        }
    }, 1000);
});
```


#### resolve与reject的行为是什么
resolve 的行为是接收某个值（由调用者在调用这个函数时，所传递的参数给出）这个值用语义是生产者生产成功后的结果。
`reject` 的行为是接收一个值（由调用者在调用时的参数列表给出），这个参数的语义是生产者生产失败时，提供的error对象


#### promise是什么？
promise是表一种连接生产者与消费者的对象。这个对象有三个状态：undefined, resolve, `reject`.
要使用promise的方法是：`new Promise(function)`其中参数function被称为excutor函数。这个函数可接收入两个参数。分别是resolve, reject.它们是promise在调用excutor时传入的回调函数。resolve 的语义是将用户传入的值作为promise对象中的result的值。并将promise对象的状态更新resolve，而与resolve不同的是reject会将promise对象的状态设置为reject. 其他的行为是一样。
pirmise如何连接消费者叱？通过promise对象的then方法，可以实现这点。promise.then(function0, function2)其中function0的行为是接收入一个姀为promiseresult的值。function0的语义是在promise的状态为resolve时，所执行的消费代码。function1的语义相反，为promise的状态为reject时执行的消费代码，代表生产失败后的，错误处理行为。
以

#### promise是如何工作的？
当用户创建promise对象时，传入对象构造器里的生产者代码会被执行。直到遇到第一个resove或reject时，更新promise对象的result与status. 
若后续还有resolve与reject，这些函数将不再到吏新promise对象状态的作用。
如果用户调用了then或catch，这些函数中的参数回调将在promise的状态更新时被执行.从而实现了异步。

#### 用typescript描述它工作流程


#### async and await

##### 原语描述
