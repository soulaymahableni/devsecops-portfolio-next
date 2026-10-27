pipeline {
  agent any
  options { timeout(time: 120, unit: 'MINUTES') }

  environment {
    NPM_OPTS = '--fetch-timeout=600000 --fetch-retries=5'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script { env.SHA = sh(returnStdout: true, script: 'git rev-parse --short=7 HEAD').trim() }
        echo "Git SHA : ${env.SHA}"
      }
    }

    // Q61 : tests
    stage('Tests API') {
      steps { dir('api') { sh 'npm ci $NPM_OPTS && npx prisma generate && npm test' } }
    }

    stage('Tests Frontend') {
      steps {
        sh '''
          docker rm -f fe-test >/dev/null 2>&1 || true
          docker create --name fe-test -w /app node:22-alpine \
            sh -c "npm ci --fetch-timeout=600000 --fetch-retries=5 && npm test"
          tar --exclude=node_modules --exclude=.next --exclude=.git -cf - . | docker cp - fe-test:/app
          docker start -a fe-test
          docker rm fe-test
        '''
      }
    }

    stage('Préparation scanners') {
      steps {
        sh '''
          docker rm -f src-holder >/dev/null 2>&1 || true
          docker volume rm -f scan-src >/dev/null 2>&1 || true
          docker volume create scan-src
          docker create --name src-holder -v scan-src:/src alpine true
          tar --exclude=node_modules --exclude=.next -cf - . | docker cp - src-holder:/src
          docker rm src-holder
        '''
      }
    }

    // Q64 : secrets
    stage('Gitleaks') {
      steps {
        sh 'docker run --rm -v scan-src:/src zricethezav/gitleaks:latest detect --source /src --no-git --redact --exit-code 1'
      }
    }

    // Q65 : SAST
    stage('Semgrep') {
      steps {
        sh '''
          docker rm -f semgrep-run >/dev/null 2>&1 || true
          docker create --name semgrep-run -w /src python:3.12-slim \
            sh -c "pip install --no-cache-dir --default-timeout=300 --retries 10 semgrep && semgrep scan --config auto --error --exclude node_modules --exclude .next /src"
          tar --exclude=node_modules --exclude=.next --exclude=.git -cf - . | docker cp - semgrep-run:/src
          docker start -a semgrep-run
          docker rm semgrep-run
        '''
      }
    }

    // Q66 : npm audit
    stage('npm audit') {
      steps {
        sh 'npm audit --audit-level=critical'
        dir('api') { sh 'npm audit --audit-level=critical' }
      }
    }

    // Q67 : Dependency-Check
    stage('Dependency-Check') {
      steps {
        sh '''
          docker run --rm -v scan-src:/src -v dc-data:/usr/share/dependency-check/data \
            -v scan-report:/report owasp/dependency-check:latest \
            --scan /src --failOnCVSS 9 --format HTML --out /report
        '''
      }
    }

    // Q62-63 : images taguées avec le SHA
    stage('Build images') {
      steps {
        sh 'docker build -t devsecops-portfolio:$SHA .'
        sh 'docker build -t devsecops-api:$SHA ./api'
        sh 'docker images | grep -E "devsecops-(portfolio|api)" | grep $SHA'
      }
    }

    // Q68-69 : Trivy, échec si CRITICAL
    stage('Trivy') {
      steps {
        sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL --exit-code 1 devsecops-portfolio:$SHA'
        sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL --exit-code 1 devsecops-api:$SHA'
      }
    }
  }
}
