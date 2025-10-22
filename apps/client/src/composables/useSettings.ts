import { ref, computed, onMounted } from 'vue';

export type SummaryMode = 'realtime' | 'on-demand' | 'disabled';

export interface Settings {
  summaryMode: SummaryMode;
  hasAnthropicApiKey: boolean;
}

const settings = ref<Settings>({
  summaryMode: 'on-demand',
  hasAnthropicApiKey: false
});

const loading = ref(false);
const error = ref<string | null>(null);

export function useSettings() {
  const loadSettings = async () => {
    loading.value = true;
    error.value = null;

    try {
      const response = await fetch('http://localhost:4000/settings');
      if (!response.ok) {
        throw new Error('Failed to load settings');
      }

      const data = await response.json();
      settings.value = {
        summaryMode: data.summaryMode,
        hasAnthropicApiKey: data.hasAnthropicApiKey
      };
    } catch (err) {
      console.error('Error loading settings:', err);
      error.value = 'Failed to load settings';
    } finally {
      loading.value = false;
    }
  };

  const updateSummaryMode = async (mode: SummaryMode): Promise<boolean> => {
    loading.value = true;
    error.value = null;

    try {
      const response = await fetch('http://localhost:4000/settings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ summaryMode: mode })
      });

      if (!response.ok) {
        throw new Error('Failed to update settings');
      }

      const data = await response.json();
      settings.value = {
        summaryMode: data.settings.summaryMode,
        hasAnthropicApiKey: data.hasAnthropicApiKey
      };

      return true;
    } catch (err) {
      console.error('Error updating settings:', err);
      error.value = 'Failed to update settings';
      return false;
    } finally {
      loading.value = false;
    }
  };

  const summaryMode = computed(() => settings.value.summaryMode);
  const hasAnthropicApiKey = computed(() => settings.value.hasAnthropicApiKey);

  onMounted(() => {
    loadSettings();
  });

  return {
    summaryMode,
    hasAnthropicApiKey,
    loading,
    error,
    updateSummaryMode,
    loadSettings
  };
}
