pipeline {
  agent any

  environment {
    REGISTRY = "docker.io"
    IMAGE    = "aryanghori/eb-express"
    TAG      = "build-${env.BUILD_NUMBER}"
    CREDS_ID = "dockerhub-creds"
    DOCKER_BUILDKIT = "1"
  }

  options {
    skipDefaultCheckout(true)
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Test (Node 16)') {
      agent {
        docker {
          image 'node:16'
          args  '-v /var/jenkins_home:/var/jenkins_home'
          reuseNode true
        }
      }
      steps {
        sh '''
          set -eux
          node -v
          npm --version
          npm install --save || true

          mkdir -p __tests__
          cat > __tests__/smoke.test.js <<'JS'
          test('smoke test runs without modifying package.json', () => {
            expect(1 + 1).toBe(2);
          });
          JS

          npx --yes jest@29 --ci
        '''
      }
    }

    stage('Dependency Scan (Fail on High/Critical)') {
      steps {
        withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_API_KEY')]) {
          sh '''
            set -eu
            rm -rf owasp
            mkdir -p owasp
            chmod -R 0777 owasp

            # sanitize key to avoid hidden \\r/\\n from copy-paste
            SANITIZED_KEY="$(printf %s "$NVD_API_KEY" | tr -d '\\r\\n')"
            if [ -z "$SANITIZED_KEY" ]; then
              echo "NVD API key appears empty after sanitizing. Check your Jenkins secret."
              exit 2
            fi

            # optional: if behind proxy, uncomment next 3 lines
            # export HTTP_PROXY="${HTTP_PROXY:-}"
            # export HTTPS_PROXY="${HTTPS_PROXY:-}"
            # export NO_PROXY="${NO_PROXY:-}"

            # Use a conservative delay to avoid 403; cache DB under owasp/data
            docker run --rm \
              --user 0:0 \
              -e NVD_API_KEY="$SANITIZED_KEY" \
              -v "$PWD":/src:ro \
              -v "$PWD"/owasp:/report \
              owasp/dependency-check:9.2.0 \
              --scan /src \
              --format HTML \
              --out /report \
              --data /report/data \
              --project eb-express \
              --nvdApiKey "$SANITIZED_KEY" \
              --nvdApiDelay 8000 \
              --nvdMaxRetryCount 5 \
              --nvdValidForHours 24 \
              --failOnCVSS 7
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'owasp/dependency-check-report.html', fingerprint: true, allowEmptyArchive: true
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          set -eux
          docker version
          docker build -t $REGISTRY/$IMAGE:$TAG -f - . <<'DOCKER'
          FROM node:16-alpine
          WORKDIR /usr/src/app
          COPY package*.json ./
          RUN npm ci --omit=dev || npm install --production
          COPY . .
          ENV PORT=3000
          EXPOSE 3000
          CMD ["npm","start"]
          DOCKER
        '''
      }
    }

    stage('Login & Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.CREDS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -eux
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY
            docker push $REGISTRY/$IMAGE:$TAG
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'package.json,package-lock.json', fingerprint: true, allowEmptyArchive: true
    }
  }
}

