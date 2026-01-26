'use client';

import { useState, useEffect, useCallback } from 'react';
import { useQueryState, parseAsString, parseAsInteger } from 'nuqs';
import {
  HelpCircle,
  Search,
  RefreshCw,
  Plus,
  Volume2,
  Filter,
  ChevronLeft,
  ChevronRight,
  Database,
  AlertCircle,
  Edit3,
  Trash2,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tooltip } from '@/components/ui/tooltip';
import { HelpButton } from '@/components/ui/help-button';
import { useMainScrollRestoration } from '@/hooks/useScrollRestoration';
import type { KBQuestion, KBDomain, DifficultyTier } from '@/types/question-packs';

// API response types
interface QuestionsResponse {
  success: boolean;
  questions: KBQuestion[];
  total: number;
  limit: number;
  offset: number;
  source: string;
  error?: string;
}

interface DomainsResponse {
  success: boolean;
  domains: KBDomain[];
  source: string;
}

interface DatabaseStatusResponse {
  success: boolean;
  database_available: boolean;
  total_questions?: number;
  domain_counts?: Record<string, number>;
  message?: string;
}

// Difficulty tier labels
const DIFFICULTY_LABELS: Record<number, string> = {
  1: 'Very Easy',
  2: 'Easy',
  3: 'Medium',
  4: 'Hard',
  5: 'Very Hard',
};

const DIFFICULTY_COLORS: Record<number, string> = {
  1: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  2: 'bg-green-500/20 text-green-400 border-green-500/30',
  3: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  4: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
  5: 'bg-red-500/20 text-red-400 border-red-500/30',
};

// Help sections
const questionsHelpSections = [
  {
    title: 'What is the Questions Browser?',
    content: (
      <div className="space-y-2">
        <p>
          The Questions Browser lets you view, search, and manage all Knowledge Bowl questions in
          the database. This is where you can browse, filter, and edit questions before organizing
          them into packs.
        </p>
      </div>
    ),
  },
  {
    title: 'Filtering Questions',
    content: (
      <div className="space-y-2">
        <p>Use the filters to narrow down questions by:</p>
        <ul className="list-disc list-inside space-y-1 text-slate-400">
          <li>
            <span className="text-slate-300">Domain:</span> Subject area (Science, History, etc.)
          </li>
          <li>
            <span className="text-slate-300">Difficulty:</span> 1 (easiest) to 5 (hardest)
          </li>
          <li>
            <span className="text-slate-300">Type:</span> Toss-up, Bonus, Pyramid, or Lightning
          </li>
          <li>
            <span className="text-slate-300">Audio Status:</span> Whether questions have generated
            audio
          </li>
          <li>
            <span className="text-slate-300">Search:</span> Full-text search in question and answer
            text
          </li>
        </ul>
      </div>
    ),
  },
  {
    title: 'Database Sync',
    content: (
      <div className="space-y-2">
        <p>
          Questions are stored in the database for reliable storage and fast querying. The status
          indicator shows whether the database is connected.
        </p>
        <p className="text-slate-400">
          Use the sync button to import questions from the Knowledge Bowl module into the database.
        </p>
      </div>
    ),
  },
];

// API functions
async function getQuestions(params?: {
  domain_id?: string;
  difficulty?: string;
  question_type?: string;
  has_audio?: string;
  search?: string;
  limit?: number;
  offset?: number;
}): Promise<QuestionsResponse> {
  const queryParams = new URLSearchParams();
  if (params?.domain_id && params.domain_id !== 'all')
    queryParams.set('domain_id', params.domain_id);
  if (params?.difficulty) queryParams.set('difficulty', params.difficulty);
  if (params?.question_type && params.question_type !== 'all')
    queryParams.set('question_type', params.question_type);
  if (params?.has_audio && params.has_audio !== 'all')
    queryParams.set('has_audio', params.has_audio);
  if (params?.search) queryParams.set('search', params.search);
  if (params?.limit) queryParams.set('limit', params.limit.toString());
  if (params?.offset) queryParams.set('offset', params.offset.toString());

  const query = queryParams.toString();
  const response = await fetch(`/api/kb/questions${query ? `?${query}` : ''}`);

  if (!response.ok) {
    throw new Error('Failed to fetch questions');
  }

  return response.json();
}

async function getDomains(): Promise<DomainsResponse> {
  const response = await fetch('/api/kb/domains');
  if (!response.ok) {
    throw new Error('Failed to fetch domains');
  }
  return response.json();
}

async function getDatabaseStatus(): Promise<DatabaseStatusResponse> {
  const response = await fetch('/api/kb/database-status');
  if (!response.ok) {
    throw new Error('Failed to check database status');
  }
  return response.json();
}

async function syncToDatabase(): Promise<{
  success: boolean;
  imported_count: number;
  total_questions: number;
}> {
  const response = await fetch('/api/kb/sync-to-database', { method: 'POST' });
  if (!response.ok) {
    throw new Error('Failed to sync to database');
  }
  return response.json();
}

