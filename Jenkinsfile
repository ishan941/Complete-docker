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
            }
        }
    }
}
  