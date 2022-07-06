pipeline {
    agent any
    environment {

        component_name = "frontend"
        BASE_DIR = "./"

       
        AWS_ECR_REGION = "ap-south-1"
        AWS_ECS_CLUSTER ="CMS-DEV-TEST-Custer"
        AWS_ECR_URL = "870562585226.dkr.ecr.ap-south-1.amazonaws.com/cms-${component_name}-test"
        AWS_ECS_EXECUTION_ROL = "ecsTaskExecutionRole"
        AWS_ECS_SERVICE = "cms-${component_name}-service-lb"
        AWS_ECS_TASK_DEFINITION = "cms-${component_name}-task"
        AWS_ECS_COMPATIBILITY = 'FARGATE'
        AWS_ECS_NETWORK_MODE = 'awsvpc'
        AWS_ECS_CPU = '256'
        AWS_ECS_MEMORY = '512'
       
        AWS_ECS_TASK_DEFINITION_PATH = "./ecs/task-definition.json"
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {
        stage("init") {
            steps {
                sh "echo init"
            }
            
        }
        stage("buildAndDockerize") {
            steps {
                dir("./") {
                    sh '''
                        docker build \
                        -t ${AWS_ECR_URL}:v_${BUILD_NUMBER} .
                    '''    
                }
            }
        }
        stage ('publishToRegistry') {
            steps {
                withAWS(credentials: 'marlabs-user', region: 'ap-south-1') {

                    sh '''
                    $(aws ecr get-login --region ap-south-1 --no-include-email)
                    docker push ${AWS_ECR_URL}:v_${BUILD_NUMBER}
                    '''
                }
            }
        } 
        stage('Deploy in ECS') {
            steps {
                 withAWS(credentials: 'marlabs-user', region: 'ap-south-1') {
                    script {
                        updateContainerDefinitionJsonWithImageVersion()
                        sh("aws ecs register-task-definition --region ${AWS_ECR_REGION} --family ${AWS_ECS_TASK_DEFINITION} --execution-role-arn ${AWS_ECS_EXECUTION_ROL} --requires-compatibilities ${AWS_ECS_COMPATIBILITY} --network-mode ${AWS_ECS_NETWORK_MODE} --cpu ${AWS_ECS_CPU} --memory ${AWS_ECS_MEMORY} --container-definitions file://${AWS_ECS_TASK_DEFINITION_PATH}")
                        def taskRevision = sh(script: "aws ecs describe-task-definition --task-definition ${AWS_ECS_TASK_DEFINITION} | egrep \"revision\" | tr \"/\" \" \" | awk '{print \$2}' | sed 's/\"\$//'", returnStdout: true)
                        sh("aws ecs update-service --cluster ${AWS_ECS_CLUSTER} --service ${AWS_ECS_SERVICE} --task-definition ${AWS_ECS_TASK_DEFINITION}")
                    }
                }
            }
        }
    }
    post {
        always {
            withAWS(credentials: 'marlabs-user', region: 'ap-south-1') {
                script {
                    deleteDir()
                    sh "docker rmi ${AWS_ECR_URL}:v_${BUILD_NUMBER}"
                }
            }
        }
    }
}
def updateContainerDefinitionJsonWithImageVersion() {
    def containerDefinitionJson = readJSON file: AWS_ECS_TASK_DEFINITION_PATH, returnPojo: true
    containerDefinitionJson[0]['image'] = "${AWS_ECR_URL}:v_${BUILD_NUMBER}".inspect()
    echo "task definiton json: ${containerDefinitionJson}"
    writeJSON file: AWS_ECS_TASK_DEFINITION_PATH, json: containerDefinitionJson
}
