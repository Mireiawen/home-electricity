This section contains the main part of this repository, and it is data fetching and storing.  

# Used services
These are the services that the system will contact.

## Nordpool Day-ahead prices
https://www.nordpoolgroup.com/Market-data1/Dayahead/Area-Prices/FI/Hourly/?view=table

Used as source for the day-ahead electricity SPOT prices in Finland, changing the URL in the Robot resource should allow price fetching for other countries and regions as well.

**Note:** Automatic extraction of data from this website and/or use for commercial purposes is strictly prohibited under Nord Pool’s  [terms & conditions](https://www.nordpoolgroup.com/link/26d0e874de384164a9e6e7a31ea7b0ae.aspx). For more information regarding data usage, contact  [pds@nordpoolgroup.com](mailto:pds@nordpoolgroup.com).

## Helmi Energy Reporting
https://helmi.sssoy.fi/EnergyReporting/EnergyReporting

Used as energy consumption reporting source, requires contract for fetching consumption data.

# Used tools
The major tools used to fetch and store the data.

## InfluxDB
* https://www.influxdata.com/

Time series database used to store the electricity consumption and SPOT pricing.

## Robot Framework
* https://robotframework.org/

Software automation robot used to automate the fetching of data from websites. Uses Selenium library for managing Chrome, and Xvfb library for virtual screen.

## Chrome
* https://www.google.com/chrome/

Browser used to automate the fetching of data from websites.

## VirtualBox
* https://www.virtualbox.org/

Virtualization platform used to separate the Robot Framework environment.

## Vagrant
* https://www.vagrantup.com/

Used to build the virtual machine used to separate the Robot Framework environment.

## Ansible
* https://www.ansible.com/

Provisioning and configuration management used to provision the virtual machine.

## Docker
* https://www.docker.com/

Used as platform to run different containers such as InfluxDB.

## Grafana
* https://grafana.com/

Used to visualize the data in the InfluxDB.

## PHP
* https://www.php.net/

Used to parse the data from the files from services into InfluxDB database.

# Requirements
This project requires several tools to do all the required steps correctly. Some of them are optional depending on your configuration, but may require changes to the scripts or running things manually if they are not present.

## Accounts
### Lumme-Energia
* https://www.lumme-energia.fi/

The robot is currently configured to fetch the electricity consumption reports with the associated SPOT prices from Lumme-Energia's Helmi service. This requires you to have the contract with them as electricity provider to use their service. Other services could likely be configured as well, by using the Robot Framework configuration made for Lumme-Energia as base for new one.

There is no API as of 2020-06-16, and as such Robot Framework is used with Chrome through Selenium Library to fetch the report as if downloaded manually with browser.

## Software
Everything has been done and tested on a physical Linux machine running  [Debian 10](https://www.debian.org/). It may be possible to turn the Robot Framework to use Docker or local host instead of virtual machine to avoid the need for running virtual machine, but the current working method is to run everything related in virtual machine.

### VirtualBox
Used as the virtualization platform by Vagrant. It should be possible to run everything on other platforms as well, such as Hyper-V, but that will require changes to the `Vagrantfile`

### Vagrant
Used to build and manage the virtual machine running the Robot Framework. This is used to automatically fetch the SPOT prices and consumption reports.

### Ansible
Used to provision the virtual machine.

### Docker
Runs the InfluxDB database used to store the measurements. You could skip this and set up the InfluxDB and Grafana either on the host or elsewhere.

### Traefik
* https://containo.us/traefik/

Used as proxy for the services. It is assumed that Traefik serves HTTP and HTTPS  connections for local containers, with the hostname generation of `container name`.`system domain name`

### jq
* https://stedolan.github.io/jq/

Used to parse the JSON data with Grafana configuration. You can skip this if you don't need Grafana, or host Grafana elsewhere.

### J2 CLI
* https://github.com/kolypto/j2cli

Used to build Jinja2 templates for Grafana configuration. You can skip this if you don't need Grafana, or host Grafana elsewhere.

### PHP 7.3+
Used in the data parsers to read the files fetched into the InfluxDB.

### Box
*  https://github.com/box-project/box2

Tool used to build the parsers from PHP into PHAR.

# Installation
Clone this repository, it should include all required for fetching the data and configuring the services. After cloning, [download Google Chrome for Linux Debian]() into `chrome` -folder and name the package as `google-chrome-stable_83.0.4103.97-1_amd64.deb` 

# Configuring
## Secrets
This file contains the local configuration parameters, mainly the secret values such as usernames and passwords. You can see all the used variables in the file `defaults` and override them in `secrets`

Mainly, you need the following 3 set up: `LOCAL_NETWORK`, `LUMME_USER_ID` and `LUMME_PASSWORD`

`LOCAL_NETWORK` defines whitelisting for Traefik, to restrict access to the services such as InfluxDB. It is comma-separated list of networks in CIDR -notation as well as single addresses.

`LUMME_USER_ID` is the username and `LUMME_PASSWORD` is the password for for the Lumme-Energia Helmi service. These are required for the Robot Framework to be able to fetch the consumption report through their website.

Example configuration could be as following:
```bash
LOCAL_NETWORK="192.168.1.0/24,172.17.0.1"
LUMME_USER_ID="1234"
LUMME_PASSWORD="Sssecret_pass_word!!!111"
```

## InfluxDB
If the default configuration is good, all you need to do is run the `database.sh` -script. It will start up InfluxDB Docker container with Traefik labels and create the databases. After that you can start, stop and otherwise control the container with usual Docker commands.

### Custom database
If you are running custom InfluxDB, you need to set up the following variables in the `secrets` -file: `INFLUXDB_CUSTOM`, `INFLUXDB_HOSTNAME`, `INFLUXDB_PORT`, `INFLUXDB_SSL` and `INFLUXDB_URL`

`INFLUXDB_CUSTOM` should be string that does not equal to `0` if custom database is used instead of the container.

`INFLUXDB_HOSTNAME` should be the host name of the InfluxDB, such as `localhost` or `influxdb.example.tld`

`INFLUXDB_PORT` should be the database port, such as `8086` or `443`

`INFLUXDB_SSL` should be a string that is `1` if the connection uses SSL and `0` if it is plain connection.

`INFLUXDB_URL` should be the full URL to the database, such as `http://localhost:8086` or `https://influxdb.example.tld/`

If you want to set up custom database names as well, you will need to set up the following variables in the `secrets` -file as well: `INFLUXDB_DATABASE_NORDPOOL` and `INFLUXDB_DATABASE_LUMME`

`INFLUXDB_DATABASE_NORDPOOL` defines the database name for Nordpool SPOT pricing, such as `nordpool`.

`INFLUXDB_DATABASE_LUMME` defines the database name for Lumme-Energia consumption data, such as `lumme`.

**Note:** You will need to manually create the databases when not using default container.

# Using
Once configured, the fetching of the data should work simply by running the `run.sh`, for example `bash "run.sh"`

First the script should build the data parsers if they don't exist yet.

After that it should start the default database container unless custom database is specified. The database is not re-started if it is already running.

Once the database is running, the script should start and provision the Robot Framework virtual machine, run commands on the machine to fetch the Nordpool day-ahead prices and parse the data into the InfluxDB.

Once the Nordpool is done, the same should be done with Lumme-Energia.
