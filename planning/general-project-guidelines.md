# Guidelines for Creating AI Agent Implementation Plans

## Purpose

This document provides instructions for AI agents on how to create comprehensive implementation plans for ESPHome projects. When tasked with implementing a feature, use these guidelines to structure your implementation approach and create actionable plans.

## Required Elements for Implementation Plans

When creating an implementation plan, ensure it includes these mandatory sections:

### 1. Project Status Tracking
- At top of the file include current progress indicator with initial value of "📐 Planning"
- Require the current progress to be updated as implementation progresses: 📐 Planning → 🔨 Implementing → 🩺 Testing → ✅ DONE

### 2. Git Workflow Instructions
- Specify feature branch naming: `feature/descriptive-feature-name`
- Include branch creation and management steps
- Require commit after each logical unit of work
- Require descriptive, action-oriented commit messages

### 3. Task Breakdown and Checklist
- Create comprehensive checklist of all implementation tasks
- Break down complex features into logical, manageable steps
- Include validation steps after each major change
- Specify completion marking with (✅) checkboxes

### 4. Configuration Validation Requirements
- Mandate `./build.sh` validation after every major change
- Emphasize preservation of existing configuration parameters
- Require incremental changes to isolate potential issues

### 5. Technical Content Requirements
- Include current system architecture overview and constraints
- Provide specific code snippets and configuration examples
- Document integration points and dependencies
- Specify preservation requirements for existing functionality

### 6. Implementation Workflow Steps
Include these specific workflow instructions in every plan:
- Project planning with comprehensive task checklist
- Git branch setup with proper naming conventions
- Implementation loop: code → validate → mark complete → **update checklist in planning document**
- Status updates throughout the development process
- **CRITICAL**: Update checklist items from `[ ]` to `[x]` in the planning document as each task is completed

## Mandatory Implementation Rules for All Plans

Every implementation plan must specify these non-negotiable requirements:

1. **Feature Branch Development**: All work must be done in dedicated feature branches
2. **Incremental Commits**: Require commits after each logical unit of work
3. **Build Validation**: Mandate `./build.sh` testing after each major change
4. **Preserve Existing Functionality**: Unless explicitly modifying, preserve all existing behavior
5. **Progress Tracking**: Require status indicator updates and checklist completion marking during project implementation
6. **Task Completion**: Each task must be marked completed (✅) when finished
7. **Live Checklist Updates**: **MANDATORY** - Update planning document checklist items from `[ ]` to `[x]` immediately after completing each task, not just at the end of the project
8. **Feature Branch Integration**: **MANDATORY** - After project completion, merge feature branch back to master and clean up by deleting the feature branch
9. **Minimal Viable Solution**: Implement only the essential functionality requested in terms of features and scope - avoid adding extra logging, error checking, or monitoring unless explicitly requested. However, provide comprehensive technical documentation, code snippets, and implementation details necessary for successful implementation.

## Implementation Plan Template Structure

Use this structure when creating implementation plans:

```
# [Feature Name] Implementation Plan

## Project Status: 📐 Planning

## Project Overview
[Brief description of what will be implemented]

## Technical Context
[Current system architecture, constraints, and integration points]

## Implementation Details
[Specific code snippets, configuration examples, and technical requirements]

## Implementation Checklist

### Git Branch Setup
- [ ] Create feature branch `feature/[descriptive-name]`
- [ ] Switch to feature branch

### [Task Category 1]
- [ ] [Specific task description]
- [ ] Commit: "[Descriptive commit message]"
- [ ] Build validation: `./build.sh`

### [Task Category 2]
- [ ] [Specific task description]  
- [ ] Commit: "[Descriptive commit message]"
- [ ] Build validation: `./build.sh`

### Final Validation
- [ ] Final build validation with `./build.sh`
- [ ] Update project status to ✅ DONE

### Git Branch Cleanup
- [ ] Switch back to master branch: `git checkout master`
- [ ] Merge feature branch: `git merge feature/[descriptive-name]`
- [ ] Delete feature branch: `git branch -d feature/[descriptive-name]`

## Architecture Notes
[Integration constraints, timing considerations, and implementation notes]
```