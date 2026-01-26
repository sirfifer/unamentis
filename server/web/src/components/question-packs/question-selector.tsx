'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Search,
  Filter,
  X,
  Plus,
  Minus,
  ChevronLeft,
  ChevronRight,
  Loader2,
  Volume2,
  VolumeX,
  Check,
  ChevronDown,
  CheckSquare,
  Square,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import type { KBQuestion, DomainId, QuestionType, CompetitionType } from '@/types/question-packs';

// Domain labels
const DOMAIN_LABELS: Record<DomainId, string> = {
  science: 'Science',
  mathematics: 'Mathematics',
  literature: 'Literature',
  history: 'History',
  social_studies: 'Social Studies',
  fine_arts: 'Fine Arts',
  current_events: 'Current Events',
  language: 'Language',
  religion_philosophy: 'Religion & Philosophy',
  pop_culture: 'Pop Culture',
  technology: 'Technology',
  miscellaneous: 'Miscellaneous',
};

// Type labels
const TYPE_LABELS: Record<QuestionType, string> = {
  toss_up: 'Toss-Up',
  bonus: 'Bonus',
  pyramid: 'Pyramid',
  lightning: 'Lightning',
};

// Difficulty colors
const DIFFICULTY_COLORS: Record<number, string> = {
  1: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  2: 'bg-lime-500/20 text-lime-400 border-lime-500/30',
  3: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  4: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
  5: 'bg-red-500/20 text-red-400 border-red-500/30',
};

// API function to fetch questions
async function fetchQuestions(params: {
  domain_id?: string;
  difficulty?: string;
  question_type?: string;
  has_audio?: string;
  search?: string;
  limit?: number;
  offset?: number;
}): Promise<{ questions: KBQuestion[]; total: number }> {
  const queryParams = new URLSearchParams();
  if (params.domain_id) queryParams.set('domain_id', params.domain_id);
  if (params.difficulty) queryParams.set('difficulty', params.difficulty);
  if (params.question_type) queryParams.set('question_type', params.question_type);
  if (params.has_audio) queryParams.set('has_audio', params.has_audio);
  if (params.search) queryParams.set('search', params.search);
  if (params.limit) queryParams.set('limit', String(params.limit));
  if (params.offset) queryParams.set('offset', String(params.offset));

  const query = queryParams.toString();
  const response = await fetch(`/api/kb/questions${query ? `?${query}` : ''}`);

  if (!response.ok) {
    throw new Error('Failed to fetch questions');
  }

  const data = await response.json();
  return { questions: data.questions || [], total: data.total || 0 };
}

interface QuestionSelectorProps {
  onSelectionChange: (selectedIds: string[], selectedQuestions: KBQuestion[]) => void;
  initialSelection?: string[];
  maxHeight?: string;
  competitionType?: CompetitionType;
}

