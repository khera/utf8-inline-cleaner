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
`Encoding::FixLatin::fix_latin` function. If the result is different
than what we started with, the new value is updated for that column.

The goal is to end up with data that is all UTF-8 clean, and can then
be loaded into a database created with the `UTF8` encoding in
PostgreSQL either via dump/reload or some other replication strategy.

## Assumptions

This program is written to use with PostgreSQL (tested with
version 9.4). It should be able to be modified to work with other
databases by changing the code relating to the **ctid** column.  We
use it instead of trying to deal with multi-part primary keys to
identify the row for the UPDATE. It is also faster than any primary
key for the update since it is a physical location into the table
file.

The other major assumption is that the database is using the `SQL_ASCII`
encoding (*i.e.*, no encoding). If your database is any other encoding,
all bets are off, and you can likely use the built-in tools to export
the data as UTF-8.

### Accuracy

The `fix_latin` function is pretty good at guessing what character set
was intended, but it is still just guessing. It will get it wrong for
some data.

One specific flaw we encountered is the UTF-8 code point 0xed 0xa0
0x8d which maps to UNICODE code point 0xd80d. This *looks* like a
proper character but in fact is not a valid character. The `fix_latin`
function thinks it is valid because it does not actually check the
code pages for valid characters. Postgres, however, does not like that
byte sequence since it is an undefined character.

If you are not a fan of the `fix_latin` function, or if some of the
transcoding it does breaks your data, it can be replaced with
something along the lines of this:

```
sub fix_latin {
 my $octets = shift;
 return decode('utf-8-strict',$octets,sub { my $t = chr shift; from_to $t, 'windows-1252', 'UTF-8'; $t; });
}
```

This code will attempt to decode the octets as strict utf-8, and upon
failure interpret them as Windows-1252 (which is a superset of iso8859-1).

Unfixable errors related to invalid code points found in the data will be
reported as transcoding failures (search for FAILURE: in the output).


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

The `--dryrun` flag can be used to inventory your database to find
which tables actually need transcoding. Direct the stdout to
*/dev/null* and look at the summary line. If it says no rows were
updated, that table is already UTF-8 clean. Do not specify any
triggers to disable with this use case to avoid any table or row
locking.

On occasion, a transcoded row may cause a unique key violation if
there is another key already in UTF-8 for that same value. In this
case, an error will be printed indicating the primary key of the row
that was not able to be updated (search for "FAILURE:" in the
output). The summary line will display how many such rows there
were.

After all the tables are transcoded, dump the database with UTF-8
encoding:

```
pg_dump -v -U postgres -j8 -Fd -f utf8test.d --encoding=UTF8 utf8test
```

Any existing encoding problems will be detected by PostgreSQL at this
time and should be corrected by hand. There should be none, as we did
the strict UTF-8 test; if there are, please file a bug including the
source data that was improperly converted.

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

## Test Data

The file `utf8test.sql` is included for testing. Load it into an
SQL_ASCII database:

```
createdb -U postgres -E SQL_ASCII -T template0 utf8test
psql -f utf8test.sql utf8test
./utf8-inline-cleaner --dryrun --db utf8test --table t1
```

The expectation is that row 1 will have invalid UTF8 that needs to be
fixed by hand, row 2 will fix the text column (for NFC change) but
leave the json column alone as it is already proper UTF8 NFC octets,
and row 4 will fix the json column for NFC change and the text column
for ISO-8859-1 to UTF8 change of the "Small y, dieresis" character.
Row 3 is left alone (not even examined).

# Sponsor

This code has been developed under sponsorship of MailerMailer
LLC, http://www.mailermailer.com/

# License

This program is Copyright 2015 MailerMailer LLC. It is licensed under
the same terms as Perl itself.
