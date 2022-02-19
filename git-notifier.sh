# !/bin/bash
VERSION='0.0.1'
MEMFILE='notifier-memo.txt'
PATHS='notifier-paths.txt'
PATHSDELIMITER=','
ICON='icons/logo.png'

SLEEPSECONDS=300

checkRepo () {
    # Decode Path
    REPO=$(echo "$1" | awk -F$PATHSDELIMITER '{print $1}')
    REPOPATH=$(echo "$1" | awk -F$PATHSDELIMITER '{print $2}')
    #Fetch remote updates
    UPD=$(git -C "$REPOPATH" remote update)
    # Get last commit info
    COMM=$(git -C "$REPOPATH" log --all -1 --format="%h%n%an%n%s%n%D") #hash,author,message,branch
    LASTCOMM=$(echo "$COMM" | sed -n '1p')
    # Last tracked commit hash
    LASTKNOWN=$(grep -w "$REPO" $MEMFILE | awk '{print $2}')

    if [ $LASTKNOWN = $LASTCOMM ];
    then
        echo "All is c0ol in $REPO, rasta..."
    else
        echo "New commit available in" "$REPO" "/" $(echo "$COMM" | sed -n '4p')
        # Update last tracked commit hash
        sed -i '.bak' -e "s/^$REPO.*/$REPO\ $LASTCOMM/" $MEMFILE
        # Decode last commit info
        AUTHOR=$(echo "$COMM" | sed -n '2p')
        MSG=$(echo "$COMM" | sed -n '3p')
        BRANCH=$(echo "$COMM" | sed -n '4p' | awk -F/ '{print $2}')
        # Identify Remote
        REMOTE=$(git -C "$REPOPATH" remote -v | sed -n '1p' | awk -F\  '{print $2}')
        # Notify
        terminal-notifier -title $AUTHOR -subtitle $REPO" / "$BRANCH -message $"$MSG" -appIcon $ICON -sound Glass -open $REMOTE
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
            checkRepo "$REPOPATH"
        done <"$PATHS"
        echo ''
        sleep $SLEEPSECONDS
    done
}

addRepo () {
    REPOPATH=$1
    echo "$REPOPATH"
    REPO=$(git -C "$REPOPATH" remote -v | sed -n '1p' | awk -F/ '{print $NF}' | awk -F.git '{print $1}')
    
    LASTCOMM=$(git -C "$REPOPATH" log -1 --all --oneline | awk '{print $1}')
    case $LASTCOMM in
        '') echo Error adding "$REPO" to watchlist ':('
        ;;
        *)
        case $(grep -w "$REPO" $MEMFILE | awk '{print $1}') in
            '')
                echo "$REPO""$PATHSDELIMITER""$REPOPATH" >> notifier-paths.txt
                echo "$REPO" $(echo "$LASTCOMM" | awk '{print $1}') >> $MEMFILE
                echo '  '"$REPO" added to watchlist ':)'    
                terminal-notifier -title $REPO -subtitle 'Added to watchlist' -message $"$REPOPATH" -appIcon $ICON -sound Glass
    
            ;;
            *) echo '  '"$REPO" is already 'in' watchlist ';)'
            ;;
        esac
        ;;
    esac
}

removeRepo () {
    # case $(grep -w "$1" $MEMFILE | awk '{print $1}') in
    #     '')
    #         case $(grep "$1" $PATHS) in
    #             '')
                    echo '  '"Repo not found in watchlist :("
    #             ;;
    #             *) 
    #                 REPO=$1
    #                 RNAME=$(echo "$1" | awk -F/ '{print $(NF)}')

    #                 # RNAME=$(git -C "$REPO" remote -v | sed -n '1p' | awk -F/ '{print $NF}' | awk -F.git '{print $1}')
    #                 echo '  'Removing "$RNAME" from paths
    #                 sed -i '.bak' -e "/$RNAME/d" $PATHS
    #                 echo '  'Removing "$RNAME" from memory
    #                 sed -i '.bak' -e "/$RNAME/d" $MEMFILE
    #                 terminal-notifier -title $RNAME -message $"Removed from watchlist" -appIcon $ICON -sound Glass
    #             ;;
    #         esac
    #     ;;
    #     *) 
    #         REPO=$1
    #         RNAME=$(echo "$1" | awk -F/ '{print $(NF)}')
    #         echo '  'Removing "$RNAME" from paths
    #         sed -i '.bak' -e "/$RNAME/d" $PATHS
    #         echo '  'Removing "$RNAME" from memory
    #         sed -i '.bak' -e "/$RNAME/d" $MEMFILE
    #         terminal-notifier -title $RNAME -message $"Removed from watchlist" -appIcon $ICON -sound Glass
    #     ;;
    # esac
}

listRepos () {
    while IFS= read -r REPOPATH
    do
        REPO=$(echo "$REPOPATH" | awk -F$PATHSDELIMITER '{print $2}')
        RNAME=$(git -C "$REPO" remote -v | sed -n '1p' | awk -F/ '{print $NF}' | awk -F.git '{print $1}')
        REMOTE=$(git -C "$REPO" remote -v | sed -n '1p' | awk -F\  '{print $2}')

        echo "\n " "$RNAME"
        echo '  Path:' "$REPO"
        echo '  Git :' "$REMOTE"
        
        LASTKNOWN=$(grep -w "$RNAME" $MEMFILE | awk '{print $2}')
        echo '  Last Known Commit :' "$LASTKNOWN" 

        COMM=$(git -C "$REPO" show "$LASTKNOWN" --no-patch --format="%an%n%s%n%cd%n%D")
        AUTHOR=$(echo "$COMM" | sed -n '1p')
        MSG=$(echo "$COMM" | sed -n '2p')
        DATE=$(echo "$COMM" | sed -n '3p')
        BRANCH=$(echo "$COMM" | sed -n '4p') #| awk -F/ '{print $2}')

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