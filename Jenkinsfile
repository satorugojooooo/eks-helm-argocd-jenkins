pipeline {
    agent any

    environment {
        IMAGE_NAME = "jeevac33/node-app:latest"  // ✅ Make sure this is correctly formatted
        CONTAINER_NAME = "myapp-container"
    }

    stages {
        stage('Pull Docker Image') {
            steps {
                sh "docker pull $IMAGE_NAME"
            }
        }

        stage('Stop Existing Container') {
            steps {
                sh "docker stop $CONTAINER_NAME || true"
                sh "docker rm $CONTAINER_NAME || true"
            }
        }

        stage('Run New Container') {
            steps {
                sh "docker run -d --name $CONTAINER_NAME -p 8080:8080 $IMAGE_NAME"
            }
        }
    }
}
