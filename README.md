
# jmvtools

An R package, analagous to devtools, which makes it easy to develop jamovi modules

To install this package, issue the following command from the R terminal:

```{r}
install.packages('jmvtools', repos='https://repo.jamovi.org')
```

### Releasing

1. Pull everything up to date. `just pull-jamovi-repo` pulls down the S3-backed package repo that serves `repo.jamovi.org`:

   ```
   git pull
   just pull-jamovi-repo
   ```

2. Update the bundled `jamovi-compiler` from `jamovi/jamovi`:

   ```
   just update-compiler
   ```

3. Bump the version in `DESCRIPTION`

4. Build the package:

   ```
   just build
   ```

5. Add the built tarball to the local package repo:

   ```
   just add-to-jamovi-repo $FILENAME
   ```

6. Push the package repo up to S3, publishing it to `repo.jamovi.org`:

   ```
   just push-jamovi-repo
   ```
