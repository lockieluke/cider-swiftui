use discord_presence::Client;

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
    pub fn new() -> Self {
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

    pub(crate) fn start(&mut self) {
        _ = self.client.start();
    }

    pub(crate) fn stop(&mut self) {
        // this somehow crashes the whole thread, wtf
        // self.client.close();
    }

    pub(crate) fn set_activity_state(&mut self, state: &str) {
        self.state = state.to_string();
    }

    pub(crate) fn set_activity_details(&mut self, details: &str) {
        self.details = details.to_string();
    }

    pub(crate) fn set_activity_timestamps(&mut self, start: i64, end: i64) {
        if start != 0 && end !=0 {
            self.start_timestamp = Some(start);
            self.end_timestamp = Some(end);
        } else {
            self.start_timestamp = None;
            self.end_timestamp = None;
        }
    }

    pub(crate) fn set_activity_assets(
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

    pub(crate) fn clear_activity(&mut self) {
        self.state = String::new();
        self.details = String::new();
        self.start_timestamp = None;
        self.end_timestamp = None;
        self.large_image = String::new();
        self.large_text = String::new();
        self.small_image = String::new();
        self.small_text = String::new();
    }

    pub(crate) fn update_activity(&mut self) {
        let mut activity = discord_presence::models::Activity::new();

        if !self.state.is_empty() {
            activity = activity.state(self.state.as_str());
        }
        if !self.details.is_empty() {
            activity = activity.details(self.details.as_str());
        }

        if let [Some(start), Some(end)] = [self.start_timestamp, self.end_timestamp] {
            activity = activity.timestamps(|_| {
                return discord_presence::models::ActivityTimestamps::new().start(start as u64).end(end as u64);
            });
        }

        let mut assets = discord_presence::models::ActivityAssets::new();
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

        if Client::is_ready() {
            if let Err(why) = self.client.set_activity(|_| {
                return activity;
            }) {
                println!("Failed to update activity: {:?}", why);
            }
        }
    }
}
