# README - Revenue Scotland Application

* Ruby version

Built with Ruby version 2.6.5

* Rails version

The version of Rails used is given in gemfile.lock

* Webpacker

The application uses webpacker for managing javascript. Webpacker introduces other dependencies during development.
See https://github.com/rails/webpacker

* System dependencies

This application requires a redis server to enable caching. For development the application can use a local cache, which can be enabled/disabled with:

```
rails dev:cache
```

A Jenkinsfile is provided for Jenkins pipeline builds. This requires Jenkins version 2.218 or later. The application is delivered through [docker](https://www.docker.com/) at least version 19.03. Autotests also use docker, as well as the [selenium](https://github.com/SeleniumHQ/docker-selenium) provided Selenium Hub and Selenium Firefox images.

The application is also dependent on third party gems that are listed in the gemfile and gemfile.lock. These are available under their own licenses.

* Configuration

The following environment variables are required:

| Variable                | Description                                            | Example                               |
| ----------------------- | ------------------------------------------------------ | ------------------------------------- |
| FL_ENDPOINT_ROOT        | URL to back office system                              | http://back-office:8080/service       |
| FL_USERNAME             | Username for back office system                        | BOUSER                                |
| FL_PASSWORD             | Password for FL_USERNAME user                          | BOPASSWORD                            |
| ADDRESS_SEARCH_ENDPOINT | URL to address search system                           | http://address-search:8080/service    |
| ADDRESS_SEARCH_UID      | Username for address search system                     | ADDSEARCHUSER                         |
| ADDRESS_SEARCH_PWD      | Password for ADDRESS_SEARCH_PWD                        | ADDSEARCHPASS                         |
| COMPANY_SEARCH_ENDPOINT | URL to Companies House API                             | https://api.companieshouse.gov.uk     |
| COMPANY_SEARCH_UID      | User name for Companies House API                      | CH_USER                               |
| COMPANY_SEARCH_PWD      | Password for COMPANY_SEARCH_PWD                        | CH_PASSWORD                           |
| REDIS_CACHE_URL         | URL for redis service, including username and password | redis://:password@redis-server:6379/1 |
| APPLICATION_VERSION     | Application version string                             | 0.0.0                                 |
| ANALYTIC_TRACKING_ID    | Google Analytic tracking ID                            | UA-123456789-1                        |
| PREVENT_JOBS_STARTING   | `Y` to stop jobs starting                              | Y                                     |

* How to run the test suite

Check that the code passes linting:

```
rake rubocop
```

Check that the code documentation is created successfully:

```
rake yard
```

Check the unit and autotests pass:

```
rake test
rake cucumber
```

Some of the tests require the use of a local browser, we recommend Firefox (version 64.0) with the latest [gecko driver](https://github.com/mozilla/geckodriver). 
As long as the gecko driver is on the path, the browser will be started automatically as required.

* Running in development mode

Use the inbuilt rails server to run the application in development mode:

```
rails server
```

And navigate to http://localhost:3000 in a browser