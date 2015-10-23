# Transcode Table Data into UTF-8

Update data inline in tables that have non-ASCII which can not be
interpreted as already being UTF-8.

**ALWAYS** run this first on a copy of your data, and validate it does
what you think it will do. Do not experiment with your production
database. Also **ALWAYS** back up your production data.

## Installing

Download the raw file and make it executable. This program requires
the following Perl modules to be installed:

* `Encoding::FixLatin`
* `DBI`
* `DBD::Pg`
* `Log::Log4perl`

## Running

Specify the name of the table to scan and fix. With the `--dryrun`
flag, there will be no UPDATEs issued, but any specified triggers will
still be disabled, resulting in table locks. For dry run, the user
specified only needs SELECT privilegs so does not necessarily need to
be the superuser.

Example:

```
./utf8-inline-cleaner --dryrun --db ${DB} --dbuser postgres --table templates --disable trig_templates_log_update
```

### Command Line Flags

The command uses long-format flags, starting with double-dashes,
`--`. The *db*, and *table* flags are required.

#### debug

Turns on debugging

#### dryrun

Does not perform the UPDATEs but does all other work.

#### dbuser USER

Name of the user to connect to the DB. The password comes from the
`.pgpass` file. Must be superuser or table owner. The $DBUSER
environment variable can also be set as the Postgres library will
honor it.

#### db DATABASE

Names the database (required).

#### host HOST

Names the database host; default "localhost".

#### schema SCHEMA

Names the schema being cleaned in the database; default "public".

#### table TABLE

Names the table being cleaned in the schema (required).

#### disable TRIGGER

Disables the named trigger during the fixup step. Specify multiple
times for multiple triggers.

# Sponsor

This code has been developed under sponsorship of MailerMailer
LLC, http://www.mailermailer.com/

# License

This program is Copyright 2015 MailerMailer LLC. It is licensed under
the same terms as Perl itself.
