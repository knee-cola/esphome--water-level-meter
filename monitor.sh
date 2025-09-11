#!/bin/bash

# ESPHome Monitor Script
# Monitor logs from ESP32 water level sensor device
# Cross-platform support for Linux, macOS, and Windows (WSL)

set -e  # Exit on any error

# Configuration
ESPHOME_CONFIG="esphome-water-level-meter.yaml"
DOCKER_IMAGE="esphome/esphome:2025.8.1"
CONTAINER_NAME="esphome-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_help() {
    cat << EOF
ESPHome Monitor Script

USAGE:
    ./monitor.sh [OPTIONS]

OPTIONS:
    --ota                   Monitor via Over-The-Air connection
    --serial                Monitor via serial connection (default)
    --device=DEVICE         Specify serial device (e.g., /dev/ttyACM0)
    --help                  Show this help message

EXAMPLES:
    ./monitor.sh                        # Monitor via serial (auto-detect device)
    ./monitor.sh --serial               # Monitor via serial (auto-detect device)
    ./monitor.sh --device=/dev/ttyACM0  # Monitor specific serial device
    ./monitor.sh --ota                  # Monitor via OTA connection

NOTE:
    Press Ctrl+C to stop monitoring and exit.

EOF
}

# Default values
MONITOR_METHOD="serial"
SERIAL_DEVICE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --serial)
            MONITOR_METHOD="serial"
            shift
            ;;
        --ota)
            MONITOR_METHOD="ota"
            shift
            ;;
        --device=*)
            SERIAL_DEVICE="${1#*=}"
            MONITOR_METHOD="serial"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get serial device for monitoring
get_serial_device() {
    # If device specified via command line, use it
    if [[ -n "$SERIAL_DEVICE" ]]; then
        if [[ -c "$SERIAL_DEVICE" ]]; then
            echo "$SERIAL_DEVICE"
            return
        else
            print_error "Specified device $SERIAL_DEVICE not found"
            exit 1
        fi
    fi
    
    # Common ESP32 serial device patterns
    local devices=(
        "/dev/ttyUSB0"
        "/dev/ttyACM0"
        "/dev/ttyUSB1"
        "/dev/ttyACM1"
        "/dev/cu.usbserial-*"
        "/dev/cu.usbmodem*"
    )
    
    # Check for existing devices
    for device in "${devices[@]}"; do
        if [[ -c "$device" ]]; then
            echo "$device"
            return
        fi
    done
    
    # If no common devices found, try to find any USB serial devices
    for device in /dev/ttyUSB* /dev/ttyACM* /dev/cu.usbserial* /dev/cu.usbmodem*; do
        if [[ -c "$device" ]]; then
            echo "$device"
            return
        fi
    done
    
    # No device found
    echo ""
}

# Get OTA device name/IP
get_ota_device() {
    # Try to extract device name from YAML
    if [[ -f "$ESPHOME_CONFIG" ]]; then
        DEVICE_NAME=$(grep -E "^\s*name:\s*" "$ESPHOME_CONFIG" | sed 's/.*name:\s*//' | tr -d '"' | tr -d "'")
        if [[ -n "$DEVICE_NAME" ]]; then
            print_success "\nFound OTA device name: $DEVICE_NAME"
            echo "$DEVICE_NAME.local"
            return
        fi
    fi
    
    # Fallback: ask user
    read -p "Enter device name or IP address: " device_input
    echo "$device_input"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        echo "Please install Docker and try again"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running or not accessible"
        echo "Please start Docker and ensure you have permissions to run Docker commands"
        exit 1
    fi
    
    print_success "Docker is available"
    
    # Check configuration file
    if [[ ! -f "$ESPHOME_CONFIG" ]]; then
        print_error "Configuration file '$ESPHOME_CONFIG' not found"
        echo "Please ensure you're in the correct directory"
        exit 1
    fi
    
    print_success "Configuration file found"
}

# Ensure Docker image is available
ensure_docker_image() {
    echo "Checking ESPHome Docker image..."
    
    # Check if image already exists locally
    if docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
        print_success "Docker image $DOCKER_IMAGE found"
        return 0
    fi
    
    # Image not found, pull it
    echo "Pulling ESPHome Docker image..."
    docker pull "$DOCKER_IMAGE" > /dev/null
    print_success "Docker image $DOCKER_IMAGE pulled successfully"
}

# Clean up any existing container
cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
    fi
}

# Start monitoring
start_monitoring() {
    print_header "Starting ESPHome Monitor"
    
    # Ensure Docker image is available
    ensure_docker_image
    
    # Create Docker command
    DOCKER_CMD="docker run --rm --name $CONTAINER_NAME  -v $(pwd):/config"
    
    if [[ "$MONITOR_METHOD" == "serial" ]]; then
        # Get serial device
        DETECTED_DEVICE=$(get_serial_device)
        if [[ -z "$DETECTED_DEVICE" ]]; then
            print_error "No serial device found for monitoring"
            print_warning "Please ensure your ESP32 device is connected via USB"
            exit 1
        fi
        
        # Add device access for serial monitoring
        DOCKER_CMD="$DOCKER_CMD --device-cgroup-rule='c 188:* rmw'"
        
        if [[ -d "/dev" ]]; then
            DOCKER_CMD="$DOCKER_CMD -v /dev:/dev"
        fi
        DOCKER_CMD="$DOCKER_CMD --device=$DETECTED_DEVICE"
        
        echo "Monitoring serial device: $DETECTED_DEVICE"
        echo
        print_warning "Press Ctrl+C to stop monitoring"
        echo
        
        # Start monitoring
        eval "$DOCKER_CMD $DOCKER_IMAGE logs $ESPHOME_CONFIG --device $DETECTED_DEVICE"
        
    else
        # OTA monitoring
        OTA_DEVICE=$(get_ota_device)
        echo "Monitoring OTA device: $OTA_DEVICE"
        echo
        print_warning "Press Ctrl+C to stop monitoring"
        echo
        
        # Start monitoring
        eval "$DOCKER_CMD --net=host $DOCKER_IMAGE logs $ESPHOME_CONFIG"
    fi
}

# Main execution
main() {
    print_header "ESPHome Monitor Script"
    echo "Configuration: $ESPHOME_CONFIG"
    echo "Monitor method: $MONITOR_METHOD"
    if [[ -n "$SERIAL_DEVICE" ]]; then
        echo "Specified device: $SERIAL_DEVICE"
    fi
    echo
    
    check_prerequisites
    cleanup_container
    start_monitoring
}

# Trap to cleanup on exit
trap 'cleanup_container' EXIT

# Run main function
main "$@"