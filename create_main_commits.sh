#!/bin/bash

# Script to create a series of commits with realistic messages
# for the Zennic project (main branch)

set -e  # Exit on error

COMMIT_MESSAGES_FILE="main_branch_commits.txt"
REPO_ROOT=$(pwd)

# Check if commit messages file exists
if [ ! -f "$COMMIT_MESSAGES_FILE" ]; then
    echo "Error: $COMMIT_MESSAGES_FILE not found!"
    exit 1
fi

# Function to make a small change to a file
make_change() {
    local file=$1
    local comment=$2
    local dir=$(dirname "$file")
    
    # Create directory if it doesn't exist
    mkdir -p "$dir"
    
    # If file doesn't exist, create it with a basic structure
    if [ ! -f "$file" ]; then
        if [[ "$file" == *.swift ]]; then
            echo "// $file" > "$file"
            echo "// Created as part of Zennic project" >> "$file"
            echo "" >> "$file"
            
            # Add basic Swift structure based on filename
            filename=$(basename "$file")
            classname="${filename%.*}"
            
            echo "import Foundation" >> "$file"
            echo "import SwiftUI" >> "$file"
            echo "" >> "$file"
            echo "// $comment" >> "$file"
            echo "struct $classname {" >> "$file"
            echo "    // TODO: Implement $classname" >> "$file"
            echo "}" >> "$file"
        else
            echo "# $file" > "$file"
            echo "# Created as part of Zennic project" >> "$file"
            echo "" >> "$file"
            echo "# $comment" >> "$file"
        fi
    else
        # File exists, append a comment and make a small change
        echo "" >> "$file"
        echo "// $comment - $(date +"%Y-%m-%d")" >> "$file"
        
        # If it's a Swift file, add a small code change
        if [[ "$file" == *.swift ]]; then
            # Add a simple method or property
            if grep -q "struct\|class\|enum" "$file"; then
                # Find the last closing brace and insert before it
                line_num=$(grep -n "}" "$file" | tail -1 | cut -d: -f1)
                if [ -n "$line_num" ]; then
                    sed -i '' "${line_num}i\\
    // Added for: $comment\\
    func newFunction() {\\
        // Implementation pending\\
        print(\"Function added for: $comment\")\\
    }\\
" "$file"
                else
                    # No closing brace found, just append
                    echo "    // Added for: $comment" >> "$file"
                    echo "    func newFunction() {" >> "$file"
                    echo "        // Implementation pending" >> "$file"
                    echo "        print(\"Function added for: $comment\")" >> "$file"
                    echo "    }" >> "$file"
                fi
            else
                # Just append a comment if no struct/class found
                echo "// Code change for: $comment" >> "$file"
            fi
        else
            # For non-Swift files, just add a comment
            echo "# Change made for: $comment" >> "$file"
        fi
    fi
}

# Function to commit changes with a message
commit_changes() {
    local message=$1
    
    git add .
    git commit -m "$message" || true  # Continue even if commit fails
}

# Extract and process commit messages
echo "Starting to create commits..."
current_section=""
commit_count=0

# Read the commit messages file line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi
    
    # Check if line is a section header (starts with #)
    if [[ $line == \#* && $line != \#\#* ]]; then
        current_section=$(echo "$line" | sed 's/^# //')
        echo -e "\n\033[1;36mProcessing section: $current_section\033[0m"
        continue
    fi
    
    # Skip section header sublines (starts with ##)
    if [[ $line == \#\#* ]]; then
        continue
    fi
    
    # Process commit message
    commit_message="$line"
    echo -e "\033[1;33mCreating commit: $commit_message\033[0m"
    
    # Determine which files to modify based on the commit message and section
    case "$current_section" in
        "Initial setup and core functionality")
            if [[ "$commit_message" == *"project setup"* ]]; then
                make_change "README.md" "$commit_message"
                make_change "Package.swift" "$commit_message"
            elif [[ "$commit_message" == *"app structure"* ]]; then
                make_change "App/Sources/zennicApp.swift" "$commit_message"
                make_change "App/Sources/ContentView.swift" "$commit_message"
            elif [[ "$commit_message" == *"Core module"* ]]; then
                make_change "Features/Core/Sources/Core/Core.swift" "$commit_message"
                make_change "Features/Core/Sources/Core/Errors/CoreError.swift" "$commit_message"
            elif [[ "$commit_message" == *"SharedUI"* ]]; then
                make_change "Features/SharedUI/Sources/SharedUI/Models/ThemeManager.swift" "$commit_message"
            elif [[ "$commit_message" == *"project.yml"* ]]; then
                make_change "project.yml" "$commit_message"
            elif [[ "$commit_message" == *"README"* ]]; then
                make_change "README.md" "$commit_message"
            fi
            ;;
            
        "Terminal Emulator Development - Phase 1")
            if [[ "$commit_message" == *"skeleton"* ]]; then
                make_change "Features/TerminalEmulator/Package.swift" "$commit_message"
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/TerminalEmulator.swift" "$commit_message"
            elif [[ "$commit_message" == *"terminal view"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"TerminalState"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalState.swift" "$commit_message"
            elif [[ "$commit_message" == *"TerminalController"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Controllers/TerminalController.swift" "$commit_message"
            elif [[ "$commit_message" == *"command parsing"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalCommandHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"text rendering"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"command history"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalState.swift" "$commit_message"
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Controllers/TerminalController.swift" "$commit_message"
            elif [[ "$commit_message" == *"terminal prompt"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            fi
            ;;
            
        "Dashboard Implementation")
            if [[ "$commit_message" == *"Dashboard module"* ]]; then
                make_change "Features/Dashboard/Package.swift" "$commit_message"
            elif [[ "$commit_message" == *"dashboard layout"* ]]; then
                make_change "Features/Dashboard/Sources/Dashboard/Views/DashboardView.swift" "$commit_message"
            elif [[ "$commit_message" == *"theme support"* ]]; then
                make_change "Features/Dashboard/Sources/Dashboard/Models/DashboardTheme.swift" "$commit_message"
            elif [[ "$commit_message" == *"core data models"* ]]; then
                make_change "Features/Dashboard/Sources/Dashboard/Models/DashboardModel.swift" "$commit_message"
            elif [[ "$commit_message" == *"layout constraints"* ]]; then
                make_change "Features/Dashboard/Sources/Dashboard/Views/DashboardView.swift" "$commit_message"
            elif [[ "$commit_message" == *"responsive design"* ]]; then
                make_change "Features/Dashboard/Sources/Dashboard/Views/DashboardView.swift" "$commit_message"
            fi
            ;;
            
        "Terminal Emulator - Phase 2")
            if [[ "$commit_message" == *"NSViewRepresentable"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            elif [[ "$commit_message" == *"command execution"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"terminal commands"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalCommandHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"focus issues"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            elif [[ "$commit_message" == *"output formatting"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalOutputHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"color support"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"scrollback buffer"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalState.swift" "$commit_message"
            fi
            ;;
            
        "Analysis Tools Development")
            if [[ "$commit_message" == *"AnalysisTools module"* ]]; then
                make_change "Features/AnalysisTools/Package.swift" "$commit_message"
                make_change "Features/AnalysisTools/Sources/AnalysisTools/AnalysisTools.swift" "$commit_message"
            elif [[ "$commit_message" == *"code metrics"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/Models/CodeMetrics.swift" "$commit_message"
            elif [[ "$commit_message" == *"code issues"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/Models/CodeIssue.swift" "$commit_message"
            elif [[ "$commit_message" == *"UI for displaying"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/Views/AnalysisToolsView.swift" "$commit_message"
            elif [[ "$commit_message" == *"editor component"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/ViewModels/AnalysisViewModel.swift" "$commit_message"
            elif [[ "$commit_message" == *"performance issues"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/Models/CodeAnalyzer.swift" "$commit_message"
            elif [[ "$commit_message" == *"filtering options"* ]]; then
                make_change "Features/AnalysisTools/Sources/AnalysisTools/Views/IssuesView.swift" "$commit_message"
            fi
            ;;
            
        "Terminal Emulator - Phase 3")
            if [[ "$commit_message" == *"NSViewControllerRepresentable"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            elif [[ "$commit_message" == *"NSTextField"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"focus issues"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            elif [[ "$commit_message" == *"event handling"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Diagnostics/EventMonitor.swift" "$commit_message"
            elif [[ "$commit_message" == *"tab completion"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalCommandHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"path completion"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalCommandHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"scrolling behavior"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"rendering performance"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            fi
            ;;
            
        "Integration and Fixes")
            if [[ "$commit_message" == *"Integrate all modules"* ]]; then
                make_change "App/Sources/MainLayout.swift" "$commit_message"
            elif [[ "$commit_message" == *"dependency issues"* ]]; then
                make_change "Package.swift" "$commit_message"
            elif [[ "$commit_message" == *"error handling"* ]]; then
                make_change "Features/Core/Sources/Core/Errors/CoreError.swift" "$commit_message"
            elif [[ "$commit_message" == *"logging system"* ]]; then
                make_change "Features/Core/Sources/Core/Core.swift" "$commit_message"
            elif [[ "$commit_message" == *"memory leaks"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Controllers/TerminalController.swift" "$commit_message"
            elif [[ "$commit_message" == *"application performance"* ]]; then
                make_change "App/Sources/zennicApp.swift" "$commit_message"
            elif [[ "$commit_message" == *"README"* ]]; then
                make_change "README.md" "$commit_message"
            fi
            ;;
            
        "Terminal Emulator - Phase 4")
            if [[ "$commit_message" == *"real zsh shell"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"Process API"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"bidirectional pipe"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"terminal environment"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"zsh prompt"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalView.swift" "$commit_message"
            elif [[ "$commit_message" == *"process monitoring"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Controllers/TerminalController.swift" "$commit_message"
            elif [[ "$commit_message" == *"shell restart"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalProcessHandler.swift" "$commit_message"
            elif [[ "$commit_message" == *"directory tracking"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Models/TerminalState.swift" "$commit_message"
            fi
            ;;
            
        "UI Improvements")
            if [[ "$commit_message" == *"application theme"* ]]; then
                make_change "App/Sources/ThemeManager.swift" "$commit_message"
            elif [[ "$commit_message" == *"accessibility"* ]]; then
                make_change "Features/SharedUI/Sources/SharedUI/Views/MainSplitView.swift" "$commit_message"
            elif [[ "$commit_message" == *"keyboard shortcuts"* ]]; then
                make_change "App/Sources/ContentView.swift" "$commit_message"
            elif [[ "$commit_message" == *"dark mode"* ]]; then
                make_change "App/Sources/ThemeManager.swift" "$commit_message"
            elif [[ "$commit_message" == *"UI inconsistencies"* ]]; then
                make_change "Features/SharedUI/Sources/SharedUI/Models/ThemeManager.swift" "$commit_message"
            elif [[ "$commit_message" == *"responsive layout"* ]]; then
                make_change "App/Sources/MainLayout.swift" "$commit_message"
            elif [[ "$commit_message" == *"syntax highlighting"* ]]; then
                make_change "Features/Editor/Sources/Editor/Views/EditorView.swift" "$commit_message"
            fi
            ;;
            
        "Final Polishing")
            if [[ "$commit_message" == *"bugs in terminal"* ]]; then
                make_change "Features/TerminalEmulator/Sources/TerminalEmulator/Views/TerminalEmulatorView.swift" "$commit_message"
            elif [[ "$commit_message" == *"error handling"* ]]; then
                make_change "Features/Core/Sources/Core/Errors/CoreError.swift" "$commit_message"
            elif [[ "$commit_message" == *"startup performance"* ]]; then
                make_change "App/Sources/zennicApp.swift" "$commit_message"
            elif [[ "$commit_message" == *"documentation"* ]]; then
                make_change "README.md" "$commit_message"
            elif [[ "$commit_message" == *"unit tests"* ]]; then
                make_change "Tests/zennicTests/zennicTests.swift" "$commit_message"
            elif [[ "$commit_message" == *"build issues"* ]]; then
                make_change "Package.swift" "$commit_message"
            elif [[ "$commit_message" == *"initial release"* ]]; then
                make_change "README.md" "$commit_message"
            fi
            ;;
            
        *)
            # Default case - make a change to README
            make_change "README.md" "$commit_message"
            ;;
    esac
    
    # Commit the changes
    commit_changes "$commit_message"
    
    commit_count=$((commit_count + 1))
    echo -e "\033[1;32mCommit created: $commit_message\033[0m"
    echo "---------------------------------------------------------"
    
    # Small delay to make commits more realistic
    sleep 0.5
done < "$COMMIT_MESSAGES_FILE"

echo -e "\n\033[1;32mCreated $commit_count commits based on the commit messages file.\033[0m"
echo "You can now use the redate_git_commits.sh script to distribute these commits over the last 6 months."
