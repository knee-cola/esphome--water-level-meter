# General Project Implementation Guidelines for AI Agents

## AI Agent Development Workflow

### Git Branch Management

1. **Feature Branch Development**: Always create and work on separate feature branches
   - Naming convention: `feature/descriptive-feature-name`
   - Examples: `feature/sensor-error-tracking`, `feature/power-management-upgrade`

2. **Branch Workflow**:
   - Create feature branch from `master`
   - Implement changes incrementally with frequent commits
   - Validate each major change before proceeding
   - Merge back to `master` when complete

### Incremental Development

1. **Commit Strategy**: Commit changes after each logical unit of work
   - Task-based commits (e.g., "Add error flag global variable")
   - Feature-based commits (e.g., "Add Home Assistant binary sensor")
   - Fix-based commits (e.g., "Fix configuration validation error")
   - Testing commits (e.g., "Validate build and entity configuration")

2. **Commit Message Standards**:
   - Use descriptive, action-oriented messages
   - Include context about what the change accomplishes
   - Reference relevant files or components when helpful

## Configuration Validation

1. **After Every Major Change**: Use `./build.sh` to validate YAML syntax and configuration
2. **Preserve Existing Configuration**: When modifying existing components, preserve ALL existing parameters unless explicitly changing them
3. **Incremental Changes**: Make one logical change at a time to isolate potential issues

## Implementation Workflow

1. **Git Branch Setup**:
   - Create feature branch: `feature/descriptive-feature-name`
   - Switch to feature branch

2. **For Each Implementation Task**:
   - Complete the implementation
   - Commit with descriptive message
   - Build validation with `./build.sh`
   - Mark checklist item as completed (✅)

3. **Project Status Updates**: Update status indicators as work progresses:
   - Start: 📐 Planning → 🔨 Implementing  
   - During: 🔨 Implementing → 🩺 Testing
   - Complete: 🩺 Testing → ✅ DONE

## ESPHome-Specific Requirements

1. **Entity ID Consistency**: Use snake_case for IDs, Title Case for display names
2. **Power Management**: Work within existing power management frameworks  
3. **Component Integration**: Ensure seamless integration with existing sensor stacks
4. **Logging Standards**: Use appropriate log levels (ESP_LOGI, ESP_LOGW, ESP_LOGE)
5. **Error Recovery**: Implement automatic recovery mechanisms where possible

## Critical Implementation Rules

1. **Always work in feature branches** for development
2. **Commit incrementally** with descriptive messages
3. **Validate after each major change** with `./build.sh` 
4. **Preserve existing functionality** unless explicitly modifying
5. **Update status indicators** as work progresses
6. **Mark checklist items completed (✅)** as each task is finished