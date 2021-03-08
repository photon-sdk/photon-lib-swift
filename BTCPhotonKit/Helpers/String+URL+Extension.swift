//
//  String+URL+Extension.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

extension String {
    public func toUrl() -> URL? {
        if let url = URL(string: self) {
            return url
        }
        return nil
    }
}
