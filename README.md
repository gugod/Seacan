# Seacan

A tool to prepare a self-contained app directory.

## Usage

Let's say I want to make a binary distribution for my app named "CoffeeChair".

Prepare a configuration file.

```
[seacan]
output = "/opt/CoffeeChair"
app = "/src/CoffeeChair"

[perl]
version = "5.20.0"
configure_args = "-Dusethreads"

```

Build it

    seacan build --config myapp_seacan.toml

Directory Layout

- /opt/CoffeeChair
  - perlbrew/perls/seacan-perl
  - local/
  - app/CoffeeChair

Afterward, invoking commands like this:

    PERL5LIB=/opt/Coffeechair/local/lib/perl5 /opt/CoffeeChair/perlbrew/perls/seacan-perl/bin/perl /opt/CoffeeChair/app/CoffeeChair/bin/app.pl
