
public class DiscordRPCAgent: DiscordRPCAgentRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$DiscordRPCAgent$_free(ptr)
        }
    }
}
extension DiscordRPCAgent {
    public convenience init() {
        self.init(ptr: __swift_bridge__$DiscordRPCAgent$new())
    }
}
public class DiscordRPCAgentRefMut: DiscordRPCAgentRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
extension DiscordRPCAgentRefMut {
    public func start() {
        __swift_bridge__$DiscordRPCAgent$start(ptr)
    }

    public func stop() {
        __swift_bridge__$DiscordRPCAgent$stop(ptr)
    }

    public func setActivityState<GenericToRustStr: ToRustStr>(_ state: GenericToRustStr) {
        state.toRustStr({ stateAsRustStr in
            __swift_bridge__$DiscordRPCAgent$set_activity_state(ptr, stateAsRustStr)
        })
    }

    public func setActivityDetails<GenericToRustStr: ToRustStr>(_ details: GenericToRustStr) {
        details.toRustStr({ detailsAsRustStr in
            __swift_bridge__$DiscordRPCAgent$set_activity_details(ptr, detailsAsRustStr)
        })
    }

    public func setActivityTimestamps(_ start: Int64, _ end: Int64) {
        __swift_bridge__$DiscordRPCAgent$set_activity_timestamps(ptr, start, end)
    }

    public func clearActivity() {
        __swift_bridge__$DiscordRPCAgent$clear_activity(ptr)
    }

    public func updateActivity() {
        __swift_bridge__$DiscordRPCAgent$update_activity(ptr)
    }

    public func setActivityAssets<GenericToRustStr: ToRustStr>(_ large_image: GenericToRustStr, _ large_text: GenericToRustStr, _ small_image: GenericToRustStr, _ small_text: GenericToRustStr) {
        small_text.toRustStr({ small_textAsRustStr in
            small_image.toRustStr({ small_imageAsRustStr in
            large_text.toRustStr({ large_textAsRustStr in
            large_image.toRustStr({ large_imageAsRustStr in
            __swift_bridge__$DiscordRPCAgent$set_activity_assets(ptr, large_imageAsRustStr, large_textAsRustStr, small_imageAsRustStr, small_textAsRustStr)
        })
        })
        })
        })
    }
}
public class DiscordRPCAgentRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension DiscordRPCAgent: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_DiscordRPCAgent$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_DiscordRPCAgent$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: DiscordRPCAgent) {
        __swift_bridge__$Vec_DiscordRPCAgent$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_DiscordRPCAgent$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (DiscordRPCAgent(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<DiscordRPCAgentRef> {
        let pointer = __swift_bridge__$Vec_DiscordRPCAgent$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return DiscordRPCAgentRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<DiscordRPCAgentRefMut> {
        let pointer = __swift_bridge__$Vec_DiscordRPCAgent$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return DiscordRPCAgentRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_DiscordRPCAgent$len(vecPtr)
    }
}



