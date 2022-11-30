# Xccurate Formatter <img alt="Logo" src="https://github.com/intitni/XccurateFormatter/blob/0dce4d51112e852b7d1f3e961bfd79228dca8ca9/XccurateFormatter/Assets.xcassets/AppIcon.appiconset/1024%20x%201024%20your%20icon@64.png" align="right" height="50">

Xccurate Formatter is an Xcode Source Extension that provides a universal format file action for all file types it recognizes according to the project-specific configurations.

It supports the following formatters:

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [swift-format](https://github.com/apple/swift-format)
- [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html)
- [Prettier](https://prettier.io/)

Check the file `UTIToExtensionName.swift` for supported file types. Some of them require Prettier plugins.

## Usage

### Enable Extension

Go to Settings.app search for Xcode extension, and enable Xccurate Formatter.

If the extension complains that it has no permission to use Accessibility API, go turn it on in Settings.app for `XccurateFormatter`.

### Setup Launch Agent

You have to click "Setup Launch Agent for XPC Service" to make the extension work. The app will put a plist file under `~/Library/LaunchAgents` and load it with `launchctl`.

If it fails, or if the extension complains that it can't connect to the helper, please try:

- restart Xcode.
- if still not working, run `launchctl list | grep com.intii` to see if `com.intii.XccurateFormatter.EditorExtensionXPCService` is loaded.
- if not, see if `com.intii.XccurateFormatter.EditorExtensionXPCService.plist` is created under `~/Library/LaunchAgents`.
- if not, create it yourself. Fill it with content that you can find in the file `LaunchAgentManager.swift`. Then run `launchctl load the/path/to/the/plist`.

### Install Formatters

Xccurate Formatter doesn't support code formatting on its own. You will need to install the formatters by yourself and provide an executable path for each formatter in the app.

For example, to enable SwiftFormat, you can:

1. install it via homebrew `brew install swiftformat`.
2. get the path of it `which swiftformat`.
3. paste the path in the app `/opt/homebrew/bin/swiftformat`.

Alternatively, you can add a file `.xccurateformatter` to the project root to override the settings:

```json
{
  "swiftFormatExecutablePath": "/opt/homebrew/bin/swiftformat",
  "appleSwiftFormatExecutablePath": "...",
  "clangFormatExecutablePath": "...",
  "clangFormatStyle": "llvm",
  "usePrettierFromNodeModules": false,
  "prettierExecutablePath": "..."
}
```

All fields are optional.

### Configurations

Place the formatter configuration files at the project root or its parent directories. Xccurate Formatter will use the nearest configuration it finds to determine which formatter to use.

If no configuration is found, it will use the first formatter in the supported formatter list that supports the language and has its executable path set.

## Limitations

~~- Since Xcode only provides the UTI of the editing file but not the file extension, the formatter won't support files that Xcode doesn't know. e.g. even though `.graphql` is supported by Prettier, `.graphql` will be recognized as `public.plain-text` by Xcode.~~

After switching to Accessibility API from Apple Script, it looks like we can now get the editing file path and the file extension, but I don't have time to update the code for that yet.

## How It Works

The source extension itself must be sandboxed, but it can still talk to XPC services that are not. That way, we can let the XPC service do the dirty work and return the formatted code to the extension.

The dirty work will be:

1. Use Accessibility API to get the opening project/file path of the frontmost Xcode window.
2. Find upwards for the nearest configuration file to determine which formatter to use.
   For example, if you are formatting a Swift file, and the folders are structured like this
   ```
   parent
    |- .swift-format
    |- project
        |- .swiftformat
        |- code.swift
   ```
   Swift Format will be used.
3. Create a temp file at the project root or in the same folder to the original file (so the formatters can read other configuration files like .swift-version), paste the code to the file, and run the formatter on the file.
4. Return the formatted code to the extension, and delete the temp file.

Though it's possible to embed a non-sandboxed XPC Service inside the sandboxed extension, notarization will fail.

The workaround I am using is to build the XPC Service into a command line tool, and copy it into the main application's executables directory. Check this link for detail: [Creating a Launch Agent that provides an XPC service on macOS using Swift](https://rderik.com/blog/creating-a-launch-agent-that-provides-an-xpc-service-on-macos/).

This method also makes the Accessibility API usable from the XPC Service.

## Note

The app was initially built with an Apple Script solution with many limitations. Luckily some troubles caused by it led me to a better solution. 塞翁失马焉知非福.

But the solution shift was such a rush that some code may not make too much sense to the new solution.
