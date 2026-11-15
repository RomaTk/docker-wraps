# DOCKER WRAPS

This library implements **docker wraps**, where a wrap combines an image, a container, and related lifecycle scripts in the user environment.

Tested on Ubuntu, though it may work on other Linux distributions. It relies on `jq` and `docker` (with `docker buildx` for image builds), which are checked/installed automatically by the setup scripts if not already present. All scripts are written in `bash` to keep the environment clean and avoid unnecessary runtime dependencies.

## Wrap Lifecycle Commands

Each wrap organizes lifecycle logic for images and containers:

### `init`

1) Runs `build.run.before` hooks, **taking all `basedOn` wraps into account** (depending on whether `asAbstract` is enabled)
2) Builds the image (using `docker buildx build`, or tags an existing base image when `to_rename` optimization applies)
3) If the new image has a different ID and the old image is dangling/unused:
    1) Removes the old image (and its associated container if needed)
4) Runs `build.run.after` hooks

### `start`

1) Initializes the image (`init`)
2) If the container does not exist:
    1) Runs a new container, **taking all `basedOn` wraps into account**
3) If the container exists:
    1) Compares the container's image ID with the current image ID
    2) If different:
        1) Removes the container, **taking all `basedOn` wraps into account**
        2) Creates and runs a new container
    3) If identical:
        1) If the container is running:
            1) Executes `docker exec` on the container with `run.entrypoint.args`, `run.entrypoint.commands`, and matching `run` options
        2) If the container is not running:
            1) Starts the existing container, **taking all `basedOn` wraps into account**

### `stop`

1) If the container is running:
    1) Stops the container using resolved `stop` options (`signal`, `timeout`, `options`)

### `kill`

1) If the container is running:
    1) Forcefully stops the container using resolved `kill` options (`signal`, `options`)

### `remove`

#### Container

1) If the container is running:
    1) Kills the container
2) Removes the container
3) If no image exists for the same wrap:
    1) Runs `clean` commands

#### Image

1) Removes the image
2) If no container exists for the same wrap:
    1) Runs `clean` commands

### `get`

Returns the resolved image/container name (with `uniquePrefix`) or the resolved `basedOn` dependency sequence.

## `BASED_ON`

Each `Dockerfile` that uses `basedOn` should start with the following lines so base image inheritance works properly:

```docker
ARG BASED_ON=""
FROM $BASED_ON
```

### `asAbstract`

Marks a `basedOn` reference as an abstract configuration template rather than a pre-built image. When `asAbstract` is `true`, no intermediate Docker image is built for that wrap; instead, its `build` options, `run` configuration, and lifecycle hooks are inherited and forwarded to the dependent wrap.

### `precreate`

Indicates that the referenced `basedOn` wrap is defined in the same configuration file and should be built/created first using the project's `uniquePrefix`. Its properties are inherited and forwarded to the dependent wrap.

### Array of `basedOn` config schemas

When `basedOn` is an array instead of a single object, it defines an ordered inheritance chain where the **first** element is closest to the current wrap (used as the direct `BASED_ON` build argument) and the **last** element is the farthest ancestor. Elements closer to the current wrap take higher priority when merging configuration options.

You can use `get sequence` to inspect the full flattened `basedOn` sequence (by default, contiguous `precreate`/`asAbstract` items are sorted by wrap weight descending via `wrapweight all` so shared dependencies are ordered consistently; pass `--no-weight` to preserve raw traversal order), or `resolve-sequence` to materialize the merged configuration into a standalone JSON file.

## Config file

