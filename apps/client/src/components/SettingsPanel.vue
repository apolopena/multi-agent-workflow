<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click="close">
    <div
      class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full mx-4 p-6"
      @click.stop
    >
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Summary Settings</h2>
        <button
          @click="close"
          class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
        >
          ✕
        </button>
      </div>

      <div class="space-y-6">
        <!-- Current Mode Display -->
        <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
          <div class="flex items-center gap-2">
            <span class="text-sm text-gray-700 dark:text-gray-300">Current mode:</span>
            <strong class="text-lg text-blue-600 dark:text-blue-400">{{ selectedMode }}</strong>
          </div>
        </div>

        <!-- Mode Options -->
        <div class="space-y-4">
          <!-- Realtime Mode -->
          <label
            class="flex items-start gap-4 p-4 border-2 rounded-lg cursor-pointer transition-all"
            :class="selectedMode === 'realtime'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'"
          >
            <input
              type="radio"
              value="realtime"
              v-model="selectedMode"
              class="mt-1"
            />
            <div class="flex-1">
              <div class="font-bold text-lg text-gray-900 dark:text-white mb-1">
                Real-time (API)
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
                Summaries generated during hooks (~1-2s delay per event)
              </p>
              <p class="text-sm font-semibold text-orange-600 dark:text-orange-400">
                💰 Cost: API usage per event
              </p>

              <!-- API Key Warning -->
              <div
                v-if="!hasAnthropicApiKey"
                class="mt-3 p-3 bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800 rounded"
              >
                <p class="text-sm font-semibold text-orange-800 dark:text-orange-200 mb-2">
                  ⚠️ Anthropic API Key Required
                </p>
                <ol class="text-xs text-orange-700 dark:text-orange-300 space-y-1 list-decimal ml-4">
                  <li>Create <code class="bg-orange-100 dark:bg-orange-900/40 px-1 rounded">.env</code> file in project root</li>
                  <li>Add: <code class="bg-orange-100 dark:bg-orange-900/40 px-1 rounded">ANTHROPIC_API_KEY=sk-ant-...</code></li>
                  <li>Restart system: <code class="bg-orange-100 dark:bg-orange-900/40 px-1 rounded">./scripts/observability-start.sh</code></li>
                </ol>
                <p class="text-xs text-orange-600 dark:text-orange-400 mt-2">
                  Get your API key: <a href="https://console.anthropic.com/" target="_blank" class="underline">https://console.anthropic.com/</a>
                </p>
              </div>
            </div>
          </label>

          <!-- On-demand Mode -->
          <label
            class="flex items-start gap-4 p-4 border-2 rounded-lg cursor-pointer transition-all"
            :class="selectedMode === 'on-demand'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'"
          >
            <input
              type="radio"
              value="on-demand"
              v-model="selectedMode"
              class="mt-1"
            />
            <div class="flex-1">
              <div class="font-bold text-lg text-gray-900 dark:text-white mb-1">
                On-demand (Claude Code Pro)
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
                Generate summaries in batches via UI button
              </p>
              <p class="text-sm font-semibold text-green-600 dark:text-green-400">
                ✅ Cost: Free (uses your Pro subscription)
              </p>
            </div>
          </label>

          <!-- Disabled Mode -->
          <label
            class="flex items-start gap-4 p-4 border-2 rounded-lg cursor-pointer transition-all"
            :class="selectedMode === 'disabled'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'"
          >
            <input
              type="radio"
              value="disabled"
              v-model="selectedMode"
              class="mt-1"
            />
            <div class="flex-1">
              <div class="font-bold text-lg text-gray-900 dark:text-white mb-1">
                Disabled
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
                No summaries generated
              </p>
              <p class="text-sm font-semibold text-blue-600 dark:text-blue-400">
                ⚡ Fastest hook execution
              </p>
            </div>
          </label>
        </div>

        <!-- Actions -->
        <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-200 dark:border-gray-700">
          <button
            @click="close"
            class="px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            @click="save"
            :disabled="saving || (selectedMode === 'realtime' && !hasAnthropicApiKey) || !hasChanges"
            class="px-6 py-2 text-sm font-bold text-white rounded-lg transition-all duration-200 shadow-md hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
            :class="saving
              ? 'bg-gray-500'
              : 'bg-gradient-to-r from-[var(--theme-primary)] to-[var(--theme-primary-dark)] hover:from-[var(--theme-primary-dark)] hover:to-[var(--theme-primary)]'"
          >
            {{ saving ? 'Saving...' : 'Save Settings' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useSettings, type SummaryMode } from '../composables/useSettings';

const {
  summaryMode,
  hasAnthropicApiKey,
  updateSummaryMode
} = useSettings();

const selectedMode = ref<SummaryMode>(summaryMode.value);
const saving = ref(false);

const hasChanges = computed(() => {
  return selectedMode.value !== summaryMode.value;
});

const emit = defineEmits<{
  close: []
}>();

const close = () => {
  emit('close');
};

const save = async () => {
  saving.value = true;

  let success = true;
  let messages: string[] = [];

  // Update summary mode if changed
  if (selectedMode.value !== summaryMode.value) {
    const modeSuccess = await updateSummaryMode(selectedMode.value);
    if (modeSuccess) {
      messages.push(`Summary mode changed to: ${selectedMode.value}`);
    } else {
      success = false;
      messages.push('Failed to update summary mode');
    }
  }

  if (success && messages.length > 0) {
    alert(`Settings saved!\n\n${messages.join('\n')}`);
    close();
  } else if (!success) {
    alert(`Error saving settings:\n\n${messages.join('\n')}`);
  } else {
    alert('No changes to save.');
  }

  saving.value = false;
};
</script>
