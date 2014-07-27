//
//  Wyrd.swift
//  Wyrd
//
//  Created by Max Desyatov on 30/06/2014.
//  Copyright (c) 2014 Max Desyatov. All rights reserved.
//

import Foundation

enum State {
  case IsPending
  case IsFulfilled
  case IsRejected
}

public class Wyrd<T> {
  var onSuccess: (T -> ())?
  var onError: (NSError -> ())?

  // FIXME: these two should be optionals, but compiler is buggy
  var value: T?
  var error: NSError?

  var queue = NSOperationQueue.mainQueue()
  var state = State.IsPending

  init() {
  }

  init(_ v: T) {
    value = v
    state = .IsFulfilled
  }

  func fulfil(v: T) {
    if let f = onSuccess {
      queue.addOperationWithBlock {
        f(v)
      }
    } else {
      value = v
      state = .IsFulfilled
    }
  }

  func reject(e: NSError) {
    if let f = onError {
      queue.addOperationWithBlock {
        f(e)
      }
    } else {
      error = e
      state = .IsRejected
    }
  }
}

operator infix =~ { associativity left }

public func =~ <T>(w: Wyrd<T>, f: T -> ()) -> Wyrd<T> {
  if w.state == .IsPending {
    w.onSuccess = f
  } else if w.state == .IsFulfilled {
    w.queue.addOperationWithBlock {
      f(w.value!)
    }
  }

  return w
}

operator infix =! { associativity left }

public func =! <T>(w: Wyrd<T>, f: NSError -> ()) -> Wyrd<T> {
  if w.state == .IsPending {
    w.onError = f
  } else if w.state == .IsRejected {
    w.queue.addOperationWithBlock {
      f(w.error!)
    }
  }

  return w
}

operator infix => { associativity left }

public func => <T1, T2>(w1: Wyrd<T1>, f: T1 -> Wyrd<T2>) -> Wyrd<T2> {
  let w2 = Wyrd<T2>()
  w1 =~ { v1 in
    let temp = f(v1)
    temp =~ { v2 in
      w2.fulfil(v2)
    }
  }
  return w2
}

operator infix =| { associativity left precedence 101 }

public func =| <T1, T2>(w1: Wyrd<T1>, w2: Wyrd<T2>) -> Wyrd<(T1, T2)> {
  let w3 = Wyrd<(T1, T2)>()

  w1 =~ { v1 in
    if w2.state == .IsFulfilled {
      w3.fulfil(v1, w2.value!)
    }
  }

  w2 =~ { v2 in
    if w1.state == .IsFulfilled {
      w3.fulfil(w1.value!, v2)
    }
  }

  return w3
}

operator infix =|| { associativity left precedence 101 }

public func =|| <T>(w1: Wyrd<T>, w2: Wyrd<T>) -> Wyrd<[T]> {
  return w1 =| w2 => { (v1, v2) in
    return Wyrd([v1, v2])
  }
}
