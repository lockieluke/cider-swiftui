#![feature(extern_types)]

use std::sync::{mpsc, Mutex};
use std::thread;
use discord_rpc_client::{Client, models::Activity, models::ActivityAssets, models::ActivityTimestamps};

pub struct DiscordRPCAgent {
    client: Client,
    state: String,
    details: String,
    start_timestamp: Option<i64>,
    end_timestamp: Option<i64>,
    large_image: String,
    large_text: String,
    small_image: String,
    small_text: String
}

impl DiscordRPCAgent {
    fn new() -> Self {
        Self {
            client: Client::new(1020414178047041627),
            state: String::new(),
            details: String::new(),
            start_timestamp: None,
            end_timestamp: None,
            large_image: String::new(),
            large_text: String::new(),
            small_image: String::new(),
            small_text: String::new()
        }
    }

    fn start(&mut self) {
        self.client.start();
    }

    fn stop(&mut self) {
        // this somehow crashes the whole thread, wtf
        // self.client.close();
    }

    fn set_activity_state(&mut self, state: &str) {
        self.state = state.to_string();
    }

    fn set_activity_details(&mut self, details: &str) {
        self.details = details.to_string();
    }

    fn set_activity_timestamps(&mut self, start: i64, end: i64) {
        if start != 0 && end !=0 {
            self.start_timestamp = Some(start);
            self.end_timestamp = Some(end);
        } else {
            self.start_timestamp = None;
            self.end_timestamp = None;
        }
    }

    fn set_activity_assets(
        &mut self,
        large_image: &str,
        large_text: &str,
        small_image: &str,
        small_text: &str,
    ) {
        self.large_image = large_image.to_string();
        self.large_text = large_text.to_string();
        self.small_image = small_image.to_string();
        self.small_text = small_text.to_string();
    }

    fn clear_activity(&mut self) {
        self.state = String::new();
        self.details = String::new();
        self.start_timestamp = None;
        self.end_timestamp = None;
        self.large_image = String::new();
        self.large_text = String::new();
        self.small_image = String::new();
        self.small_text = String::new();
    }

    fn update_activity(&mut self) {
        let mut activity = Activity::new();

        if !self.state.is_empty() {
            activity = activity.state(self.state.as_str());
        }
        if !self.details.is_empty() {
            activity = activity.details(self.details.as_str());
        }

        if let [Some(start), Some(end)] = [self.start_timestamp, self.end_timestamp] {
            activity = activity.timestamps(|_| {
                return ActivityTimestamps::new().start(start as u64).end(end as u64);
            });
        }

        let mut assets = ActivityAssets::new();
        if !self.large_image.is_empty() {
            assets = assets.large_image(self.large_image.as_str());
        }
        if !self.large_text.is_empty() {
            assets = assets.large_text(self.large_text.as_str());
        }
        if !self.small_image.is_empty() {
            assets = assets.small_image(self.small_image.as_str());
        }
        if !self.small_text.is_empty() {
            assets = assets.small_text(self.small_text.as_str());
        }
        activity = activity.assets(|_| {
            return assets;
        });

        if std::env::var("DISCORD_RPC_LOGS").is_ok() {
            println!("Updating activity: {:?}", activity);
        }

        self.client.set_activity(|_| {
            return activity;
        }).expect("Unable to set activity");
    }
}

#[swift_bridge::bridge]
mod ffi {
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