pipeline {
  agent any
  options { timeout(time: 90, unit: 'MINUTES') }

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
      steps { sh 'npm ci $NPM_OPTS && npm test' }
    }

    // Prépare le code dans un volume lisible par les scanners (socket Docker partagé)
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
        sh 'docker run --rm -v scan-src:/src semgrep/semgrep semgrep scan --config auto --error /src'
      }
    }

    // Q66 : npm audit
    stage('npm audit') {
      steps {
        sh 'npm audit --audit-level=critical'
        dir('api') { sh 'npm audit --audit-level=critical' }
      }
    }

    // Q67 : Dependency-Check (premier lancement très long : base NVD)
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
