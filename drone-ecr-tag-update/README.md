# drone-ecr-tag-update

This image runs Drone.io plugin designed to properly tag ECR images/

Parameters:

| Parameter name       | Required | Default value | Possible values    | Description                                                          |
|:---------------------|:---------|:--------------|:-------------------|:---------------------------------------------------------------------|
| `aws_default_region` | **no**   | `eu-west-1`   | _String_           | AWS region on which to operate                                       |
| `access_key`         | **no**   | _none_        | _String_           | IAM Access key giving permissions to operate on S3 bucket            |
| `secret_key`         | **no**   | _none_        | _String_           | IAM Access secret key giving permissions to operate on S3 bucket     |
| `repository`         | **yes**  | _none_        | _String_           | ECR repository name where image will be tagged                       |
| `tag_origin`         | **yes**  | _none_        | _String_           | Origin image's tag. This image will be tagged with `tag_destination` |
| `tag_destination`    | **yes**  | _none_        | _String_           | Name of tag to be set on given image                                 |
| `log_mode`           | **no**   | `1`           | `0`, `1`, `2`, `3` | Log mode: 0 - warnings only, 1 - info; 2 - debug; 3 - trace          |


# Example usage


Usage to tag image from current commit ID as `production`
```yaml
- image: 
    from_secret: drone_tag_update_plugin
  name: check-current-version
  settings:
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    tag_origin: ${DRONE_COMMIT}
    tag_destination: production
    repository: my-ecr-repo/image
```
