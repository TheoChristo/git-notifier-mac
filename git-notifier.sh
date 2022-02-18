# !/bin/bash
VERSION='0.0.1'
MEMFILE='notifier-memo.txt'
PATHS='notifier-paths.txt'
ICON='logo.png'

checkRepo () {
    REPOPATH=$1
    UPD=$(git -C "$REPOPATH" remote update)
    
    REPO=$(echo "$REPOPATH" | awk -F/ '{print $(NF)}')

    UPDTMSG=$(git -C "$REPOPATH" remote show origin)
    REMOTE=$(echo "$UPDTMSG" | grep -i 'Fetch URL' | awk -F'Fetch\ URL:\ ' '{print $2}')
    
    LASTCOMM=$(git -C "$REPOPATH" log --all --oneline| grep -m1 '\ ' | awk '{print $1}')
    BRANCH=$(echo $(echo $(git -C "$REPOPATH" branch -a --contains $LASTKNOWN))| awk -F/ '{print $(NF)}')
    LASTKNOWN=$(grep -w "$REPO" $MEMFILE | awk '{print $2}')

    if [ $LASTKNOWN = $LASTCOMM ];
    then
        echo "All is c0ol in $REPO, rasta..."
    else
        if [ -z "$LASTKNOWN" ];
        then
            echo "$REPO was is not in watchlist."
        else
            echo "New commit available in " "$REPO""/""$BRANCH"
            sed -i '.bak' -e "s/^$REPO.*/$REPO\ $LASTCOMM/" $MEMFILE
        fi
        COMM=$(git -C "$REPOPATH" show "$LASTCOMM")
        AUTHOR=$(echo "$COMM" | grep 'Author' | awk -F'Author:\ ' '{print $2}' | awk -F'<' '{print $1}')
        MSG=$(echo "$COMM" | grep -v -e '^$' | grep -A1 -i 'Date:\ ' | grep -m1 -vi 'Date:\ ' | xargs)

        terminal-notifier -title $AUTHOR -subtitle $REPO" / "$BRANCH -message $"$MSG" -appIcon $ICON -sound Glass -open $REMOTE
    fi
}

showMessage () {
    echo 1
}

processRepos () {
    while true; do
        while IFS= read -r REPOPATH
        do
            checkRepo "$REPOPATH"
        done <"$PATHS"
        sleep 300
    done
}

addRepo () {
    REPOPATH=$1
    echo "$REPOPATH"
    REPO=$(echo "$REPOPATH" | awk -F/ '{print $(NF)}')
    LASTCOMM=$(git -C "$REPOPATH" log -1 --all --oneline | awk '{print $1}')
    case $LASTCOMM in
        '') echo Error adding "$REPO" to watchlist ':('
        ;;
        *)
        case $(grep -w "$REPO" $MEMFILE | awk '{print $1}') in
            '')
                echo "$REPOPATH" >> notifier-paths.txt
                echo "$REPO" $(echo "$LASTCOMM" | awk '{print $1}') >> $MEMFILE
                echo '  '"$REPO" added to watchlist ':)'    
                terminal-notifier -title $REPO -subtitle 'Added to watchlist' -message $"$REPOPATH" -appIcon $ICON -sound Glass -open $REMOTE
    
            ;;
            *) echo '  '"$REPO" is already 'in' watchlist ';)'
            ;;
        esac
        ;;
    esac
}

removeRepo () {
    case $(grep -w "$1" $MEMFILE | awk '{print $1}') in
        '')
            case $(grep "$1" $PATHS) in
                '')
                    echo '  '"Repo not found in watchlist :("
                ;;
                *) 
                    REPO=$1
                    RNAME=$(echo "$1" | awk -F/ '{print $(NF)}')
                    echo '  'Removing "$RNAME" from paths
                    sed -i '.bak' -e "/$RNAME/d" $PATHS
                    echo '  'Removing "$RNAME" from memory
                    sed -i '.bak' -e "/$RNAME/d" $MEMFILE
                    terminal-notifier -title $REPO -message $"Removed from watchlist" -appIcon $ICON -sound Glass -open $REMOTE
                ;;
            esac
        ;;
        *) 
            REPO=$1
            RNAME=$(echo "$1" | awk -F/ '{print $(NF)}')
            echo '  'Removing "$RNAME" from paths
            sed -i '.bak' -e "/$RNAME/d" $PATHS
            echo '  'Removing "$RNAME" from memory
            sed -i '.bak' -e "/$RNAME/d" $MEMFILE
            terminal-notifier -title $REPO -message $"Removed from watchlist" -appIcon $ICON -sound Glass -open $REMOTE
        ;;
    esac
}

listRepos () {
    while IFS= read -r REPOPATH
    do
        REPO=$REPOPATH
        RNAME=$(echo "$REPOPATH" | awk -F/ '{print $(NF)}')

        echo "\n  Repo:" "$RNAME"
        echo '  Path:' "$REPOPATH"
        
        LASTKNOWN=$(grep -w "$RNAME" $MEMFILE | awk '{print $2}')
        echo '  Last Known Commit :' "$LASTKNOWN" 

        BRANCH=$(echo $(echo $(git -C "$REPOPATH" branch -a --contains $LASTKNOWN))| awk -F/ '{print $(NF)}')
        COMM=$(git -C "$REPOPATH" show "$LASTKNOWN")
        AUTHOR=$(echo "$COMM" | grep 'Author' | awk -F'Author:\ ' '{print $2}' | awk -F'<' '{print $1}')
        MSG=$(echo "$COMM" | grep -v -e '^$' | grep -A1 -i 'Date:\ ' | grep -m1 -vi 'Date:\ ' | xargs)
        echo '             Author :' "$AUTHOR"
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
    echo '  [start | -s]'
    echo '  \tStart git-notifier deamon'
    
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
    'start' | '-s') processRepos
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