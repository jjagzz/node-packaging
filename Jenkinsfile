pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    // Task 2: build on every GitHub push
    // (if you can't use webhooks, replace with: pollSCM('H/2 * * * *'))
    triggers {
        githubPush()
    }

    environment {
        APP_NAME     = 'node-packaging-demo'
        DEPLOY_DIR   = '/var/lib/jenkins/staging'
        STAGING_PORT = '3001'
    }

    stages {

        // Task 4: Build - install exact dependencies from the lock file
        stage('Build') {
            steps {
                sh 'node -v && npm -v'
                sh 'npm ci'
            }
        }

        // Task 5: Test - a failing test returns non-zero, so the pipeline stops
        stage('Test') {
            steps {
                sh '''
                    node --test \
                      --test-reporter=spec  --test-reporter-destination=stdout \
                      --test-reporter=junit --test-reporter-destination=test-results.xml
                '''
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }

        // Security: fail on high or critical vulnerabilities in production dependencies
        stage('Security Audit') {
            steps {
                sh 'npm audit --omit=dev --audit-level=high'
            }
        }

        // Task 6a: Package the artifact and checksum it
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

        // Task 6b + 7: Deploy to a simulated staging environment
        stage('Deploy') {
            steps {
                // Demo of credential masking: Jenkins prints **** instead of the value
                withCredentials([string(credentialsId: 'deploy-token', variable: 'DEPLOY_TOKEN')]) {
                    sh 'echo "Authenticating with token: $DEPLOY_TOKEN"'
                }
                sh '''
                    # Stop the previous staging instance, if any
                    if [ -f "$DEPLOY_DIR/app.pid" ]; then
                        kill "$(cat "$DEPLOY_DIR/app.pid")" 2>/dev/null || true
                        sleep 1
                    fi

                    # Fresh install of the packaged artifact (not the source tree)
                    rm -rf "$DEPLOY_DIR" && mkdir -p "$DEPLOY_DIR"
                    cp -r config "$DEPLOY_DIR/config"
                    cd "$DEPLOY_DIR"
                    npm init -y > /dev/null
                    npm install "$WORKSPACE"/dist/${APP_NAME}-*.tgz

                    # JENKINS_NODE_COOKIE stops Jenkins killing the app when the build ends
                    APP_ENV=staging APP_CONFIG_DIR="$DEPLOY_DIR/config" JENKINS_NODE_COOKIE=dontKillMe \
                      nohup node node_modules/${APP_NAME}/src/server.js > app.log 2>&1 &
                    echo $! > app.pid

                    sleep 3
                    curl -f http://localhost:${STAGING_PORT}/health
                '''
            }
        }
    }

    post {
        success { echo 'Pipeline finished successfully.' }
        failure { echo 'Pipeline failed. Check the failing stage log.' }
    }
}
