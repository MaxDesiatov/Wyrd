# Wyrd
Wyrd is a library for asynchronous programming in Swift. It aims to be concise and simple.
Wyrd is inspired by [Promises/A+](http://promisesaplus.com). Both Swift and Cocoa Touch doesn't provide any helpers for asynchronous programming besides standard functions taking success/failure callbacks. Wyrd tries to alleviate this with fairly simple API and a few helpers of its own.


## How to Install
At the moment the most convenient way is to add Wyrd repository as a git submodule to your main repository:

    git add submodule add https://github.com/explicitcall/Wyrd.git wyrd

Then add `Wyrd.swift` file to your project.

CocoaPods package will be added as soon as CocoaPods will support source code in Swift.

## How to Use
Essentially, Wyrd instance is a promise, which can be chained with other promises using closures and chaining operators. Wyrd library provides a few wrapper extensions for standard asynchronous Cocoa Touch functions. These extended functions return a promise instead of taking a success/error callback, giving you much clearer code and saving you from a [Pyramid of Doom](http://survivejs.com/common_problems/pyramid.html).

Obligatory example (`getURLData` and `FullResponse` typealias are provided to you by Wyrd):

```swift
let s = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
let u1 = NSURL(string: "https://api/endpoint1")
let u2 = NSURL(string: "https://api/endpoint2")
s.getURLData(u1) => { (full: FullResponse) -> Wyrd<FullResponse> in
  switch full {
  case let (data, response):
    println("data1 length is \(data.length)")
  }
  return s.getURLData(u2)
} =~ { (full: FullResponse) in
  switch full {
  case let (data, response):
    println("data2 length is \(data.length)")
  }
}
```

This code issues two API calls in serial, the second will fail if the first fails.

Wrapping typical asynchronous Cocoa Touch code is fairly easy, just define a method/function which will return a Wyrd instance, which you will be able to chain. You will need to fulfil or reject the promise in the raw callbacks code to indicate when the promise will be able to chain further:

```swift
typealias FullResponse = (NSData!, NSURLResponse!)

extension NSURLSession {
  func getURLData(url: NSURL) -> Wyrd<FullResponse> {
    let result = Wyrd<FullResponse>()

    let task = dataTaskWithURL(url) { data, response, error in
      if let e = error {
        result.reject(e)
      } else {
        result.fulfil(data, response)
      }
    }

    task.resume()

    return result
  }
}
```

More examples and wrapper functions are coming soon.