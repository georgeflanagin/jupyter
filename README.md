# Jupyter on a compute node.

Most of the necessary comments are in the `jupyter.sh` file. A word about
what problem we are trying to solve is called for. 

In a cluster computer, you want to run Jupyter on a compute node while
using one's own Linux workstation for the browser and the user interface.
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
run_jupyter PARTITION [ HOURS ] [ NUMGPUS ]
```

`PARTITION` : Name of the group of nodes where you want to run the Jupyter
notebook. It defaults to the default partition on the cluster, and all SLURM
clusters have a default partition.

`HOURS` : Number of hours to initially allocate. The default is `1`.

`NUMGPUS` : The number of GPUs you plan to use. The default is none.
