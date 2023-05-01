# BUNDLE: Push to FTP

This action is a bundle of other actions which simplifies the workflow definition process for our standard wp-content rooted projects.

## Getting Started

This is the most common configuration

```yml
- name: Push to FTP
  uses: saucal/action-bundle-push-to-ftp@v1
  with:
    env-host: ${{ secrets.ENV_HOST }}
    env-port: ${{ secrets.ENV_PORT }}
    env-user: ${{ secrets.ENV_USER }}
    env-pass: ${{ secrets.ENV_PASS }}
    env-remote-root: ${{ secrets.ENV_REMOTE_ROOT }}
```

## Full options

```yml
- uses: saucal/action-bundle-push-to-ftp@v1
  with:
    # Folder where source code is already built
    source: "source"

    # Folder of the repo that things will be pushed to
    built: "built"

    # SFTP is the default, and only supported value here.
    env-type: "sftp"

    # FTP Host to use to connect
    env-host: ""

    # FTP Port to use to connect
    env-port: ""

    # FTP User to use to connect
    env-user: ""

    # FTP Password to use to connect
    env-pass: ""

    # FTP Root to push to
    env-remote-root: ""

    # Forced .gitignore entries (appended at the end)
    force-ignore: |
      /auth.json
      /vendor/*
      !/vendor/composer
      /vendor/composer/*
      !/vendor/composer/installers
      !/vendor/composer/installed.json

    # Ignore files when present in the manifest. 
    # Similar to .gitignore functionality, tho each rule is
    # analized individually, compared to how gitignore works
    # where you can negate part of a previous rule.
    ftp-ignore: |
      /vendor/**
      /auth.json
      /composer.json
      /composer.lock

    # Wether to do a full deployment or not
    full-deployment: "${{ github.event_name != 'push' }}"
```
