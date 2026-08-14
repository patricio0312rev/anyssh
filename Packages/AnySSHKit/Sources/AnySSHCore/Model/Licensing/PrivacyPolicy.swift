public enum PrivacyPolicy {
    public static let updated = "August 2026"

    public static let sections: [(title: String, body: String)] = [
        (
            "What is collected",
            "Nothing. There is no account, no analytics, no crash reporting and no server of ours. "
                + "Nothing you type and nothing a host sends back leaves your device."
        ),
        (
            "Where your keys live",
            "Private keys and passwords are stored in the iOS Keychain on this device, guarded by "
                + "Face ID or your passcode. They are never copied anywhere else, never sent to us, "
                + "and never included in a backup that leaves the device unencrypted."
        ),
        (
            "What the hosts see",
            "The app connects directly to the hosts you configure, over SSH, and nothing is "
                + "installed on them. Every feature works by running ordinary commands over that "
                + "connection, so a host sees what any SSH client would show it and nothing more."
        ),
        (
            "What stays on your device",
            "Host definitions, the directory each host was last used in, saved commands, gesture "
                + "bindings and terminal preferences are written to this device's app container. "
                + "Deleting the app deletes all of it."
        ),
        (
            "Microphone and speech",
            "Dictation is recognised on this device. Audio is not recorded, not stored and not "
                + "sent anywhere. The permission is only requested when you first start dictation."
        ),
        (
            "Children",
            "The app is not directed at children and collects no personal data from anyone."
        ),
    ]
}
