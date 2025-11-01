╔══════════════════════════════════════════════════════════════════════════════╗
║              IMPLEMENTATION PLAN - STEP BY STEP GUIDE                         ║
║                      Phase 2: Building the UI Layer                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

Files will be created/modified in this order:
1. Dialogs (for add/edit/test flows)
2. Widgets (ProviderCard)
3. Pages (Settings refactor, Chat update)
4. No breaking changes - all new, isolated files

═════════════════════════════════════════════════════════════════════════════════

STEP 1: ADD PROVIDER DIALOG
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/dialogs/add_provider_dialog.dart
PURPOSE: Multi-step dialog for adding new providers

Features:
├─ Step 1: Select provider from registry (filter by category)
├─ Step 2: Enter credentials (API key, endpoint, deployment ID)
├─ Step 3: Test connection (loading state, error handling)
├─ Step 4: Select favorite models (from test result)
└─ Step 5: Confirm and save

Implementation Details:
• Uses StatefulWidget with PageView for steps
• Watches providersNotifierProvider for save
• Error states with retry
• Progress indicator during test
• Validation before each step

Variables Used:
  _selectedProviderMeta: ProviderMetadata?
  _apiKey: String = ''
  _endpoint: String = ''
  _deploymentId: String = ''
  _availableModels: List<String> = []
  _selectedModels: Set<String> = {}
  _isLoading: bool = false
  _error: String? = null
  _currentStep: int = 0

State Management:
  → ref.read(providersNotifierProvider).addConfig(config)
  → On success: Navigator.pop(context)
  → Triggers: providersConfigProvider reload → Chat updates


═════════════════════════════════════════════════════════════════════════════════

STEP 2: EDIT PROVIDER DIALOG  
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/dialogs/edit_provider_dialog.dart
PURPOSE: Edit existing provider configuration

Features:
├─ Load current config
├─ Edit API key (masked input)
├─ Edit endpoint (optional)
├─ Manage favorite models
├─ Test connection again
└─ Save changes

Implementation Details:
• Takes configId as parameter
• Watches providerConfigByIdProvider (get current config)
• Similar to add dialog but pre-fills existing values
• Can mask/show API key
• Ability to clear and enter new key

Variables Used:
  _configId: String
  _apiKey: String = ''
  _showApiKey: bool = false
  _selectedModels: Set<String> = {}
  _isLoading: bool = false

State Management:
  → ref.read(providersNotifierProvider).updateConfig(config)
  → On success: Navigator.pop(context)
  → Triggers: providersConfigProvider reload


═════════════════════════════════════════════════════════════════════════════════

STEP 3: PROVIDER CARD WIDGET
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/widgets/provider_card.dart
PURPOSE: Display a single provider configuration card

Features:
├─ Display provider name, icon, status badge
├─ Show connected/configured/tested status
├─ Display favorite models as chips
├─ Enable/Disable toggle
├─ Edit/Delete buttons via menu
└─ Last tested timestamp

Structure:
┌─────────────────────────────────┐
│ [Icon] Provider Name [Status] │
│ Connected • 2 models         │
│ [Toggle]│ [•••] ←────────────── Menu
│ Models: [chip1] [chip2]      │
│ [Quick Actions]              │
└─────────────────────────────────┘

Widget Properties:
  - config: ProviderConfig
  - onEdit: VoidCallback
  - onDelete: VoidCallback
  - onToggle: VoidCallback
  - onTest: VoidCallback

Implementation:
• Card with InkWell for interaction
• PopupMenuButton for [•••] actions
• Animated status indicators
• Responsive layout


═════════════════════════════════════════════════════════════════════════════════

STEP 4: SETTINGS PAGE REFACTOR
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/pages/provider_settings_page.dart (rename/replace)
PURPOSE: Show all configured providers with management options

Layout:
├─ Header: "AI Providers" + Search + Add button
├─ Stats Bar: Total/Enabled/Configured/Models count
├─ Active Providers Section (configured & enabled)
│  └─ List of ProviderCard widgets
├─ Inactive Providers Section
│  └─ Available providers to add
└─ Footer: Bulk actions (test all, refresh, clear)

