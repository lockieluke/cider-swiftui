//
//  List.swift
//  Cider
//
//  Created by Sherlock LUK on 26/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUIIntrospect
import SwiftUI

extension List {
  /// List on macOS uses an opaque background with no option for
  /// removing/changing it. listRowBackground() doesn't work either.
  /// This workaround works because List is backed by NSTableView.
  func removeBackground() -> some View {
      #if os(macOS)
      return introspect(.table, on: .macOS(.v12, .v13, .v14)) { tableView in
          tableView.backgroundColor = .clear
          tableView.enclosingScrollView!.drawsBackground = false
      }
      #else
      return self
      #endif
  }
}
