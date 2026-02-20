# guided-setup

OpenShift cluster installation wizard based on https://github.com/appuio/gandalf


## Usage

We recommend using the provided docker image, by way of the alias commands found in `docker/alias.sh`.

The docker image includes all dependencies necessary for the guided setup workflows provided here.

```
source docker/alias.sh

# Run guided setup for a specific cloud provider
guided-setup run cloudplosion

# Run guided setup for a specific cloud provider, using a local workflow directory instead of the provided one
guided-setup -w /path/to/workflow/directory run cloudplosion

# Run guided setup for a specific cloud provider, including additional workflow files in addition to the default
guided-setup run cloudplosion /path/to/workflow/file.yml

# Run guided setup without automatic cloud provider workflow inclusion - provide all workflow file paths manually
guided-setup-base run /workflows/cloudplosion.workflow /workflows/cloudplosion/*.yml

# Run guided setup without automatic cloud provider workflow inclusion - provide all workflow file paths manually
# Additionally include a local workflow directory in the container
guided-setup-base -v /path/to/local/workflows:/container_dir run /container_dir/cloudplosion.workflow /container_dir/cloudplosion/*.yml

```

### Running manually

If you install [gandalf](https://github.com/appuio/gandalf) in addition to all workflow dependencies, you can run workflows without docker:

```
gandalf run /path/to/workflows/cloudplosion.workflow /path/to/workflows/cloudplosion/*.yml
```