Key Features:
• Watches: providersConfigProvider (all), enabledProviderConfigsProvider
• Displays providers organized by status
• Search functionality to find providers
• Add button opens AddProviderDialog
• Edit button opens EditProviderDialog
• Delete shows confirmation
• Toggle updates immediately

State Management:
  final allConfigs = ref.watch(providersConfigProvider);
  final enabledConfigs = ref.watch(enabledProviderConfigsProvider);
  → allConfigs.when(
      loading: () => LoadingWidget(),
      error: (e, st) => ErrorWidget(e),
      data: (configs) => ListView(...)
    )

Data Flow:
  User clicks [+ Add] 
    → AddProviderDialog
    → ref.read(providersNotifierProvider).addConfig()
    → providersConfigProvider invalidates
    → Settings page rebuilds
    → Shows new provider card


═════════════════════════════════════════════════════════════════════════════════

STEP 5: CHAT PAGE - ADD REACTIVE MODEL DROPDOWN
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/pages/enhanced_ai_chat_page.dart (update)
PURPOSE: Update chat page to use reactive favorite models

Changes:
├─ Watch: allFavoriteModelsProvider
├─ Update: Model dropdown to show all enabled favorite models
├─ Add: Provider indicator (show which provider model is from)
└─ Ensure: No null safety issues

Old Implementation:
  _selectedModel: String = 'gpt-4'
  // Hardcoded or from static list

New Implementation:
  final favoriteModels = ref.watch(allFavoriteModelsProvider);
  
  return favoriteModels.when(
    loading: () => CircularProgressIndicator(),
    error: (e, st) => Text('Error loading models'),
    data: (models) => DropdownButton(
      items: models.map((m) => DropdownMenuItem(
        value: m,
        child: Text(m),
      )).toList(),
      onChanged: (value) {
        setState(() => _selectedModel = value);
      },
    ),
  );

Features:
• Auto-updates when settings change
• Shows models only from enabled providers
• Handles empty list (no models configured)
• Handles loading state
• Handles error state
• No manual refresh needed

State Management:
  ref.watch(allFavoriteModelsProvider) → rebuilds when:
    • Provider added
    • Provider deleted
    • Provider toggled
    • Favorite models changed
    • Provider configuration updated


═════════════════════════════════════════════════════════════════════════════════

STEP 6: HELPER UTILITIES
═════════════════════════════════════════════════════════════════════════════════

FILE: lib/presentation/widgets/provider_widgets_helper.dart
PURPOSE: Shared widgets and utilities for provider UI

Contains:
├─ StatusBadge (shows: ✓ Connected, ⚠ Warning, ✗ Error)
├─ ProviderIcon (from registry metadata)
├─ ModelChip (displays individual model)
├─ ConnectionState widget
├─ ErrorMessage widget
├─ LoadingOverlay widget
└─ buildProviderGridItem() function

Example Usage:
  StatusBadge(
    isConnected: config.testPassed,
    isConfigured: config.isConfigured,
    isEnabled: config.isEnabled,
  )


═════════════════════════════════════════════════════════════════════════════════

IMPLEMENTATION SEQUENCE - DO NOT DEVIATE
═════════════════════════════════════════════════════════════════════════════════

1️⃣  Create add_provider_dialog.dart
    └─ Builds all 5 steps
    └─ Test: Can select, configure, test, save

2️⃣  Create edit_provider_dialog.dart
    └─ Loads existing config
    └─ Test: Can modify and save

3️⃣  Create provider_card.dart
    └─ Displays config in settings
    └─ Test: Shows status and actions

4️⃣  Create provider_widgets_helper.dart
    └─ Shared UI components
    └─ Used by dialogs and cards

5️⃣  Refactor settings page
    └─ Use dynamic list instead of hardcoded cards
    └─ Hook up dialogs
    └─ Test: Settings workflow end-to-end

6️⃣  Update chat page
    └─ Watch allFavoriteModelsProvider
    └─ Update dropdown
    └─ Test: Model dropdown reactive


═════════════════════════════════════════════════════════════════════════════════

