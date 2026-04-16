import Foundation

enum DetectionPatterns {
    static let meeting: Set<String> = [
        "meet.google.com",
        "google meet",
        "zoom.us",
        "teams.microsoft.com",
        "webex.com",
        "whereby.com",
        "around.co",
        "slack.com/huddle",
        "discord.com/channels",
        "facetime",
        "meeting",
        "standup",
        "huddle",
        "call in progress"
    ]

    static let video: Set<String> = [
        "youtube.com/watch",
        "youtu.be/",
        "netflix.com/watch",
        "twitch.tv/",
        "vimeo.com/",
        "hulu.com/watch",
        "play.max.com",
        "video",
        "watch"
    ]
}
