#!/bin/bash

# DuetWebControl + Nginx Installation Script for Jetson Devices
# Author: Assistant
# Usage: ./install-dwc.sh [DUET_IP] [OPTIONS]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DUET_IP="10.10.10.100"
DWC_DIR="/var/www/dwc"
BUILD_FROM_SOURCE=false
DWC_ZIP_PATH=""
DOMAIN="dwc.local"

# Function to print colored output
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
    echo "Usage: $0 [DUET_IP] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  DUET_IP                 IP address of your Duet 3D printer (default: 10.10.10.100)"
    echo ""
    echo "Options:"
    echo "  -s, --source           Build DWC from source (latest version)"
    echo "  -z, --zip PATH         Use specific DWC zip file"
    echo "  -d, --domain DOMAIN    Set custom domain name (default: dwc.local)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.100                           # Use Duet at 192.168.1.100"
    echo "  $0 192.168.1.100 --source                  # Build from source"
    echo "  $0 192.168.1.100 --zip ./DuetWebControl-SD.zip"
    echo "  $0 192.168.1.100 --domain printer.local"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                BUILD_FROM_SOURCE=true
                shift
                ;;
            -z|--zip)
                DWC_ZIP_PATH="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*|--*)
                log_error "Unknown option $1"
                show_usage
                exit 1
                ;;
            *)
                # First positional argument is DUET_IP
                if [[ -z "${DUET_IP_SET:-}" ]]; then
                    DUET_IP="$1"
                    DUET_IP_SET=true
                else
                    log_error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Function to check if running as root
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Run as a regular user with sudo privileges."
        exit 1
    fi

    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_warning "This script requires sudo privileges. You may be prompted for your password."
    fi
}

# Function to install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    sudo apt update -qq
    
    # Check if nginx is already installed
    if ! command -v nginx &> /dev/null; then
        log_info "Installing nginx..."
        sudo apt install -y nginx
    else
        log_success "Nginx already installed"
    fi
    
    # Install unzip if not present
    if ! command -v unzip &> /dev/null; then
        sudo apt install -y unzip
    fi
    
    # Install Node.js and npm if building from source
    if [[ "$BUILD_FROM_SOURCE" == true ]]; then
        if ! command -v npm &> /dev/null; then
            log_info "Installing Node.js and npm for building from source..."
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt install -y nodejs
        else
            log_success "Node.js and npm already installed"
        fi
    fi
    
    # Install git if building from source
    if [[ "$BUILD_FROM_SOURCE" == true ]] && ! command -v git &> /dev/null; then
        sudo apt install -y git
    fi
}

# Function to create DWC directory
create_dwc_directory() {
    log_info "Creating DuetWebControl directory..."
    sudo mkdir -p "$DWC_DIR"
}

# Function to install DWC from zip
install_dwc_from_zip() {
    local zip_path="$1"
    
    if [[ ! -f "$zip_path" ]]; then
        log_error "DWC zip file not found: $zip_path"
        exit 1
    fi
    
    log_info "Installing DuetWebControl from zip: $zip_path"
    sudo unzip -o "$zip_path" -d "$DWC_DIR"
    log_success "DuetWebControl installed from zip"
}

# Function to build and install DWC from source
install_dwc_from_source() {
    log_info "Cloning DuetWebControl repository..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    git clone https://github.com/Duet3D/DuetWebControl.git
    cd DuetWebControl
    
    log_info "Installing npm dependencies..."
    npm install
    
    log_info "Building DuetWebControl..."
    npm run build
    
    log_info "Deploying built files..."
    sudo rsync -av --delete dist/ "$DWC_DIR/"
    
    log_success "DuetWebControl built and deployed from source"
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Function to find DWC zip automatically
find_dwc_zip() {
    local search_dirs=("." "/home/$USER/Downloads" "/tmp")
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local zip_file=$(find "$dir" -maxdepth 1 -name "*DuetWebControl*SD*.zip" -type f 2>/dev/null | head -n 1)
            if [[ -n "$zip_file" ]]; then
                echo "$zip_file"
                return 0
            fi
        fi
    done
    return 1
}

# Function to install DWC
install_dwc() {
    if [[ "$BUILD_FROM_SOURCE" == true ]]; then
        install_dwc_from_source
    elif [[ -n "$DWC_ZIP_PATH" ]]; then
        install_dwc_from_zip "$DWC_ZIP_PATH"
    else
        # Try to find DWC zip automatically
        local auto_zip
        if auto_zip=$(find_dwc_zip); then
            log_info "Found DWC zip file: $auto_zip"
            install_dwc_from_zip "$auto_zip"
        else
            log_warning "No DWC zip file specified and none found automatically"
            log_info "Building from source instead..."
            BUILD_FROM_SOURCE=true
            install_dwc_from_source
        fi
    fi
}

# Function to create nginx configuration
create_nginx_config() {
    log_info "Creating nginx configuration..."
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Create DWC site configuration
    sudo tee /etc/nginx/sites-available/dwc > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    # Duet backend
    set \$duet "http://$DUET_IP";

    # DuetWebControl root directory
    root $DWC_DIR;
    index index.html;

    # Enable large file uploads (2GB limit)
    client_max_body_size 2G;
    client_body_timeout 600s;
    proxy_read_timeout 600s;
    proxy_send_timeout 600s;

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # Main location block for static files
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Handle .gz files properly (DuetWebControl comes pre-gzipped)
    location ~ \.gz\$ {
        add_header Content-Encoding gzip;
        add_header Vary Accept-Encoding;
        
        location ~ \.css\.gz\$ { add_header Content-Type text/css; }
        location ~ \.js\.gz\$ { add_header Content-Type application/javascript; }
        location ~ \.html\.gz\$ { add_header Content-Type text/html; }
        location ~ \.json\.gz\$ { add_header Content-Type application/json; }
    }

    # Proxy RepRapFirmware API calls (rr_*)
    location ^~ /rr_ {
        proxy_pass \$duet;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_request_buffering off;
    }

    # Proxy machine API calls
    location ^~ /machine {
        proxy_pass \$duet;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_request_buffering off;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    server_tokens off;
}
EOF

    log_success "Nginx site configuration created"
}

# Function to add WebSocket support
add_websocket_support() {
    log_info "Adding WebSocket support to nginx..."
    
    # Check if websocket map already exists
    if grep -q "connection_upgrade" /etc/nginx/nginx.conf; then
        log_success "WebSocket support already configured"
        return
    fi
    
    # Create temporary websocket map file
    cat > /tmp/websocket_map.conf << 'EOF'

    # WebSocket connection upgrade map
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }
EOF

    # Add websocket map to nginx.conf
    sudo sed -i '/http {/r /tmp/websocket_map.conf' /etc/nginx/nginx.conf
    rm -f /tmp/websocket_map.conf
    
    log_success "WebSocket support added"
}

