# Summary

This is a containerized version of [nasher](https://github.com/squattingmonk/nasher) with dependent binaries for use in CI pipelines that have specific requirements around nasher version. See packages for build versions. It also includes all the [neverwinter.nim](https://github.com/niv/neverwinter.nim) tools such as `nwn_tlk`. 

Contact [tpickles](discordapp.com/users/272170902693871616) on discord to request other versions.

Mostly relying on github actions for deployment so we are simply downloading binaries instead of building from source, as that takes a lot of time and CI minutes.

I was somewhat lazy and just picked `1002` as the user ID, this choice was arbitrary. It is important to set ownership on server assets in CI builds to the same user ID however if mounting source as a volume like in the example below.

# Example CI Pipeline

```yml
on:
  workflow_dispatch:
    inputs:
      note:
        description: 'Note'
        required: false
        default: 'No note'

name: Do Nasher Stuff

jobs:
  build-assets:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout server source code
        uses: actions/checkout@v2
        with:
          path: my-module
      - name: Update file permissions
        run: sudo chown -R 1002:1002 ${{ github.workspace }}
      - name: Build nwn server assets
        uses: addnab/docker-run-action@v3
        with:
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}
          registry: ghcr.io
          image: ghcr.io/narfell/nasher:8193.35_0.20.0
          options: -v ${{ github.workspace }}/my-module:/nasher --user nasher
          run: |
            nasher pack all --yes --clean
            nwn_tlk -i ./src/server_files/custom.json -o ./docker/volumes/server/tlk/custom.tlk
```