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
export jupyter_exe="/usr/local/sw/anaconda/anaconda3/bin/jupyter-notebook --no-browser"

# The port that Jupyter is listening on for a connection.
export jupyter_port=0

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
    if [ -z $1 ]; then
        echo "Usage: open_port {headnode|computenode}"
        return
    fi
    name_fragment="$1"
    lower=${2:-9500}
    upper=${3:-9600}
    

    for ((port = $lower; port <= $upper; port++)); do
        if ! ss -tuln | grep -q ":$port "; then
            echo "$port" > "$HOME/openport.$name_fragment.txt" 
            break
        fi
    done
}

# The easiest way to have the command as both a function and
# a script is to echo the function to a script, and then call it.
function open_port_script
{
    if [ -z "$1" ]; then
        echo "Usage: open_port_script {headnode|computenode}"
        return
    fi 
    type open_port | tail -n +2 > open_port.sh
    echo "open_port $1" >> open_port.sh
    chmod 755 open_port.sh
    ./open_port.sh
}

# Create the job on the headnode.
function slurm_jupyter
{
    # Pickup the value of partition, runtime, and gres.
    source jparams.txt
    # find an open port on the headnode.
    #  This will create a file named $HOME/openport.headnode.txt
    open_port_script headnode
    export headnode_port=$(cat $HOME/openport.headnode.txt)

    # This command only creates a reservation for our session. We
    # are using this to retrieve the SLURM_JOBID and the name of
    # the node. 
    if [ "$gres" == "NONE" ]; then
        cmd="salloc --account $me -p "$partition" --time=$runtime:00:00 --no-shell > salloc.txt 2>&1"
    else
        cmd="salloc --account $me -p $partition --gpus=$gres --time=$runtime:00:00 --no-shell > salloc.txt 2>&1"
    fi
        
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
        echo "your request is granted. Job ID $thisjob"

        thisnode=$(squeue -o %N -j $thisjob | tail -1)
        echo "JOB $SLURM_JOBID will be executing on $thisnode"
    fi

    # Connect to the compute node and find an open port. Keep in mind
    # the script is already there because the $HOME directory is
    # NFS mounted everywhere on the system. Now, there will be a file
    # named $HOME/openport.computenode.txt
    ssh "$me@$thisnode" "./open_port.sh computenode"
    export jupyter_port=$(cat $HOME/openport.computenode.txt)

    # Now we have all the information needed to create the tunnel.
    # Let's make the command that creates the tunnel. We don't want
    # to execute it /here/, so we write it to a file. 
    cat <<EOF >"$HOME/tunnelspec.txt"
ssh -q  -L $jupyter_port:localhost:$headnode_port $me@$cluster -t ssh -L $headnode_port:localhost:$jupyter_port $me@$computenode
export jupyter_port=$jupyter_port
EOF

    # Now we need to start the Jupyter Notebook.
    ssh "$me@$thisnode" "nohup $jupyter_exe --no-browser --ip=0.0.0.0 --port=$jupyter_port &"

}

function run_jupyter
{
    if [ -z $1 ]; then
        echo "Usage:"
        echo "  run_jupyter PARTITION [HOURS] [GPU]"
        echo " "
        echo " PARTITION -- the name of the partition where you want "
        echo "    your job to run."
        echo " "
        echo " HOURS -- defaults to 1, max is 8."
        echo " " 
        echo " GPU -- defaults to 0, max depends on the node."
        echo " "
        return
    fi

    partition="$1"  
    runtime=${2-1}  # default to one hour.
    gres=${3-NONE}  # if not provided, then nothing. 

    # Save the arguments.    
    cat<<EOF >jparams.txt
export partition=$partition
export runtime=$runtime
export gres=$gres
EOF

    # copy the parameters to the headnode.
    scp jparams.txt "$me@$cluster:~/." 2>/dev/null
    if [ ! $? ]; then
        echo "Could not copy parameters to $cluster"
        return
    fi

    # copy these functions to the headnode.
    scp jupyter.sh "$me@$cluster:~/." 2>/dev/null
    if [ ! $? ]; then
        echo "Could not copy jupyter commands to $cluster"
        return
    fi
    sleep 1

    #@@@@
    return
    
    ssh "$me@$cluster" "source jupyter.sh && slurm_jupyter"
    sleep 1
    scp "$me@$cluster:tunnelspec.txt" . 

    # Open the tunnel.
    source tunnelspec.txt

    # Find the default browser    
    default_browser

    xdg-open http://localhost:$jupyter_port
}

