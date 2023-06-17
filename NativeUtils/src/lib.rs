#![feature(extern_types)]

use cli_clipboard::{ClipboardContext, ClipboardProvider};
use serde_json::{json};
use serde::{Serialize, Deserialize};
use uuid::Uuid;

pub struct NativeUtils {
    clipboard_ctx: ClipboardContext,
}

#[derive(Serialize, Deserialize)]
struct LyricsLine {
    id: String,
    line: String,
    start_time: f64,
    end_time: f64,
}

impl NativeUtils {
    pub fn new() -> Self {
        NativeUtils {
            clipboard_ctx: ClipboardContext::new().unwrap()
        }
    }

    fn get_name(&self) -> String {
        return "NativeUtils".to_string();
    }

    pub fn parse_lyrics_xml(&self, xml: String) -> String {
        let doc = roxmltree::Document::parse(&xml).unwrap();
        let children = doc.root_element().children();
        let body = children.clone().find(|n| n.has_tag_name("body")).unwrap();
        let head = children.clone().find(|n| n.has_tag_name("head")).unwrap();
        let itunes_metadata = head.children().find(|n| n.has_tag_name("metadata")).unwrap().first_child().unwrap();
        let songwriters = itunes_metadata.first_child();
        if !songwriters.is_none() {
            assert_eq!(songwriters.unwrap().tag_name().name(), "songwriters");
        }
        let segments = body.children().filter(|n| n.has_tag_name("div"));
        let mut lyrics: Vec<LyricsLine> = Vec::new();

        for segment in segments {
            let lines = segment.children().filter(|n| n.has_tag_name("p"));
            for line in lines {
                let mut text = String::new();
                if let Some(l_text) = line.text() {
                    text = l_text.to_string();
                } else {
                    let words = line.children().filter(|n| n.has_tag_name("span"));
                    for word in words {
                        if let Some(w_text) = word.text() {
                            text.push_str(w_text);
                            text.push(' ');
                        }
                    }
                }

                let get_time_as_f64 = |attr_name: &str| -> f64 {
                    let time_atr = line.attribute(attr_name).unwrap();
                    let minutes = if time_atr.contains(":") { time_atr.split(":").next().unwrap_or("0.0").parse::<f64>().unwrap() } else { 0.0 };
                    let seconds = time_atr.split(":").last().unwrap_or("0.0").parse::<f64>().unwrap();

                    minutes * 60.0 + seconds
                };

                lyrics.push(LyricsLine {
                    id: Uuid::new_v4().to_string(),
                    line: text.to_string(),
                    start_time: get_time_as_f64("begin"),
                    end_time: get_time_as_f64("end"),
                });
            }
        }

        return json!({
            "lyrics": lyrics,
            "leadingSilence": itunes_metadata.attribute("leadingSilence").unwrap_or("0.0").parse::<f64>().unwrap(),
            "songwriters": if songwriters.is_none() { vec!() } else { songwriters.unwrap().children().map(|n| n.text().unwrap().to_string()).collect::<Vec<String>>() }
        }).to_string();
    }

    pub fn copy_string_to_clipboard(&mut self, string: String) {
        self.clipboard_ctx.set_contents(string).unwrap();
    }

    pub fn get_clipboard_string(&mut self) -> String {
        return self.clipboard_ctx.get_contents().unwrap();
    }

}

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
    }
}