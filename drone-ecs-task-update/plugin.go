package main

import (
	"fmt"
	"log"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/credentials/stscreds"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
)

type Plugin struct {
	Key           string
	Secret        string
	Region        string
	UserRoleArn   string
	Service       string
	ContainerName string
	DockerImage   string
	Tag           string
	Cluster       string
	IgnoreMissing bool
}

func (p *Plugin) Exec() error {
	fmt.Println("Drone ECS task definition updater")

	if len(p.Cluster) == 0 || len(p.Service) == 0 {
		log.Fatal("You need to provide both cluster and service parameters")
	}

	awsConfig := aws.Config{}
	var sess *session.Session

	awsConfig.Region = aws.String(p.Region)

	if len(p.Key) != 0 && len(p.Secret) != 0 {
		fmt.Printf("Creating AWS session using AWS_ACCESS_KEY.")
		awsConfig.Credentials = credentials.NewStaticCredentials(p.Key, p.Secret, "")
		// Must is a helper function to ensure the Session is valid and there was no error when calling a NewSession function
		// In case of error it will call panic(err)
		sess = session.Must(session.NewSession(&awsConfig))
	} else {
		// If no Key or Secret try to use SSO
		fmt.Println("No valid AWS access key and/or secret provided. Falling back to shared config...")
		sess = session.Must(session.NewSessionWithOptions(session.Options{
			SharedConfigState: session.SharedConfigEnable}))
	}

	var svc *ecs.ECS

	//If user role ARN is set then assume role here
	if len(p.UserRoleArn) > 0 {
		awsConfigArn := aws.Config{Region: aws.String(p.Region)}
		arnCredentials := stscreds.NewCredentials(sess, p.UserRoleArn)
		awsConfigArn.Credentials = arnCredentials
		svc = ecs.New(sess, &awsConfigArn)
	} else {
		svc = ecs.New(sess)
	}

	input := &ecs.DescribeServicesInput{
		Services: []*string{
			aws.String(p.Service),
		},
		Cluster: aws.String(p.Cluster),
	}
	service, err := svc.DescribeServices(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case ecs.ErrCodeServerException:
				fmt.Println(ecs.ErrCodeServerException, aerr.Error())
			case ecs.ErrCodeClientException:
				fmt.Println(ecs.ErrCodeClientException, aerr.Error())
			case ecs.ErrCodeInvalidParameterException:
				fmt.Println(ecs.ErrCodeInvalidParameterException, aerr.Error())
			case ecs.ErrCodeClusterNotFoundException:
				fmt.Println(ecs.ErrCodeClusterNotFoundException, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		return err
	}

	inputTd := &ecs.DescribeTaskDefinitionInput{
		TaskDefinition: service.Services[0].TaskDefinition,
		Include:        []*string{aws.String("TAGS")},
	}

	taskDefinitionOld, err := svc.DescribeTaskDefinition(inputTd)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case ecs.ErrCodeServerException:
				fmt.Println(ecs.ErrCodeServerException, aerr.Error())
			case ecs.ErrCodeClientException:
				fmt.Println(ecs.ErrCodeClientException, aerr.Error())
			case ecs.ErrCodeInvalidParameterException:
				fmt.Println(ecs.ErrCodeInvalidParameterException, aerr.Error())
			case ecs.ErrCodeClusterNotFoundException:
				fmt.Println(ecs.ErrCodeClusterNotFoundException, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		return err
	}

	taskDefinition := *taskDefinitionOld.TaskDefinition

	var newImage string
	var found = false

	for i, container := range taskDefinition.ContainerDefinitions {
		if *container.Name == p.ContainerName {
			oldImage := strings.SplitN(*taskDefinitionOld.TaskDefinition.ContainerDefinitions[i].Image, ":", 2)
			if len(p.DockerImage) == 0 {
				fmt.Println("No docker image provided. Using value from task definition.")
				newImage = oldImage[0]
			} else {
				newImage = p.DockerImage
			}
			if len(p.Tag) == 0 {
				fmt.Println("No docker image TAG provided. Using value from task definition (if present).")
				if len(oldImage) == 2 {
					newImage = newImage + ":" + oldImage[1]
				}
			} else {
				newImage = newImage + ":" + p.Tag
			}
			*taskDefinition.ContainerDefinitions[i].Image = newImage
			found = true
		}
	}

	if !found {
		fmt.Printf("No container named \"%s\" found in container definitions.\nService: %s\nTask definition: %s\n", p.ContainerName, *(service.Services[0].ServiceArn), *(taskDefinition.TaskDefinitionArn))
		if p.IgnoreMissing {
			log.Print("'ignore-missing-container' flag set. Continuing anyway...")
		} else {
			log.Fatal("Exiting.")
		}
	}

	inputRegTagDef := &ecs.RegisterTaskDefinitionInput{
		ContainerDefinitions:    taskDefinition.ContainerDefinitions,
		Cpu:                     taskDefinition.Cpu,
		EphemeralStorage:        taskDefinition.EphemeralStorage,
		ExecutionRoleArn:        taskDefinition.ExecutionRoleArn,
		Family:                  taskDefinition.Family,
		InferenceAccelerators:   taskDefinition.InferenceAccelerators,
		IpcMode:                 taskDefinition.IpcMode,
		Memory:                  taskDefinition.Memory,
		NetworkMode:             taskDefinition.NetworkMode,
		PidMode:                 taskDefinition.PidMode,
		PlacementConstraints:    taskDefinition.PlacementConstraints,
		ProxyConfiguration:      taskDefinition.ProxyConfiguration,
		RequiresCompatibilities: taskDefinition.RequiresCompatibilities,
		RuntimePlatform:         taskDefinition.RuntimePlatform,
		Tags:                    taskDefinitionOld.Tags,
		TaskRoleArn:             taskDefinition.TaskRoleArn,
		Volumes:                 taskDefinition.Volumes,
	}

	newTaskDefinition, err := svc.RegisterTaskDefinition(inputRegTagDef)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case ecs.ErrCodeServerException:
				fmt.Println(ecs.ErrCodeServerException, aerr.Error())
			case ecs.ErrCodeClientException:
				fmt.Println(ecs.ErrCodeClientException, aerr.Error())
			case ecs.ErrCodeInvalidParameterException:
				fmt.Println(ecs.ErrCodeInvalidParameterException, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		return err
	}

	newTaskDefinitionArn := *newTaskDefinition.TaskDefinition.TaskDefinitionArn

	serviceParams := &ecs.UpdateServiceInput{
		Cluster:        aws.String(p.Cluster),
		Service:        aws.String(p.Service),
		TaskDefinition: aws.String(newTaskDefinitionArn),
	}

	updatedService, err := svc.UpdateService(serviceParams)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case ecs.ErrCodeServerException:
				fmt.Println(ecs.ErrCodeServerException, aerr.Error())
			case ecs.ErrCodeClientException:
				fmt.Println(ecs.ErrCodeClientException, aerr.Error())
			case ecs.ErrCodeInvalidParameterException:
				fmt.Println(ecs.ErrCodeInvalidParameterException, aerr.Error())
			case ecs.ErrCodeClusterNotFoundException:
				fmt.Println(ecs.ErrCodeClusterNotFoundException, aerr.Error())
			case ecs.ErrCodeServiceNotFoundException:
				fmt.Println(ecs.ErrCodeServiceNotFoundException, aerr.Error())
			case ecs.ErrCodeServiceNotActiveException:
				fmt.Println(ecs.ErrCodeServiceNotActiveException, aerr.Error())
			case ecs.ErrCodePlatformUnknownException:
				fmt.Println(ecs.ErrCodePlatformUnknownException, aerr.Error())
			case ecs.ErrCodePlatformTaskDefinitionIncompatibilityException:
				fmt.Println(ecs.ErrCodePlatformTaskDefinitionIncompatibilityException, aerr.Error())
			case ecs.ErrCodeAccessDeniedException:
				fmt.Println(ecs.ErrCodeAccessDeniedException, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			fmt.Println(err.Error())
		}
		return err
	}

	fmt.Println("Updated Task Definition:")
	fmt.Println(newTaskDefinition)

	fmt.Println("Updated Service: ")
	fmt.Println(updatedService)

	return nil
}
