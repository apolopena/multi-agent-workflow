<template>
  <div class="bg-gradient-to-r from-[var(--theme-bg-primary)] to-[var(--theme-bg-secondary)] border-b-2 border-[var(--theme-primary)] px-3 py-4 mobile:py-2 shadow-lg">
    <div class="flex flex-wrap gap-3 items-center mobile:flex-col mobile:items-stretch">
      <div class="flex-1 min-w-0 mobile:w-full">
        <label class="block text-base mobile:text-sm font-bold text-[var(--theme-primary)] mb-1.5 drop-shadow-sm">
          Source App
        </label>
        <select
          v-model="localFilters.sourceApp"
          @change="updateFilters"
          class="w-full px-4 py-2 mobile:px-2 mobile:py-1.5 text-base mobile:text-sm border border-[var(--theme-primary)] rounded-lg focus:ring-2 focus:ring-[var(--theme-primary)]/30 focus:border-[var(--theme-primary-dark)] bg-[var(--theme-bg-primary)] text-[var(--theme-text-primary)] shadow-md hover:shadow-lg transition-all duration-200"
        >
          <option value="">All Sources</option>
          <option v-for="app in filterOptions.source_apps" :key="app" :value="app">
            {{ app }}
          </option>
        </select>
      </div>
      
      <div class="flex-1 min-w-0 mobile:w-full">
        <label class="block text-base mobile:text-sm font-bold text-[var(--theme-primary)] mb-1.5 drop-shadow-sm">
          Session ID
        </label>
        <select
          v-model="localFilters.sessionId"
          @change="updateFilters"
          class="w-full px-4 py-2 mobile:px-2 mobile:py-1.5 text-base mobile:text-sm border border-[var(--theme-primary)] rounded-lg focus:ring-2 focus:ring-[var(--theme-primary)]/30 focus:border-[var(--theme-primary-dark)] bg-[var(--theme-bg-primary)] text-[var(--theme-text-primary)] shadow-md hover:shadow-lg transition-all duration-200"
        >
          <option value="">All Sessions</option>
          <option v-for="session in filterOptions.session_ids" :key="session" :value="session">
            {{ session.slice(0, 8) }}...
          </option>
        </select>
      </div>
      
      <div class="flex-1 min-w-0 mobile:w-full">
        <label class="block text-base mobile:text-sm font-bold text-[var(--theme-primary)] mb-1.5 drop-shadow-sm">
          Event Type
        </label>
        <select
          v-model="localFilters.eventType"
          @change="updateFilters"
          class="w-full px-4 py-2 mobile:px-2 mobile:py-1.5 text-base mobile:text-sm border border-[var(--theme-primary)] rounded-lg focus:ring-2 focus:ring-[var(--theme-primary)]/30 focus:border-[var(--theme-primary-dark)] bg-[var(--theme-bg-primary)] text-[var(--theme-text-primary)] shadow-md hover:shadow-lg transition-all duration-200"
        >
          <option value="">All Types</option>
          <option v-for="type in filterOptions.hook_event_types" :key="type" :value="type">
            {{ type }}
          </option>
        </select>
      </div>
      
      <button
        v-if="hasActiveFilters"
        @click="clearFilters"
        class="px-4 py-2 mobile:px-2 mobile:py-1.5 mobile:w-full text-base mobile:text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-md transition-colors"
      >
        Clear Filters
      </button>

      <!-- Settings Button -->
      <button
        @click="showSettings = true"
        class="px-4 py-2 mobile:px-2 mobile:py-1.5 mobile:w-full text-base mobile:text-sm font-bold text-white rounded-lg transition-all duration-200 shadow-md hover:shadow-lg bg-gradient-to-r from-gray-600 to-gray-700 hover:from-gray-700 hover:to-gray-800"
        title="Summary Settings"
      >
        ⚙️ Settings
      </button>

      <!-- Generate Summaries Button - Only show in on-demand mode -->
      <button
        v-if="summaryMode === 'on-demand'"
        @click="generateSummaries"
        :disabled="generatingSummaries || visibleEventsWithoutSummaries === 0"
        class="px-4 py-2 mobile:px-2 mobile:py-1.5 mobile:w-full text-base mobile:text-sm font-bold text-white rounded-lg transition-all duration-200 shadow-md hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        :class="generatingSummaries ? 'bg-gray-500' : 'bg-gradient-to-r from-[var(--theme-primary)] to-[var(--theme-primary-dark)] hover:from-[var(--theme-primary-dark)] hover:to-[var(--theme-primary)]'"
        :title="`Generate summaries for ${visibleEventsWithoutSummaries} visible events`"
      >
        {{ generatingSummaries ? 'Preparing...' : `Generate Summaries (${visibleEventsWithoutSummaries})` }}
      </button>
    </div>

    <!-- Settings Panel Modal -->
    <SettingsPanel v-if="showSettings" @close="showSettings = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { FilterOptions, HookEvent } from '../types';
