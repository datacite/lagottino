# DataCite Event Data API

** This repository has been archived, as functionality is now included in datacite/lupo. **

[![Build Status](https://travis-ci.org/datacite/lagottino.svg?branch=master)](https://travis-ci.org/datacite/lagottino) [![Docker Build Status](https://img.shields.io/docker/build/datacite/lagottino.svg)](https://hub.docker.com/r/datacite/lagottino/) [![Maintainability](https://api.codeclimate.com/v1/badges/37f15ec443bc203a406f/maintainability)](https://codeclimate.com/github/datacite/lagottino/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/37f15ec443bc203a406f/test_coverage)](https://codeclimate.com/github/datacite/lagottino/test_coverage)

## Installation


Using Docker.

```bash
docker run -p 8085:80 datacite/lagottino
```

or

```bash
docker-compose up
```

You can now point your browser to `http://localhost:8085` and use the application. Some API endpoints require authentication.

To populate the database and index with resources:

```bash
bundle exec rake elasticsearch:event:create_index
bundle exec rake elasticsearch:event:import
bundle exec rake event:index

```

To delete events by subj-id, for example events with subj-id 'https://doi.org/10.1007/s10680-018-9485-1':

```bash
bundle exec rake event:detete_by_sub_id[https://doi.org/10.1007/s10680-018-9485-1]

```

## Development

We use Rspec for testing:

```bash
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/datacite/lagottino/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License

**Lagottino** is released under the [MIT License](https://github.com/datacite/lagottino/blob/master/LICENSE).