# Function to set permissions
set_permissions() {
    log_info "Setting proper permissions..."
    sudo chown -R www-data:www-data "$DWC_DIR"
    sudo chmod -R 755 "$DWC_DIR"
    log_success "Permissions set"
}

# Function to enable site and reload nginx
enable_site() {
    log_info "Enabling DWC site and reloading nginx..."
    
    # Remove existing symlink if it exists
    sudo rm -f /etc/nginx/sites-enabled/dwc
    
    # Enable site
    sudo ln -s /etc/nginx/sites-available/dwc /etc/nginx/sites-enabled/dwc
    
    # Test nginx configuration
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log_success "Nginx reloaded successfully"
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
}

# Function to setup local DNS
setup_local_dns() {
    log_info "Setting up local DNS..."
    
    # Check if domain already exists in hosts file
    if grep -q "$DOMAIN" /etc/hosts; then
        log_success "Domain $DOMAIN already in hosts file"
    else
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts > /dev/null
        log_success "Added $DOMAIN to hosts file"
    fi
}

# Function to run tests
run_tests() {
    log_info "Running connectivity tests..."
    
    # Test DWC UI
    if curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/" | grep -q "200"; then
        log_success "DWC UI is accessible"
    else
        log_warning "DWC UI test failed - check nginx configuration"
    fi
    
    # Test API endpoint (will timeout if Duet is not reachable, which is expected)
    log_info "Testing API connectivity (may timeout if Duet is not reachable)..."
    if timeout 5 curl -s "http://$DOMAIN/rr_connect?password=" >/dev/null 2>&1; then
        log_success "API proxy is working"
    else
        log_warning "API test timed out - this is normal if Duet is not currently reachable"
    fi
}

# Function to show completion summary
show_summary() {
    echo ""
    echo "=========================================="
    log_success "DuetWebControl Installation Complete!"
    echo "=========================================="
    echo ""
    echo "🌐 Access URLs:"
    echo "   Primary:     http://$DOMAIN/"
    echo "   Alternative: http://$(hostname -I | awk '{print $1}')/"
    echo ""
    echo "🖨️ Duet Configuration:"
    echo "   Duet IP:     $DUET_IP"
    echo "   API Proxy:   Enabled (/rr_*, /machine)"
    echo "   Max Upload:  2GB"
    echo ""
    echo "🔧 Configuration Files:"
    echo "   Nginx Site:  /etc/nginx/sites-available/dwc"
    echo "   DWC Files:   $DWC_DIR"
    echo ""
    echo "📱 Mobile Access:"
    echo "   Add '$DOMAIN' to your router's DNS or use the IP address"
    echo ""
    echo "🧪 Test Commands:"
    echo "   curl \"http://$DOMAIN/rr_connect?password=\""
    echo "   curl \"http://$DOMAIN/rr_gcode?gcode=M115\""
    echo ""
}

# Main execution function
main() {
    echo "=========================================="
    echo "  DuetWebControl + Nginx Installer"
    echo "=========================================="
    echo ""
    
    parse_args "$@"
    check_sudo
    
    log_info "Configuration:"
    log_info "  Duet IP: $DUET_IP"
    log_info "  Domain: $DOMAIN"
    log_info "  Build from source: $BUILD_FROM_SOURCE"
    [[ -n "$DWC_ZIP_PATH" ]] && log_info "  DWC zip: $DWC_ZIP_PATH"
    echo ""
    
    install_dependencies
    create_dwc_directory
    install_dwc
    create_nginx_config
    add_websocket_support
    set_permissions
    enable_site
    setup_local_dns
    run_tests
    show_summary
}

# Run main function with all arguments
main "$@"
