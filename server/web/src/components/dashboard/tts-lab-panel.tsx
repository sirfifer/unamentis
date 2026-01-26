'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Slider } from '@/components/ui/slider';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Play,
  Download,
  Settings,
  Volume2,
  FileAudio,
  RefreshCw,
  Trash2,
  Copy,
  Save,
  FolderPlus,
  X,
  Check,
  Loader2,
} from 'lucide-react';
import { createTTSProfile } from '@/lib/api-client';
import type { TTSProvider } from '@/types/tts-pregen';

/**
 * TTS Lab Panel - Experimentation Interface
 *
 * Allows server administrators to:
 * - Configure different TTS models (Kyutai, Fish Speech, etc.)
 * - Adjust "nerd knobs" (cfg_coef, n_q, padding, etc.)
 * - Generate test audio files
 * - Compare outputs side-by-side
 * - Save configurations for batch processing
 */

interface TTSModel {
  id: string;
  name: string;
  version: string;
  parameters: string;
  capabilities: string[];
  recommended: boolean;
}

interface TTSConfig {
  model: string;
  voice: string;
  cfgCoef: number;
  nQ: number;
  paddingBetween: number;
  paddingBonus: number;
  temperature: number;
  topP: number;
  batchSize: number;
}

interface GeneratedAudio {
  id: string;
  config: TTSConfig;
  text: string;
  url: string;
  duration: number;
  generatedAt: Date;
}

const ttsModels: TTSModel[] = [
  {
    id: 'kyutai-tts-1.6b',
    name: 'Kyutai TTS 1.6B',
    version: '1.6B',
    parameters: '1.6 billion',
    capabilities: [
      '40+ voices (including emotional)',
      'Delayed streams (low latency)',
      'Voice cloning',
      'Batch processing optimized',
    ],
    recommended: true,
  },
  {
    id: 'kyutai-pocket-tts',
    name: 'Kyutai Pocket TTS',
    version: '100M',
    parameters: '100 million',
    capabilities: [
      '8 built-in voices',
      'Voice cloning from 5s',
      'CPU-only (no GPU)',
      '6x real-time speed',
      'Sub-50ms latency',
    ],
    recommended: false,
  },
  {
    id: 'fish-speech-v1.5',
    name: 'Fish Speech V1.5',
    version: 'V1.5',
    parameters: '~2B',
    capabilities: [
      'Zero-shot voice cloning',
      'Multilingual (30+ languages)',
      'Cross-lingual synthesis',
      'Batch processing',
    ],
    recommended: true,
  },
];

const defaultConfig: TTSConfig = {
  model: 'kyutai-tts-1.6b',
  voice: 'sarah',
  cfgCoef: 2.0,
  nQ: 24,
  paddingBetween: 1,
  paddingBonus: 0,
  temperature: 1.0,
  topP: 0.95,
  batchSize: 8,
};

const kyutaiVoices = [
  { id: 'sarah', name: 'Sarah (Neutral)', emotional: false },
  { id: 'john', name: 'John (Neutral)', emotional: false },
  { id: 'emma', name: 'Emma (Warm)', emotional: false },
  { id: 'alex', name: 'Alex (Professional)', emotional: false },
  { id: 'sarah-happy', name: 'Sarah (Happy)', emotional: true },
  { id: 'sarah-sad', name: 'Sarah (Sad)', emotional: true },
  { id: 'john-excited', name: 'John (Excited)', emotional: true },
  { id: 'emma-calm', name: 'Emma (Calm)', emotional: true },
];

// Map model IDs to providers
const modelToProvider: Record<string, TTSProvider> = {
  'kyutai-tts-1.6b': 'chatterbox',
  'kyutai-pocket-tts': 'chatterbox',
  'fish-speech-v1.5': 'vibevoice',
};

