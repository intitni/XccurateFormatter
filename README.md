# Xccurate Formatter <img alt="Logo" src="/AppIcon.png" align="right" height="50">

Xccurate Formatter is an Xcode Source Editor Extension that reads the **project-specific configurations**. It provides a universal format file action for all file types it recognizes.

The following formatters are supported:

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [swift-format](https://github.com/apple/swift-format)
- [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html)
- [Prettier](https://prettier.io/)

Check the file `UTIToExtensionName.swift` for supported file types. Some of them require Prettier plugins.

[Download From Releases](https://github.com/intitni/XccurateFormatter/releases)

<a href="https://www.buymeacoffee.com/intitni" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

## Note

The application was originally built using an Apple Script solution with many limitations. Fortunately, some problems caused by it led me to a better solution. 塞翁失马焉知非福.

But the solution shift was such a rush that some code may not make too much sense for the new solution.

## Usage

### Enable the Extension

Go to System Settings.app search for Xcode extension, and enable Xccurate Formatter.

If the extension complains that it does not have permission to use the Accessibility API, go to System Settings.app and enable `XccurateFormatter`.

If it keeps complaining (especially when after you have updated the app or run it from Xcode), try to:

- Remove the app from the Accessibility settings. Add it back manually, or use the extension once and check the list again.
- Remove Launch Agent and setup again.

This can be tricky.

### Setup Launch Agent

You have to click "Setup Launch Agent for XPC Service" to make the extension work. The app will put a plist file under `~/Library/LaunchAgents` and load it with `launchctl`.

If it fails, or if the extension complains that it can't connect to the helper, please try to:

- restart Xcode.
- if still not working, run `launchctl list | grep com.intii` to see if `com.intii.XccurateFormatter.EditorExtensionXPCService` is loaded.
- if not, check if `com.intii.XccurateFormatter.EditorExtensionXPCService.plist` is created under `~/Library/LaunchAgents`.
- if not, create it yourself. Fill it with content that you can find in the file `LaunchAgentManager.swift`. Then run `launchctl load the/path/to/the/plist`.

### Install Formatters

Xccurate Formatter doesn't support code formatting on its own. You will need to install the formatters by yourself and provide an executable path for each formatter in the app.

For example, to enable SwiftFormat, you can:

1. install it via homebrew `brew install swiftformat`.
2. get the path to it `which swiftformat`.
3. paste the path into the app `/opt/homebrew/bin/swiftformat`.

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

Place the formatter configuration files at the project root or its parent directories. Xccurate Formatter will use the closet configuration it finds to determine which formatter to use.

If no configuration is found, it will use the first formatter in the supported formatters list that supports the language and has its executable path set.

### Prettier Plugins

It's possible to use Prettier plugins. To add a plugin, you should setup the Prettier Arguments in the settings.

For example, if you want to use the Ruby plugin, you will have to 

1. Install the plugin gloablly, make sure you follow it's instruction and install all the dependencies.
2. Set the Prettier Arguments text field to 
```
--plugin=/opt/homebrew/lib/node_modules/@prettier/plugin-ruby/src/plugin.js
```

If you want to enable multiple plugins, just write multiple `--plugin`.

When the arguments field in not empty, the app will run Prettier in an interactive logged-in (`-ilc`) shell so that it can find other dependencies installed by the plugin.

### Key Bindings

You can set key bindings for the command in Xcode settings.

## How It Works

The source extension itself must be sandboxed, but it can still talk to XPC services that are not. This way, we can let the XPC service do the dirty work and return the formatted code to the extension.

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
3. Create a temporary file at the project root or in the same folder as the original file (so the formatters can read other configuration files like .swift-version), paste the code into the file, and run the formatter on the file.
4. Return the formatted code to the extension, and delete the temporary file.

Although it's possible to embed a non-sandboxed XPC Service inside the sandboxed extension, notarization will fail (not sure, notarization can fail for no reason). And managing permissions will be hard.

The workaround I am using is to build the XPC Service into a command line tool, and copy it into the executable directory of the main application. Check this link for detail: [Creating a Launch Agent that provides an XPC service on macOS using Swift](https://rderik.com/blog/creating-a-launch-agent-that-provides-an-xpc-service-on-macos/).

This method also makes the Accessibility API usable from the XPC Service.

## Development Instruction

### Building and Running the App

You can change the `BUNDLE_IDENTIFIER_BASE` in `Config.debug.xcconfig` to whatever you want, but please do not change the bundle identifiers on the target directly. Some of the suffixes are hardcoded in info.plist and code to let them find each other.

There are 4 targets in this project:

- XccurateFormatter: the settings app
- EditorExtension: the Xcode Source Editor Extension
- EditorExtensionXPCCLI: the XPC Service
- EditorExtensionTests: Tests for the extension and the XPC Services

When you need to run the extension in Xcode, you normally need to:

1. Run `XccurateFormatter` and update the settings.
2. Run `EditorExtensionXPCCLI`.
3. Run `EditorExtension`.

### Testing

The test target doesn't have any host application, it just includes all the files that need to be tested, thanks to the trickiness of XPC Services.

To run the tests, you first need to:

- install swift-format, SwiftFormat, ClangFormat, Node, Prettier.
- provide their executable paths in `Test.xcconfig`. Check `Test.sample.xcconfig` for requried fields.
