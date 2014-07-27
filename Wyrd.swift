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

  // FIXME: not really needed, but compiler is buggy
  init() {

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

operator infix =~ { associativity left }

public func =~ <T>(w: Wyrd<T>, f: T -> ()) -> Wyrd<T> {
  switch w.state {
  case .IsPending:
    w.onSuccess = f
  case .IsFulfilled:
    w.queue.addOperationWithBlock {
      f(w.value!)
    }
  default:
    ()
  }

  return w
}

operator infix =! { associativity left }

public func =! <T>(w: Wyrd<T>, f: NSError -> ()) -> Wyrd<T> {
  switch w.state {
  case .IsPending:
    w.onError = f
  case .IsRejected:
    w.queue.addOperationWithBlock {
      f(w.error!)
    }
  default:
    ()
  }

  return w
}

operator infix =| { associativity left precedence 101 }

func =| <T1, T2>(w1: Wyrd<T1>, w2: Wyrd<T2>) -> Wyrd<(T1, T2)> {
  let w3 = Wyrd<(T1, T2)>()

  return w3
}

operator infix =|| { associativity left precedence 101 }

func =| <T>(w1: Wyrd<T>, w2: Wyrd<T>) -> Wyrd<[T]> {
  let w3 = Wyrd<[T]>()

  return w3
}
