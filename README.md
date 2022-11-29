# Xccurate Formatter

Xccurate Formatter is an Xcode Source Extension that provides a universal format file action for all file types it recognizes according to the project-specific configurations.

It supports the following formatters:

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [swift-format](https://github.com/apple/swift-format)
- [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html)
- [Prettier](https://prettier.io/)

Check the file `UTIToExtensionName.swift` for supported file types. Some of them require Prettier plugins.

## Usage

### Installing Formatters

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

- Since Xcode only provides the UTI of the editing file but not the file extension, the formatter won't support files that Xcode doesn't know. e.g. even though `.graphql` is supported by Prettier, `.graphql` will be recognized as `public.plain-text` by Xcode.
- Xccurate Formatter can only read the configurations at the root of the project, or anywhere in its parent directories. See **How It Works** below for detail.
- Every time you quit Xcode and open it again, the extension will take a few seconds(?) to warm up the first time it runs, thanks to the Apple Script workaround.

## How It Works

The source extension itself must be sandboxed, but it can still talk to XPC services that are not. That way, we can let the XPC service do the dirty work and return the formatted code back to the extension.

The dirty work will be:

1. Use Apple Script to get the opening project path of the frontmost Xcode window. (An Accessibility API trick used to work with Xcode 13, but failed to work anymore when building with Xcode 14.) Sadly we can't get the file path.
2. Find upwards the nearest configuration file to determine which formatter to use.
   For example, if you are formatting a Swift file, and the folders structured like this
   ```
   parent
    |- .swift-format
    |- project
        |- .swiftformat
        |- code.swift
   ```
   Swift Format will be used.
3. Create a temp file at the project root (so the formatters can read other configuration files like .swift-version), paste the code to the file, and run the formatter on the file.
4. Return the formatted code back to the extension, and delete the temp file.