export function TTSLabPanel() {
  const [config, setConfig] = useState<TTSConfig>(defaultConfig);
  const [testText, setTestText] = useState(
    'The French Revolution began in 1789 when the Estates-General convened at Versailles.'
  );
  const [generatedAudios, setGeneratedAudios] = useState<GeneratedAudio[]>([]);
  const [generating, setGenerating] = useState(false);
  const [activeTab, setActiveTab] = useState('configure');

  // Save as Profile state
  const [saveProfileModalOpen, setSaveProfileModalOpen] = useState(false);
  const [profileName, setProfileName] = useState('');
  const [profileDescription, setProfileDescription] = useState('');
  const [savingProfile, setSavingProfile] = useState(false);
  const [saveProfileSuccess, setSaveProfileSuccess] = useState(false);
  const [saveProfileError, setSaveProfileError] = useState<string | null>(null);

  // Save to Library state
  const [savingToLibrary, setSavingToLibrary] = useState<string | null>(null);
  const [savedToLibrary, setSavedToLibrary] = useState<Set<string>>(new Set());

  const handleGenerate = async () => {
    setGenerating(true);

    // Simulate API call to generate audio
    // In real implementation, this would call the Python backend
    setTimeout(() => {
      const newAudio: GeneratedAudio = {
        id: `audio-${Date.now()}`,
        config: { ...config },
        text: testText,
        url: '#', // Would be actual audio URL from backend
        duration: 4.5,
        generatedAt: new Date(),
      };

      setGeneratedAudios([newAudio, ...generatedAudios]);
      setGenerating(false);
      setActiveTab('compare');
    }, 2000);
  };

  const handleClearAll = () => {
    setGeneratedAudios([]);
  };

  const handleOpenSaveProfile = () => {
    const model = ttsModels.find((m) => m.id === config.model);
    const voice = kyutaiVoices.find((v) => v.id === config.voice);
    setProfileName(`${model?.name || 'Custom'} - ${voice?.name || config.voice}`);
    setProfileDescription('');
    setSaveProfileSuccess(false);
    setSaveProfileError(null);
    setSaveProfileModalOpen(true);
  };

  const handleSaveAsProfile = async () => {
    if (!profileName.trim()) {
      setSaveProfileError('Please enter a profile name');
      return;
    }

    setSavingProfile(true);
    setSaveProfileError(null);

    try {
      const provider = modelToProvider[config.model] || 'chatterbox';
      await createTTSProfile({
        name: profileName.trim(),
        description: profileDescription.trim() || undefined,
        provider,
        voice_id: config.voice,
        settings: {
          speed: 1.0, // Default, could map from paddingBonus
          cfg_weight: config.cfgCoef,
          extra: {
            n_q: config.nQ,
            padding_between: config.paddingBetween,
            padding_bonus: config.paddingBonus,
            temperature: config.temperature,
            top_p: config.topP,
            model_id: config.model,
          },
        },
        tags: ['experimentation', config.model],
        use_case: 'Generated from TTS Lab experimentation',
        generate_sample: true,
        sample_text: testText.slice(0, 200),
      });

      setSaveProfileSuccess(true);
      setTimeout(() => {
        setSaveProfileModalOpen(false);
        setSaveProfileSuccess(false);
      }, 1500);
    } catch (err) {
      setSaveProfileError(err instanceof Error ? err.message : 'Failed to save profile');
    } finally {
      setSavingProfile(false);
    }
  };

  const handleSaveToLibrary = async (audioId: string) => {
    setSavingToLibrary(audioId);

    // Simulate saving to library - in real implementation, this would call an API
    // to persist the audio file to the audio library for baselines/A-B testing
    setTimeout(() => {
      setSavedToLibrary((prev) => new Set([...prev, audioId]));
      setSavingToLibrary(null);
    }, 1000);
  };

  const selectedModel = ttsModels.find((m) => m.id === config.model);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-100">TTS Lab</h1>
        <p className="text-slate-400 mt-2">
          Experiment with TTS models and settings before batch conversion
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="configure">
            <Settings className="mr-2 h-4 w-4" />
            Configure
          </TabsTrigger>
          <TabsTrigger value="compare">
            <FileAudio className="mr-2 h-4 w-4" />
            Compare
            {generatedAudios.length > 0 && (
              <Badge variant="secondary" className="ml-2">
                {generatedAudios.length}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        {/* Configure Tab */}
        <TabsContent value="configure" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            {/* Model Selection */}
            <Card>
              <CardHeader>
                <CardTitle>Model Selection</CardTitle>
                <CardDescription>Choose TTS model for generation</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>TTS Model</Label>
                  <Select
                    value={config.model}
                    onValueChange={(value) => setConfig({ ...config, model: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {ttsModels.map((model) => (
                        <SelectItem key={model.id} value={model.id}>
                          <div className="flex items-center gap-2">
                            {model.name}
                            {model.recommended && (
                              <Badge variant="success" className="text-xs">
                                Recommended
                              </Badge>
                            )}
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {selectedModel && (
                  <div className="space-y-2 rounded-lg bg-slate-800/50 p-3 text-sm">
                    <div className="font-medium">{selectedModel.name}</div>
                    <div className="text-slate-400">{selectedModel.parameters} parameters</div>
                    <div className="space-y-1">
                      {selectedModel.capabilities.map((cap, idx) => (
                        <div key={idx} className="flex items-start gap-2">
                          <div className="mt-1 h-1.5 w-1.5 rounded-full bg-indigo-500" />
                          <span className="text-slate-400">{cap}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <div className="space-y-2">
                  <Label>Voice</Label>
                  <Select
                    value={config.voice}
                    onValueChange={(value) => setConfig({ ...config, voice: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {kyutaiVoices.map((voice) => (
                        <SelectItem key={voice.id} value={voice.id}>
                          <div className="flex items-center gap-2">
                            {voice.name}
                            {voice.emotional && (
                              <Badge variant="outline" className="text-xs">
                                Emotional
                              </Badge>
                            )}
                          </div>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            {/* Configuration Parameters */}
            <Card>
              <CardHeader>
                <CardTitle>Configuration Parameters</CardTitle>
                <CardDescription>Fine-tune generation settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* CFG Coefficient */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>CFG Coefficient (Voice Adherence)</Label>
                    <span className="text-sm font-medium">{config.cfgCoef.toFixed(1)}</span>
                  </div>
                  <Slider
                    value={config.cfgCoef}
                    onValueChange={(value) => setConfig({ ...config, cfgCoef: value })}
                    min={1.0}
                    max={5.0}
                    step={0.1}
                  />
                  <p className="text-xs text-slate-400">
                    Higher = more faithful to target voice (default: 2.0)
                  </p>
                </div>

                {/* Number of Quantization Levels */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>Quantization Levels (Quality)</Label>
                    <span className="text-sm font-medium">{config.nQ}</span>
                  </div>
                  <Slider
                    value={config.nQ}
                    onValueChange={(value) => setConfig({ ...config, nQ: value })}
                    min={8}
                    max={32}
                    step={1}
                  />
                  <p className="text-xs text-slate-400">
                    Higher = better quality, slower (default: 24)
                  </p>
                </div>

                {/* Padding Between Words */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>Padding Between Words</Label>
                    <span className="text-sm font-medium">{config.paddingBetween}</span>
                  </div>
                  <Slider
                    value={config.paddingBetween}
                    onValueChange={(value) => setConfig({ ...config, paddingBetween: value })}
                    min={0}
                    max={5}
                    step={1}
                  />
                  <p className="text-xs text-slate-400">Articulation clarity (default: 1 frame)</p>
                </div>

                {/* Padding Bonus (Speed) */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>Padding Bonus (Speech Speed)</Label>
                    <span className="text-sm font-medium">{config.paddingBonus}</span>
                  </div>
                  <Slider
                    value={config.paddingBonus}
                    onValueChange={(value) => setConfig({ ...config, paddingBonus: value })}
                    min={-3}
                    max={3}
                    step={1}
                  />
                  <p className="text-xs text-slate-400">
                    Negative = faster, Positive = slower (default: 0)
                  </p>
                </div>

                {/* Temperature */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label>Temperature</Label>
                    <span className="text-sm font-medium">{config.temperature.toFixed(2)}</span>
                  </div>
                  <Slider
                    value={config.temperature}
                    onValueChange={(value) => setConfig({ ...config, temperature: value })}
                    min={0.1}
                    max={2.0}
                    step={0.05}
                  />
                  <p className="text-xs text-slate-400">
                    Lower = more consistent, Higher = more varied (default: 1.0)
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Test Text Input */}
          <Card>
            <CardHeader>
              <CardTitle>Test Text</CardTitle>
              <CardDescription>Enter text to generate test audio</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <Textarea
                value={testText}
                onChange={(e) => setTestText(e.target.value)}
                placeholder="Enter text to synthesize..."
                rows={4}
                className="font-mono text-sm"
              />
              <div className="flex items-center justify-between">
                <p className="text-sm text-slate-400">
                  {testText.length} characters · Est. duration: {(testText.length / 15).toFixed(1)}s
                </p>
                <div className="flex gap-2">
                  <Button variant="outline" onClick={handleOpenSaveProfile}>
                    <Save className="mr-2 h-4 w-4" />
                    Save as Profile
                  </Button>
                  <Button onClick={handleGenerate} disabled={generating || !testText}>
                    {generating ? (
                      <>
                        <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Play className="mr-2 h-4 w-4" />
                        Generate Audio
                      </>
                    )}
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Compare Tab */}
        <TabsContent value="compare" className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold">Generated Samples</h2>
              <p className="text-slate-400">Compare different configurations side-by-side</p>
            </div>
            {generatedAudios.length > 0 && (
              <Button variant="destructive" size="sm" onClick={handleClearAll}>
                <Trash2 className="mr-2 h-4 w-4" />
                Clear All
              </Button>
            )}
          </div>

          {generatedAudios.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center justify-center py-12">
                <Volume2 className="h-12 w-12 text-slate-500" />
                <h3 className="mt-4 text-lg font-semibold">No samples yet</h3>
                <p className="text-sm text-slate-400">
                  Generate audio samples in the Configure tab to compare them here
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {generatedAudios.map((audio) => (
                <Card key={audio.id}>
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-base">
                          {ttsModels.find((m) => m.id === audio.config.model)?.name}
                        </CardTitle>
                        <CardDescription className="mt-1">
                          Voice: {audio.config.voice} · Duration: {audio.duration}s · Generated:{' '}
                          {audio.generatedAt.toLocaleTimeString()}
                        </CardDescription>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleSaveToLibrary(audio.id)}
                          disabled={savingToLibrary === audio.id || savedToLibrary.has(audio.id)}
                        >
                          {savedToLibrary.has(audio.id) ? (
                            <Check className="h-4 w-4 text-emerald-400" />
                          ) : savingToLibrary === audio.id ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <FolderPlus className="h-4 w-4" />
                          )}
                        </Button>
                        <Button variant="outline" size="sm">
                          <Copy className="h-4 w-4" />
                        </Button>
                        <Button variant="outline" size="sm">
                          <Download className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="rounded-lg bg-slate-800/50 p-3 font-mono text-sm">
                      {audio.text}
                    </div>

                    {/* Audio Player Placeholder */}
                    <div className="rounded-lg border border-slate-700 bg-slate-800/30 p-4">
                      <div className="flex items-center gap-4">
                        <Button size="icon" variant="outline">
                          <Play className="h-4 w-4" />
                        </Button>
                        <div className="flex-1">
                          <div className="h-2 rounded-full bg-slate-700">
                            <div className="h-full w-0 rounded-full bg-indigo-500" />
                          </div>
                        </div>
                        <span className="text-sm text-slate-400">
                          0:00 / {audio.duration.toFixed(1)}
                        </span>
                      </div>
                    </div>

                    {/* Configuration Details */}
                    <div className="grid grid-cols-2 gap-4 text-sm md:grid-cols-4">
                      <div>
                        <div className="text-slate-400">CFG Coef</div>
                        <div className="font-medium">{audio.config.cfgCoef.toFixed(1)}</div>
                      </div>
                      <div>
                        <div className="text-slate-400">n_q</div>
                        <div className="font-medium">{audio.config.nQ}</div>
                      </div>
                      <div>
                        <div className="text-slate-400">Padding</div>
                        <div className="font-medium">
                          {audio.config.paddingBetween} / {audio.config.paddingBonus}
                        </div>
                      </div>
                      <div>
                        <div className="text-slate-400">Temp</div>
                        <div className="font-medium">{audio.config.temperature.toFixed(2)}</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>

      {/* Save as Profile Modal */}
      {saveProfileModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <Card className="bg-slate-900 border-slate-700 w-full max-w-md">
            <CardHeader className="flex flex-row items-center justify-between border-b border-slate-800 pb-4">
              <CardTitle className="flex items-center gap-2 text-white">
                <Save className="w-5 h-5 text-orange-400" />
                Save as Profile
              </CardTitle>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSaveProfileModalOpen(false)}
                disabled={savingProfile}
              >
                <X className="w-5 h-5" />
              </Button>
            </CardHeader>

            <CardContent className="pt-6 space-y-4">
              {saveProfileSuccess ? (
                <div className="flex flex-col items-center py-8">
                  <div className="w-12 h-12 rounded-full bg-emerald-500/20 flex items-center justify-center mb-4">
                    <Check className="w-6 h-6 text-emerald-400" />
                  </div>
                  <p className="text-lg font-medium text-white">Profile Saved!</p>
                  <p className="text-sm text-slate-400 mt-1">
                    Your profile is now available in the Batch tab
                  </p>
                </div>
              ) : (
                <>
                  {saveProfileError && (
                    <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-md text-red-400 text-sm">
                      {saveProfileError}
                    </div>
                  )}

                  <div className="space-y-2">
                    <Label htmlFor="profileName">Profile Name</Label>
                    <Input
                      id="profileName"
                      value={profileName}
                      onChange={(e) => setProfileName(e.target.value)}
                      placeholder="e.g., Expressive Quiz Voice"
                      className="bg-slate-800 border-slate-700"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="profileDesc">Description (optional)</Label>
                    <Textarea
                      id="profileDesc"
                      value={profileDescription}
                      onChange={(e) => setProfileDescription(e.target.value)}
                      placeholder="What is this profile optimized for?"
                      rows={2}
                      className="bg-slate-800 border-slate-700"
                    />
                  </div>

                  {/* Config Summary */}
                  <div className="p-3 bg-slate-800/50 rounded-lg space-y-2 text-sm">
                    <div className="font-medium text-slate-300">Configuration Summary</div>
                    <div className="grid grid-cols-2 gap-2 text-slate-400">
                      <div>Model: {selectedModel?.name}</div>
                      <div>Voice: {config.voice}</div>
                      <div>CFG: {config.cfgCoef.toFixed(1)}</div>
                      <div>Temp: {config.temperature.toFixed(2)}</div>
                    </div>
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <Button
                      variant="outline"
                      onClick={() => setSaveProfileModalOpen(false)}
                      disabled={savingProfile}
                    >
                      Cancel
                    </Button>
                    <Button
                      onClick={handleSaveAsProfile}
                      disabled={savingProfile || !profileName.trim()}
                      className="bg-orange-500 hover:bg-orange-600"
                    >
                      {savingProfile ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Saving...
                        </>
                      ) : (
                        <>
                          <Save className="mr-2 h-4 w-4" />
                          Save Profile
                        </>
                      )}
                    </Button>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
