#!/bin/bash

# =============================================================================
# JENKINS COMPLETE SETUP SCRIPT FOR MACOS/LINUX
# =============================================================================
# This script will install and configure Jenkins with all necessary plugins
# and tools for React Docker CI/CD pipeline
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected Linux"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Install Homebrew (macOS only)
install_homebrew() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
            
            log_success "Homebrew installed successfully"
        else
            log_info "Homebrew already installed"
        fi
    fi
}

# Install Java (required for Jenkins)
install_java() {
    log_info "Installing Java..."
    
    if [[ "$OS" == "macos" ]]; then
        # Install Java using Homebrew
        if ! java -version &> /dev/null; then
            brew install openjdk@17
            
            # Add Java to PATH
            echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
            export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
            
            # Set JAVA_HOME
            echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17"' >> ~/.zshrc
            export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
            
            log_success "Java 17 installed successfully"
        else
            log_info "Java already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Install Java on Linux
        if ! java -version &> /dev/null; then
            sudo apt update
            sudo apt install -y openjdk-17-jdk
            
            # Set JAVA_HOME
            echo 'export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"' >> ~/.bashrc
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
            
            log_success "Java 17 installed successfully"
        else
            log_info "Java already installed"
        fi
    fi
}

# Install Jenkins
install_jenkins() {
    log_info "Installing Jenkins..."
    
    if [[ "$OS" == "macos" ]]; then
        # Install Jenkins using Homebrew
        if ! brew list jenkins-lts &> /dev/null; then
            brew install jenkins-lts
            log_success "Jenkins installed successfully"
        else
            log_info "Jenkins already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Install Jenkins on Linux
        if ! command -v jenkins &> /dev/null; then
            # Add Jenkins repository
            curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
            
            echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
            
            # Update package index and install Jenkins
            sudo apt update
            sudo apt install -y jenkins
            
            # Start and enable Jenkins service
            sudo systemctl start jenkins
            sudo systemctl enable jenkins
            
            log_success "Jenkins installed and started successfully"
        else
            log_info "Jenkins already installed"
        fi
    fi
}

# Install Node.js and npm
install_nodejs() {
    log_info "Installing Node.js..."
    
    if [[ "$OS" == "macos" ]]; then
        if ! command -v node &> /dev/null; then
            brew install node@20
            
            # Add Node.js to PATH
            echo 'export PATH="/opt/homebrew/opt/node@20/bin:$PATH"' >> ~/.zshrc
            export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
            
            log_success "Node.js 20 installed successfully"
        else
            log_info "Node.js already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if ! command -v node &> /dev/null; then
            # Install Node.js using NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            
            log_success "Node.js 20 installed successfully"
        else
            log_info "Node.js already installed"
        fi
    fi
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    if [[ "$OS" == "macos" ]]; then
        if ! command -v docker &> /dev/null; then
            # For macOS, we'll install Docker Desktop using Homebrew
            brew install --cask docker
            
            log_warning "Docker Desktop installed. Please start Docker Desktop manually and complete the setup."
            log_warning "You may need to restart your terminal after Docker Desktop is running."
        else
            log_info "Docker already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if ! command -v docker &> /dev/null; then
            # Install Docker on Linux
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            
            # Start and enable Docker service
            sudo systemctl start docker
            sudo systemctl enable docker
            
            log_success "Docker installed successfully"
            log_warning "You need to log out and log back in for Docker group changes to take effect"
        else
            log_info "Docker already installed"
        fi
    fi
}

# Install Git (if not already installed)
install_git() {
    log_info "Checking Git installation..."
    
    if ! command -v git &> /dev/null; then
        if [[ "$OS" == "macos" ]]; then
            brew install git
        elif [[ "$OS" == "linux" ]]; then
            sudo apt install -y git
        fi
        log_success "Git installed successfully"
    else
        log_info "Git already installed"
    fi
}

# Start Jenkins service
start_jenkins() {
    log_info "Starting Jenkins service..."
    
    if [[ "$OS" == "macos" ]]; then
        # Start Jenkins using Homebrew services
        brew services start jenkins-lts
        log_success "Jenkins service started"
    elif [[ "$OS" == "linux" ]]; then
        # Jenkins should already be started during installation
        sudo systemctl status jenkins --no-pager
        log_success "Jenkins service is running"
    fi
    
    log_info "Waiting for Jenkins to start up..."
    sleep 30
}

# Get Jenkins initial admin password
get_jenkins_password() {
    log_info "Getting Jenkins initial admin password..."
    
    if [[ "$OS" == "macos" ]]; then
        JENKINS_HOME="/opt/homebrew/var/lib/jenkins"
    elif [[ "$OS" == "linux" ]]; then
        JENKINS_HOME="/var/lib/jenkins"
    fi
    
    if [[ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]]; then
        JENKINS_PASSWORD=$(sudo cat "$JENKINS_HOME/secrets/initialAdminPassword" 2>/dev/null || cat "$JENKINS_HOME/secrets/initialAdminPassword" 2>/dev/null)
        log_success "Jenkins initial admin password: $JENKINS_PASSWORD"
        echo "Save this password - you'll need it for initial setup!"
    else
        log_warning "Could not find Jenkins initial admin password file"
        log_info "You may need to check: $JENKINS_HOME/secrets/initialAdminPassword"
    fi
}