export function QuestionsPanel() {
  const [questions, setQuestions] = useState<KBQuestion[]>([]);
  const [domains, setDomains] = useState<KBDomain[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dbStatus, setDbStatus] = useState<DatabaseStatusResponse | null>(null);
  const [syncing, setSyncing] = useState(false);

  // URL-synced state
  const [searchQuery, setSearchQuery] = useQueryState('q', parseAsString.withDefault(''));
  const [domainFilter, setDomainFilter] = useQueryState('domain', parseAsString.withDefault('all'));
  const [difficultyFilter, setDifficultyFilter] = useQueryState(
    'diff',
    parseAsString.withDefault('')
  );
  const [typeFilter, setTypeFilter] = useQueryState('qtype', parseAsString.withDefault('all'));
  const [audioFilter, setAudioFilter] = useQueryState('audio', parseAsString.withDefault('all'));
  const [page, setPage] = useQueryState('page', parseAsInteger.withDefault(1));

  const pageSize = 20;

  // Scroll restoration
  useMainScrollRestoration('questions-panel');

  // Fetch database status
  useEffect(() => {
    getDatabaseStatus().then(setDbStatus).catch(console.error);
  }, []);

  // Fetch domains
  useEffect(() => {
    getDomains()
      .then((data) => setDomains(data.domains))
      .catch(console.error);
  }, []);

  // Fetch questions
  const fetchQuestions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getQuestions({
        domain_id: domainFilter || undefined,
        difficulty: difficultyFilter || undefined,
        question_type: typeFilter || undefined,
        has_audio: audioFilter || undefined,
        search: searchQuery || undefined,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      });
      setQuestions(data.questions);
      setTotal(data.total);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load questions');
    } finally {
      setLoading(false);
    }
  }, [searchQuery, domainFilter, difficultyFilter, typeFilter, audioFilter, page]);

  useEffect(() => {
    fetchQuestions();
  }, [fetchQuestions]);

  // Handle sync
  const handleSync = async () => {
    setSyncing(true);
    try {
      const result = await syncToDatabase();
      setDbStatus((prev) => (prev ? { ...prev, total_questions: result.total_questions } : prev));
      await fetchQuestions();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sync failed');
    } finally {
      setSyncing(false);
    }
  };

  // Pagination
  const totalPages = Math.ceil(total / pageSize);
  const canPrevPage = page > 1;
  const canNextPage = page < totalPages;

  // Clear filters
  const clearFilters = () => {
    setSearchQuery('');
    setDomainFilter('all');
    setDifficultyFilter('');
    setTypeFilter('all');
    setAudioFilter('all');
    setPage(1);
  };

  const hasActiveFilters =
    searchQuery ||
    domainFilter !== 'all' ||
    difficultyFilter ||
    typeFilter !== 'all' ||
    audioFilter !== 'all';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2">
            <HelpCircle className="w-6 h-6 text-cyan-400" />
            Questions
            <HelpButton
              title="Questions Browser Help"
              description="Learn how to browse and manage Knowledge Bowl questions"
              sections={questionsHelpSections}
            />
          </h2>
          <p className="text-slate-400 mt-1">
            Browse and manage all Knowledge Bowl questions
            {dbStatus?.database_available && (
              <span className="ml-2 text-emerald-400">
                ({dbStatus.total_questions?.toLocaleString() || 0} in database)
              </span>
            )}
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Database status indicator */}
          <Tooltip
            content={dbStatus?.database_available ? 'Database connected' : 'Using JSON storage'}
          >
            <div
              className={`flex items-center gap-1.5 px-2 py-1 rounded-md text-xs ${
                dbStatus?.database_available
                  ? 'bg-emerald-500/20 text-emerald-400'
                  : 'bg-amber-500/20 text-amber-400'
              }`}
            >
              <Database className="w-3 h-3" />
              {dbStatus?.database_available ? 'DB' : 'JSON'}
            </div>
          </Tooltip>

          <Tooltip content="Sync questions from Knowledge Bowl module to database">
            <button
              onClick={handleSync}
              disabled={syncing}
              className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors border border-slate-700 disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
              Sync
            </button>
          </Tooltip>

          <Tooltip content="Create a new question">
            <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-white bg-cyan-600 hover:bg-cyan-500 rounded-md transition-colors shadow-lg shadow-cyan-500/20">
              <Plus className="w-4 h-4" />
              New Question
            </button>
          </Tooltip>

          <Tooltip content="Refresh list">
            <button
              onClick={() => fetchQuestions()}
              className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </Tooltip>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        {/* Search */}
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
            className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500"
          />
        </div>

        {/* Filter dropdowns */}
        <div className="flex flex-wrap items-center gap-2">
          <Tooltip content="Filter by subject domain">
            <div className="flex items-center gap-1">
              <Filter className="w-4 h-4 text-slate-400" />
              <select
                value={domainFilter}
                onChange={(e) => {
                  setDomainFilter(e.target.value);
                  setPage(1);
                }}
                className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-cyan-500/50"
              >
                <option value="all">All Domains</option>
                {domains.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </select>
            </div>
          </Tooltip>

          <Tooltip content="Filter by difficulty level (1-5)">
            <select
              value={difficultyFilter}
              onChange={(e) => {
                setDifficultyFilter(e.target.value);
                setPage(1);
              }}
              className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-cyan-500/50"
            >
              <option value="">All Difficulties</option>
              <option value="1">1 - Very Easy</option>
              <option value="2">2 - Easy</option>
              <option value="3">3 - Medium</option>
              <option value="4">4 - Hard</option>
              <option value="5">5 - Very Hard</option>
            </select>
          </Tooltip>

          <Tooltip content="Filter by question type">
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value);
                setPage(1);
              }}
              className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-cyan-500/50"
            >
              <option value="all">All Types</option>
              <option value="toss_up">Toss-up</option>
              <option value="bonus">Bonus</option>
              <option value="pyramid">Pyramid</option>
              <option value="lightning">Lightning</option>
            </select>
          </Tooltip>

          <Tooltip content="Filter by audio status">
            <select
              value={audioFilter}
              onChange={(e) => {
                setAudioFilter(e.target.value);
                setPage(1);
              }}
              className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-md text-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-cyan-500/50"
            >
              <option value="all">All Audio</option>
              <option value="true">Has Audio</option>
              <option value="false">No Audio</option>
            </select>
          </Tooltip>

          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="px-3 py-2 text-sm text-slate-400 hover:text-slate-200 transition-colors"
            >
              Clear filters
            </button>
          )}
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-center gap-2 p-4 bg-red-500/10 border border-red-500/30 rounded-md text-red-400">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Questions list */}
      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin w-8 h-8 border-2 border-cyan-500 border-t-transparent rounded-full" />
        </div>
      ) : questions.length === 0 ? (
        <Card className="bg-slate-900/50 border-slate-800">
          <CardContent className="flex flex-col items-center justify-center py-12 text-center">
            <HelpCircle className="w-12 h-12 text-slate-600 mb-4" />
            <h3 className="text-lg font-medium text-slate-300 mb-2">No questions found</h3>
            <p className="text-slate-500 max-w-md">
              {hasActiveFilters
                ? 'Try adjusting your filters or search query'
                : 'Sync questions from the Knowledge Bowl module to get started'}
            </p>
            {!hasActiveFilters && dbStatus?.database_available && (
              <button
                onClick={handleSync}
                disabled={syncing}
                className="mt-4 flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-cyan-600 hover:bg-cyan-500 rounded-md transition-colors"
              >
                <RefreshCw className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
                Sync from Module
              </button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {/* Results count */}
          <div className="text-sm text-slate-400">
            Showing {(page - 1) * pageSize + 1}-{Math.min(page * pageSize, total)} of{' '}
            {total.toLocaleString()} questions
          </div>

          {/* Questions grid */}
          <div className="space-y-3">
            {questions.map((q) => (
              <Card
                key={q.id}
                className="bg-slate-900/50 border-slate-800 hover:border-slate-700 transition-colors"
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-4">
                    {/* Main content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start gap-2 mb-2">
                        <p className="text-slate-100 line-clamp-2">{q.question_text}</p>
                      </div>
                      <p className="text-sm text-cyan-400 mb-3">
                        <span className="text-slate-500">Answer:</span> {q.answer_text}
                      </p>
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge className="bg-slate-700/50 text-slate-300 border-slate-600">
                          {q.domain_name || q.domain_id}
                        </Badge>
                        <Badge className={DIFFICULTY_COLORS[q.difficulty] || DIFFICULTY_COLORS[2]}>
                          {DIFFICULTY_LABELS[q.difficulty] || 'Medium'}
                        </Badge>
                        <Badge className="bg-slate-700/50 text-slate-300 border-slate-600">
                          {q.question_type?.replace('_', ' ') || 'toss-up'}
                        </Badge>
                        {q.has_audio ? (
                          <Badge className="bg-emerald-500/20 text-emerald-400 border-emerald-500/30 flex items-center gap-1">
                            <Volume2 className="w-3 h-3" />
                            Audio
                          </Badge>
                        ) : (
                          <Badge className="bg-slate-700/50 text-slate-500 border-slate-600 flex items-center gap-1">
                            <Volume2 className="w-3 h-3" />
                            No Audio
                          </Badge>
                        )}
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <Tooltip content="Edit question">
                        <button className="p-2 text-slate-400 hover:text-cyan-400 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                      </Tooltip>
                      <Tooltip content="Delete question">
                        <button className="p-2 text-slate-400 hover:text-red-400 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </Tooltip>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between pt-4 border-t border-slate-800">
              <div className="text-sm text-slate-400">
                Page {page} of {totalPages}
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setPage(page - 1)}
                  disabled={!canPrevPage}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronLeft className="w-4 h-4" />
                  Previous
                </button>
                <button
                  onClick={() => setPage(page + 1)}
                  disabled={!canNextPage}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm text-slate-300 bg-slate-800 hover:bg-slate-700 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
