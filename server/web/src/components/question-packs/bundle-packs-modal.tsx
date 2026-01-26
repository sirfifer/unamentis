'use client';

import { useState, useCallback } from 'react';
import {
  X,
  ChevronLeft,
  ChevronRight,
  Loader2,
  AlertCircle,
  Check,
  Layers,
  Package,
  Maximize2,
  Minimize2,
} from 'lucide-react';
import type { KBQuestion, DifficultyTier, CompetitionType } from '@/types/question-packs';
import { QuestionSelector } from './question-selector';
import { Portal } from '@/components/ui/portal';

// Difficulty tier labels
const TIER_LABELS: Record<DifficultyTier, string> = {
  elementary: 'Elementary',
  middle_school: 'Middle School',
  jv: 'JV',
  varsity: 'Varsity',
  championship: 'Championship',
  college: 'College',
};

// API function to create a pack from questions
async function createPackFromQuestions(input: {
  name: string;
  description: string;
  question_ids: string[];
  difficulty_tier: DifficultyTier;
  type: 'custom' | 'bundle';
}): Promise<{ id: string }> {
  const response = await fetch('/api/kb/packs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.error || 'Failed to create pack');
  }
  const data = await response.json();
  return data.pack;
}

interface BundlePacksModalProps {
  onClose: () => void;
  onSuccess: (packId: string) => void;
  preselectedPackId?: string;
}

type Step = 'competition' | 'select' | 'settings';

// Competition type labels and descriptions
const COMPETITION_INFO: Record<
  CompetitionType,
  { label: string; description: string; icon: string }
> = {
  knowledge_bowl: {
    label: 'Knowledge Bowl',
    description:
      'Team-based academic competition with written and oral rounds. Questions focus on broad knowledge across subjects.',
    icon: '🎓',
  },
  quiz_bowl: {
    label: 'Quiz Bowl',
    description:
      'Buzzer-based competition with toss-up, bonus, pyramid, and lightning question formats.',
    icon: '🔔',
  },
};

