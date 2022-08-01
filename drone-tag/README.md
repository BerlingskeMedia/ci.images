# drone-tag

This image runs Drone.io plugin designed to properly tag images. It will

Parameters:

| Parameter name              | Required | Default value | Possible values   | Description                                                                                                                                                       |
|:----------------------------|:---------|:--------------|:------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `access_key`                | **no**   | _none_        | _String_          | IAM Access key giving permissions to operate on S3 bucket                                                                                                         |
| `secret_key`                | **no**   | _none_        | _String_          | IAM Access secret key giving permissions to operate on S3 bucket                                                                                                  |
| `fetch_only`                | **no**   | `false`       | `true`, `false`   | If set on _true_ not increment version                                                                                                                            |
| `fetch_from`                | **no**   | `s3`          | `s3`,`local`      | By default fetches from `s3` otherwise will fetch from given local path                                                                                           |
| `fetch_path`                | **yes**  | _none_        | _string_          | Path from which fetch last version (local path, or in case of S3 bucket `[s3-bucket]:[object_path]`)                                                              |
| `s3_use_prefix_as_filename` | **no**   | `false`       | `true`, `false`   | If true, will use evaluated prefix as filename, this modifies `save_paths` value for `s3` key to act as directory path. Prefix should be set and evaluable!       |
| `save_paths`                | **no**   | _none_        | _list(key=value)_ | list of key=value elements, where key is type of storage (`s3` or `local`) and value is path                                                                      |
| `tag_clear_sublevels`       | **no**   | `false`       | `true`, `false`   | If set on true, will clear (set to 0) all minor tag levels below increment level. I.e. for `tag_increment_level=0` will set tag `X.0.0`; for `1` will set `X.Y.0` |
| `tag_increment_level`       | **no**   | `0`           | `0`, `1`, `2`     | Index of number to increment: `[0]`.`[1]`.`[2]`                                                                                                                   |
| `tag_prefix`                | **no**   | _none_        | _String_          | Fixed tag prefix. If not provided, will be empty. Otherwise will create tag: `[prefix]-[version]`                                                                 |
| `tag_prefix_regex`          | **no**   | _none_        | _String_          | If set, will use matching pattern from branch name to generate prefix. Overwrites `tag_prefix` if matched.                                                        |
| `log_mode`                  | **no**   | `1`           | `0`, `1`, `2`     | Log mode: 0 - warnings only, 1 - info; 2 - debug                                                                                                                  |


# Example usage


Usage to check current version in s3 and store it localy
```yaml
- image: drone-tag
  name: check-current-version
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    fetch_only: true
    fetch_from: s3
    fetch_path: some-version-bucket:this_namespace/testing/this_name/version
    save_paths:
      - local=.tag
```

Usage to tag testing builds. Version stored in s3,
```yaml
- image: drone-tag
  name: tag-build-for-testing
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    fetch_from: s3
    fetch_path: some-version-bucket:this_namespace/testing/this_name/version
    save_paths:
      - s3=some-version-bucket:this_namespace/testing/this_name/version
    tag_increment_level: 1 # Will increment minor version
    tag_prefix_regex: "^\w+-\d+" # i.e. get jira ticket number like "BMD-123" etc 
```

Usage to tag production, version stored localy. Using IAM role instead of credentials. Save version to s3 AND localy
```yaml
- image: drone-tag
  name: tag-build-production
  settings:
    fetch_from: local
    fetch_path: .tag
    save_paths:
      - s3=some-version-bucket:this_namespace/production/this_name/version
      - local=.tag
    tag_increment_level: 0 # Will increment major version 
```

Example of tagging version by branch prefix. Usable to version feature branches

```yaml
- image: drone-tag
  name: tag-feature-qa1
  settings:
    fetch_from: s3
    fetch_path: some-version-bucket:this_namespace/testing/this_name/version
    save_paths:
      - s3=some-version-bucket:this_namespace/testing/this_name
      - local=.tag
    local_path: .tag
    tag_prefix_regex: "^\w+-\d+" # i.e. get jira ticket number like "BMD-123" etc 
    tag_prefix: qa1 # default value in case regex not resolveable
    tag_increment_level: 1 # Will increment minor version
    s3_use_prefix_as_filename: true
```