# drone-ecs-standalone-task

This plugin was created on base of Josmo's drone-ecs plugin. In fact it is modified version, which runs only standalone tasks instead of whole services. Big thanks for his work!

Drone plugin to run standalone tasks in AWS ECS

Use this plugin for deploying a docker container application to AWS EC2 Container Service (ECS) as a standalone task.

### Required IAM Policies:

```json
{
        "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "iam:PassRole",
                "ecs:RunTask",
                "ecs:RegisterTaskDefinition",
                "ecr:GetAuthorizationToken",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecs:DescribeTasks",
                "ecs:StopTask"
            ],
            "Resource": "*"
}
```

### Settings

* `access_key` - AWS access key ID, MUST be an IAM user with the AmazonEC2ContainerServiceFullAccess policy attached
* `secret_key` - AWS secret access key
* `user_role_arn` - AWS user role. Optional. Switch to different role after initial authentication
* `region` - AWS availability zone
* `container_name` - Name of the container, defaults to ${family}-container
* `cluster` - Name of the cluster.
* `family` - Family name of the task definition to create or update with a new revision
* `task_role_arn` - ECS task IAM role
* `docker_image` - Container image to use, do not include the tag here
* `tag` - Tag of the image to use, defaults to latest
* `port_mappings` - Port mappings from host to container, format is `hostPort containerPort`, protocol is automatically set to TransportProtocol
* `cpu` - The number of cpu units to reserve for the container
* `memory` - The hard limit (in MiB) of memory to present to the container
* `memory_reservation` - The soft limit (in MiB) of memory to reserve for the container. Defaults to 128
* `environment_variables` - List of Environment Variables to be passed to the container, format is `NAME=VALUE`
* `desired_count` - The number of instantiations of the specified task definition to place and keep running on your cluster. Set it to a negative number to not modify current desired_count in the service.
* `log_driver` - The log driver to use for the container
* `log_options` - The configuration options to send to the log driver
* `labels` - A key/value map of labels to add to the container
* `entry_point` - A list of strings to build the container entry point configuration
* `secret_environment_variables` - List of Environment Variables to be injected into the container from drone secrets. You can use the name of the secret itself or set a custom name to be used within the container. Syntax is `NAME` (must match the name of one of your secrets) or `CUSTOM_NAME=NAME`
* `secrets_manager_variables` - List of Environment Variables to be injected into the container from AWS secrets manager, format is `NAME=VALUE`. `VALUE` must match the resource name in AWS secrets manager. I.e. `arn:aws:secretsmanager:region:aws_account_id:secret:password-xxxx`
* `task_cpu` - The number of CPU units used by the task. It can be expressed as an integer using CPU units, for example 1024, or as a string using vCPUs, for example 1 vCPU or 1 vcpu
* `task_memory` - The amount of memory (in MiB) used by the task.It can be expressed as an integer using MiB, for example 1024, or as a string using GB. Required if using Fargate launch type
* `task_execution_role_arn` - The Amazon Resource Name (ARN) of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
* `compatibilities` - Space-delimited list of launch types supported by the task, defaults to EC2 if not specified
* `network_mode` - If compatibilities includes FARGATE, this must be set to awsvpc.
* `service_network_assign_public_ip` - Whether the task's elastic network interface receives a public IP address. The default value is DISABLED.
* `service_network_security_groups` - The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used. There is a limit of 5 security groups that can be specified per AwsVpcConfiguration.
* `service_network_subnets` - The subnets associated with the task or service. There is a limit of 16 subnets that can be specified per AwsVpcConfiguration.
* `ulimits` - The Ulimit property specifies the ulimit settings to pass to the container. This is an array of strings in the format: `name softLimit hardLimit` where name is one of: core, cpu, data, fsize, locks, memlock, msgqueue, nice, nofile, nproc, rss, rtprio, rttime, sigpending, stack and soft/hard limits are integers.
* `mount_points` - Mount points from host to container, format is `sourceVolume containerPath readOnly` where `sourceVolume`, `containerPath` are strings, `readOnly` is string [`true`, `false`]
* `volumes` - Bind Mount Volumes, format is `name sourcePath` both values are strings. Note with FARGATE launch type, you only provide the name of the volume, not the `sourcePath`
* `efs_volumes` - Define EFS volume, format: `name efs-id root-directory`. Current configuration doesn't support encryption in transit.
* `placement_constraints` - Ecs task definition placement constraints. Specify an array of constraints as a single string. Note that "distinctInstance" type can only be specified during run task or in service. Not inside a task definition.
* `healthcheck_command` - List representing the command that the container runs to determine if it is healthy. Must start with CMD to execute the command arguments directly, or CMD-SHELL to run the command with the container's default shell.
* `healthcheck_interval` - The time period in seconds between each health check execution. You may specify between 5 and 300 seconds. Defaults to 30 seconds. Default: 30
* `healthcheck_retries` - The number of times to retry a failed health check before the container is considered unhealthy. You may specify between 1 and 10 retries. Defaults to 3
* `healthcheck_start_period` - The grace period within which to provide containers time to bootstrap before failed health checks count towards the maximum number of retries. You may specify between 0 and 300 seconds. The startPeriod is disabled by default.
* `healthcheck_timeout` - The time period in seconds to wait for a health check to succeed before it is considered a failure. You may specify between 2 and 60 seconds. Defaults to 5 seconds