REACTIVE BEHAVIOR - GUARANTEED NON-BREAKING
═════════════════════════════════════════════════════════════════════════════════

Scenario 1: User is in Chat Page, someone (or same user) adds provider in Settings

Chat Page Code:
  final models = ref.watch(allFavoriteModelsProvider);
  
What happens:
  1. Settings page: User saves provider
  2. providersNotifierProvider.addConfig() called
  3. ProviderStorageService.saveConfig() saves to disk
  4. providersConfigProvider reloads from disk
  5. allFavoriteModelsProvider recalculates
  6. Chat page's ref.watch() gets notified
  7. Chat page rebuilds with new model in dropdown
  8. ✓ Automatic! No user interaction needed


Scenario 2: User toggles provider enable/disable in Settings

Chat Page Sees:
  • Before: [gpt-4, claude-3-opus, mistral-7b]
  • User disables OpenAI in Settings
  • After: [claude-3-opus, mistral-7b]
  • Chat dropdown automatically updates!


Scenario 3: User deletes a provider

Chat Page Sees:
  • Models from deleted provider are removed
  • Other models remain
  • If no models left: dropdown shows error state
  • User can add new provider and models reappear


═════════════════════════════════════════════════════════════════════════════════

TESTING CHECKLIST - VERIFY NO BREAKING CHANGES
═════════════════════════════════════════════════════════════════════════════════

After Each File:
☐ flutter pub get (dependencies OK)
☐ flutter analyze (no errors)
☐ flutter build apk --debug (builds OK)

After Add Dialog:
☐ Dialog opens when [+ Add Provider] clicked
☐ Can select provider
☐ Can enter API key
☐ Test connection works
☐ Models load from API
☐ Can select favorites
☐ Saves to storage

After Edit Dialog:
☐ Dialog opens when [Edit] clicked
☐ Current values pre-filled
☐ Can modify API key
☐ Can change favorite models
☐ Changes save correctly

After Provider Card:
☐ Card displays correctly
☐ Status badges show correct state
☐ Toggle works
☐ Menu buttons work
☐ Delete shows confirmation

After Settings Page:
☐ Page loads without errors
☐ Shows all providers
☐ Add button works
☐ Edit button works
☐ Delete button works
☐ Search works

After Chat Page Update:
☐ Dropdown shows models
☐ Dropdown updates when settings change
☐ No null errors
☐ Can send messages with selected model
☐ Model persists when navigating away


═════════════════════════════════════════════════════════════════════════════════

IMPORTANT NOTES
═════════════════════════════════════════════════════════════════════════════════

🔐 Security:
  • Always use ref.read(providerStorageServiceProvider)
  • Never log API keys
  • API key input should not be visible unless user clicks show
  • Clear API key from memory after use

⚡ Performance:
  • Use .family for parameterized providers
  • Watch only needed providers (not entire object if possible)
  • Lazy load large lists
  • Debounce search input

🎨 UI/UX:
  • Consistent spacing (16dp, 8dp)
  • Use theme colors from Theme.of(context)
  • Animations smooth but not slow
  • Loading states immediately (no delay)
  • Error messages clear and actionable

♻️ Reactivity:
  • When invalidating: ref.invalidate(providersConfigProvider)
  • Use .future for FutureProviders in dialogs
  • Always handle loading/error/data states
  • Don't force refresh - let Riverpod handle it


═════════════════════════════════════════════════════════════════════════════════

EXPECTED OUTCOME
═════════════════════════════════════════════════════════════════════════════════

✅ Users can:
  • Add new providers from registry of 46
  • Test connection before saving
  • Select favorite models
  • Edit any configuration
  • Delete providers
  • Toggle enable/disable
  • See models automatically in chat dropdown
  • Have their choices persist across app restarts

✅ System will:
  • Never break existing functionality
  • Securely store API keys
  • Keep metadata in SharedPreferences
  • React to changes automatically
  • Handle errors gracefully
  • Display loading states
  • Provide user feedback for all actions

✅ Code will:
  • Be well-organized in separate files
  • Use Riverpod for state management
  • Follow Flutter best practices
  • Have proper error handling
  • Be easy to maintain and extend
  • Support future enhancements
