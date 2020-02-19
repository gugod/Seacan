# NAME

Seacan - A tool to prepare a self-contained app directory.

# USAGE

Let's say I want to make a distribution for my app named "CoffeeChair".

First, prepare a configuration file in TOML format, named `coffeechair_seacan.toml`

```perl
[seacan]
output = "/opt/CoffeeChair"
app = "/src/CoffeeChair"
app_name = "CoffeeChair.pl"

[perl]
version = "5.20.0"
configure_args = "-Dusethreads"
```

Noted that The source code of the CoffeeChair must be placed at `"/src/CoffeeChair"` first.

Now, build the the distribution with this, the output directory
`/opt/CoffeeChair` will be filled by this process:

```
seacan coffeechair_seacan.toml
```

Here's how the directyr looks like:

```
- /opt/CoffeeChair
  - perlbrew/perls/seacan-perl
  - local/
  - app/CoffeeChair
```

Afterwards, invoking commands like this:

```
PERL5LIB=/opt/Coffeechair/local/lib/perl5 /opt/CoffeeChair/perlbrew/perls/seacan-perl/bin/perl /opt/CoffeeChair/app/CoffeeChair/bin/app.pl
```

Or alternatively, a launcher script with the that command can be found at:

```
 /opt/CoffeeChair/bin/CoffeeChair
```

# AUTHORS

Kang-min Liu `<gugod@gugod.org>`

# LICENCE

The MIT License

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
