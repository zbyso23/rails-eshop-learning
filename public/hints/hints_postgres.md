### Postgres Install

```bash
apt upadate
apt install postgresql postgresql-contrib
```

### Postgres setup password

```bash
sudo -i -u postgres psql
\password postgres
```

### Postgres setup localhost connection

```bash
vim /etc/postgresql/<version>/main/pg_hba.conf
```

Find:

```bash
local   all             all                                     peer
```

and replace to:

```bash
local   all             all                                     scram-sha-256
```

and **restart** Postgres:

```bash
sudo systemctl restart postgresql
```


## Local session - login
```bash
sudo -i -u postgres
psql
```