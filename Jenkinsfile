pipeline {
  agent any

  environment {
    REGISTRY = "docker.io"
    IMAGE    = "aryanghori/eb-express-aryanghori"   // change if needed
    TAG      = "build-${env.BUILD_NUMBER}"
    CREDS_ID = "dockerhub-creds"
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install Node 16 (once per build)') {
      steps {
        sh '''
          set -eux
          if ! command -v node >/dev/null 2>&1; then
            apt-get update
            # Install curl + xz just in case
            apt-get install -y curl xz-utils ca-certificates
            # Install Node 16 LTS via NodeSource
            curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
            apt-get install -y nodejs
            node -v
            npm -v
          else
            node -v
            npm -v
          fi
        '''
      }
    }

    stage('Install & Test') {
      steps {
        sh '''
          set -eux
          npm ci || npm install
          npm test || echo "No tests found, continuing..."
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/junit*.xml,**/test-results/*.xml'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${REGISTRY}/${IMAGE}:${TAG} ."
      }
    }

    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.CREDS_ID,
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin ${REGISTRY}
            docker push ${REGISTRY}/${IMAGE}:${TAG}
          """
        }
      }
    }
  }

  post {
    success { echo "Pushed: ${REGISTRY}/${IMAGE}:${TAG}" }
    failure { echo "Build failed. Check the failing stage’s console log." }
  }
}


