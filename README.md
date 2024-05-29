# Jupyter on a compute node.

Most of the necessary comments are in the `jupyter.sh` file. A word about
what problem we are trying to solve is called for. 

In a cluster computer, you want to run Jupyter on a compute node while
using one's own Linux workstation (or Mac) for the browser and the user interface.
Doing so is not technically difficult, but for people who are unfamiliar
with ssh and tunneling and even the internal configuration of the cluster,
it is a mistake prone operation. 

`jupyter.sh` is a file of shell functions that can be placed on the user's 
workstation. Rather
than divide the shell functions into client and server, they are all present
in the one file. Not all are used on all the computers involved, but experience
shows that it is more problematic to distribute multiple files than just one.

## Assumptions

- The script assumes you are using SLURM --- it is the most widely used cluster
  scheduling system, and the one we use at University of Richmond. Changing it 
  for SGE or Torq should not be too much trouble.
- The script assumes that the username is the same on the cluster and the user's
  workstation (`localhost`). The UIDs need not match, and no centralized authentication
  is used.
- The script assumes ssh keys are available for the connections; the operation 
  should be fully automatic, requiring no user interaction. 
- The default browser is used. If you set the `BROWSER` environment variable on
  your workstation, another browser can be used.

## How to use it

```
source jupyter.sh
run_jupyter PARTITION [USER] [ HOURS ] [ NUMGPUS ]
```

### Parameters

#### PARTITION

This is the only required parameter. The `run_jupyter` command checks that the partition
name is valid. Case is relevant, so `basic` is correct, but `BASIC` will give you an error.

#### USER

This is generally your University of Richmond `netid`. If you are logged in as "yourself" 
on your workstation, then you probably can omit this parameter. If you are logged in
as a user that doesn't exist on the cluster (example: you are on a personal computer
and VPN-ed into UR's network), then you will need provide your netid. 

#### HOURS

This value defaults to `1`. If you need more than `1`, provide the number. Note that
GPUs are not available on all partitions/nodes.

#### NUMGPUS

This value defaults to `NONE`. Generally, one is enough.

### Examples

`run_jupyter medium` Run a notebook as your currently logged in user for one hour, no GPUs.

`run_jupyter basic xx8ur` Run a notebook as `xx8ur` on the basic partition for one hour.

`run_jupyter sci gflanagi 2 1` Run a notebook as `gflanagi` on the sci partition for two hours, and use one GPU.
