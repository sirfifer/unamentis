/**
 * UnaMentis Operations Console
 *
 * This console provides operations monitoring features:
 * - System health monitoring (CPU, memory, thermal, battery)
 * - Service status and management (Ollama, VibeVoice, Piper, etc.)
 * - Power/idle management profiles and thresholds
 * - Logs, metrics, and performance data
 * - Client connection monitoring
 *
 * Note: Curriculum management (Source Browser, import, enrichment) is in
 * the Management Console at port 8766.
 */
'use client';

import { useState, useEffect } from 'react';
import { Zap, CheckCircle, Users, FileText, AlertTriangle, AlertCircle } from 'lucide-react';
import { Header } from './header';
import { NavTabs, TabId } from './nav-tabs';
import { StatCard } from '@/components/ui/stat-card';
import { LogsPanel, LogsPanelCompact } from './logs-panel';
import { ServersPanelCompact, ServersPanel } from './servers-panel';
import { ClientsPanelCompact, ClientsPanel } from './clients-panel';
import { MetricsPanel, LatencyOverview } from './metrics-panel';
import { ModelsPanel } from './models-panel';
import { HealthPanel } from './health-panel';
import type { DashboardStats } from '@/types';
import { getStats } from '@/lib/api-client';
import { formatDuration } from '@/lib/utils';

export function Dashboard() {
  const [activeTab, setActiveTab] = useState<TabId>('dashboard');
  const [stats, setStats] = useState<DashboardStats | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await getStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch stats:', error);
      }
    };

    fetchStats();
    const interval = setInterval(fetchStats, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-screen flex flex-col bg-slate-950 text-slate-100 overflow-hidden">
      {/* Background Pattern - fixed behind everything */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-1/2 -right-1/2 w-full h-full bg-gradient-to-bl from-orange-500/5 via-transparent to-transparent" />
        <div className="absolute -bottom-1/2 -left-1/2 w-full h-full bg-gradient-to-tr from-amber-500/5 via-transparent to-transparent" />
      </div>

      {/* Sticky Header - never scrolls */}
      <div className="relative z-20 flex-shrink-0">
        <Header
          stats={{
            logsCount: stats?.total_logs ?? 0,
            clientsCount: stats?.online_clients ?? 0,
          }}
          connected={true}
        />
        <NavTabs activeTab={activeTab} onTabChange={setActiveTab} />
      </div>

      {/* Scrollable Content Area */}
      <main className="relative z-10 flex-1 overflow-y-auto">
        <div className="max-w-[1920px] mx-auto p-4 sm:p-6">
          {/* Dashboard Tab */}
          {activeTab === 'dashboard' && (
            <div className="space-y-4 sm:space-y-6 animate-in fade-in duration-300">
              {/* Stats Grid - responsive columns */}
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
                <StatCard
                  icon={Zap}
                  value={stats ? formatDuration(stats.uptime_seconds) : '--'}
                  label="Uptime"
                  iconColor="text-indigo-400"
                  iconBgColor="bg-indigo-400/20"
                />
                <StatCard
                  icon={CheckCircle}
                  value={`${stats?.healthy_servers ?? 0}/${stats?.total_servers ?? 0}`}
                  label="Healthy Servers"
                  iconColor="text-emerald-400"
                  iconBgColor="bg-emerald-400/20"
                />
                <StatCard
                  icon={Users}
                  value={stats?.online_clients ?? 0}
                  label="Online Clients"
                  iconColor="text-blue-400"
                  iconBgColor="bg-blue-400/20"
                />
                <StatCard
                  icon={FileText}
                  value={stats?.total_logs ?? 0}
                  label="Total Logs"
                  iconColor="text-violet-400"
                  iconBgColor="bg-violet-400/20"
                />
                <StatCard
                  icon={AlertTriangle}
                  value={stats?.warnings_count ?? 0}
                  label="Warnings"
                  iconColor="text-amber-400"
                  iconBgColor="bg-amber-400/20"
                />
                <StatCard
                  icon={AlertCircle}
                  value={stats?.errors_count ?? 0}
                  label="Errors"
                  iconColor="text-red-400"
                  iconBgColor="bg-red-400/20"
                />
              </div>

              {/* Dashboard Content - responsive grid */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6">
                {/* Latency Chart */}
                <LatencyOverview />

                {/* Recent Activity */}
                <LogsPanelCompact />

                {/* Server Status */}
                <ServersPanelCompact />

                {/* Connected Clients */}
                <ClientsPanelCompact />
              </div>
            </div>
          )}

          {/* Metrics Tab */}
          {activeTab === 'metrics' && (
            <div className="animate-in fade-in duration-300">
              <MetricsPanel />
            </div>
          )}

          {/* Logs Tab */}
          {activeTab === 'logs' && (
            <div className="animate-in fade-in duration-300">
              <LogsPanel />
            </div>
          )}

          {/* Clients Tab */}
          {activeTab === 'clients' && (
            <div className="animate-in fade-in duration-300">
              <ClientsPanel />
            </div>
          )}

          {/* Servers Tab */}
          {activeTab === 'servers' && (
            <div className="animate-in fade-in duration-300">
              <ServersPanel />
            </div>
          )}

          {/* Models Tab */}
          {activeTab === 'models' && (
            <div className="animate-in fade-in duration-300">
              <ModelsPanel />
            </div>
          )}

          {/* System Health Tab */}
          {activeTab === 'health' && (
            <div className="animate-in fade-in duration-300">
              <HealthPanel />
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
