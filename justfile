jamovi_repo := "https://github.com/jamovi/jamovi.git"
checkout_dir := ".jamovi-checkout"
jamovi_repo_dir := "jamovi-repo"
package_repo_bucket := "s3://jamovi-repo"

default:
    just --list

# build the package into a .tar.gz in this directory
build:
    R CMD build .

# sync the jmvtools package repo's src/contrib down from s3://jamovi-repo into jamovi-repo/src/contrib
pull-jamovi-repo:
    doppler run --project cloudflare-s3 --config prd -- \
        aws s3 sync {{package_repo_bucket}}/src/contrib {{jamovi_repo_dir}}/src/contrib

# push the local jamovi-repo/src/contrib up to s3://jamovi-repo
push-jamovi-repo:
    doppler run --project cloudflare-s3 --config prd -- \
        aws s3 sync {{jamovi_repo_dir}}/src/contrib {{package_repo_bucket}}/src/contrib

# copy a built package tarball into the local jamovi-repo and regenerate its PACKAGES index
add-to-jamovi-repo package:
    mkdir -p {{jamovi_repo_dir}}/src/contrib
    cp {{package}} {{jamovi_repo_dir}}/src/contrib/
    Rscript -e 'tools::write_PACKAGES("{{jamovi_repo_dir}}/src/contrib", type="source")'

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