# Install Jenkins CLI
install_jenkins_cli() {
    log_info "Installing Jenkins CLI..."
    
    # Wait for Jenkins to be fully available
    log_info "Waiting for Jenkins to be fully available..."
    sleep 60
    
    # Download Jenkins CLI
    if curl -sSL http://localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar; then
        log_success "Jenkins CLI downloaded successfully"
    else
        log_warning "Could not download Jenkins CLI - Jenkins might not be fully started yet"
    fi
}

# Create Jenkins job for the project
create_jenkins_job() {
    log_info "Instructions for creating Jenkins job will be provided at the end"
}

# Display setup completion message
display_completion_message() {
    echo ""
    echo "============================================================================="
    log_success "JENKINS SETUP COMPLETED SUCCESSFULLY!"
    echo "============================================================================="
    echo ""
    log_info "Next Steps:"
    echo ""
    echo "1. 🌐 Open Jenkins in your browser:"
    echo "   http://localhost:8080"
    echo ""
    echo "2. 🔐 Use the initial admin password to unlock Jenkins:"
    if [[ -n "$JENKINS_PASSWORD" ]]; then
        echo "   Password: $JENKINS_PASSWORD"
    else
        echo "   Check: $JENKINS_HOME/secrets/initialAdminPassword"
    fi
    echo ""
    echo "3. 📦 Install suggested plugins (click 'Install suggested plugins')"
    echo ""
    echo "4. 👤 Create your first admin user"
    echo ""
    echo "5. 🔧 Install additional required plugins:"
    echo "   - Go to 'Manage Jenkins' > 'Manage Plugins'"
    echo "   - Install these plugins:"
    echo "     • Docker Pipeline"
    echo "     • NodeJS Plugin"
    echo "     • Git Plugin (usually pre-installed)"
    echo "     • GitHub Integration Plugin"
    echo "     • Blue Ocean (optional, for better UI)"
    echo ""
    echo "6. 🛠 Configure Global Tools:"
    echo "   - Go to 'Manage Jenkins' > 'Global Tool Configuration'"
    echo "   - Configure NodeJS:"
    echo "     • Add NodeJS installation"
    echo "     • Name: 'NodeJS-20'"
    echo "     • Version: '20.x.x'"
    echo "   - Configure Docker (if not auto-detected):"
    echo "     • Add Docker installation"
    echo "     • Name: 'Docker'"
    echo ""
    echo "7. 📁 Create a new Pipeline job:"
    echo "   - Click 'New Item'"
    echo "   - Enter name: 'react-app-pipeline'"
    echo "   - Select 'Pipeline'"
    echo "   - In Pipeline section, select 'Pipeline script from SCM'"
    echo "   - SCM: Git"
    echo "   - Repository URL: https://github.com/ishan941/Complete-docker.git"
    echo "   - Script Path: jenkinsfile"
    echo ""
    echo "8. 🚀 Run your first build:"
    echo "   - Click 'Build Now' in your pipeline job"
    echo ""
    echo "============================================================================="
    log_info "TROUBLESHOOTING TIPS:"
    echo "============================================================================="
    echo ""
    echo "🐛 If Jenkins doesn't start:"
    if [[ "$OS" == "macos" ]]; then
        echo "   brew services restart jenkins-lts"
    elif [[ "$OS" == "linux" ]]; then
        echo "   sudo systemctl restart jenkins"
    fi
    echo ""
    echo "🐛 If Docker isn't working:"
    echo "   - Make sure Docker Desktop is running (macOS)"
    echo "   - Check Docker service status (Linux): sudo systemctl status docker"
    echo "   - Verify Docker permissions: docker run hello-world"
    echo ""
    echo "🐛 If Node.js isn't found in Jenkins:"
    echo "   - Configure NodeJS in Global Tool Configuration"
    echo "   - Make sure the NodeJS plugin is installed"
    echo ""
    echo "🐛 For Jenkins logs:"
    if [[ "$OS" == "macos" ]]; then
        echo "   tail -f /opt/homebrew/var/log/jenkins/jenkins.log"
    elif [[ "$OS" == "linux" ]]; then
        echo "   sudo journalctl -u jenkins -f"
    fi
    echo ""
    echo "============================================================================="
    log_success "Happy CI/CD with Jenkins! 🎉"
    echo "============================================================================="
}

# Main execution function
main() {
    echo "============================================================================="
    log_info "JENKINS COMPLETE SETUP SCRIPT"
    echo "============================================================================="
    echo ""
    log_info "This script will install and configure:"
    echo "  ✓ Java 17 (required for Jenkins)"
    echo "  ✓ Jenkins LTS"
    echo "  ✓ Node.js 20 (for React builds)"
    echo "  ✓ Docker (for containerization)"
    echo "  ✓ Git (for source control)"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    echo ""
    log_info "Starting installation process..."
    echo ""
    
    # Run installation steps
    check_root
    detect_os
    
    if [[ "$OS" == "macos" ]]; then
        install_homebrew
    fi
    
    install_java
    install_nodejs
    install_docker
    install_git
    install_jenkins
    start_jenkins
    get_jenkins_password
    install_jenkins_cli
    create_jenkins_job
    
    display_completion_message
}

# Run the main function
main "$@"
