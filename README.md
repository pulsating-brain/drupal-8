# Managing Builds for Drupal deployment

## Build an image
Run <code> build -t tagname:version . </code>
to build from the current directory
### Moving Parts
#### Alpine 3 
Linux distribution designed for security and compactness.

##### It comprises:

musl - the C library for Alpine Linux. It is cleaner, faster & much smaller than glibc.

BusyBox - minimal Linux distribution ~100mb

### Alpine Packaged software
<code>apk update</code> is run first to ensure package lists are up to date

<code>apk upgrade</code> updates preinstalled software

<code>apk add</code> adds additional packages - bash, curl, git, nginx, php (+ some 
extensions)

<code>apk add -u musl</code> is run separately to avoid a bug
### Composer installation
Composer is the future-proof way of installing Drupal Core and Drupal Contributed 
Modules. Drush Make will be depreciated in Drupal 9. A tool to convert makefiles to 
composer files will be supported by the core maintainers.

<code>curl -sS https://getcomposer.org/installer</code> is piped into the Hypertext 
Preprocessor (PHP) command line interface (CLI) with some parameters

### Notes on transitioning legacy Drupal 7 (D7) sites
In D7 <code>drush make</code> was the way of managing Drupal Distribution's
required modules, themes, libraries & patches. 

In D8 <code>composer</code> and <code>drush make</code> coexist although 
developers are encouraged to make any new sites using Composer. All efforts MUST go 
into developing with Composer then bringing legacy sites off the island.

There is a contributed module which converts D7 makefiles into composer files which a
core maintainer has promised will be maintained until D8 is end of life.
### Drupal 8 Core installation
The drupal-composer project ( https://github.com/drupal-composer/drupal-project ) provides all of the composer
dependencies and scaffolding files for drupal leaving us with only the drupal contributed modules to deal with in the
composer.json file. Nice and clean.

Note: it is strongly recommended to include the development tools with all of the contribs for cascading reasons
It's extra bandwidth (which is important in my rural situation) but the consequences of not having them sound serious
  - if there are no dev tools in the top level then no dev tools will installable in any subsequent levels
  - if the dev tools are not installed right from the top level then incomplete composer.lock files will be generated

See: https://github.com/composer/composer/issues/1874

#### composer create-project
<code>composer create-project drupal-composer/drupal-project:8.x-dev some-dir</code>

#### composer create-project flags:

<code>--stability dev</code>    latest package versions. Presumably should be changed in production and needs abstracting

<code>--profile </code>          display timing and memory usage information

<code>--no-interaction</code>    needs to be present to stop installer crashing for want of user input. Defaults are fine.

<code>--no-progress</code>       disables the download progress display - stops terminal & log clutter


### Contrib Modules - Downloading
#### composer require
<code>cd /drupal</code>

<code>composer require</code> installs a list of contributed modules

#### composer require flags:

<code>--prefer-dist</code>    prefer packaged modules over source code if possible

<code># --no-update</code>     defaults to commented out; uncomment this line in the Dockerfile this if you have 
changed this section to allow the image to update. Running composer-require without the no-update flag is slow and 
bandwidth-heavy

<code>--prefer-stable</code>   prefer stable versions of modules

<code>--no-progress</code>    disables the download progress display - stops terminal & log clutter

## Creating a container
Initialising the container with <code>docker-compose up</code> creates the container then the drush command is run at 
the end to install the modules into the database. See the <code>docker-compose.yml</code> file.

## Stopping and Starting a container
# Warning!
Stopping and starting the container is done with <code>docker-compose stop</code> and <code>docker-compose start</code>. 

#####CAUTION: 
running <code>docker-compose up</code> again on a site that contains data will erase all of the data in the 
database and reinitialise the container. 

Sometimes this is what we want e.g we are spinning up a development code branch. 

There are also times when we DO NOT want to do this IE. ON SITES WITH LIVE USERS.

## Pushing a build to the registry
Alternatively use a cloud registry and get it built automatically when new code is committed to the git repository

## Running an application on the container
get setup and orientated by reading the 6 part introduction at https://docs.docker.com/get-started/ if necessary

Otherwise type <code>docker run -p 80:80 repo/image:version</code>
## running multiple containers as a swarm

## Spanning service across multiple machines

## Deploy swarm into production