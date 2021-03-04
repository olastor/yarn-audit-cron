# yarn-audit-cron

Small tool for checking a list of NodeJS projects triggering an alert webhook if there are new security vulnerabilites found using `yarn audit` in a given interval.

Example Screenshot:



## Requirements

Linux with those packages

- curl
- jq
- yarn

## Configuration

Create a `projects.tsv` file using this format:

```
<project1 name>\t<project1 url>
<project2 name>\t<project2 url>
<project3 name>\t<project3 url>
```

Please note that the project url cannot be just a link to a repository, but it has to be an url that when "/package.json", "/yarn.lock" are appended, then those are valid links pointing to **raw** files.


Update the variables at the top of the script:

```
TEMP_DIR="/tmp"               # A directory to write temporary files
AUDIT_GROUPS="dependencies"   # Pass this to the `--groups` parameter of yarn audit
CRON_INTERVAL="100"           # Only check last CRON_INTERVAL minutes for new vulnerabilites
WEBHOOK_URL=""                # Trigger this (Discord-)webhook (adjust alert method for other services)
```


If you want to display all vulnerabilities without filtering out the recent ones, use

```
YARN_AUDIT_SKIP_DATE=1 ./yarn-audit-cron.sh
```
