# DuetWebControl Automated Installer

A single-script installer for DuetWebControl + Nginx on Jetson devices (or any ARM64/x64 Linux system).

## 🚀 Quick Start

```bash
# Download the script
curl -O https://your-server/install-dwc.sh
chmod +x install-dwc.sh

# Basic installation with default settings
./install-dwc.sh 192.168.1.100

# Build from latest source
./install-dwc.sh 192.168.1.100 --source

# Use specific DWC zip file
./install-dwc.sh 192.168.1.100 --zip ./DuetWebControl-SD.zip

# Custom domain name
./install-dwc.sh 192.168.1.100 --domain printer.local
```

## 📋 Features

✅ **Automated Installation**: One command setup  
✅ **Multiple Install Methods**: Pre-built zip or build from source  
✅ **Smart Detection**: Auto-finds DWC zip files  
✅ **Nginx Optimization**: Pre-configured for 3D printing  
✅ **WebSocket Support**: Real-time printer communication  
✅ **Large File Uploads**: 2GB limit for G-code files  
✅ **Security Headers**: Production-ready configuration  
✅ **Error Handling**: Comprehensive error checking  

## 🔧 Requirements

- **OS**: Ubuntu 20.04+ (tested on Jetson devices)
- **User**: Regular user with sudo privileges
- **Network**: Internet access for package downloads
- **Storage**: ~100MB free space

## 📖 Usage Examples

### Basic Installation
```bash
./install-dwc.sh 10.10.10.100
```
Access: `http://dwc.local/`

### Build Latest Version from GitHub
```bash
./install-dwc.sh 10.10.10.100 --source
```

### Use Existing DWC Zip
```bash
./install-dwc.sh 10.10.10.100 --zip ~/Downloads/DuetWebControl-SD.zip
```

### Custom Domain
```bash
./install-dwc.sh 10.10.10.100 --domain my-printer.local
```
Access: `http://my-printer.local/`

## 🌐 Access Methods

After installation, access DuetWebControl via:

- **Primary URL**: `http://dwc.local/` (or your custom domain)
- **IP Access**: `http://[JETSON_IP]/`
- **Mobile**: Same URLs work on phones/tablets

## 🔄 Re-running the Script

The script is **idempotent** - safe to run multiple times:
- Updates existing installation
- Changes Duet IP address
- Rebuilds from source if requested

## 📁 File Locations

- **Nginx Config**: `/etc/nginx/sites-available/dwc`
- **DWC Files**: `/var/www/dwc/`
- **Logs**: Check `journalctl -u nginx`

## 🧪 Testing Installation

```bash
# Test DWC UI
curl -I http://dwc.local/

# Test API (requires Duet to be reachable)
curl "http://dwc.local/rr_connect?password="
curl "http://dwc.local/rr_gcode?gcode=M115"
```

## 🐛 Troubleshooting

### DWC UI Not Loading
```bash
sudo nginx -t                    # Check config
sudo systemctl status nginx     # Check service
sudo systemctl reload nginx     # Reload config
```

### API Not Working
- Verify Duet IP is correct and reachable
- Check firewall settings on Duet
- Ensure Duet is running RepRapFirmware 3.0+

### Permission Issues
```bash
sudo chown -R www-data:www-data /var/www/dwc
sudo chmod -R 755 /var/www/dwc
```

## 🔧 Manual Duet IP Change

```bash
sudo sed -i 's/OLD_IP/NEW_IP/g' /etc/nginx/sites-available/dwc
sudo systemctl reload nginx
```

## 📦 What Gets Installed

- **nginx** (web server)
- **DuetWebControl** (web interface)
- **Node.js + npm** (if building from source)
- **Configuration files** (nginx, hosts entry)

## 🗑️ Uninstall

```bash
sudo rm -rf /var/www/dwc
sudo rm -f /etc/nginx/sites-available/dwc
sudo rm -f /etc/nginx/sites-enabled/dwc
sudo sed -i '/dwc.local/d' /etc/hosts
sudo systemctl reload nginx
```

## 📝 License

This installer script is provided as-is. DuetWebControl is licensed under GPL-3.0.
