# !/bin/bash
VERSION='0.0.1'
MEMFILE='notifier-memo.txt'
PATHS='notifier-paths.txt'
MYDELIMITER=','
ICON='icons/logo.png'

SLEEPSECONDS=300

checkRepo () {
    echo "Checking " $1
    # Decode Path
    REPO=$(echo "$1" | awk -F$MYDELIMITER '{print $1}')
    REPOPATH=$(echo "$1" | awk -F$MYDELIMITER '{print $2}')
    #Fetch remote updates
    UPD=$(git -C "$REPOPATH" remote update)
    # Get last commit info
    COMM=$(git -C "$REPOPATH" log --all -1 --format="%h%n%an%n%s%n%D") # hash, author, message, branch
    LASTCOMM=$(echo "$COMM" | sed -n '1p')
    # Last tracked commit hash
    LASTKNOWN=$(grep -w "$REPO" $MEMFILE | awk -F$MYDELIMITER '{print $2}')

    if [ $LASTKNOWN = $LASTCOMM ];
    then
        echo "All is c0ol in $REPO, rasta..."
    else
        echo "New commit available in" "$REPO" "/" $(echo "$COMM" | sed -n '4p')
        # Update last tracked commit hash
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '.bak' -e "s/^$REPO.*/$REPO"$MYDELIMITER"$LASTCOMM/" $MEMFILE
        else 
            sed -i -e "s/^$REPO.*/$REPO"$MYDELIMITER"$LASTCOMM/" $MEMFILE
        fi
        # Decode last commit info
        AUTHOR=$(echo "$COMM" | sed -n '2p')
        MSG=$(echo "$COMM" | sed -n '3p')
        BRANCH=$(echo "$COMM" | sed -n '4p' | awk -F/ '{print $2}')
        # Identify Remote
        REMOTE=$(git -C "$REPOPATH" remote -v | sed -n '1p' | awk -F\  '{print $2}')
        # Notify
        if [[ "$OSTYPE" == "darwin"* ]]; then
            terminal-notifier -title $AUTHOR -subtitle $REPO" / "$BRANCH -message $"$MSG" -appIcon $ICON -sound Glass -open $REMOTE
        else 
            notify-send "$AUTHOR @ $REPO/$BRANCH" "$MSG" --icon=$(echo $(pwd)/$ICON)
        fi  
    fi
}

processRepos () {
    if [[ $1 -gt 0 ]]
    then
        SLEEPSECONDS=$1
    fi
    while true; do
        while IFS= read -r REPOPATH
        do
            checkRepo "$REPOPATH" &
        done <"$PATHS"
        echo ''
        sleep $SLEEPSECONDS
    done
}

addRepo () {
    REPOPATH=$1
    # Get repo name
    REPO=$(git -C "$REPOPATH" remote -v | sed -n '1p' | awk -F/ '{print $NF}' | awk -F.git '{print $1}')
    # Get last commit hash
    LASTCOMM=$(git -C "$REPOPATH" log --all -1 --format="%h")
    case $LASTCOMM in
        '') 
            echo 'Error adding' "$REPO" 'to watchlist :('
        ;;
        *)
            case $(grep -w "$REPO" $MEMFILE) in
                '')
                    # Store path
                    echo "$REPO""$MYDELIMITER""$REPOPATH" >> notifier-paths.txt
                    # Store last commit hash
                    echo "$REPO""$MYDELIMITER""$LASTCOMM" >> $MEMFILE
                    #Notify
                    echo '  '"$REPO" 'added to watchlist :)'
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        terminal-notifier -title $REPO -subtitle 'Added to watchlist' -message $"$REPOPATH" -appIcon $ICON -sound Glass
                    else
                        notify-send "$REPO, added to watchlist" "$REPOPATH" --icon=$(echo $(pwd)/$ICON)
                    fi
                ;;
                *) echo '  '"$REPO" 'is already in watchlist ;)'
                ;;
            esac
        ;;
    esac
}

