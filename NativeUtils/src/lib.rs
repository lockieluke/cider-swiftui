#![feature(extern_types)]

extern crate port_scanner;

use discord_rpc::DiscordRPCAgent;
use native_utils::NativeUtils;

mod discord_rpc;
mod native_utils;

#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        type NativeUtils;

        #[swift_bridge(init)]
        fn new() -> NativeUtils;

        fn get_name(&self) -> String;
        fn parse_lyrics_xml(&self, xml: String) -> String;

        fn copy_string_to_clipboard(&mut self, string: String);
        fn get_clipboard_string(&mut self) -> String;

        fn is_port_open(&mut self, port: u16) -> bool;
    }

    extern "Rust" {
        type DiscordRPCAgent;

        #[swift_bridge(init)]
        fn new() -> DiscordRPCAgent;

        fn start(&mut self);
        fn stop(&mut self);

        #[swift_bridge(swift_name = "setActivityState")]
        fn set_activity_state(&mut self, state: &str);

        #[swift_bridge(swift_name = "setActivityDetails")]
        fn set_activity_details(&mut self, details: &str);

        #[swift_bridge(swift_name = "setActivityTimestamps")]
        fn set_activity_timestamps(&mut self, start: i64, end: i64);

        #[swift_bridge(swift_name = "clearActivity")]
        fn clear_activity(&mut self);

        #[swift_bridge(swift_name = "updateActivity")]
        fn update_activity(&mut self);

        #[swift_bridge(swift_name = "setActivityAssets")]
        fn set_activity_assets(
            &mut self,
            large_image: &str,
            large_text: &str,
            small_image: &str,
            small_text: &str,
        );
    }
}