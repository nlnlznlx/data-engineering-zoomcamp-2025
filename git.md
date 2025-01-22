# Basic git

1. Make sure your local copy of the selected branch is updated.
   1. Without overwriting anything, but update the status on all branches.
      - `git fetch`
   1. If you already fetched or you are ready to overwrite your local copy (your active branch only!), then pull
      - `git pull`
      - This is actually the same as doing `git fetch` on your branch and then `git merge`, which we will see later.
1. Check your repo branches
   1. Local branches
      - `git branch`
   1. All branches on remote repo
      - `git branch -r`
   1. Both local and remote branches
      - `git branch -a`
   1. You can also add `-v` to make the commands explicitly verbose
1. Create a branch and access it
   1. Normal way
      1. `git branch new_branch`
      2. (2 ways)
         -  `git checkout new_branch`
         -  `git switch new_branch`  > Recommended option (avoid `checkout` unless necessary)
   2. Shortcut (2 ways)
      - `git checkout -b new_branch`
      - `git switch -c new_branch` > Recommended option (avoid `checkout` unless necessary)
1. Get some work done lol
1. Check the status of your work
   - `git status`
1. Did you mess up editing a file and want to restore it to how it was beforehand?
   - `git restore changed_file.txt`
1. Add changes to staging in order to prepare your commit
   1. Add a single file
      - `git add new_file.txt`
   1. Add all changed files
      - `git add .`
   1. Add just a hunk (small piece) within a file but not the whole file
      - `git add -p new_file.txt`
      - This will open an interactive prompt for each hunk within the file. You will have to confirm an action for each hunk; input `?` to see the help for the available options.
      - You can do this for all files at once with `git add -p .`
1. Did you screw up? Reset the staging
   - `git reset`
1. Commit
   - `git commit -m "This is a commit message"`
1. Check the commit history of the branch you're in
   - `git log`
   - If you wanna see some cool things with log, you can use something like this:
      - `git log --graph --oneline --all`
1. Make sure you upload your commits to the remote repo! If your local branch is brand new, you must add it to the remote repo.
    1. New branch
       - `git push -u origin new_branch`
    2. Previously existing branch
       - `git push`
    3. All your modified local branches
       - `git push origin --all`
1. Move to another branch
    - `git switch another_branch`
1. Merge some branch into your current branch (assuming default behavior of pull is merge)
    - `git merge branch_that_will_be_merged_into_current_branch`
    - Remember that pull = fetch + merge, so you can also do `git pull branch_that_will_be_merged_into_current_branch`

