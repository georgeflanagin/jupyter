###
# Environment variables, with their default values.
###

# In production, this will be the result of executing `whoami`,
#     shown here commented out. For testing, you can set it to 
#     any user who has an id on all the computers involved.
# export me=$(whoami)
export me=gflanagi

# If this is set, we use it.
export browser_exe="$BROWSER"

# Name of the cluster
export cluster="spydur"

# Extra output if we are debugging.
export debug=

# The port on the headnode that we are passing through.
export headnode_port=0

# The exe we are running. Note that this location is on the compute node.
export jupyter_exe="jupyter-notebook --no-browser"

# The port that Jupyter is listening on for a connection.
export jupyter_port=0

# The local port that will be forwarded.
export local_port=0

# used to store the value of the port search.
export next_open_port=0

# Default partition. Strictly speaking, the partition
# is not required, but it is a good idea to set this
# to the default on your cluster.
export partition=basic

# How long is the Jupyter session in hours?
export runtime=1

# These variables will be assigned by the headnode.
export thisjob=
export thisnode=


# This variable holds the cascaded tunnel once we know what
# the values are. It will look something like this:
#
# ssh -q  -L localport:localhost:headnodeport spydur -t 
#      ssh -L headnodeport:localhost:jupyterport computenode
export tunnel=

###
# Shell functions.
###

# Find the default browser on the user's computer
function default_browser
{
    if [ -z $browser_exe ]; then
        browser_exe=$(xdg-settings get default-web-browser)
    fi
}

# Change this function as approprate for the environment.
function limit_time
{
    if (( $runtime > 8 )); then
        echo "Setting hours to the maximum of 8"
        runtime=8
    fi
}

# Search a range of ports for something not in use.
function open_port 
{
    lower=${1:-9000}
    upper=${2:-9100}

    for ((port = $lower; port <= $upper; port++)); do
        if ! ss -tuln | grep -q ":$port "; then
            next_open_port="$port"
            break
        fi
    done
}

function open_port_script
{
    type open_port | tail -n +2 > open_port.sh
    echo "open_port" >> open_port.sh
    chmod 755 open_port.sh
}

# Write a job 
function slurm_jupyter
{
    # This command only creates a reservation for our session. We
    # are using this to retrieve the SLURM_JOBID and the name of
    # the node. 
    cmd="salloc --account $me -p $partition --gres=$gres --time=$runtime:00:00 --no-shell > salloc.txt 2>&1"
    if [ "$debug" ]; then
        echo $cmd
    fi
    eval "$cmd"

    # If we don't have a compute node, we are sunk.
    if [ ! $? ]; then
        echo "salloc was unable to allocate a compute node for you."
        cat salloc.txt
        return
    else
        echo "-------------------------------------"
        cat salloc.txt
        echo "-------------------------------------"
        sleep 5
        export thisjob=$(cat salloc.txt | head -1 | awk '{print $NF}')
        echo "your request is granted. Job ID $SLURM_JOBID"

        thisnode=$(squeue -o %N -j $SLURM_JOBID | tail -1)
        echo "JOB $SLURM_JOBID will be executing on $thisnode"
    fi

    # Connect to the compute node and find an open port.
    

    # Now we need to star the Jupyter Notebook.
    ssh "$thisnode" "jupyter-notebook --no-browser"

}

