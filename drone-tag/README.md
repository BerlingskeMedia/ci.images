# drone-tag

This image runs Drone.io plugin designed to properly tag images. It will

Parameters:

| Parameter name              | Required | Default value | Possible values | Description                                                                                                                                      |
|:----------------------------|:---------|:--------------|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------|
| `access_key`                | **yes**  | _none_        | _String_        | IAM Access key giving permissions to operate on S3 bucket                                                                                        |
| `secret_key`                | **yes**  | _none_        | _String_        | IAM Access secret key giving permissions to operate on S3 bucket                                                                                 |
| `fetch_version`             | **no**   | `false`       | `true`, `false` | If set on _true_ will only fetch stored version on given `s3_bucket` under given `s3_path` and save into given `local_path` file                 |
| `local_path`                | **no**   | `.tag`        | _String_        | Path to file where will be localy stored latest version                                                                                          |
| `region`                    | **yes**  | _none_        | _String_        | AWS region to set                                                                                                                                |
| `s3_bucket`                 | **yes**  | _none_        | _String_        | S3 bucket which stores version numbers                                                                                                           |
| `s3_path`                   | **yes**  | _none_        | _String_        | Path to S3 object on given bucket, which stores last version number                                                                              |
| `s3_use_prefix_as_filename` | **no**   | `false`       | _string_        | If true, will use evaluated prefix as filename, this modifies `s3_path` to act as path (s3 object's prefix). Prefix should be set and evaluable! |
| `tag_increment_level`       | **no**   | `0`           | `0`, `1`, `2`   | Index of number to increment: `[0]`.`[1]`.`[2]`                                                                                                  |
| `tag_prefix`                | **no**   | _none_        | _String_        | Fixed tag prefix. If not provided, will be empty. Otherwise will create tag: `[prefix]-[version]`                                                |
| `tag_prefix_regex`          | **no**   | _none_        | _String_        | If set, will use matching pattern from branch name to generate prefix. Overwrites `tag_prefix` if matched.                                       |
| `log_mode`                  | **no**   | `1`           | `0`, `1`, `2`   | Log mode: 0 - warnings only, 1 - info; 2 - debug                                                                                                 |


# Example usage

Usage to tag testing builds
```yaml
- image: drone-tag
  name: tag-build-for-testing
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    local_path: .version
    s3_bucket: some-version-bucket
    s3_path: this_namespace/testing/this_name/version
    tag_increment_level: 1 # Will increment minor version
    tag_prefix_regex: "^\w+-\d+" # i.e. get jira ticket number like "BMD-123" etc 
```

Usage to tag production
```yaml
- image: drone-tag
  name: tag-build-production
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    local_path: .version
    s3_bucket: some-version-bucket
    s3_path: this_namespace/production/this_name/version
    tag_increment_level: 0 # Will increment major version 
```

Example of fetching latest tag number, i.e to use with docker plugin later on

```yaml
- image: drone-tag
  name: fetch-tag
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    local_path: .tag
    s3_bucket: some-version-bucket
    s3_path: this_namespace/this_stage/this_name/version 
```