export function BundlePacksModal({ onClose, onSuccess }: BundlePacksModalProps) {
  const [step, setStep] = useState<Step>('competition');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isMaximized, setIsMaximized] = useState(false);

  // Competition selection
  const [selectedCompetition, setSelectedCompetition] = useState<CompetitionType | null>(null);

  // Question selection
  const [selectedQuestionIds, setSelectedQuestionIds] = useState<string[]>([]);
  const [selectedQuestions, setSelectedQuestions] = useState<KBQuestion[]>([]);

  // Bundle settings
  const [bundleName, setBundleName] = useState('');
  const [bundleDescription, setBundleDescription] = useState('');
  const [difficultyTier, setDifficultyTier] = useState<DifficultyTier>('varsity');

  // Handle selection changes from QuestionSelector
  const handleSelectionChange = useCallback((ids: string[], questions: KBQuestion[]) => {
    setSelectedQuestionIds(ids);
    setSelectedQuestions(questions);
  }, []);

  // Get unique domains from selected questions
  const getUniqueDomains = () => {
    const domains = new Set(selectedQuestions.map((q) => q.domain_id));
    return domains.size;
  };

  const handleNextFromSelect = () => {
    if (selectedQuestionIds.length === 0) {
      setError('Please select at least one question');
      return;
    }

    setError(null);

    // Generate default bundle name based on selection
    if (!bundleName) {
      const domainCount = getUniqueDomains();
      setBundleName(
        `Custom Bundle (${selectedQuestionIds.length} questions, ${domainCount} domains)`
      );
    }

    setStep('settings');
  };

  const handleCreateBundle = async () => {
    if (!bundleName.trim()) {
      setError('Bundle name is required');
      return;
    }

    if (selectedQuestionIds.length === 0) {
      setError('Please select at least one question');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const pack = await createPackFromQuestions({
        name: bundleName.trim(),
        description: bundleDescription.trim(),
        question_ids: selectedQuestionIds,
        difficulty_tier: difficultyTier,
        type: 'bundle',
      });

      onSuccess(pack.id);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create bundle');
    } finally {
      setLoading(false);
    }
  };

  // Handle next from competition step
  const handleNextFromCompetition = () => {
    if (!selectedCompetition) {
      setError('Please select a competition type');
      return;
    }
    setError(null);
    setStep('select');
  };

  // Step 1: Select competition
  if (step === 'competition') {
    return (
      <Portal>
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999] p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-lg w-full max-w-lg">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700">
              <div className="flex items-center gap-3">
                <Layers className="w-5 h-5 text-orange-400" />
                <h2 className="text-lg font-semibold text-white">Create Bundle</h2>
              </div>
              <button
                onClick={onClose}
                className="p-1.5 text-slate-400 hover:text-slate-200 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Step indicator */}
            <div className="px-6 py-3 border-b border-slate-700 bg-slate-800/30">
              <div className="flex items-center gap-2 text-sm">
                <span className="flex items-center gap-1.5 text-purple-400">
                  <span className="w-5 h-5 rounded-full bg-purple-500 text-white text-xs flex items-center justify-center">
                    1
                  </span>
                  Competition
                </span>
                <ChevronRight className="w-4 h-4 text-slate-600" />
                <span className="text-slate-500">Select Questions</span>
                <ChevronRight className="w-4 h-4 text-slate-600" />
                <span className="text-slate-500">Settings</span>
              </div>
            </div>

            {/* Content */}
            <div className="p-6">
              {error && (
                <div className="flex items-center gap-2 p-3 mb-4 bg-red-500/10 border border-red-500/30 rounded-md text-red-400 text-sm">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  {error}
                </div>
              )}

              <p className="text-slate-400 text-sm mb-4">
                Select the competition type this bundle is for. This determines which filters and
                question types are available.
              </p>

              <div className="space-y-3">
                {(
                  Object.entries(COMPETITION_INFO) as [
                    CompetitionType,
                    (typeof COMPETITION_INFO)[CompetitionType],
                  ][]
                ).map(([type, info]) => (
                  <button
                    key={type}
                    onClick={() => setSelectedCompetition(type)}
                    className={`w-full p-4 rounded-lg border text-left transition-all ${
                      selectedCompetition === type
                        ? 'bg-purple-500/10 border-purple-500 ring-1 ring-purple-500/50'
                        : 'bg-slate-800/50 border-slate-700 hover:border-slate-600'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <span className="text-2xl">{info.icon}</span>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-white">{info.label}</span>
                          {selectedCompetition === type && (
                            <Check className="w-4 h-4 text-purple-400" />
                          )}
                        </div>
                        <p className="text-sm text-slate-400 mt-1">{info.description}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Footer */}
            <div className="flex justify-end gap-2 px-6 py-4 border-t border-slate-700">
              <button
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleNextFromCompetition}
                disabled={!selectedCompetition}
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </Portal>
    );
  }

  // Step 2: Select questions
  if (step === 'select') {
    return (
      <Portal>
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999] p-4">
          <div
            className={`bg-slate-900 border border-slate-700 rounded-lg flex flex-col transition-all duration-200 ${
              isMaximized
                ? 'w-full h-full max-w-none max-h-none rounded-none'
                : 'w-full max-w-6xl max-h-[90vh]'
            }`}
          >
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700 flex-shrink-0">
              <div className="flex items-center gap-3">
                <Layers className="w-5 h-5 text-orange-400" />
                <h2 className="text-lg font-semibold text-white">Create Bundle</h2>
              </div>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setIsMaximized(!isMaximized)}
                  className="p-1.5 text-slate-400 hover:text-slate-200 transition-colors"
                  title={isMaximized ? 'Restore' : 'Maximize'}
                >
                  {isMaximized ? (
                    <Minimize2 className="w-5 h-5" />
                  ) : (
                    <Maximize2 className="w-5 h-5" />
                  )}
                </button>
                <button
                  onClick={onClose}
                  className="p-1.5 text-slate-400 hover:text-slate-200 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Step indicator */}
            <div className="px-6 py-3 border-b border-slate-700 bg-slate-800/30 flex-shrink-0">
              <div className="flex items-center gap-2 text-sm">
                <span className="flex items-center gap-1.5 text-slate-400">
                  <span className="w-5 h-5 rounded-full bg-slate-600 text-white text-xs flex items-center justify-center">
                    <Check className="w-3 h-3" />
                  </span>
                  Competition
                </span>
                <ChevronRight className="w-4 h-4 text-slate-600" />
                <span className="flex items-center gap-1.5 text-purple-400">
                  <span className="w-5 h-5 rounded-full bg-purple-500 text-white text-xs flex items-center justify-center">
                    2
                  </span>
                  Select Questions
                </span>
                <ChevronRight className="w-4 h-4 text-slate-600" />
                <span className="text-slate-500">Settings</span>
              </div>
            </div>

            {/* Content */}
            <div className="p-6 flex-1 overflow-hidden">
              {error && (
                <div className="flex items-center gap-2 p-3 mb-4 bg-red-500/10 border border-red-500/30 rounded-md text-red-400 text-sm">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  {error}
                </div>
              )}

              <QuestionSelector
                onSelectionChange={handleSelectionChange}
                maxHeight={isMaximized ? 'calc(100vh - 280px)' : 'calc(90vh - 280px)'}
                competitionType={selectedCompetition || 'knowledge_bowl'}
              />
            </div>

            {/* Footer */}
            <div className="flex justify-between items-center gap-2 px-6 py-4 border-t border-slate-700 flex-shrink-0">
              <div className="flex items-center gap-4">
                <button
                  onClick={() => setStep('competition')}
                  className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors"
                >
                  <ChevronLeft className="w-4 h-4" />
                  Back
                </button>
                <div className="text-sm text-slate-400">
                  {selectedQuestionIds.length > 0 && (
                    <span>
                      {selectedQuestionIds.length} question
                      {selectedQuestionIds.length !== 1 ? 's' : ''} selected
                      {getUniqueDomains() > 0 &&
                        ` from ${getUniqueDomains()} domain${getUniqueDomains() !== 1 ? 's' : ''}`}
                    </span>
                  )}
                </div>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={onClose}
                  className="px-4 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleNextFromSelect}
                  disabled={selectedQuestionIds.length === 0}
                  className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </Portal>
    );
  }

  // Step 2: Bundle settings
  return (
    <Portal>
      <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999] p-4">
        <div className="bg-slate-900 border border-slate-700 rounded-lg w-full max-w-lg">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700">
            <div className="flex items-center gap-3">
              <Layers className="w-5 h-5 text-orange-400" />
              <h2 className="text-lg font-semibold text-white">Create Bundle</h2>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 text-slate-400 hover:text-slate-200 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Step indicator */}
          <div className="px-6 py-3 border-b border-slate-700 bg-slate-800/30">
            <div className="flex items-center gap-2 text-sm">
              <span className="flex items-center gap-1.5 text-slate-400">
                <span className="w-5 h-5 rounded-full bg-slate-600 text-white text-xs flex items-center justify-center">
                  <Check className="w-3 h-3" />
                </span>
                Competition
              </span>
              <ChevronRight className="w-4 h-4 text-slate-600" />
              <span className="flex items-center gap-1.5 text-slate-400">
                <span className="w-5 h-5 rounded-full bg-slate-600 text-white text-xs flex items-center justify-center">
                  <Check className="w-3 h-3" />
                </span>
                Select Questions
              </span>
              <ChevronRight className="w-4 h-4 text-slate-600" />
              <span className="flex items-center gap-1.5 text-purple-400">
                <span className="w-5 h-5 rounded-full bg-purple-500 text-white text-xs flex items-center justify-center">
                  3
                </span>
                Settings
              </span>
            </div>
          </div>

          {/* Content */}
          <div className="p-6 space-y-4">
            {error && (
              <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-md text-red-400 text-sm">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                {error}
              </div>
            )}

            {/* Bundle Name */}
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">
                Bundle Name <span className="text-red-400">*</span>
              </label>
              <input
                type="text"
                value={bundleName}
                onChange={(e) => setBundleName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500/50"
                placeholder="Enter bundle name..."
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">Description</label>
              <textarea
                value={bundleDescription}
                onChange={(e) => setBundleDescription(e.target.value)}
                rows={2}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500/50 resize-none"
                placeholder="Describe the purpose of this bundle..."
              />
            </div>

            {/* Difficulty Tier */}
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">
                Competition Level
              </label>
              <select
                value={difficultyTier}
                onChange={(e) => setDifficultyTier(e.target.value as DifficultyTier)}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-300 focus:outline-none focus:ring-2 focus:ring-purple-500/50"
              >
                {Object.entries(TIER_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            {/* Summary */}
            <div className="p-3 bg-slate-800/50 rounded-lg">
              <div className="flex items-center gap-2 text-sm text-slate-300">
                <Package className="w-4 h-4" />
                <span>
                  Creating bundle with {selectedQuestionIds.length} question
                  {selectedQuestionIds.length !== 1 ? 's' : ''}
                  {getUniqueDomains() > 0 &&
                    ` from ${getUniqueDomains()} domain${getUniqueDomains() !== 1 ? 's' : ''}`}
                </span>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="flex justify-between gap-2 px-6 py-4 border-t border-slate-700">
            <button
              onClick={() => setStep('select')}
              className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors"
            >
              <ChevronLeft className="w-4 h-4" />
              Back
            </button>
            <button
              onClick={handleCreateBundle}
              disabled={loading || !bundleName.trim()}
              className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              Create Bundle
            </button>
          </div>
        </div>
      </div>
    </Portal>
  );
}
