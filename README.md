# OrangeFox Builder Action
🦊 Build OrangeFox recovery with Github Action!

## How to use?
- First, configure the workflow file according to the following example:

```yml
name: OrangeFox - Builder

on:
  workflow_dispatch:

jobs:
  build:
    name: 🦊 Build OrangeFox Recovery
    runs-on: ubuntu-latest
    env:
      GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Build OrangeFox
      uses: linastorvaldz/orangefox-builder-action@master
      with:
        USER_NAME: '' # Your github username
        USER_EMAIL: '' # Your github email
        DEVICE_TREE: '' # Your device tree
        DEVICE_TREE_BRANCH: '' # Device tree branch
        DEVICE_PATH: '' # Path to the device tree
        DEVICE_NAME: '' # Device codename
        BUILD_TARGET: '' # Build Target [boot,recovery,vendorboot]
        TG_CHAT_ID: '${{ secrets.TG_CHAT_ID }}' # Chat ID secret
        TG_TOKEN: '${{ secrets.TG_TOKEN }}' # Telegram bot token secret
        MAINTAINER_URL: '' # Maintainer picture (this is not necessary)
```

- Finally, run the workflow you just wrote.

## Credits
- All credits belong to [UWU-TEAM](https://github.com/UWU-TEAM)
