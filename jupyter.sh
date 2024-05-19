# ssh -q  -L localport:localhost:headnodeport spydur -t ssh -L headnodeport:localhost:jupyterport computenode

###
# Environment variables.
###

# used to store the value of the port search.
export next_open_port=0

# If this is set, we use it.
export browser_exe="$BROWSER"

# The local port that will be forwarded.
export local_port=0

# The port on the headnode that we are passing through.
export headnode_port=0

# The port that Jupyter is listening on for a connection.
export jupyter_port=0

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
