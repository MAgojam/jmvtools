jamovi_repo := "https://github.com/jamovi/jamovi.git"
checkout_dir := ".jamovi-checkout"

default:
    just --list

# update the `compiler` branch in jamovi/jamovi from the current jamovi-compiler subtree,
# using a clean throwaway clone so it never touches this working tree
update-compiler-branch message="Update jamovi-compiler":
    rm -rf {{checkout_dir}}
    git clone {{jamovi_repo}} {{checkout_dir}}
    cd {{checkout_dir}} && \
        git checkout main && \
        git subtree split -P jamovi-compiler -b tmp/compiler && \
        git checkout compiler && \
        git merge tmp/compiler -m "{{message}}" && \
        git push
    rm -rf {{checkout_dir}}

# ensure the jamovi/jamovi remote used to pull the compiler branch is set up
ensure-jamovi-remote:
    git remote get-url jamovi >/dev/null 2>&1 || git remote add jamovi {{jamovi_repo}}

# pull the current `compiler` branch from jamovi/jamovi into inst/node_modules/jamovi-compiler
pull-compiler-subtree message="Update jamovi-compiler": ensure-jamovi-remote
    git fetch jamovi
    git subtree pull --prefix=inst/node_modules/jamovi-compiler jamovi compiler --squash -m "{{message}}"

# full jamovi-compiler update: refresh the compiler branch upstream, then pull it in here
update-compiler message="Update jamovi-compiler": (update-compiler-branch message) (pull-compiler-subtree message)
