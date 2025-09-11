# DOCKER WRAPS

This lib implements docker wraps, where wrap is (image + container + related scripts in user env).

Tested in ubuntu. But, may work with other systems. This lib use `jq` and `docker`, which is going to be installed by script if not installed yet. Also all script are written on `bash`, as it is default for development and clear to check what it does.

Why `bash` - not to install unnecessary packages and keep the environment clean.

## Within each wrap organized logic for images and containers:

### init

1) `build.run.before` with all **basedOn wraps taking into account**, depends on is it asAbstact or not
2) Building image
3) If new image have diffent id and not used 
    1) Remove old one
4) `build.run.after`

### start

1) If container running
    1) Do exec on container with `run.args` and `run.commands` and `other same options as for run `
2) If container not running
    1) Init wrap
    2) If container image is not the same as for image created by wrap
        1) Remove the container with all **basedOn wraps taking into account**
    3) If container exist
        1) Start container with all **basedOn wraps taking into account**
    4) If container doesn`t exist
        1) Run container with all **basedOn wraps taking into account**

### stop

1) If container running
    1) Stop container with all **basedOn wraps taking into account**

### kill

1) If container running
    1) Kill container with all **basedOn wraps taking into account**

### remove

#### Container

1) If container running
    1) Kill wrap
2) Remove container
3) If no image of the same wrap
    1) Clean

#### Image

1) Remove image
2) If no container of the same wrap
    1) Clean

### get

Returns name of image or container taking into account `uniquePrefix`


## BASED_ON

Each dockerfile that will use basedOn should be started with this lines if based on is expected to work correctly.

```docker
ARG BASED_ON=""
FROM $BASED_ON
```

### asAsbatract

Used when image not created and just build options is forwarded, can be used only if wrap based on another wrap.
<br>
`build` options will be executed depending on this property, so if asAbstact - not used for image before, but forwarded to image with `basedOn.asAbstact` equals to true. That is what **basedOn wraps taking into account** means.

### precreate

Means that wrap will be used, so uniquePrefix will be added, properties forwarded.

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
                ], // optional, volumes for run command
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

Commands below use `main.sh`, so that file you need to create using `example.sh` in the folder where you would like to execute it.

Also you need to create config file, you can use schema above, or use `example.json` as a template.

You can use relative path depending where your `main.sh` is located. You are free on choosing names. Also check that newly create file has right permissions. `chmod +x ./main.sh` is recommended.

## Command explanations and syntax

| Command | Explanation | Syntax |
|---|---|---|
| `get name` | Retrieves the name of the image or container associated with the specified configuration and wrap. | `./main.sh get name image <wrap_name>`<br>or<br>`./main.sh get name container <wrap_name>` |
| `get sequence` | Retrieves the basedOn sequence of some wrap. | `./main.sh get sequence <wrap_name>` |
| `resolve-sequence` | Makes a new file with resolved sequence based on mentioned wrap. | `./main.sh resolve-sequence <wrap_name> <file_for_new_config>` |
| `remove` | Removes the image or container associated with the specified configuration and wrap. | `./main.sh remove image <wrap_name>`<br>or<br>`./main.sh remove container <wrap_name>`<br>or<br>`./main.sh remove both <wrap_name>`<br>or<br>`./main.sh remove all <container\|image>`<br>or<br>`./main.sh remove all <container\|image\|both>`|
| `init` | Initializes resources (such as images or containers) based on the configuration and wrap. | `./main.sh init <wrap_name>` |
| `start` | Starts the container or service defined by the configuration and wrap. | `./main.sh start <wrap_name>` |
| `stop` | Stops the running container or service defined by the configuration and wrap. | `./main.sh stop <wrap_name>` |
| `kill` | Forcefully stops (kills) the running container or service defined by the configuration and wrap. | `./main.sh kill <wrap_name>` |

Replace `<wrap_name>` with your actual paths and wrap name as needed.

