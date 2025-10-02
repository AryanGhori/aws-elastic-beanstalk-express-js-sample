pipeline {
  agent any

  environment {
    REGISTRY = "docker.io"                          
    IMAGE    = "aryanghori/eb-express"
    TAG      = "build-${env.BUILD_NUMBER}"
    CREDS_ID = "dockerhub-creds"                    
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Test (Node 16)') {
      agent {
        docker {
          image 'node:16'
          reuseNode true
        }
      }
      steps {
        sh 'node -v'
        sh 'npm --version'
        sh 'npm install --save'
        sh 'npm test'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $REGISTRY/$IMAGE:$TAG .'
      }
    }

    stage('Login & Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.CREDS_ID,
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY'
        }
        sh 'docker push $REGISTRY/$IMAGE:$TAG'
      }
    }

    stage('Dependency Scan (Fail on High/Critical)') {
      steps {
        sh '''
          mkdir -p dependency-check-report
          docker run --rm \
            -v "$PWD":/src \
            -v "$PWD/dependency-check-report":/report \
            owasp/dependency-check:latest \
            --scan /src \
            --noupdate \
            --out /report \
            --format "HTML" \
            --failOnCVSS 7
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dependency-check-report/**', onlyIfSuccessful: false
    }
  }
}
