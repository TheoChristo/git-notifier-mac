# git-notifier-mac

A simple tool to keep track of changes in git repositories.

<p align="center"> <img src="./icons/logo.png" width="128" height="128" /> </p>

**git-notifier-mac** will notify you - using a system notification -, every time a new commit is made in your tracked git repositories.

**git-notifier-mac** uses JulienXX's [terminal notifier](https://github.com/julienXX/terminal-notifier) to trigger notifications on MacOs.

## Use

* To **add** a new repository to your watchlist, simply run
  
    ``` cli
    ./git-notifier add [path-to-repo]
    ```

* To **remove** a repo from your watchlist,run
  
    ```cli
    ./git-notifier remove [repo-name]
    ```

* To **list** all git repos in watchlist, run
  
    ```cli
    ./git-notifier list
    ```

* To **start git-notifier** deamon to watch for new commits, run

    ```cli
    ./git-notifier start
    ```

    You can also pass an (optional) argument to specify the frequency with which git-notifier will watch for changes. By default, git-notifier waits 300 seconds between checks.

    ```cli
    ./git-notifier start [(optional) sleep-seconds]
    ```
