## Prerequisites

  - download the Gov Delivery files and virus scan, unzip
    If you need the ftp server and log in details, they are in the 2ndline
    password store under `govdelivery/ftps`. Unzipping the files will also
    require a password which is under `govdelivery/zipfile`.
  - cd into your fabric script directory
  - activate fabric virtual env if you use it
  - announce in slack #2ndline that you are going to deploy

## Set env var

```
export environment=staging
export machineclass=email-alert-api
```

## Stop puppet

```
fab $environment class:$machineclass puppet.disable:"Email alert api deployment"
```

Feeling paranoid? test with
```
fab $environment class:$machineclass puppet.check_disabled
```

## Use pseudo email provider instead of notify
```
fab $environment class:$machineclass app.setenv:app=email-alert-api,name=EMAIL_SERVICE_PROVIDER,value=PSEUDO
```

## Restart procfile worker

```
fab $environment class:$machineclass app.restart:email-alert-api-procfile-worker
fab $environment class:$machineclass app.restart:email-alert-api
```

## Confirm emails are *not* going through Notify

### 1) Get your dashboards up and note any activity

[Staging dashboard](https://grafana.staging.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

[Production](https://grafana.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

### 2) Manually send an email:

```
fab $environment emailalertapi.deliver_test_email:'email.address@digital.cabinet-office.gov.uk'
```

You should not receive an email

Check the dashboards. Optionally wait for a minute or two to ensure no email was
sent.

### 3) Confirm pseudo delivery "worked"

```
fab $environment class:email-alert-api do:'[ -f "/var/apps/email-alert-api/log/pseudo_email.log" ]; tail -n 15 /var/apps/email-alert-api/log/pseudo_email.log || echo 0'
```

## Delete the data
```
fab $environment emailalertapi.truncate_tables
```

## Backup the db
```
fab $environment -H postgresql-primary-1 do:'sudo -upostgres pg_dump email-alert-api_production > pre_migration_backup.sql'
```

## Import all the data

### SCP files up
```
scp uk_gov_subscribers.csv $machineclass-1.$environment:/var/apps/email-alert-api/govdelivery_subscriptions.csv
scp ukgov_subscriber_digest.csv $machineclass-1.$environment:/var/apps/email-alert-api/govdelivery_digests.csv
```

### ssh, tmux and go

```
ssh $machineclass-1.$environment
sudo su - deploy
cd /var/apps/email-alert-api
tmux
govuk_setenv email-alert-api bundle exec rake import_govdelivery_csv[govdelivery_subscriptions.csv,govdelivery_digests.csv]
```

You can detatch from the tmux session with `ctrl-b d` and then exit the ssh as
per normal.

Any other developer can look in on the progress by sshing on to the relevant
machine and:

```
sudo su - deploy
tmux list-sessions
```
The output will be something like:

```
> 0: 1 windows (created Fri Mar  2 13:29:29 2018) [142x36] (attached)
```

take note of the session number (will probably be 0) - the first number listed

```
tmux a -t 0
```

Where "0" is the session number.

## Pause while everything imports

Roughly 2 hours as at 28/02

## Exit your tmux if you are happy

`ctrl-b x` and confirm to terminate your tmux session.

Exit the ssh session as per normal.

## Sense check table sizes

Subscriptions should be in the 3 million ballpark
Subscribers should be in the 500k ballpark

```
fab $environment emailalertapi.table_counts
```

## Set email provider to use Notify, use the Email alert frontend for collection and disable GovDelivery

```
fab $environment class:$machineclass app.setenv:app=email-alert-api,name=EMAIL_SERVICE_PROVIDER,value=NOTIFY
fab $environment class:$machineclass app.setenv:app=email-alert-api,name=USE_EMAIL_ALERT_FRONTEND_FOR_EMAIL_COLLECTION,value=yes
fab $environment class:$machineclass app.setenv:app=email-alert-api,name=DISABLE_GOVDELIVERY_EMAILS,value=yes
```

## Restart app and procfile workers

```
fab $environment class:$machineclass app.restart:email-alert-api
fab $environment class:$machineclass app.restart:email-alert-api-procfile-worker
```

## Confirm notify receiving email messages by manually sending an email in prod

```
fab $environment emailalertapi.deliver_test_email:'email.address@digital.cabinet-office.gov.uk'
```

You should receive an email!

### Check the dashboards

[Staging dashboard](https://grafana.staging.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

[Production](https://grafana.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

## Re-start puppet

```
fab $environment class:$machineclass puppet.enable
```

feeling paranoid? test with
```
fab $environment class:$machineclass puppet.check_disabled
```

## Remove the zip and csv files from GovDelivery from your local machine

```
rm filenames
```

## Delete the backup you took

If you are confident all went to plan

```
ssh $machineclass-1.$environment
rm pre_migration_backup.sql
exit
```

## Announce in slack #2ndline that you are done

# Back out

If it's all gone wrong and you need to revert to using GovDelivery then....

## Prerequisites

  - cd into your fabric script directory and `git pull` on master
  - activate fabric virtual env if you use it
  - announce in slack #2ndline that you are going to deploy

## Set env var

```
export environment=staging
export machineclass=email-alert-api
```

## Stop puppet

```
fab $environment class:$machineclass puppet.disable:"Email alert api deployment"
```

Feeling paranoid? test with
```
fab $environment class:$machineclass puppet.check_disabled
```

## Set email provider to use Pseudo, remove the env vars that switch frontend and disable GovDelivery

```
fab $environment class:$machineclass app.setenv:app=email-alert-api,name=EMAIL_SERVICE_PROVIDER,value=PSEUDO
fab $environment class:$machineclass app.rmenv:app=email-alert-api,name=USE_EMAIL_ALERT_FRONTEND_FOR_EMAIL_COLLECTION
fab $environment class:$machineclass app.rmenv:app=email-alert-api,name=DISABLE_GOVDELIVERY_EMAILS
```

## Restart app and procfile workers

```
fab $environment class:$machineclass app.restart:email-alert-api
fab $environment class:$machineclass app.restart:email-alert-api-procfile-worker
```

## Re-start puppet

```
fab $environment class:$machineclass puppet.enable
```

feeling paranoid? test with
```
fab $environment class:$machineclass puppet.check_disabled
```
