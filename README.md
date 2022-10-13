# MBox Workspace

[![Test](https://github.com/MBoxPlus/mbox-workspace/actions/workflows/test.yml/badge.svg?branch=main&event=push)](https://github.com/MBoxPlus/mbox-workspace/actions/workflows/test.yml)

MBoxWorkspace is a core plugin implements the function of workspace, which contains three native plugins: `MBoxWorkspaceLoader` `MBoxWorkspaceCore` `MBoxWorkspace`.

## MBoxWorkspaceLoader

This native plugin will be always loaded. It provides the command `mbox init` before the MBox workspace created.

## MBoxWorkspaceCore

It provides the model for workspace.

- `MBWorkspace` - The model class for each MBox workspace.
- `MBConfig` - The model class for the `.mbox/config.json` file.
- `MBConfig.Feature` - The model class for each feature in one workspace.
- `MBConfig.Repo` - The model class for each repo in one feature.
- `MBWorkRepo` - The model class for each repo under the working directory.
- `MBStoreRepo` - The model class for each repo under the cache directory.

## MBoxWorkspace

It provides the command implements of workspace. See the command implements according to the file's name.


## Contributing
Please reference the section [Contributing](https://github.com/MBoxPlus/mbox#contributing)

## License
MBox is available under [GNU General Public License v2.0 or later](./LICENSE).
