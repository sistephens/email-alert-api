## Prerequisites

  - download the Gov Delivery files and virus scan, unzip
  - activate fabric virtual env
  - cd into your fabric script directory

## Set env var

```
export environment=staging
export machineclass=backend
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

confirm notify not receiving email messages by manually sending an email in prod
 - Jenkins run rake task on prod - deliver:to_test_email[email.address@digital.cabinet-office.gov.uk]
   - https://deploy.staging.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=backend&RAKE_TASK=deliver:to_test_email[email.address@digital.cabinet-office.gov.uk]
 - confirm email drop off on grafana
 - confirm pseudo delivery "worked"
    - fab $environment -H $machineclass-1 do:'tail -n 15 /var/apps/email-alert-api/log/pseudo_email.log'

Delete the data
 - Jenkins run rake task on prod - deploy:truncate_tables
    - https://deploy.staging.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=backend&RAKE_TASK=deploy:truncate_tables
backup the db
 - ssh postgresql-primary-1.staging
 - sudo -upostgres pg_dump email-alert-api > pre_migration_backup.sql

Import all the data
  (
  - ssh $machineclass-1.staging
  - cd /var/apps/email-alert-api
  - ftp get ftp credentials
  )

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