removeRepo () {
    # Search in paths
    RES=$(grep -w "$1" $PATHS)
    case "$RES" in
        '')
            echo '  '"Repo not found in watchlist :("
        ;;
        *) 
            # Get target name
            TARGET=$(echo "$RES" | awk -F$MYDELIMITER '{print $1}')
            # Remove from paths and commit hash memory
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '.bak' -e "/$TARGET/d" $PATHS $MEMFILE
            else
                sed -i -e "/$TARGET/d" $PATHS $MEMFILE
            fi
            # Notify
            echo '  '"$TARGET" 'removed from watchlist'
            if [[ "$OSTYPE" == "darwin"* ]]; then
                terminal-notifier -title $TARGET -message $"Removed from watchlist" -appIcon $ICON -sound Glass
            else
                notify-send "$TARGET" 'Removed from watchlist' --icon=$(echo $(pwd)/$ICON)
            fi
        ;;
    esac
}

listRepos () {
    while IFS= read -r REPOPATHINFO
    do
        # Retrieve local repo name and path
        REPO=$(echo "$REPOPATHINFO" | awk -F$MYDELIMITER '{print $1}')
        REPOPATH=$(echo "$REPOPATHINFO" | awk -F$MYDELIMITER '{print $2}')
        # Identify remote
        REMOTE=$(git -C "$REPOPATH" remote -v | sed -n '1p' | awk -F\  '{print $2}')
        # Retrieve last known commit
        LASTKNOWN=$(grep -w "$REPO" $MEMFILE | awk -F$MYDELIMITER '{print $2}')
        # Get last known commit info 
        COMM=$(git -C "$REPOPATH" show "$LASTKNOWN" --no-patch --format="%an%n%s%n%cd%n%D") # author, message, date, branch
        # Decode last known commit info 
        AUTHOR=$(echo "$COMM" | sed -n '1p')
        MSG=$(echo "$COMM" | sed -n '2p')
        DATE=$(echo "$COMM" | sed -n '3p')
        BRANCH=$(echo "$COMM" | sed -n '4p')
        # Display
        echo "\n " "$REPO"
        echo '  Path:' "$REPOPATH"
        echo '  Git :' "$REMOTE"
        echo '  Last Known Commit :' "$LASTKNOWN" 
        echo '             Author :' "$AUTHOR"
        echo '             Date   :' $DATE
        echo '             Branch :' "$BRANCH"
        echo '             Message:' "$MSG"
    done <"$PATHS"
}

showVersion () {
    echo '  'git-notifier
    echo '  'version: "$VERSION"
}

showHelp () {
    showVersion
    echo '\n  Usage:'
    echo '  [start | -s] [arg]'
    echo '  \tStart git-notifier deamon'
    echo '  \targ: (optional) Seconds between remote updates. Default: 300'
    
    echo '  [add | -a] [arg]'
    echo '  \tAdd new git repo to watchlist'
    echo '  \targ: Absolute path to a git repo'
    
    echo '  [remove | -rm]'
    echo '  \tRemove git repo from watchlist'
    echo '  \targ: Absolute path to a git repo'
    echo '  \t     OR git repo name'
    
    echo '  [list | -l]'
    echo '  \tList all git repos in watchlist'
    
    echo '  [version | -v]'
    echo '  \tShow git-notifier version'

    echo '  [help | -h]'
    echo '  \tShow git-notifier help'
}

case $1 in
    'start' | '-s') processRepos $2
    ;;
    'add' | '-a') addRepo "$2"
    ;;
    'remove' | '-rm' ) removeRepo "$2"
    ;;
    'list' | '-l') listRepos 
    ;;
    'version' | '-v') showVersion
    ;;
    'help' | '-h') showHelp
    ;;
    *)
    echo "  Invalid git-notifier command"
    echo "  To show commands type: git-notifier help"
esac