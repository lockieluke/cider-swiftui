//
//  List.swift
//  Cider
//
//  Created by Sherlock LUK on 26/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Introspect
import SwiftUI

extension List {
  /// List on macOS uses an opaque background with no option for
  /// removing/changing it. listRowBackground() doesn't work either.
  /// This workaround works because List is backed by NSTableView.
  func removeBackground() -> some View {
    return introspectTableView { tableView in
      tableView.backgroundColor = .clear
      tableView.enclosingScrollView!.drawsBackground = false
    }
  }
}
