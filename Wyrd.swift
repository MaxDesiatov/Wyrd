//
//  Wyrd.swift
//  Wyrd
//
//  Created by Max Desyatov on 30/06/2014.
//  Copyright (c) 2014 Max Desyatov. All rights reserved.
//

import Foundation

class Wyrd<T, E> {
  var onSuccess: (T -> ())?
  var onError: (E -> ())?
  var value: T[] = []

  func fulfill(v: T) {
    if let f = onSuccess {
      f(v)
    } else {
      value = [v]
    }
  }

  func reject(error: E) {
    if let f = onError {
      f(error)
    }
  }
}

operator infix => { associativity left }

func => <T1, T2, E>(w1: Wyrd<T1, E>, then: T1 -> Wyrd<T2, E>) -> Wyrd<T2, E> {
  let w2 = Wyrd<T2, E>()
  w1.onSuccess = { v1 in
    NSOperationQueue.mainQueue().addOperationWithBlock {
      let temp = then(v1)
      temp.onSuccess = { v2 in
        w2.fulfill(v2)
      }
    }
  }
  return w2
}
