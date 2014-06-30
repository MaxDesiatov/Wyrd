//
//  Wyrd.swift
//  Wyrd
//
//  Created by Max Desyatov on 30/06/2014.
//  Copyright (c) 2014 Max Desyatov. All rights reserved.
//

import Foundation

extension NSURLSession {
  func getURLData(url: NSURL) -> Wyrd<NSData, NSError> {
    let result = Wyrd<NSData, NSError>()

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

class Wyrd<T, E> {
  var onSuccess: (T -> ())?
  var onError: (E -> ())?
  var value: T[] = []
  var error: E[] = []
  var state: State = .IsPending

  func fulfill(v: T) {
    if let f = onSuccess {
      f(v)
    } else {
      value = [v]
      state = .IsFulfilled
    }
  }

  func reject(e: E) {
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

func => <T1, T2, E>(w1: Wyrd<T1, E>, then: T1 -> Wyrd<T2, E>) -> Wyrd<T2, E> {
  let w2 = Wyrd<T2, E>()
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


