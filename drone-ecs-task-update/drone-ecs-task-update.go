package main

import (
	"fmt"
	"log"
	"os"

	"github.com/urfave/cli"
)

var (
	version = "0.0.0"
	build   = "0"
)

func main() {
	app := cli.NewApp()
	app.Name = "Drone ECS service task definition update"
	app.Usage = "Drone plugin: ECS service task definition container image update"
	app.Action = run
	app.Version = fmt.Sprintf("%s+%s", version, build)
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:   "access-key, a",
			Usage:  "AWS access key",
			EnvVar: "PLUGIN_ACCESS_KEY,ECS_ACCESS_KEY,AWS_ACCESS_KEY",
		},
		cli.StringFlag{
			Name:   "secret-key, k",
			Usage:  "AWS secret key",
			EnvVar: "PLUGIN_SECRET_KEY,ECS_SECRET_KEY,AWS_SECRET_KEY",
		},
		cli.StringFlag{
			Name:   "user-role-arn",
			Usage:  "AWS user role",
			EnvVar: "PLUGIN_USER_ROLE_ARN,ECS_USER_ROLE_ARN,AWS_USER_ROLE_ARN",
		},
		cli.StringFlag{
			Name:   "region, r",
			Usage:  "aws region",
			Value:  "eu-west-1",
			EnvVar: "PLUGIN_REGION",
		},
		cli.StringFlag{
			Name:   "service, s",
			Usage:  "Service to act on",
			EnvVar: "PLUGIN_SERVICE",
		},
		cli.StringFlag{
			Name:   "container-name, n",
			Usage:  "Container name",
			EnvVar: "PLUGIN_CONTAINER_NAME",
		},
		cli.StringFlag{
			Name:   "docker-image, i",
			Usage:  "image to use",
			EnvVar: "PLUGIN_DOCKER_IMAGE",
		},
		cli.StringFlag{
			Name:   "tag, t",
			Usage:  "AWS tag",
			EnvVar: "PLUGIN_TAG",
		},
		cli.StringFlag{
			Name:   "cluster, c",
			Usage:  "AWS ECS cluster",
			EnvVar: "PLUGIN_CLUSTER",
		},
		cli.BoolFlag{
			Name:   "ignore-missing-container, i",
			Usage:  "Ignore missing container definition in task definition and continue",
			EnvVar: "PLUGIN_IGNORE_MISSING_CONTAINER",
		},
	}
	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func run(c *cli.Context) error {
	plugin := Plugin{
		Key:           c.String("access-key"),
		Secret:        c.String("secret-key"),
		UserRoleArn:   c.String("user-role-arn"),
		Region:        c.String("region"),
		Service:       c.String("service"),
		ContainerName: c.String("container-name"),
		DockerImage:   c.String("docker-image"),
		Tag:           c.String("tag"),
		Cluster:       c.String("cluster"),
		IgnoreMissing: c.Bool("ignore-missing-container"),
	}
	return plugin.Exec()
}
