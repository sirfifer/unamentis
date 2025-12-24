'use client';

import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  BarChart3,
  FileText,
  Smartphone,
  Server,
  FlaskConical,
  Activity,
} from 'lucide-react';

// Operations console tabs (curriculum management is in the Management Console at port 8766)
export type TabId = 'dashboard' | 'metrics' | 'logs' | 'clients' | 'servers' | 'models' | 'health';

interface NavTabsProps {
  activeTab: TabId;
  onTabChange: (tab: TabId) => void;
}

const tabs: { id: TabId; label: string; shortLabel: string; icon: typeof LayoutDashboard }[] = [
  { id: 'dashboard', label: 'Dashboard', shortLabel: 'Home', icon: LayoutDashboard },
  { id: 'health', label: 'System Health', shortLabel: 'Health', icon: Activity },
  { id: 'metrics', label: 'Metrics', shortLabel: 'Metrics', icon: BarChart3 },
  { id: 'logs', label: 'Logs', shortLabel: 'Logs', icon: FileText },
  { id: 'clients', label: 'Clients', shortLabel: 'Clients', icon: Smartphone },
  { id: 'servers', label: 'Servers', shortLabel: 'Servers', icon: Server },
  { id: 'models', label: 'Models', shortLabel: 'Models', icon: FlaskConical },
];

export function NavTabs({ activeTab, onTabChange }: NavTabsProps) {
  return (
    <nav className="bg-slate-800/50 border-b border-slate-700/50">
      <div className="max-w-[1920px] mx-auto px-2 sm:px-4">
        {/* Horizontally scrollable on mobile */}
        <div className="flex items-center gap-1 py-2 overflow-x-auto scrollbar-hide">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;

            return (
              <button
                key={tab.id}
                onClick={() => onTabChange(tab.id)}
                className={cn(
                  'flex items-center gap-1.5 sm:gap-2 px-2.5 sm:px-4 py-2 text-xs sm:text-sm font-medium rounded-md transition-all duration-150',
                  'border whitespace-nowrap flex-shrink-0',
                  isActive
                    ? 'bg-slate-700/80 text-white border-slate-600 shadow-sm'
                    : 'text-slate-400 border-transparent hover:text-slate-200 hover:bg-slate-700/40 hover:border-slate-600/50'
                )}
              >
                <Icon className={cn('w-4 h-4', isActive ? 'text-orange-400' : '')} />
                {/* Show short label on mobile, full label on larger screens */}
                <span className="sm:hidden">{tab.shortLabel}</span>
                <span className="hidden sm:inline">{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
