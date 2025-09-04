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
            
            }
        }
        stage('Deploy'){
            steps{
                echo 'Deploying the application ...'
                sh 'docker-compose up -d'
                echo 'Deployment Completed.'
              
            }
        }
    }
}
  