import SettingsPanel from './SettingsPanel.vue';
import { useSettings } from '../composables/useSettings';

const props = defineProps<{
  filters: {
    sourceApp: string;
    sessionId: string;
    eventType: string;
  };
  events: HookEvent[];
}>();

// Helper: Check if event is a meta-event (Jerry's summary processing)
const isMetaEvent = (event: HookEvent): boolean => {
  const payload = event.payload;

  // Check if it's a subagent event
  if (event.hook_event_type === 'SubagentStart' || event.hook_event_type === 'SubagentStop') {
    return true;
  }

  // Check if it involves summary-related files/endpoints
  if (payload.tool_input?.file_path === '.summary-prompt.txt') {
    return true;
  }

  if (payload.tool_input?.command &&
      (payload.tool_input.command.includes('/events/batch-summaries') ||
       payload.tool_input.command.includes('/events/save-summary-prompt') ||
       payload.tool_input.command.includes('.summary-prompt.txt'))) {
    return true;
  }

  // Check if summary already has meta-event tag
  if (event.summary?.startsWith('[Meta-event:')) {
    return true;
  }

  return false;
};

// Computed: count events without summaries from visible events (excluding meta-events)
const visibleEventsWithoutSummaries = computed(() => {
  return props.events.filter(e => !e.summary && !isMetaEvent(e)).length;
});

const emit = defineEmits<{
  'update:filters': [filters: typeof props.filters];
}>();

const filterOptions = ref<FilterOptions>({
  source_apps: [],
  session_ids: [],
  hook_event_types: []
});

const localFilters = ref({ ...props.filters });
const generatingSummaries = ref(false);
const showSettings = ref(false);

// Get summary mode from settings
const { summaryMode } = useSettings();

const hasActiveFilters = computed(() => {
  return localFilters.value.sourceApp || localFilters.value.sessionId || localFilters.value.eventType;
});

const updateFilters = () => {
  emit('update:filters', { ...localFilters.value });
};

const clearFilters = () => {
  localFilters.value = {
    sourceApp: '',
    sessionId: '',
    eventType: ''
  };
  updateFilters();
};

const fetchFilterOptions = async () => {
  try {
    const response = await fetch('http://localhost:4000/events/filter-options');
    if (response.ok) {
      filterOptions.value = await response.json();
    }
  } catch (error) {
    console.error('Failed to fetch filter options:', error);
  }
};


const buildSummaryPrompt = (events: HookEvent[]): string => {
  const eventsList = events.map(e => {
    const payloadStr = JSON.stringify(e.payload, null, 2);
    const truncatedPayload = payloadStr.length > 500 ? payloadStr.substring(0, 500) + '...' : payloadStr;

    return `Event ID: ${e.id}
Type: ${e.hook_event_type}
Payload: ${truncatedPayload}
---`;
  }).join('\n\n');

  return `Please generate concise one-sentence summaries for these hook events.

For each event, respond with ONLY valid JSON in this format:
{"id": <event_id>, "summary": "<one sentence summary>"}

Requirements for summaries:
- ONE sentence only (no period at the end)
- Focus on the key action or information
- Be specific and technical
- Keep under 15 words
- Use present tense
- No quotes or extra formatting

Events to summarize:
${eventsList}

After generating the summaries, execute this bash command to update the database:
curl -X POST http://localhost:4000/events/batch-summaries \\
  -H "Content-Type: application/json" \\
  -d '{"summaries": [<your generated JSON objects here>]}'`;
};

const generateSummaries = async () => {
  generatingSummaries.value = true;

  try {
    // Get ALL visible events without summaries (including meta-events)
    // Jerry will tag meta-events with [Meta-event: prefix
    const eventsToSummarize = props.events.filter(e => !e.summary);

    if (eventsToSummarize.length === 0) {
      alert('No events need summaries!');
      generatingSummaries.value = false;
      return;
    }

    const prompt = buildSummaryPrompt(eventsToSummarize);

    // Save prompt to file on server
    const saveResponse = await fetch('http://localhost:4000/events/save-summary-prompt', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt })
    });

    if (!saveResponse.ok) {
      throw new Error('Failed to save prompt to file');
    }

    alert(
      `✅ Summary prompt saved!\n\n` +
      `Go to Claude Code and run:\n` +
      `/process-summaries`
    );
  } catch (error) {
    console.error('Error generating summaries:', error);
    alert('Failed to generate summaries. See console for details.');
  } finally {
    generatingSummaries.value = false;
  }
};

onMounted(() => {
  fetchFilterOptions();

  // Refresh filter options periodically
  setInterval(() => {
    fetchFilterOptions();
  }, 10000);
});
</script>