For more info check the [GitHub Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

## Checkout vs Switch

`checkout` can be used to switch branches and/or restore working tree files, which means that you can do things like undo/restore commmits and overwrite local changes, or detach the HEAD (navigating a commit which is not the latest on its branch).

`switch` is only used for switching and creating branches. It cannot discard changes to tracked files: if you've changed a tracked file and want to switch branches, you'll need to stash or commit the changes.

I'd stick to `git switch` unless you really need `git checkout`. But that's just me.

# Intermediate git - merging branches

The following are some best practices that may be useful, taken from [this blog post](https://mislav.net/2013/02/merge-vs-rebase/), as well as [this tip](https://stackoverflow.com/questions/501407/is-there-a-git-merge-dry-run-option).

This workflow is useful for updating a feature branch and merging it with the main branch. You may also use it for merging custom branches among them, but we will assume that the intent here is to merge with main. We will also assume that the feature branch is set upstream in the remote repo and you can push and pull from it; if your feature branch is local only

1. While working on a branch, if you need to pull commits from the remote repo to your local repo, use rebase instead of merge to reduce the amount of commits
   - `git pull --rebase`
   - If you want to make rebasing the default behavior when doing `git pull`, do so with `git config --global --bool pull.rebase true`.
      - This is useful when collaborating with people on the same branch and you have to pull from the same branch more times than you need to merge branches.
1. Before pushing your changes to the remote repo, perform basic housekeeping (squash related commits together, rewording messages, etc)
   - `git rebase -i @{u}`
1. Make sure that you've fetched all changes from the remote repo
   - `git fetch`
   - Optionally, you may also want to switch to the main branch and `git pull` from it.
1. From your feature branch, simulate a merge to see any possible conflicts:
   1. Do a merge with the `--no-commit` flag.
      - `get merge --no-commit --no-ff main`
   3. Examine the staged changes
      - `git diff --cached`
   4. Undo the merge
      - `git merge --abort`
3. Merge (do not rebase) changes from the main branch into your branch, in order to update your branch with the latest features and solve any compatibility issues and/or conflicts
   1. If you already pulled main, then `git merge main`
   2. If you haven't pulled main or you're not sure, then `git pull --merge main`
4. Switch to the main branch with `git switch main`
5. Enforce merge commit when merging your feature branch into main, even if a merge commit isn't necessary (check the next point for an  exception), in order to make it easier to see the where and when of changes.
   - `git merge --no-ff feature_branch`
6. Exception to point 4: merging a single commit (typical for stuff such as bugfixes):
   - `git cherry-pick feature_branch_with_a_single_commit`
7. Push the changes to the remote repo.
   1. If you want to push the feature branch to the remote repo, make sure that you've set it up upstream before with `git push -u origin feature_branch`
   2. Push the branch(es)
      - Push main only with `git push` or `git push main`
      - Push explicitly both main and feature_branch with `git push origin main feature_branch`
      - Push all your local branches with `git push --all`
8. If you don't need it anymore, you may delete the feature branch (after merging, you won't lose the commits even if you delete the branch):
   1. Delete the feature branch locally 
      - `git branch -d feature_branch`
   1. Delete the feature branch on the remote repo
      - `git push origin :feature_branch`

# Advanced git - extra commands

1. Tag your current commit (useful for checkpoints!)
    - Annotated: `git tag -a your_tag -m "This is a message, like in a commit"`
    - Lightweight: `git tag your_tag`
1. Display your tags
    - `git tag`
1. Get info on a specific tag
    - `git show your_tag`
1. Tags are not pushed when you push your branch! Push your tag!
    - `git push origin your_tag`
    - `git push --tags` if you want to push all your tags at once.
1. Need to switch to another branch but you're not ready to commit? Stash the changes!
    - `git stash`
    - You can also use `git stash save`
    - Untracked files will NOT be stashed! If you want to stash them as well, use `git stash -u`
1. Finished with the other branch and want to recover your stashed away work? Then pop it!
    - `git stash pop`
    - This will apply the stashed work into your current branch and delete the stash.
    - If you don't want to delete the stash (useful for applying the changes to multiple branches), then do `git stash apply`
1. If you stash multiple times without popping, the stashes will accumulate! Manage your stashes!
    - List your stashes with `git stash list`
    - Apply a particular stash with `git stash apply stash@{X}`, with `X` being whatever stash ID you want.
    - Delete a particular stash with `git stash drop stash@{X}`
    - Delete all the stashes with `git stash clear`
1. Do you have a special commit like a bugfix or a small update in another branch and want to apply it to your current branch? Cherry-pick it!
    - `git cherry-pick commit_hash_goes_here` > applies the commit identified by its hash to your active branch.
    - Cherry-picking creates a new commit! It contains the same info as the commit you clone/cherry-pick, but it's a different hash.
1. Do you want to cherry-pick a hunk inside a commit? You can! Follow these steps in order:
    1. `git cherry-pick -n commit_hash_goes_here` > Using `-n` (`--no-commit`) stages the changes for the cherry-pick but doesn't commit them.
    1. `git reset` > Unstage the changes from the cherry-picked commit
    1. `git add -p` > Interactive patching; add the hunks you want
    1. `git commit` > Yay!

# SSH vs HTTPS - credential management

If possible, try to use SSH. Read below for additional info.

## SSH
SSH is convenient because you can set up passwordless access to repos and is secure, but set up can be a little tedious.

For setting up SSH, follow the instructions [in this gist](https://gist.github.com/ziritrion/9b445926fb5d8b65194946c7e2ee9074).

Once you've created SSH keys and optionally set up your work environment to work with multiple accounts, you can simply clone a repo with `git clone ssh://url.com/repo.git`.

## HTTPS

Sometimes you cannot clone a repo with SSH for a number of reasons: maybe the SSH ports are blocked inside your work network, or perhaps your repo provider does not support SSH. In that case, you will most likely use HTTPS for accessing your repos.

However, HTTPS does not use public keys and relies on username and password for accesss. Setup is significantly easier for most users but any operation on the remote repo will prompt the user and password, which is extremely annoying.

By default Git does not store usernames and passwords, but it is possible to set this up with [Git's credential helpers for credential storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage). However, the file is stored in plain text, which is **very bad**.

An alternative is using [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager). It already comes pre-installed with Git for Windows, but can also be installed separately on MacOS and Linux. Follow the instructions for installation and usage on its GitHub page.

Note that if you're using WSL, there are special instructions for making the Windows manager available to your linux distro. Check the Windows install instructions.

### HTTPS under WSL

- Make sure you install Git for Windows with the Git Credential Manager
- Add the Credential Manager as the credential helper in your global git config. In a WSL terminal, type:
   - `git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"`
   - Make sure that the path is correct for your install path.
- (Optional) If you use Azure DevOps, in a WSL terminal, type:
   - `git config --global credential.https://dev.azure.com.useHttpPath true`
- Use git normally. On first clone/pull/push, you will be asked your credentials. Afterwards, you shouldn't have to type them in anymore.
- If you change your password in your remote server, authentication will fail. You need to reject the current credentials and refresh them:
   - In the WSL terminal:
      - `git credential reject`
   - The terminal will display a blank line. Type in the following:
      - `url=https://url/of/your/repo.git`
   - Press the Enter key to create a new blank line, and press the Enter key again on the blank line.
   - Try to clone/pull/push again. You will be asked the credentials once again.
- Git Credential Manager will try to automatically detect the Git provider but it may not always be successful, especially with on-premises solutions. In order to manually set up the provider, do this from a PowerShell terminal:
   - `git config --global credential.<your_git_repo_host_url>.provider <git_provider>`
   - You can see the list of providers [in this url](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/configuration.md#credentialprovider)
   - Doing this from a WSL shell will not work, because Git Credential Manager is a Windows executable and it will look for the global .gitconfig in Windows. Make sure you run the command above from a PowerShell terminal.

# Create a remote repo (local folder as remote repo)

## Official method

_[Source](https://git-scm.com/book/en/v2/Git-on-the-Server-Getting-Git-on-a-Server)_

1. Make sure you've got a local commit. You may initialize a local repo with `git init` on any project folder and making sure that it has at least one commit, or you may use an already existing local repo.
2. On a separate folder, run:
   ```bash
   git clone --bare path/to/local/project project.git
   ```
   * This will create a folder with name `project.git` on the folder you're running the command.
   * Remote repo folders use the `.git` extension as a standard.
   * This folder is a ***bare*** repository. It does not contain a working folder, only the git files.
3. Move the `project.git` folder to the final destination. Ideally, a shared folder such as a networked drive that everyone has access to "locally".
   * You may combine steps 2 and 3 by creating the bare repo directly on the final folder.
4. You should now be able to clone the repo:
   ```bash
   git clone path/to/remote/repo/project.git
   ```
5. The original repo that we bare-cloned does not have an origin repo to push to. If you want to keep using it, set up a remote like this:
   ```bash
   git remote add origin path/to/remote/repo/project.git
   ```

## Alternative method

_[Source](https://stackoverflow.com/questions/14087667/create-a-remote-git-repo-from-local-folder)_

1. On remote folder:
   ```bash
   mkdir my_repo
   cd my_repo
   git init --bare
   ```
2. On local folder:
   ```bash
   cd my_repo
   git init
   git remote add origin ssh://myserver/my_repo
   git add .
   git commit -m "Initial commit"
   git push -u origin master
   ```