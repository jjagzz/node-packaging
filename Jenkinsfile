pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        githubPush()   // or: pollSCM('H/2 * * * *')
    }

    environment {
        APP_NAME      = 'node-packaging-demo'
        REGISTRY_USER = 'jjagzz'      // <-- change this
        IMAGE_NAME    = "${REGISTRY_USER}/${APP_NAME}"
        CONTAINER     = 'node-staging'
        STAGING_PORT  = '3001'
    }

    stages {

        stage('Build') {
            steps {
                sh 'node -v && npm -v'
                sh 'npm ci'
            }
        }

        stage('Test') {
            steps {
                sh '''
                    node --test \
                      --test-reporter=spec  --test-reporter-destination=stdout \
                      --test-reporter=junit --test-reporter-destination=test-results.xml
                '''
            }
            post {
                always { junit 'test-results.xml' }
            }
        }

        stage('Security Audit') {
            steps {
                sh 'npm audit --omit=dev --audit-level=high'
            }
        }

        stage('Package') {
            steps {
                sh '''
                    rm -rf dist && mkdir dist
                    npm pack --pack-destination dist
                    cd dist
                    sha256sum *.tgz > checksum.sha256
                    sha256sum -c checksum.sha256
                '''
                archiveArtifacts artifacts: 'dist/*', fingerprint: true
            }
        }

        // NEW: build the container image from the Dockerfile
        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t "$IMAGE_NAME:$BUILD_NUMBER" -t "$IMAGE_NAME:latest" .
                    docker images "$IMAGE_NAME"
                '''
            }
        }

        // NEW: push the image to Docker Hub using Jenkins credentials
        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DOCKER_USER',
                                                  passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        trap 'docker logout' EXIT
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push "$IMAGE_NAME:$BUILD_NUMBER"
                        docker push "$IMAGE_NAME:latest"
                    '''
                }
            }
        }

        // UPDATED: pull the pushed image and run it as a container
        stage('Deploy') {
            steps {
                withCredentials([string(credentialsId: 'deploy-token', variable: 'DEPLOY_TOKEN')]) {
                    sh 'echo "Authenticating with token: $DEPLOY_TOKEN"'   // masked as ****
                }
                sh '''
                    docker pull "$IMAGE_NAME:$BUILD_NUMBER"
                    docker rm -f "$CONTAINER" 2>/dev/null || true

                    docker run -d --name "$CONTAINER" --restart unless-stopped \
                      -p "$STAGING_PORT:3000" \
                      -e APP_ENV=staging -e PORT=3000 \
                      -v "$WORKSPACE/config:/app/config:ro" \
                      "$IMAGE_NAME:$BUILD_NUMBER"

                    # Wait up to 60s for Docker's HEALTHCHECK to report healthy
                    for i in $(seq 1 12); do
                        status=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER")
                        echo "Health: $status"
                        [ "$status" = "healthy" ] && break
                        sleep 5
                    done
                    if [ "$status" != "healthy" ]; then
                        docker logs "$CONTAINER"
                        exit 1
                    fi

                    curl -f "http://localhost:$STAGING_PORT/"
                '''
            }
        }
    }

    post {
        always  { sh 'docker image prune -f || true' }   // free disk space
        success { echo 'Pipeline finished successfully.' }
        failure { echo 'Pipeline failed. Check the failing stage log.' }
    }
}
