# LUUID Native

LUUID Native is a pure Lua library for generating UUIDs (Universally Unique Identifiers) with no external dependencies. It supports various UUID versions including time-based, DCE Security, and random UUIDs.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [API](#api)
- [Contributing](#contributing)
- [License](#license)

## Installation

1. Clone the repository:

```sh
git clone https://github.com/yourusername/luuid-native.git
cd luuid-native
```

## Usage

Here's a quick example to get you started:

1. Require the library in your Lua script:

```lua
local uuid = require("luuid-native")
```

2. Generate a UUID:

```lua
local time_based_uuid = uuid.new("TIME_BASED"):generate()
local dce_security_uuid = uuid.new("DCE_SECURITY"):generate()
local random_uuid = uuid.new("RANDOM"):generate()

print("Time-based UUID: ", time_based_uuid)
print("DCE Security UUID: ", dce_security_uuid)
print("Random UUID: ", random_uuid)
```

## API

### `uuid.new(version_str)`

Creates a new UUID generator object based on the specified version.

- `version_str` (string): The version of the UUID to generate. Supported values are `"TIME_BASED"`, `"DCE_SECURITY"`, and `"RANDOM"`.

### `uuid:generate()`

Generates a UUID based on the generator object's version.

## Contributing

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License with an additional non-commerical clause.
