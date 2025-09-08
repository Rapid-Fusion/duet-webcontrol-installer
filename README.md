# DuetWebControl Automated Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-ARM64%20%7C%20x64-blue)](https://github.com)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green)](https://www.gnu.org/software/bash/)

A complete automated installer for DuetWebControl + Nginx proxy configuration, optimized for Jetson devices and ARM64 Linux systems.

## 🚀 Quick Start

### One-Line Installation
```bash
# Basic installation (builds from latest source)
./install-dwc.sh 192.168.1.100

# Quick install via curl (if hosted)
curl -sSL https://raw.githubusercontent.com/Rapid-Fusion/duet-webcontrol-installer/main/quick-install.sh | bash -s -- 192.168.1.100
```

### Download and Run
```bash
# Clone this repository
git clone https://github.com/Rapid-Fusion/duet-webcontrol-installer.git
cd duet-webcontrol-installer

# Make executable and run
chmod +x install-dwc.sh
./install-dwc.sh [YOUR_DUET_IP]
```

## 📋 What Gets Installed

- **DuetWebControl** - Latest web interface for RepRapFirmware
- **Nginx** - High-performance web server with proxy configuration
- **WebSocket Support** - Real-time printer communication
- **Large File Upload** - 2GB limit for G-code files
- **Security Headers** - Production-ready configuration
- **Local DNS** - Access via `http://dwc.local/`

## 🛠️ Installation Options

### Basic Usage
```bash
./install-dwc.sh [DUET_IP] [OPTIONS]
```

### Available Options
- `-s, --source` - Build from latest GitHub source
- `-z, --zip PATH` - Use specific DWC zip file
- `-d, --domain NAME` - Custom domain (default: dwc.local)
- `-h, --help` - Show help message

### Examples
```bash
# Use Duet at specific IP
./install-dwc.sh 10.10.10.100

# Build from source for latest features
./install-dwc.sh 192.168.1.100 --source

# Use downloaded DWC zip file
./install-dwc.sh 192.168.1.100 --zip ~/Downloads/DuetWebControl-SD.zip

# Custom domain name
./install-dwc.sh 192.168.1.100 --domain printer.local
```

## 🌐 Access Methods

After installation, access DuetWebControl via:

- **Primary**: `http://dwc.local/`
- **IP Access**: `http://[DEVICE_IP]/`
- **Mobile**: Same URLs work on phones/tablets

## 🔧 System Requirements

- **OS**: Ubuntu 18.04+ (ARM64/x64)
- **User**: Regular user with sudo privileges  
- **Memory**: 1GB+ RAM recommended
- **Storage**: ~200MB free space
- **Network**: Internet for package downloads

## 📱 Tested Platforms

- ✅ NVIDIA Jetson Nano
- ✅ NVIDIA Jetson Xavier NX  
- ✅ NVIDIA Jetson AGX Orin
- ✅ Raspberry Pi 4 (ARM64)
- ✅ Ubuntu 20.04/22.04 (x64)

## 🔄 Features

### Automatic Configuration
- **Nginx Proxy**: Seamless API forwarding to Duet
- **WebSocket**: Real-time temperature/status updates
- **File Uploads**: Drag-drop G-code files up to 2GB
- **Compression**: Optimized for fast loading
- **Caching**: Static asset optimization

### Smart Installation
- **Auto-Detection**: Finds existing DWC zip files
- **Dependency Management**: Installs required packages
- **Error Handling**: Comprehensive error checking
- **Idempotent**: Safe to run multiple times
- **Rollback**: Easy uninstall process

## 🧪 Testing Your Installation

```bash
# Test web interface
curl -I http://dwc.local/

# Test API proxy (requires Duet connection)
curl "http://dwc.local/rr_connect?password="
curl "http://dwc.local/rr_gcode?gcode=M115"
```

## 📁 File Locations

- **Web Root**: `/var/www/dwc/`
- **Nginx Config**: `/etc/nginx/sites-available/dwc`
- **Logs**: `journalctl -u nginx`

## 🐛 Troubleshooting

### Common Issues

**DWC not loading:**
```bash
sudo nginx -t                    # Check config
sudo systemctl reload nginx     # Reload service
```

**API not working:**
- Verify Duet IP address is correct
- Check Duet is running RepRapFirmware 3.0+
- Ensure firewall allows connections

**Permission errors:**
```bash
sudo chown -R www-data:www-data /var/www/dwc
sudo chmod -R 755 /var/www/dwc
```

## 🗑️ Uninstall

```bash
sudo rm -rf /var/www/dwc
sudo rm -f /etc/nginx/sites-available/dwc
sudo rm -f /etc/nginx/sites-enabled/dwc
sudo sed -i '/dwc.local/d' /etc/hosts
sudo systemctl reload nginx
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Rapid-Fusion/duet-webcontrol-installer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Rapid-Fusion/duet-webcontrol-installer/discussions)
- **DuetWebControl**: [Duet3D Forum](https://forum.duet3d.com/)

## 🙏 Acknowledgments

- [Duet3D](https://www.duet3d.com/) for DuetWebControl
- [RepRapFirmware](https://github.com/Duet3D/RepRapFirmware) community
- [Nginx](https://nginx.org/) for the excellent web server

---

**Made with ❤️ for the 3D printing community**
