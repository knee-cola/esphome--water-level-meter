# Build Script Check-Only Flag Implementation Plan

## Project Status: 📐 Planning

**Progress Indicators:**
- 📐 Planning → 🔨 Implementing → 🩺 Testing → ✅ DONE

## Project Overview

Add a `--check-only` flag to the build.sh script that validates ESPHome configuration syntax without performing a full compilation. This will provide quick validation for configuration changes during development, reducing feedback time and resource usage.

## Technical Context

### Current Build Script Architecture
- **Main Script**: `build.sh` - Docker-based ESPHome compilation and flashing
- **Docker Image**: `esphome/esphome:2025.8.1` with ESPHome toolchain
- **Current Commands**: 
  - `compile` - Full compilation to firmware
  - `run` - Compile and flash to device
- **Configuration Files**: `src/config.yaml` and `src/secrets.yaml`
- **Validation Flow**: Currently requires full compilation for syntax checking

### ESPHome Command Options
- `esphome config <config.yaml>` - Configuration validation and expansion
- `esphome compile <config.yaml>` - Full compilation (current default)
- Docker execution pattern: `docker run --rm -v $(pwd):/config esphome/esphome:VERSION <command> /config/config.yaml`

## Implementation Details

### 1. Command Line Flag Addition
Add `--check-only` flag to argument parsing:
```bash
# Add to argument parsing section
--check-only)
    CHECK_ONLY=true
    shift
    ;;
```

### 2. Help Documentation Update
Update help text to include new option:
```bash
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
EOF
}
```

### 3. Build Function Modification
Modify `build_firmware()` function to support configuration-only mode:
```bash
build_firmware() {
    if [[ "$CHECK_ONLY" == true ]]; then
        print_header "Validating ESPHome Configuration"
        echo "Configuration check only - no compilation will be performed..."
        eval "$DOCKER_CMD config $ESPHOME_CONFIG"
        print_success "Configuration validation completed successfully"
    else
        print_header "Building ESPHome Firmware"
        # ... existing build logic
    fi
}
```

### 4. Validation Logic Enhancement
Ensure check-only mode:
- Skips device access setup (no serial/OTA device detection needed)
- Uses minimal Docker configuration
- Provides clear output about configuration status
- Exits early after validation without compilation

## Implementation Checklist

### Git Branch Setup
- [ ] Create feature branch `feature/build-check-only-flag`
- [ ] Switch to feature branch

### Add Command Line Flag Support
- [ ] Add `--check-only` flag to argument parsing section
- [ ] Add `CHECK_ONLY=false` to default values section
- [ ] Add validation to prevent conflicting options (check-only with flash)
- [ ] Commit: "Add --check-only flag argument parsing"
- [ ] Build validation: `./build.sh`

### Update Help Documentation
- [ ] Update `show_help()` function with new flag documentation
- [ ] Add example usage for check-only mode
- [ ] Commit: "Update help documentation for --check-only flag"
- [ ] Build validation: `./build.sh --help`

### Implement Configuration Validation Logic
- [ ] Modify `build_firmware()` function to support check-only mode
- [ ] Add ESPHome config command execution for validation
- [ ] Ensure Docker command is simplified for config-only mode
- [ ] Add appropriate success/error messaging for validation results
- [ ] Commit: "Implement configuration validation logic for --check-only"
- [ ] Build validation: `./build.sh --check-only`

### Add Option Conflict Validation
- [ ] Prevent `--check-only` from being used with `--flash`
- [ ] Add appropriate error messaging for invalid option combinations
- [ ] Commit: "Add validation for conflicting command options"
- [ ] Build validation: `./build.sh --check-only --flash` (should error)

### Final Validation
- [ ] Test configuration check with valid config: `./build.sh --check-only`
- [ ] Test configuration check with invalid config (temporarily break syntax)
- [ ] Test help display: `./build.sh --help`
- [ ] Test normal build still works: `./build.sh`
- [ ] Verify error handling for invalid option combinations
- [ ] Update project status to ✅ DONE

### Git Branch Cleanup
- [ ] Switch back to master branch: `git checkout master`
- [ ] Merge feature branch: `git merge feature/build-check-only-flag`
- [ ] Delete feature branch: `git branch -d feature/build-check-only-flag`

## Architecture Notes

- **Docker Integration**: Check-only mode uses same Docker image but different ESPHome command (`config` vs `compile`)
- **Performance**: Configuration validation is significantly faster than full compilation
- **Error Handling**: ESPHome config command returns proper exit codes for validation success/failure
- **Compatibility**: New flag doesn't affect existing build/flash functionality
- **Use Cases**: Ideal for CI/CD validation, development iteration, and configuration debugging
- **Resource Usage**: Minimal Docker container requirements (no device access, no compilation toolchain usage)