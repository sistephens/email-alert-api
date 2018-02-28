## Prerequisites

  - download the Gov Delivery files and virus scan, unzip
    If you need the ftp server and log in details, they are in the 2ndline
    password store under `govdelivery/ftps`
  - activate fabric virtual env
  - cd into your fabric script directory

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

## Confirm emails are not going through Notify

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
fab $environment -H $machineclass-1 do:'tail -n 15 /var/apps/email-alert-api/log/pseudo_email.log'
```

## Delete the data
```
fab $environment emailalertapi.truncate_tables
```

## Backup the db
 - ssh postgresql-primary-1.staging
 - sudo -upostgres pg_dump email-alert-api > pre_migration_backup.sql

## Import all the data
  - scp file onto $machineclass-1.staging:/var/apps/email-alert-api/govdelivery_subscriptions.csv
  - scp file onto $machineclass-1.staging:/var/apps/email-alert-api/govdelivery_digests.csv
  - ssh $machineclass-1.staging
  - cd /var/apps/email-alert-api
  - sudo -u deploy govuk_setenv email-alert-api bundle exec rake import_govdelivery_csv[govdelivery_subscriptions.csv,govdelivery_digests.csv]

## Pause while everything imports
- COULD DO WITH BEEFING THIS UP
- sense check that the subscriptions are in the right ballpark 3 million
- sense check that the subscribers are in the right ballpark 500k

## Set email provider to use Notify, use the Email alert frontend for collection
and disable GovDelivery

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

confirm notify receiving email messages by manually sending an email in prod
 - deliver:to_test_email[email.addresse@digital.cabinet-office.gov.uk]

## Re-start puppet

```
fab $environment class:$machineclass puppet.enable
```

feeling paranoid? test with
```
fab $environment class:$machineclass puppet.check_disabled)
```
