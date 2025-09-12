#!/bin/bash

# ESPHome Build and Flash Script
# Docker-based compilation and flashing for ESP32-C3 Super Mini
# Cross-platform support for Linux, macOS, and Windows (WSL)

set -e  # Exit on any error

# Configuration
ESPHOME_CONFIG="src/config.yaml"
ESPHOME_SECRETS="src/secrets.yaml"
DOCKER_IMAGE="esphome/esphome:2025.8.1"
CONTAINER_NAME="esphome-builder"

# Default values
FLASH_AFTER_BUILD=false
FLASH_METHOD="serial"
CHECK_ONLY=false

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
ESPHome Build and Flash Script

USAGE:
    ./build.sh [OPTIONS]

OPTIONS:
    --flash                 Flash after successful build
    --method=METHOD         Flashing method: serial or ota (default: serial)
    --check-only           Validate configuration syntax only (no compilation)
    --help                  Show this help message

EXAMPLES:
    ./build.sh                          # Build only
    ./build.sh --check-only             # Configuration check only
    ./build.sh --flash                  # Build and flash (via serial by default)
    ./build.sh --flash --method=ota     # Build and flash via OTA
    ./build.sh --flash --method=serial  # Build and flash via serial

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --flash)
            FLASH_AFTER_BUILD=true
            shift
            ;;

        --method=*)
            FLASH_METHOD="${1#*=}"
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
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



# Validate flash method
if [[ "$FLASH_METHOD" != "serial" && "$FLASH_METHOD" != "ota" ]]; then
    print_error "Invalid flash method: $FLASH_METHOD. Must be 'serial' or 'ota'"
    exit 1
fi

# Validate option conflicts
if [[ "$CHECK_ONLY" == true && "$FLASH_AFTER_BUILD" == true ]]; then
    print_error "Cannot use --check-only with --flash options"
    echo "Configuration check mode only validates syntax without building firmware"
    exit 1
fi

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

    # check if docker image exists
    if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
        print_warning "Docker image not found, pulling..."
        # Pull latest Docker image
        docker pull "$DOCKER_IMAGE"
    else
        print_success "Docker image found"
    fi
    
    # Check configuration file
    if [[ ! -f "$ESPHOME_CONFIG" ]]; then
        print_error "Configuration file '$ESPHOME_CONFIG' not found"
        echo "Please ensure you're in the correct directory"
        exit 1
    fi
    
    print_success "Configuration file found"
    
    # Check secrets file
    if [[ ! -f "$ESPHOME_SECRETS" ]]; then
        print_warning "secrets.yaml not found"
        echo "You may need to create this file with your WiFi credentials:"
        echo "  wifi_ssid: \"YourWiFiName\""
        echo "  wifi_password: \"YourWiFiPassword\""
        echo
        read -p "Continue anyway? (y/N): " continue_choice
        case $continue_choice in
            [Yy]* )
                echo "Continuing without secrets.yaml..."
                ;;
            * )
                exit 1
                ;;
        esac
    else
        print_success "secrets.yaml found"
    fi
}

# Clean up any existing container
cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_header "Cleaning up previous build container"
        docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true
        print_success "Previous container removed"
    fi
}

# Build firmware
build_firmware() {
    if [[ "$CHECK_ONLY" == true ]]; then
        print_header "Validating ESPHome Configuration"
        echo "Configuration check only - no compilation will be performed..."
        
        # Create simplified Docker command for config validation
        DOCKER_CMD="docker run --rm --name $CONTAINER_NAME"
        DOCKER_CMD="$DOCKER_CMD -v $(pwd):/config"
        DOCKER_CMD="$DOCKER_CMD $DOCKER_IMAGE"
        
        # Run configuration validation
        eval "$DOCKER_CMD config $ESPHOME_CONFIG"
        print_success "Configuration validation completed successfully"
        return
    fi

    print_header "Building ESPHome Firmware"

    # Create Docker command
    DOCKER_CMD="docker run --rm --name $CONTAINER_NAME"
    DOCKER_CMD="$DOCKER_CMD -v $(pwd):/config"
    
    # Add device access for flashing if needed
    if [[ "$FLASH_AFTER_BUILD" == true && "$FLASH_METHOD" == "serial" ]]; then
        DOCKER_CMD="$DOCKER_CMD --device-cgroup-rule='c 188:* rmw'"
        if [[ -d "/dev" ]]; then
            DOCKER_CMD="$DOCKER_CMD -v /dev:/dev"
        fi
        # Get serial device early to add it to Docker command
        SERIAL_DEVICE=$(get_serial_device)
        if [[ -n "$SERIAL_DEVICE" ]]; then
            DOCKER_CMD="$DOCKER_CMD --device=$SERIAL_DEVICE"
        fi
    fi
    
    DOCKER_CMD="$DOCKER_CMD --network=host $DOCKER_IMAGE"
    
    # Build only or build and flash
    if [[ "$FLASH_AFTER_BUILD" == true ]]; then
        if [[ "$FLASH_METHOD" == "serial" ]]; then
            echo "Building and flashing via serial..."
            if [[ -n "$SERIAL_DEVICE" ]]; then
                echo "Using serial device: $SERIAL_DEVICE"
                eval "$DOCKER_CMD run $ESPHOME_CONFIG --device $SERIAL_DEVICE"
            else
                print_error "No serial device found for flashing"
                print_warning "Please ensure your ESP32 device is connected via USB"
                exit 1
            fi
        else
            echo "Building and flashing via OTA..."
            OTA_DEVICE=$(get_ota_device)
            echo "Flashing OTA device: $OTA_DEVICE"

            eval "$DOCKER_CMD run $ESPHOME_CONFIG --device=$OTA_DEVICE"
        fi
    else
        echo "Building firmware..."
        eval "$DOCKER_CMD compile $ESPHOME_CONFIG"
    fi
    
    print_success "Build completed successfully"
}

# Get serial device for flashing
get_serial_device() {
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

# Main execution
main() {
    print_header "ESPHome Build Script"
    echo "Configuration: $ESPHOME_CONFIG"
    echo "Flash after build: $FLASH_AFTER_BUILD"
    echo "Configuration check only: $CHECK_ONLY"
    if [[ "$FLASH_AFTER_BUILD" == true ]]; then
        echo "Flash method: $FLASH_METHOD"
    fi
    echo
    
    check_prerequisites   
    cleanup_container

    build_firmware
    
    print_success "All operations completed successfully!"
    
    if [[ "$FLASH_AFTER_BUILD" == false ]]; then
        echo
        print_header "Next Steps"
        echo "To flash the compiled firmware:"
        echo "  ./build.sh --flash --method=serial   # For serial flashing"
        echo "  ./build.sh --flash --method=ota      # For OTA updates"
    fi
}

# Run main function
main "$@"