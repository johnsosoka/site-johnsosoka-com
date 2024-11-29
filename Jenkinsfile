pipeline {
    agent {
        docker {
            label 'jekyll-agent'
            image 'jekyll/jekyll'
//             args '-u root' // Optional: Run as root user inside the container
        }
    }
    stages {
        stage('Build Jekyll Site') {
            steps {
                script {
                    dir('website') {
                        sh 'bundle install'
                        sh 'bundle exec jekyll build'
                    }
                }
            }
        }
    }
}