New parameters:
* `capacity_providers` - Defines capacity providers. Format: list of `base(int) weight(int) name`; base - designates how many tasks, at a minimum, to run on the specified provider; weight - designates how many tasks will be assigned to this provider from among of all tasks cap in comparition to other providers; name - capacity provider's name
* `enable_execute_command` - Whether or not to enable the execute command functionality for the containers. Value is boolean [`true`, `false`]
* `propagate_tags` - Specifies whether to propagate the tags from the task definition to the task. Value is boolean [`true`, `false`]
* `platform_version` - The platform version the task should run. A platform version is only specified for tasks using the Fargate launch type. If one is not specified, the LATEST platform version is used by default
* `dont_wait` - If set on `true` - this drone's step won't wait for all tasks to finish. Step ends execution when all tasks enter into `RUNNING` state. This also doesn't checks execution exit status. Default `false`
* `ignore_execution_fail` - If set on `true` - drone's step won't fail on container's exit code !=0.
* `task_timeout` - Timeout in seconds for task to successfully set all stages from `PROVISSIONING` to `STOPPED` or to `RUNNING` if `dont-wait` flag enabled. Default 300.
* `task_kill_on_timeout` - When task reaches timeout - send kill signal to the containers. Deafult `true`
* `command` - A list of strings to pass as `Command` to container.
* `privileged` - Container will run in privileged mode (applicable only for EC2 launch type)
* `use_existing_task_definition` - If set on `true` it tells the plugin to ignore task settings and try to use existing task definition from ECS. `existing_task_definition` must be defined. If set on `false` `existing_task_definition_arn` is defined plugin will try to create new revision of existing task definition using provided configuration or create new task definition if update fails. Default is `true`.
* `existing_task_definition_arn` - Existing ECS task definition to be used to run standalone task. Can be `family`, `family:revision`, or `ARN` (with or without revision)


### Example 1

```yaml
steps:
  - name: Deploy to ECS
    image: ////
    settings:
      region: eu-west-1
      family: my-ecs-task
      docker_image: namespace/repo
      tag: latest
      task_role_arn: arn:aws:iam::012345678901:role/rolename
      log_driver: awslogs
      log_options:
        - awslogs-group=my-ecs-group
        - awslogs-region=us-east-1
      environment_variables:
        - DATABASE_URI=$$MY_DATABASE_URI
      secret_environment_variables:
        - MY_SECRET=MY_SANDBOX_SECRET
        - MY_ACCESS_KEY
      labels:
        - traefik.frontend.rule=Host:my.host.gov
        - traefik.backend=pirates
      port_mappings:
        - 80 9000
      memoryReservation: 128
      placement_constraints: [{"type": "memberOf","expression": "attribute:test == true"}]
      cpu: 1024
      desired_count: 1
      ulimits:
        - nofile 2048 4096  
      secrets: [AWS_SECRET_KEY, AWS_ACCESS_KEY]
      enable_execute_command: true
      propagate_tags: true
      platform_version: LATEST
      dont_wait: false
      ignore_execution_fail: false
      task_timeout: 300
      task_kill_on_timeout: true
    # declaring the environment is necessary to get secret_environment_variables to work  
    environment:
      MY_SANDBOX_SECRET:
        from_secret: MY_SANDBOX_SECRET
      MY_ACCESS_KEY:
        from_secret: access_key

```
### Example 2

```yaml
steps:
  - name: Deploy to ECS
    image: ////
    settings:
      region: eu-west-1
      secret_environment_variables:
        - MY_SECRET=MY_SANDBOX_SECRET
        - MY_ACCESS_KEY
      # this mount_point and volumes config will give drone_runner_docker access to docker.sock
      mount_points:
        - dockersock /var/run/docker.sock false
      volumes:
        - dockersock /var/run/docker.sock      
      secrets: [AWS_SECRET_KEY, AWS_ACCESS_KEY]
      enable_execute_command: true
      propagate_tags: true
      platform_version: LATEST
      dont_wait: false
      ignore_execution_fail: false
      task_timeout: 300
      task_kill_on_timeout: true
      use_existing_task_definition: true
      existing_task_definition_arn: arn:aws:ecs:eu-west-1:123456789012:task-definition/TaskDefinitionFamily:1
    # declaring the environment is necessary to get secret_environment_variables to work  
    environment:
      MY_SANDBOX_SECRET:
        from_secret: MY_SANDBOX_SECRET
      MY_ACCESS_KEY:
        from_secret: access_key

```