## Prerequisites

  - cd into your fabric script directory
  - download the Gov Delivery files and virus scan, unzip
    If you need the ftp server and log in details, they are in the 2ndline
    password store under `govdelivery/ftps`
  - activate fabric virtual env
  - announce in 2ndline that you are going to deploy

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

### 1) Manually send an email:

```
fab $environment emailalertapi.deliver_test_email:'email.address@digital.cabinet-office.gov.uk'
```

You should not receive an email

### 2) Confirm email drop off on grafana

[Staging dashboard](https://grafana.staging.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

[Production](https://grafana.publishing.service.gov.uk/dashboard/file/email_alert_api.json?refresh=10s&orgId=1)

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

## Pause while everything imports
- COULD DO WITH BEEFING THIS UP
- sense check that the subscriptions are in the right ballpark 3 million
- sense check that the subscribers are in the right ballpark 500k

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
fab $environment class:$machineclass puppet.check_disabled)
```

## Remove the zip and csv files from GovDelivery from your local machine

```
rm filenames
```


## Announce in 2ndline that you are done
