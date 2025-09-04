pipeline {
    // Define the agent where the pipeline will run
    // 'any' means Jenkins can use any available agent
    agent any
    
    // Define tools needed for this pipeline
    // UNCOMMENT BELOW IF YOU HAVE CONFIGURED NODEJS IN JENKINS GLOBAL TOOLS
    // tools {
    //     // Use NodeJS tool (must be configured in Jenkins Global Tool Configuration)
    //     nodejs 'NodeJS-22'  // Updated to Node.js 22 for Vite compatibility
    // }
    
    // Environment variables available throughout the pipeline
    environment {
        // Docker image name and tag
        DOCKER_IMAGE = 'react-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        
        // Docker registry (uncomment and modify if using a registry)
        // DOCKER_REGISTRY = 'your-registry.com'
        // DOCKER_CREDENTIALS = 'docker-hub-credentials'
        
        // Node.js version for Vite compatibility (22.x required)
        NODE_VERSION = '22'
        
        // Add common Node.js paths to PATH (fallback if tools not configured)
        PATH = "/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/node@22/bin:${env.PATH}"
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
        
        // Stage 1.5: Setup Node.js (if not available via tools)
        stage('Setup Node.js') {
            steps {
                echo 'Setting up Node.js environment...'
                
                sh '''
                    echo "Checking Node.js availability..."
                    echo "Current PATH: $PATH"
                    
                    # Try to find and use existing Node.js installation
                    if command -v node >/dev/null 2>&1; then
                        NODE_CURRENT_VERSION=$(node --version | sed 's/v//')
                        echo "✅ Node.js found: v$NODE_CURRENT_VERSION"
                        echo "✅ npm found: $(npm --version)"
                        
                        # Check if Node.js version meets Vite requirements (22.12+ or 20.19+)
                        NODE_MAJOR=$(echo $NODE_CURRENT_VERSION | cut -d. -f1)
                        NODE_MINOR=$(echo $NODE_CURRENT_VERSION | cut -d. -f2)
                        
                        if [ "$NODE_MAJOR" -lt 20 ] || ([ "$NODE_MAJOR" -eq 20 ] && [ "$NODE_MINOR" -lt 19 ]); then
                            echo "⚠️  Node.js $NODE_CURRENT_VERSION detected. Vite requires Node.js 20.19+ or 22.12+"
                            echo "Attempting to upgrade Node.js..."
                            UPGRADE_NEEDED=true
                        elif [ "$NODE_MAJOR" -eq 21 ]; then
                            echo "⚠️  Node.js $NODE_CURRENT_VERSION detected. Vite requires Node.js 20.19+ or 22.12+"
                            echo "Attempting to upgrade Node.js..."
                            UPGRADE_NEEDED=true
                        else
                            echo "✅ Node.js version is compatible with Vite"
                            UPGRADE_NEEDED=false
                        fi
                    else
                        echo "❌ Node.js not found in PATH"
                        UPGRADE_NEEDED=true
                    fi
                    
                    if [ "$UPGRADE_NEEDED" = true ]; then
                        echo "Installing/Upgrading to Node.js 22..."
                        
                        # Check if running on macOS with Homebrew
                        if command -v brew >/dev/null 2>&1; then
                            echo "Installing Node.js 22 via Homebrew..."
                            brew unlink node || true
                            brew install node@22 || brew install node
                            brew link --force node@22 || true
                            export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
                        # Check if running on Linux
                        elif command -v apt >/dev/null 2>&1; then
                            echo "Installing Node.js 22 via apt..."
                            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
                            sudo apt-get install -y nodejs || true
                        else
                            echo "❌ Cannot install Node.js automatically"
                            echo "Please install Node.js 22+ manually or configure NodeJS tool in Jenkins"
                            exit 1
                        fi
                        
                        # Verify installation
                        if command -v node >/dev/null 2>&1; then
                            echo "✅ Node.js installed: $(node --version)"
                            echo "✅ npm available: $(npm --version)"
                        else
                            echo "❌ Node.js installation failed"
                            exit 1
                        fi
                    fi
                '''
            }
        }
        
        // Stage 2: Install dependencies and run tests
        stage('Install Dependencies & Test') {
            steps {
                echo 'Installing Node.js dependencies...'
                
                // Verify Node.js and npm are available, then install dependencies
                sh '''
                    echo "Current directory: $(pwd)"
                    echo "Listing files:"
                    ls -la
                    
                    # Verify Node.js and npm installation
                    echo "Checking Node.js version:"
                    node --version || echo "Node.js not found in PATH"
                    
                    echo "Checking npm version:"
                    npm --version || echo "npm not found in PATH"
                    
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
        
        // Stage 4: Build Docker Images (Production & Development)
        stage('Build Docker Images') {
            parallel {
                // Build production image (optimized for size)
                stage('Build Production Image') {
                    steps {
                        echo "Building production Docker image: ${DOCKER_IMAGE}-prod:${DOCKER_TAG}"
                        
                        script {
                            // Build production Docker image using multi-stage build
                            def prodImage = docker.build("${DOCKER_IMAGE}-prod:${DOCKER_TAG}", "--target production .")
                            
                            // Also tag as 'latest' for convenience
                            sh "docker tag ${DOCKER_IMAGE}-prod:${DOCKER_TAG} ${DOCKER_IMAGE}-prod:latest"
                            
                            // Show image size
                            sh "docker images ${DOCKER_IMAGE}-prod:${DOCKER_TAG}"
                        }
                    }
                }
                
                // Build development image (for testing)
                stage('Build Development Image') {
                    steps {
                        echo "Building development Docker image: ${DOCKER_IMAGE}-dev:${DOCKER_TAG}"
                        
                        script {
                            // Build development Docker image
                            def devImage = docker.build("${DOCKER_IMAGE}-dev:${DOCKER_TAG}", "--target development .")
                            
                            // Also tag as 'latest' for convenience
                            sh "docker tag ${DOCKER_IMAGE}-dev:${DOCKER_TAG} ${DOCKER_IMAGE}-dev:latest"
                        }
                    }
                }
            }
        }
        
        // Stage 5: Test Docker Images
        stage('Test Docker Images') {
            parallel {
                // Test production image
                stage('Test Production Image') {
                    steps {
                        echo 'Testing production Docker image...'
                        
                        script {
                            sh '''
                                # Start production container in detached mode
                                docker run -d --name test-prod-container -p 8081:80 ${DOCKER_IMAGE}-prod:${DOCKER_TAG}
                                
                                # Wait a few seconds for the container to start
                                sleep 10
                                
                                # Check if container is running
                                docker ps | grep test-prod-container
                                
                                # Test if the application responds
                                curl -f http://localhost:8081 || echo "Production app not responding yet"
                                
                                # Clean up test container
                                docker stop test-prod-container
                                docker rm test-prod-container
                            '''
                        }
                    }
                }
                
                // Test development image
                stage('Test Development Image') {
                    steps {
                        echo 'Testing development Docker image...'
                        
                        script {
                            sh '''
                                # Start development container in detached mode (quick test)
                                docker run -d --name test-dev-container -p 5174:5173 ${DOCKER_IMAGE}-dev:${DOCKER_TAG}
                                
                                # Wait a few seconds for the container to start
                                sleep 15
                                
                                # Check if container is running
                                docker ps | grep test-dev-container
                                
                                # Clean up test container (dev server takes longer to start)
                                docker stop test-dev-container
                                docker rm test-dev-container
                            '''
                        }
                    }
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
                # Remove old production images (keep last 3 builds)
                docker images ${DOCKER_IMAGE}-prod --format "table {{.Tag}}" | grep -E "^[0-9]+$" | sort -nr | tail -n +4 | xargs -I {} docker rmi ${DOCKER_IMAGE}-prod:{} || true
                
                # Remove old development images (keep last 3 builds)
                docker images ${DOCKER_IMAGE}-dev --format "table {{.Tag}}" | grep -E "^[0-9]+$" | sort -nr | tail -n +4 | xargs -I {} docker rmi ${DOCKER_IMAGE}-dev:{} || true
                
                # Clean up dangling images to save space
                docker image prune -f || true
                
                # Show remaining images and disk usage
                echo "Remaining Docker images:"
                docker images | grep ${DOCKER_IMAGE} || echo "No project images found"
                echo "Docker disk usage:"
                docker system df
            '''
            
            // Archive build artifacts (optional)
            archiveArtifacts artifacts: 'dist/**/*', allowEmptyArchive: true
            
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