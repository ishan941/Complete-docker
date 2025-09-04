pipeline{
    agent any
    stages{
        stage('Print'){
            steps{
                echo 'Hello, jenkins'
            }
        }
        stage('Checkout'){
            steps{
                echo 'Checking out source code..'
                checkout scm
                echo 'Checkout Source code completed.'
            }
        }
        stage('Build'){
            steps{
                echo 'Building the application ...'
                sh 'docker-compose build'
                echo 'Build Completed.'
                currentBuild.result = 'SUCCESS'
                echo 'Build stage completed.'
            }
        }
        stage('Deploy'){
            steps{
                echo 'Deploying the application ...'
                sh 'docker-compose up -d'
                echo 'Deployment Completed.'
                currentBuild.result = 'SUCCESS'
                echo 'Deploy stage completed.'
            }
        }
    }
}
  