```json
{
    "uniquePrefix": "string", // all images and containers created from this file will have this prefix. It is expected that all images with this prefix created from this file
    "wraps": {
        "wrapName": {
            "basedOn": "basedOn config schema OR array of basedOn config schemas", // optional, inform what will be set as BASED_ON argument
            "dockerfile": "string", //optional, path to dockerfile
            "build": {
                "context": "string", // path to context, optional if can be extracted from basedOn
                "run": {
                    "before": [
                        "string", //adding this string
                        {"value": "string", "action": "add|remove", "basedOnScope": "string" } // some action to do with value
                    ], // optional, commands to do before making build
                    "after": [
                        "string", //adding this string
                        {"value": "string", "action": "add|remove", "basedOnScope": "string" } // some action to do with value
                    ], // optional, commands to do after making build
                },
                "options": [
                    "string", //adding this string
                    {"value": "string", "action": "add|remove"} // some action to do with value
                ], // optional, additional options for build command
            },
            "run": {
                "options":[
                    "string", //adding this string
                    {"value": "string", "action": "add|remove"} // some action to do with value
                ], // optional, additional options for run command
                "volumes": [
                    {
                        "destination": "string",
                        "source": "string|null", //null meaning to remove
                        "readonly": "boolean", //optional   
                        "nocopy": "boolean" //optional
                    }
                ], // optional, volumes for run command (it is only type=bind for now)
                "entrypoint": {
                    "tool": "string|null", //optional
                    "args": [
                        "string",
                        {"value": "string", "action": "add|remove"} // some action to do with value
                    ], //optional
                    "commands": [
                        "string", //adding this string
                        {"value": "string", "action": "add|remove", "continueInError": "boolean"/*optional, by default - false, when add, if remove - mentioned one or existing*/ } // some action to do with value
                    ] //optional
                },
                "interactive": "boolean", //optional, boolean
            },
            "stop": {
                "options":[
                    "string", //adding this string
                    {"value": "string", "action": "add|remove"} // some action to do with value
                ], // optional, additional options for stop command
                "signal": "string|null", //optional
                "timeout": "string|null", //optional
            },
            "kill": {
                "options":[
                    "string", //adding this string
                    {"value": "string", "action": "add|remove"} // some action to do with value
                ], // optional, additional options for kill command
                "signal": "string|null", //optional
            },
            "clean": [
                "string", //adding this string
            ] //optional (commands to do to remove all staff left in the system) - this will be not executed during init, as do before fully implement it.
        },
    }, // Here will be all info about wraps, optional
}
```

### BasedOn config schema

```json
{
    "name": "string", // name of image, if expected to be done from this file uniquePrefix should not be added
    "tag": "string", // tag for image, if expected to be created should be latest
    "precreate": "boolean", // optional, is to create from this file. By default - false
    "asAbstract": "boolean", // optional, by default - false, meaning is to extend only values
}
```

## How to use

Commands below use `main.sh`, which you can create using [example.sh](./example.sh) in the folder where you would like to execute it.

You also need a configuration file; you can follow the schema above or use [example.json](./example.json) as a template.

You can use a relative path depending on where your `main.sh` is located. Make sure the newly created script has execute permissions (`chmod +x ./main.sh` is recommended).

## Command explanations and syntax

| Command | Explanation | Syntax |
|---|---|---|
| `get name` | Retrieves the name of the image or container associated with the specified configuration and wrap. | `./main.sh get name image <wrap_name>`<br>or<br>`./main.sh get name container <wrap_name>` |
| `get sequence` | Retrieves the basedOn sequence of some wrap. By default uses weights to sort the sequence, unless `--no-weight` is provided. | `./main.sh get sequence [--no-weight] <wrap_name>` |
| `resolve-sequence` | Makes a new file with resolved sequence based on mentioned wrap. | `./main.sh resolve-sequence <wrap_name> <file_for_new_config>` |
| `remove` | Removes the image or container associated with the specified configuration and wrap. | `./main.sh remove <container\|image\|both> <wrap_name> [--force]`<br>or<br>`./main.sh remove all [<container\|image\|both>] [--force]` |
| `init` | Initializes resources (such as images or containers) based on the configuration and wrap. | `./main.sh init <wrap_name>` |
| `start` | Starts the container or service defined by the configuration and wrap. | `./main.sh start <wrap_name>` |
| `stop` | Stops the running container or service defined by the configuration and wrap. | `./main.sh stop <wrap_name>` |
| `kill` | Forcefully stops (kills) the running container or service defined by the configuration and wrap. | `./main.sh kill <wrap_name>` |
| `wrapweight all` | Calculates the weight (number of dependencies in the basedOn sequence) for all wraps in the configuration. | `./main.sh wrapweight all` |

Replace `<wrap_name>` with your actual paths and wrap name as needed.

