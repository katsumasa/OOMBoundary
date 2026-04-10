#!/bin/bash

# Setup Xcode Schemes for Memory Enforcement Modes
# This script creates OOMBoundary-Full scheme with pre-action script

set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
XCSCHEMES_DIR="${PROJECT_DIR}/OOMBoundary.xcodeproj/xcshareddata/schemes"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Xcode Schemes${NC}"
echo ""

# Create xcshareddata directory if needed
mkdir -p "${XCSCHEMES_DIR}"

# Create OOMBoundary scheme (Soft Mode)
cat > "${XCSCHEMES_DIR}/OOMBoundary.xcscheme" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2640"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Switch to Soft Mode"
               scriptText = "export MEMORY_ENFORCEMENT_MODE=soft&#10;${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "8248BAFC2F7B848E00699123"
                     BuildableName = "OOMBoundary.app"
                     BlueprintName = "OOMBoundary"
                     ReferencedContainer = "container:OOMBoundary.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "8248BAFC2F7B848E00699123"
               BuildableName = "OOMBoundary.app"
               BlueprintName = "OOMBoundary"
               ReferencedContainer = "container:OOMBoundary.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "8248BAFC2F7B848E00699123"
            BuildableName = "OOMBoundary.app"
            BlueprintName = "OOMBoundary"
            ReferencedContainer = "container:OOMBoundary.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "8248BAFC2F7B848E00699123"
            BuildableName = "OOMBoundary.app"
            BlueprintName = "OOMBoundary"
            ReferencedContainer = "container:OOMBoundary.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo -e "${GREEN}✅ Created OOMBoundary scheme (Soft Mode)${NC}"

# Create OOMBoundary-Full scheme (Full Mode)
cat > "${XCSCHEMES_DIR}/OOMBoundary-Full.xcscheme" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2640"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Switch to Full Mode"
               scriptText = "export MEMORY_ENFORCEMENT_MODE=full&#10;${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "8248BAFC2F7B848E00699123"
                     BuildableName = "OOMBoundary.app"
                     BlueprintName = "OOMBoundary"
                     ReferencedContainer = "container:OOMBoundary.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "8248BAFC2F7B848E00699123"
               BuildableName = "OOMBoundary.app"
               BlueprintName = "OOMBoundary"
               ReferencedContainer = "container:OOMBoundary.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "8248BAFC2F7B848E00699123"
            BuildableName = "OOMBoundary.app"
            BlueprintName = "OOMBoundary"
            ReferencedContainer = "container:OOMBoundary.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "8248BAFC2F7B848E00699123"
            BuildableName = "OOMBoundary.app"
            BlueprintName = "OOMBoundary"
            ReferencedContainer = "container:OOMBoundary.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo -e "${GREEN}✅ Created OOMBoundary-Full scheme (Full Mode)${NC}"
echo ""
echo -e "${BLUE}📝 Schemes created:${NC}"
echo -e "   • OOMBoundary      (Soft Mode)"
echo -e "   • OOMBoundary-Full (Full Mode)"
echo ""
echo -e "${YELLOW}💡 How to use:${NC}"
echo -e "   1. Open Xcode"
echo -e "   2. Select scheme from toolbar (Product > Scheme)"
echo -e "   3. Choose OOMBoundary or OOMBoundary-Full"
echo -e "   4. Build (⌘B) or Run (⌘R)"
echo ""
echo -e "${GREEN}✨ Done!${NC}"