export function QuestionSelector({
  onSelectionChange,
  initialSelection = [],
  maxHeight = '600px',
  competitionType = 'knowledge_bowl',
}: QuestionSelectorProps) {
  // Determine which filters to show based on competition type
  const showQuestionTypeFilter = competitionType === 'quiz_bowl';
  // Questions state
  const [questions, setQuestions] = useState<KBQuestion[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Selection state
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set(initialSelection));
  const [selectedQuestions, setSelectedQuestions] = useState<KBQuestion[]>([]);

  // Filter state
  const [searchQuery, setSearchQuery] = useState('');
  const [filterDomain, setFilterDomain] = useState<string>('');
  const [filterDifficulty, setFilterDifficulty] = useState<string>('');
  const [filterType, setFilterType] = useState<string>('');
  const [filterAudio, setFilterAudio] = useState<string>('');
  const [showFilters, setShowFilters] = useState(false);

  // Pagination
  const [page, setPage] = useState(1);
  const pageSize = 20;

  // Load questions
  const loadQuestions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await fetchQuestions({
        domain_id: filterDomain || undefined,
        difficulty: filterDifficulty || undefined,
        question_type: filterType || undefined,
        has_audio: filterAudio || undefined,
        search: searchQuery || undefined,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      });
      setQuestions(result.questions);
      setTotal(result.total);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load questions');
    } finally {
      setLoading(false);
    }
  }, [filterDomain, filterDifficulty, filterType, filterAudio, searchQuery, page]);

  useEffect(() => {
    loadQuestions();
  }, [loadQuestions]);

  // Notify parent of selection changes
  useEffect(() => {
    onSelectionChange(Array.from(selectedIds), selectedQuestions);
  }, [selectedIds, selectedQuestions, onSelectionChange]);

  // Toggle question selection
  const toggleSelection = (question: KBQuestion) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(question.id)) {
        next.delete(question.id);
        setSelectedQuestions((sq) => sq.filter((q) => q.id !== question.id));
      } else {
        next.add(question.id);
        setSelectedQuestions((sq) => [...sq, question]);
      }
      return next;
    });
  };

  // Select all visible questions
  const selectAllVisible = () => {
    const newIds = new Set(selectedIds);
    const newQuestions = [...selectedQuestions];
    for (const q of questions) {
      if (!newIds.has(q.id)) {
        newIds.add(q.id);
        newQuestions.push(q);
      }
    }
    setSelectedIds(newIds);
    setSelectedQuestions(newQuestions);
  };

  // Deselect all visible questions
  const deselectAllVisible = () => {
    const visibleIds = new Set(questions.map((q) => q.id));
    setSelectedIds((prev) => {
      const next = new Set(prev);
      for (const id of visibleIds) {
        next.delete(id);
      }
      return next;
    });
    setSelectedQuestions((sq) => sq.filter((q) => !visibleIds.has(q.id)));
  };

  // Remove from selection
  const removeFromSelection = (questionId: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      next.delete(questionId);
      return next;
    });
    setSelectedQuestions((sq) => sq.filter((q) => q.id !== questionId));
  };

  // Clear all selections
  const clearSelection = () => {
    setSelectedIds(new Set());
    setSelectedQuestions([]);
  };

  // Clear filters
  const clearFilters = () => {
    setSearchQuery('');
    setFilterDomain('');
    setFilterDifficulty('');
    setFilterType('');
    setFilterAudio('');
    setPage(1);
  };

  const hasActiveFilters =
    searchQuery ||
    filterDomain ||
    filterDifficulty ||
    (showQuestionTypeFilter && filterType) ||
    filterAudio;
  const totalPages = Math.ceil(total / pageSize);
  const allVisibleSelected = questions.length > 0 && questions.every((q) => selectedIds.has(q.id));

  return (
    <div className="flex gap-4" style={{ maxHeight }}>
      {/* Left Panel: Question Browser */}
      <div className="flex-1 flex flex-col bg-slate-900/80 border border-slate-700 rounded-lg overflow-hidden min-w-0">
        {/* Search and Filter Header */}
        <div className="px-4 py-3 border-b border-slate-700 space-y-3">
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search questions..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setPage(1);
                }}
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500/50 text-sm"
              />
            </div>
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors ${
                hasActiveFilters
                  ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30'
                  : 'bg-slate-800 text-slate-300 border border-slate-700 hover:bg-slate-700'
              }`}
            >
              <Filter className="w-4 h-4" />
              Filters
              {hasActiveFilters && <span className="w-2 h-2 rounded-full bg-purple-400" />}
            </button>
          </div>

          {/* Filter Panel */}
          {showFilters && (
            <div className="flex flex-wrap gap-3 pt-2">
              {/* Domain Filter */}
              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-400">Domain:</span>
                <select
                  value={filterDomain}
                  onChange={(e) => {
                    setFilterDomain(e.target.value);
                    setPage(1);
                  }}
                  className="px-2 py-1 bg-slate-700 border border-slate-600 rounded text-sm text-slate-300 focus:outline-none"
                >
                  <option value="">All</option>
                  {Object.entries(DOMAIN_LABELS).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Difficulty Filter */}
              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-400">Difficulty:</span>
                <div className="flex gap-1">
                  {[1, 2, 3, 4, 5].map((level) => (
                    <button
                      key={level}
                      onClick={() => {
                        setFilterDifficulty(
                          filterDifficulty === String(level) ? '' : String(level)
                        );
                        setPage(1);
                      }}
                      className={`w-7 h-7 rounded text-xs font-medium transition-colors ${
                        filterDifficulty === String(level)
                          ? 'bg-purple-500 text-white'
                          : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                      }`}
                    >
                      {level}
                    </button>
                  ))}
                </div>
              </div>

              {/* Type Filter - Only shown for Quiz Bowl */}
              {showQuestionTypeFilter && (
                <div className="flex items-center gap-2">
                  <span className="text-xs text-slate-400">Type:</span>
                  <select
                    value={filterType}
                    onChange={(e) => {
                      setFilterType(e.target.value);
                      setPage(1);
                    }}
                    className="px-2 py-1 bg-slate-700 border border-slate-600 rounded text-sm text-slate-300 focus:outline-none"
                  >
                    <option value="">All</option>
                    {Object.entries(TYPE_LABELS).map(([value, label]) => (
                      <option key={value} value={value}>
                        {label}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Audio Filter */}
              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-400">Audio:</span>
                <select
                  value={filterAudio}
                  onChange={(e) => {
                    setFilterAudio(e.target.value);
                    setPage(1);
                  }}
                  className="px-2 py-1 bg-slate-700 border border-slate-600 rounded text-sm text-slate-300 focus:outline-none"
                >
                  <option value="">All</option>
                  <option value="true">Has Audio</option>
                  <option value="false">No Audio</option>
                </select>
              </div>

              {hasActiveFilters && (
                <button
                  onClick={clearFilters}
                  className="text-xs text-purple-400 hover:text-purple-300"
                >
                  Clear filters
                </button>
              )}
            </div>
          )}
        </div>

        {/* Results Header */}
        <div className="flex items-center justify-between px-4 py-2 bg-slate-800/50 border-b border-slate-700">
          <div className="flex items-center gap-3">
            <button
              onClick={allVisibleSelected ? deselectAllVisible : selectAllVisible}
              className="flex items-center gap-2 text-sm text-slate-400 hover:text-slate-200"
            >
              {allVisibleSelected ? (
                <CheckSquare className="w-4 h-4 text-purple-400" />
              ) : (
                <Square className="w-4 h-4" />
              )}
              {allVisibleSelected ? 'Deselect page' : 'Select page'}
            </button>
          </div>
          <span className="text-sm text-slate-400">{total.toLocaleString()} questions found</span>
        </div>

        {/* Questions List */}
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="w-6 h-6 text-purple-500 animate-spin" />
            </div>
          ) : error ? (
            <div className="p-4 text-red-400 text-center">{error}</div>
          ) : questions.length === 0 ? (
            <div className="py-12 text-center text-slate-400">
              {hasActiveFilters ? 'No questions match your filters' : 'No questions available'}
            </div>
          ) : (
            <div className="divide-y divide-slate-800">
              {questions.map((question) => (
                <div
                  key={question.id}
                  onClick={() => toggleSelection(question)}
                  className={`px-4 py-3 cursor-pointer transition-colors ${
                    selectedIds.has(question.id)
                      ? 'bg-purple-500/10 border-l-2 border-l-purple-500'
                      : 'hover:bg-slate-800/50 border-l-2 border-l-transparent'
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div
                      className={`mt-1 w-5 h-5 rounded border flex-shrink-0 flex items-center justify-center transition-colors ${
                        selectedIds.has(question.id)
                          ? 'bg-purple-500 border-purple-500'
                          : 'border-slate-600'
                      }`}
                    >
                      {selectedIds.has(question.id) && <Check className="w-3 h-3 text-white" />}
                    </div>

                    <div className="flex-1 min-w-0">
                      <p className="text-slate-200 text-sm line-clamp-2">
                        {question.question_text}
                      </p>
                      <p className="text-slate-400 text-xs mt-1">
                        <span className="text-slate-500">A: </span>
                        {question.answer_text}
                      </p>

                      <div className="flex flex-wrap items-center gap-1.5 mt-2">
                        <Badge
                          className={DIFFICULTY_COLORS[question.difficulty] || DIFFICULTY_COLORS[3]}
                        >
                          {question.difficulty}
                        </Badge>
                        <Badge className="bg-slate-700/50 text-slate-300 border-slate-600 text-xs">
                          {DOMAIN_LABELS[question.domain_id as DomainId] || question.domain_id}
                        </Badge>
                        {question.has_audio ? (
                          <Volume2 className="w-3 h-3 text-emerald-400" />
                        ) : (
                          <VolumeX className="w-3 h-3 text-slate-500" />
                        )}
                      </div>
                    </div>

                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleSelection(question);
                      }}
                      className={`p-1.5 rounded transition-colors ${
                        selectedIds.has(question.id)
                          ? 'text-red-400 hover:bg-red-500/20'
                          : 'text-emerald-400 hover:bg-emerald-500/20'
                      }`}
                    >
                      {selectedIds.has(question.id) ? (
                        <Minus className="w-4 h-4" />
                      ) : (
                        <Plus className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-700 bg-slate-800/30">
            <span className="text-sm text-slate-400">
              Page {page} of {totalPages}
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
                className="p-1.5 text-slate-400 hover:text-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
                className="p-1.5 text-slate-400 hover:text-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Right Panel: Selected Questions */}
      <div className="w-80 flex flex-col bg-slate-900/80 border border-slate-700 rounded-lg overflow-hidden flex-shrink-0">
        {/* Selection Header */}
        <div className="px-4 py-3 border-b border-slate-700 bg-slate-800/50">
          <div className="flex items-center justify-between">
            <h3 className="font-medium text-slate-200">Selected Questions</h3>
            <Badge className="bg-purple-500/20 text-purple-300 border-purple-500/30">
              {selectedIds.size}
            </Badge>
          </div>
          {selectedIds.size > 0 && (
            <button
              onClick={clearSelection}
              className="text-xs text-slate-400 hover:text-red-400 mt-1"
            >
              Clear all
            </button>
          )}
        </div>

        {/* Selected Questions List */}
        <div className="flex-1 overflow-y-auto">
          {selectedQuestions.length === 0 ? (
            <div className="py-12 text-center text-slate-500">
              <ChevronDown className="w-8 h-8 mx-auto mb-2 opacity-50" />
              <p className="text-sm">No questions selected</p>
              <p className="text-xs mt-1">Click questions to add them</p>
            </div>
          ) : (
            <div className="divide-y divide-slate-800">
              {selectedQuestions.map((question) => (
                <div
                  key={question.id}
                  className="px-3 py-2 hover:bg-slate-800/50 transition-colors group"
                >
                  <div className="flex items-start gap-2">
                    <div className="flex-1 min-w-0">
                      <p className="text-slate-300 text-xs line-clamp-2">
                        {question.question_text}
                      </p>
                      <div className="flex items-center gap-1 mt-1">
                        <Badge
                          className={`${DIFFICULTY_COLORS[question.difficulty] || DIFFICULTY_COLORS[3]} text-xs py-0`}
                        >
                          {question.difficulty}
                        </Badge>
                        <span className="text-xs text-slate-500">
                          {DOMAIN_LABELS[question.domain_id as DomainId] || question.domain_id}
                        </span>
                      </div>
                    </div>
                    <button
                      onClick={() => removeFromSelection(question.id)}
                      className="p-1 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Selection Summary */}
        {selectedIds.size > 0 && (
          <div className="px-4 py-3 border-t border-slate-700 bg-slate-800/30">
            <div className="text-xs text-slate-400 space-y-1">
              <div className="flex justify-between">
                <span>Questions:</span>
                <span className="text-slate-300">{selectedIds.size}</span>
              </div>
              <div className="flex justify-between">
                <span>Domains:</span>
                <span className="text-slate-300">
                  {new Set(selectedQuestions.map((q) => q.domain_id)).size}
                </span>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
