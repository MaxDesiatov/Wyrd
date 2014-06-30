//
//  Wyrd.swift
//  Wyrd
//
//  Created by Max Desyatov on 30/06/2014.
//  Copyright (c) 2014 Max Desyatov. All rights reserved.
//

import Foundation

extension NSURLSession {
  func getURLData(url: NSURL) -> Wyrd<NSData> {
    let result = Wyrd<NSData>()

    let task = dataTaskWithURL(url) { data, response, error in
      if let e = error {
        result.reject(e)
      } else {
        result.fulfill(data)
      }
    }

    task.resume()

    return result
  }
}

enum State {
  case IsPending
  case IsFulfilled
  case IsRejected
}

class Wyrd<T> {
  var onSuccess: (T -> ())?
  var onError: (NSError -> ())?
  var value: T[] = []
  var error: NSError[] = []
  var state: State = .IsPending

  func fulfill(v: T) {
    if let f = onSuccess {
      f(v)
    } else {
      value = [v]
      state = .IsFulfilled
    }
  }

  func reject(e: NSError) {
    if let f = onError {
      f(e)
    } else {
      error = [e]
    }
  }

  func success(f: T -> ()) {
    switch state {
    case .IsPending:
      onSuccess = f
    case .IsFulfilled:
      f(value[0])
    default:
      ()
    }
  }
}

operator infix => { associativity left }

func => <T1, T2>(w1: Wyrd<T1>, then: T1 -> Wyrd<T2>) -> Wyrd<T2> {
  let w2 = Wyrd<T2>()
  w1.success { v1 in
    NSOperationQueue.mainQueue().addOperationWithBlock {
      let temp = then(v1)
      temp.success { v2 in
        w2.fulfill(v2)
      }
    }
  }
  return w2
}
