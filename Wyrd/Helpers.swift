//
//  Helpers.swift
//  Wyrd
//
//  Created by Max Desyatov on 01/07/2014.
//  Copyright (c) 2014 Max Desyatov. All rights reserved.
//

import Foundation

public typealias FullResponse = (NSData!, NSURLResponse!)

extension NSURLSession {
  public func getURLData(url: NSURL) -> Wyrd<FullResponse> {
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
