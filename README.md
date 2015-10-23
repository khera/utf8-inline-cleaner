# Transcode Table Data into UTF-8

Update data inline in tables that have non-ASCII data which can not be
interpreted as already being UTF-8.

**ALWAYS** run this first on a copy of your data, and validate it does
what you think it will do. Do not experiment with your production
database. Also **ALWAYS** back up your production data.

The strategy is to search the table for any text-based columns (char,
varchar, text, JSON, etc.) which contain non-ASCII bytes. Those rows
are selected "FOR UPDATE" to prevent any changes while we inspect them
further. Next, each column is run through the
Encoding::FixLatin::fix_latin function. If the result is different
than what we started with, the new value is updated for that column.

## Assumptions

This program is written to use with PostgreSQL (tested with
version 9.4). It should be able to be modified to work with other
databases by changing the code relating to the **ctid** column.  We
use it instead of trying to deal with multi-part primary keys to
identify the row for the UPDATE. It is also faster than any primary
key for the update since it is a physical location into the table
file.

The other major assumption is that the database is using the SQL_ASCII
encoding (i.e., no encoding). If your table is any other encoding,
all bets are off.

The fix_latin function is pretty good at guessing what character set
was intended, but it is still just guessing. It will get it wrong for
some data.


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
specified only needs SELECT privileges so does not necessarily need to
be the superuser.

All of the rows with invalid data will be updated and committed within
one transaction, so other updates to those rows will be blocked until
completion. Rows containing only ASCII data will not be locked.

Example:

```
./utf8-inline-cleaner --dryrun --db utf8test --dbuser postgres --table templates --disable trig_templates_log_update
```

### Command Line Flags

The command uses long-format flags, starting with double-dashes,
`--`. The *db*, and *table* flags are required.

#### debug

Turns on debugging

#### dryrun

Does not perform the UPDATEs but does all other work.

#### dbuser USER

Name of the user to connect to the DB.  Must be superuser
or table owner. The $PGUSER environment variable can also be set as
the Postgres library will honor it.

The password comes from the `.pgpass` file or $PGPASSWORD environment
variable.

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
times for multiple triggers. If your trigger does not have side
effects from the updates that are about to be issued, do not bother
disabling them. When triggers are disabled, the whole table is locked
so there can be no concurrency.

# Sponsor

This code has been developed under sponsorship of MailerMailer
LLC, http://www.mailermailer.com/

# License

This program is Copyright 2015 MailerMailer LLC. It is licensed under
the same terms as Perl itself.
