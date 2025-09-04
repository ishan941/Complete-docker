pipeline {
    // Define the agent where the pipeline will run
    // 'any' means Jenkins can use any available agent
    agent any
    
    // Environment variables available throughout the pipeline
    environment {
        // Docker image name and tag
        DOCKER_IMAGE = 'react-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        
        // Docker registry (uncomment and modify if using a registry)
        // DOCKER_REGISTRY = 'your-registry.com'
        // DOCKER_CREDENTIALS = 'docker-hub-credentials'
        
        // Node.js version for compatibility
        NODE_VERSION = '20'
    }
    
    // Define the stages of the pipeline
    stages {
        
        // Stage 1: Checkout source code from Git repository
        stage('Checkout') {
            steps {
                echo 'Checking out source code from Git repository...'
                // Jenkins automatically checks out the code when using SCM
                // This step is mainly for logging purposes
                checkout scm
            }
        }
        
        // Stage 2: Install dependencies and run tests
        stage('Install Dependencies & Test') {
            steps {
                echo 'Installing Node.js dependencies...'
                
                // Install Node.js dependencies
                sh '''
                    echo "Current directory: $(pwd)"
                    echo "Listing files:"
                    ls -la
                    
                    # Install dependencies
                    npm install
                    
                    # Run tests (if you have any)
                    # npm test
                    
                    # Run linting (if configured)
                    # npm run lint
                '''
            }
        }
        
        // Stage 3: Build the React application
        stage('Build Application') {
            steps {
                echo 'Building React application...'
                
                sh '''
                    # Build the React app for production
                    npm run build
                    
                    # List the build directory to verify build success
                    echo "Build completed. Contents of dist/build directory:"
                    ls -la dist/ || ls -la build/ || echo "No dist or build directory found"
                '''
            }
        }
        
        // Stage 4: Build Docker image
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                
                script {
                    // Build Docker image using the Dockerfile
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    
                    // Also tag as 'latest' for convenience
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        // Stage 5: Test Docker image (optional)
        stage('Test Docker Image') {
            steps {
                echo 'Testing Docker image...'
                
                script {
                    // Run a quick test to ensure the container starts properly
                    sh '''
                        # Start container in detached mode
                        docker run -d --name test-container -p 5174:5173 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        # Wait a few seconds for the container to start
                        sleep 10
                        
                        # Check if container is running
                        docker ps | grep test-container
                        
                        # Optional: Test if the application responds
                        # curl -f http://localhost:5174 || echo "Application not responding yet"
                        
                        # Clean up test container
                        docker stop test-container
                        docker rm test-container
                    '''
                }
            }
        }
        
        // Stage 6: Push to Docker Registry (optional - uncomment if needed)
    
        stage('Push to Registry') {
            steps {
                echo 'Pushing Docker image to registry...'
                
                script {
                    // Login to Docker registry and push
                    docker.withRegistry('https://index.docker.io/v1/', env.DOCKER_CREDENTIALS) {
                        def dockerImage = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        dockerImage.push()
                        dockerImage.push("latest")
                    }
                }
            }
        }
        
        
        // Stage 7: Deploy (optional - modify according to your deployment strategy)
        
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                
                sh '''
                    # Example deployment using docker-compose
                    docker-compose down || true
                    docker-compose up -d
                    
                    # Or deploy to Kubernetes
                    # kubectl apply -f k8s-deployment.yaml
                    
                    # Or deploy to a server
                    # ssh user@server "docker pull ${DOCKER_IMAGE}:${DOCKER_TAG} && docker-compose up -d"
                '''
            }
        }
        
    }
    
    // Post-build actions that run regardless of build result
    post {
        // Actions to run when build is successful
        success {
            echo 'Pipeline completed successfully! 🎉'
            
            // Optional: Send notification
            // emailext (
            //     subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "The build completed successfully.",
            //     to: "your-email@example.com"
            // )
        }
        
        // Actions to run when build fails
        failure {
            echo 'Pipeline failed! ❌'
            
            // Optional: Send failure notification
            // emailext (
            //     subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "The build failed. Please check the console output.",
            //     to: "your-email@example.com"
            // )
        }
        
        // Actions to run always (cleanup)
        always {
            echo 'Cleaning up...'
            
            // Clean up Docker images to save space
            sh '''
                # Remove old images (keep last 5 builds)
                docker images ${DOCKER_IMAGE} --format "table {{.Tag}}" | grep -E "^[0-9]+$" | sort -nr | tail -n +6 | xargs -I {} docker rmi ${DOCKER_IMAGE}:{} || true
                
                # Clean up dangling images
                docker image prune -f || true
            '''
            
            // Archive build artifacts (optional)
            // archiveArtifacts artifacts: 'dist/**/*', allowEmptyArchive: true
            
            // Publish test results (if you have tests)
            // publishTestResults testResultsPattern: 'test-results.xml'
        }
    }
}

/*
JENKINS PIPELINE EXPLANATION:

1. PIPELINE STRUCTURE:
   - pipeline: Main block that defines the entire pipeline
   - agent: Defines where the pipeline runs (any available Jenkins agent)
   - environment: Global variables used throughout the pipeline
   - stages: Sequential steps of the build process
   - post: Actions that run after the pipeline completes

2. STAGES BREAKDOWN:
   
   a) Checkout: 
      - Gets the source code from your Git repository
      - Jenkins does this automatically for SCM-triggered builds
   
   b) Install Dependencies & Test:
      - Runs npm install to get all required packages
      - Optionally runs tests and linting
   
   c) Build Application:
      - Compiles the React app for production
      - Creates optimized static files
   
   d) Build Docker Image:
      - Creates a Docker image using your Dockerfile
      - Tags it with the build number and 'latest'
   
   e) Test Docker Image:
      - Starts a test container to verify the image works
      - Performs basic health checks
      - Cleans up test resources
   
   f) Push to Registry (commented):
      - Pushes the image to a Docker registry like Docker Hub
      - Requires authentication credentials
   
   g) Deploy (commented):
      - Example deployment strategies
      - Can be customized for your specific deployment needs

3. ENVIRONMENT VARIABLES:
   - DOCKER_IMAGE: Name of your Docker image
   - DOCKER_TAG: Uses Jenkins BUILD_NUMBER for versioning
   - NODE_VERSION: Ensures Node.js compatibility

4. POST ACTIONS:
   - success: Runs when pipeline succeeds
   - failure: Runs when pipeline fails
   - always: Runs regardless of outcome (cleanup)

5. CUSTOMIZATION TIPS:
   - Uncomment registry and deployment stages as needed
   - Add your own test commands
   - Configure email notifications
   - Add security scanning stages
   - Integrate with monitoring tools

6. PREREQUISITES:
   - Jenkins with Docker pipeline plugin installed
   - Docker available on Jenkins agents
   - Node.js available on Jenkins agents
   - Proper Jenkins credentials configured (for registry/deployment)

This pipeline provides a complete CI/CD workflow for your React Docker application!
*/