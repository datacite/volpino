# Volpino

[![Build Status](https://travis-ci.org/datacite/volpino.svg)](https://travis-ci.org/datacite/volpino) [![Code Climate](https://codeclimate.com/github/datacite/volpino/badges/gpa.svg)](https://codeclimate.com/github/datacite/volpino) [![Test Coverage](https://codeclimate.com/github/datacite/volpino/badges/coverage.svg)](https://codeclimate.com/github/datacite/volpino/coverage)

The DataCite service for user accounts. Users are authenticated via ORCID Oauth. Single-sign to various DataCite services via JWT.

## Installation

Using Docker.

```
docker run -p 8080:80 datacite/volpino
```

You can now point your browser to `http://localhost:8080` and use the application.

For a more detailed configuration, including serving the application from the host for live editing, look at `docker-compose.yml` in the root folder.

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/datacite/volpino/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License
**volpino** is released under the [MIT License](https://github.com/datacite/volpino/blob/master/LICENSE).