'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Activity,
  Battery,
  Thermometer,
  Cpu,
  Zap,
  Moon,
  Sun,
  Timer,
  Power,
  RefreshCw,
  AlertTriangle,
  Check,
  X,
  Coffee,
  BatteryCharging,
  Gauge,
  HardDrive,
  Settings,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  getSystemMetrics,
  getIdleStatus,
  getPowerModes,
  setIdleConfig,
  keepAwake,
  cancelKeepAwake,
  forceIdleState,
  unloadAllModels,
  getMetricsHistorySummary,
} from '@/lib/api-client';
import type {
  SystemMetricsSummary,
  IdleStatus,
  PowerModesResponse,
  MetricsHistorySummary,
} from '@/types';
import { formatDuration } from '@/lib/utils';
import { PowerSettingsPanel } from './power-settings-panel';

// Thermal pressure colors
const thermalColors = {
  nominal: { bg: 'bg-emerald-500/20', text: 'text-emerald-400', border: 'border-emerald-500/30' },
  fair: { bg: 'bg-amber-500/20', text: 'text-amber-400', border: 'border-amber-500/30' },
  serious: { bg: 'bg-orange-500/20', text: 'text-orange-400', border: 'border-orange-500/30' },
  critical: { bg: 'bg-red-500/20', text: 'text-red-400', border: 'border-red-500/30' },
};

// Idle state colors
const idleStateColors = {
  active: { bg: 'bg-emerald-500/20', text: 'text-emerald-400', icon: Sun },
  warm: { bg: 'bg-blue-500/20', text: 'text-blue-400', icon: Activity },
  cool: { bg: 'bg-indigo-500/20', text: 'text-indigo-400', icon: Moon },
  cold: { bg: 'bg-purple-500/20', text: 'text-purple-400', icon: Timer },
  dormant: { bg: 'bg-slate-500/20', text: 'text-slate-400', icon: Power },
};

export function HealthPanel() {
  const [metrics, setMetrics] = useState<SystemMetricsSummary | null>(null);
  const [idleStatus, setIdleStatus] = useState<IdleStatus | null>(null);
  const [powerModes, setPowerModes] = useState<PowerModesResponse | null>(null);
  const [historySummary, setHistorySummary] = useState<MetricsHistorySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [showAdvanced, setShowAdvanced] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const [metricsData, idleData, modesData, historyData] = await Promise.all([
        getSystemMetrics(),
        getIdleStatus(),
        getPowerModes(),
        getMetricsHistorySummary(),
      ]);
      setMetrics(metricsData);
      setIdleStatus(idleData);
      setPowerModes(modesData);
      setHistorySummary(historyData);
    } catch (error) {
      console.error('Error fetching health data:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 5000); // Refresh every 5 seconds
    return () => clearInterval(interval);
  }, [fetchData]);

  const handleSetMode = async (mode: string) => {
    setActionLoading(`mode-${mode}`);
    try {
      await setIdleConfig({ mode });
      await fetchData();
    } catch (error) {
      console.error('Error setting power mode:', error);
    } finally {
      setActionLoading(null);
    }
  };

  const handleKeepAwake = async (duration: number) => {
    setActionLoading('keep-awake');
    try {
      await keepAwake(duration);
      await fetchData();
    } catch (error) {
      console.error('Error setting keep awake:', error);
    } finally {
      setActionLoading(null);
    }
  };

  const handleCancelKeepAwake = async () => {
    setActionLoading('cancel-awake');
    try {
      await cancelKeepAwake();
      await fetchData();
    } catch (error) {
      console.error('Error cancelling keep awake:', error);
    } finally {
      setActionLoading(null);
    }
  };

  const handleForceState = async (state: string) => {
    setActionLoading(`force-${state}`);
    try {
      await forceIdleState(state);
      await fetchData();
    } catch (error) {
      console.error('Error forcing state:', error);
    } finally {
      setActionLoading(null);
    }
  };

  const handleUnloadModels = async () => {
    setActionLoading('unload');
    try {
      await unloadAllModels();
      await fetchData();
    } catch (error) {
      console.error('Error unloading models:', error);
    } finally {
      setActionLoading(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="w-8 h-8 animate-spin text-slate-400" />
      </div>
    );
  }

  const thermal = metrics?.thermal;
  const power = metrics?.power;
  const cpu = metrics?.cpu;
  const thermalStyle = thermal ? thermalColors[thermal.pressure] : thermalColors.nominal;
  const idleState = idleStatus?.current_state || 'active';
  const idleStyle =
    idleStateColors[idleState as keyof typeof idleStateColors] || idleStateColors.active;
  const IdleIcon = idleStyle.icon;

  return (
    <div className="space-y-6 animate-in">
      {/* Top Stats Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* Battery */}
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardContent className="pt-4">
            <div className="flex items-center gap-3">
              <div
                className={`p-2 rounded-lg ${power?.battery_charging ? 'bg-emerald-500/20' : 'bg-amber-500/20'}`}
              >
                {power?.battery_charging ? (
                  <BatteryCharging className="w-5 h-5 text-emerald-400" />
                ) : (
                  <Battery className="w-5 h-5 text-amber-400" />
                )}
              </div>
              <div>
                <p className="text-2xl font-bold text-slate-100">
                  {power?.battery_percent?.toFixed(0) || '--'}%
                </p>
                <p className="text-xs text-slate-400">
                  {power?.battery_charging
                    ? 'Charging'
                    : `${power?.current_battery_draw_w?.toFixed(1) || '--'}W draw`}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Thermal */}
        <Card className={`border ${thermalStyle.border}`}>
          <CardContent className="pt-4">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${thermalStyle.bg}`}>
                <Thermometer className={`w-5 h-5 ${thermalStyle.text}`} />
              </div>
              <div>
                <p className={`text-2xl font-bold ${thermalStyle.text}`}>
                  {thermal?.pressure?.charAt(0).toUpperCase()}
                  {thermal?.pressure?.slice(1) || 'Unknown'}
                </p>
                <p className="text-xs text-slate-400">
                  {thermal?.cpu_temp_c ? `${thermal.cpu_temp_c.toFixed(0)}°C CPU` : 'Thermal state'}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* CPU */}
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardContent className="pt-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-blue-500/20">
                <Cpu className="w-5 h-5 text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-bold text-slate-100">
                  {cpu?.total_percent?.toFixed(1) || '--'}%
                </p>
                <p className="text-xs text-slate-400">Total CPU usage</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Idle State */}
        <Card className={`border ${idleStyle.bg.replace('/20', '/30')}`}>
          <CardContent className="pt-4">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${idleStyle.bg}`}>
                <IdleIcon className={`w-5 h-5 ${idleStyle.text}`} />
              </div>
              <div>
                <p className={`text-2xl font-bold ${idleStyle.text}`}>
                  {idleState.charAt(0).toUpperCase() + idleState.slice(1)}
                </p>
                <p className="text-xs text-slate-400">
                  Idle {formatDuration(idleStatus?.seconds_idle || 0)}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Grid */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Power Mode Controls */}
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Zap className="w-5 h-5 text-amber-400" />
              Power Mode
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {powerModes &&
              Object.entries(powerModes.modes).map(([key, mode]) => (
                <button
                  key={key}
                  onClick={() => handleSetMode(key)}
                  disabled={actionLoading !== null}
                  className={`w-full p-3 rounded-lg border text-left transition-all ${
                    powerModes.current === key
                      ? 'border-indigo-500 bg-indigo-500/20'
                      : 'border-slate-600 bg-slate-700/50 hover:bg-slate-700'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-slate-100">{mode.name}</span>
                    {powerModes.current === key && <Check className="w-4 h-4 text-indigo-400" />}
                    {actionLoading === `mode-${key}` && (
                      <RefreshCw className="w-4 h-4 animate-spin text-slate-400" />
                    )}
                  </div>
                  <p className="text-xs text-slate-400 mt-1">{mode.description}</p>
                </button>
              ))}

            <div className="pt-3 border-t border-slate-700">
              <p className="text-xs text-slate-400 mb-2">Quick Actions</p>
              <div className="flex gap-2">
                <button
                  onClick={() => handleKeepAwake(3600)}
                  disabled={actionLoading !== null}
                  className="flex-1 px-3 py-2 rounded-lg bg-amber-500/20 text-amber-400 hover:bg-amber-500/30 transition-colors text-sm flex items-center justify-center gap-1"
                >
                  <Coffee className="w-4 h-4" />
                  Keep Awake 1hr
                </button>
                {idleStatus?.keep_awake_remaining && idleStatus.keep_awake_remaining > 0 ? (
                  <button
                    onClick={handleCancelKeepAwake}
                    disabled={actionLoading !== null}
                    className="px-3 py-2 rounded-lg bg-red-500/20 text-red-400 hover:bg-red-500/30 transition-colors text-sm"
                  >
                    <X className="w-4 h-4" />
                  </button>
                ) : null}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Service Resources */}
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <HardDrive className="w-5 h-5 text-blue-400" />
                Services
              </CardTitle>
              <button
                onClick={handleUnloadModels}
                disabled={actionLoading !== null}
                className="px-2 py-1 rounded text-xs bg-red-500/20 text-red-400 hover:bg-red-500/30 transition-colors flex items-center gap-1"
              >
                {actionLoading === 'unload' ? (
                  <RefreshCw className="w-3 h-3 animate-spin" />
                ) : (
                  <Power className="w-3 h-3" />
                )}
                Unload All
              </button>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {metrics?.services &&
              Object.entries(metrics.services).map(([key, service]) => (
                <div
                  key={key}
                  className="p-3 rounded-lg bg-slate-700/50 border border-slate-600/50"
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-medium text-slate-100">{service.service_name}</span>
                    <Badge variant={service.model_loaded ? 'success' : 'default'}>
                      {service.model_loaded ? 'Loaded' : 'Idle'}
                    </Badge>
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-xs">
                    <div>
                      <p className="text-slate-400">CPU</p>
                      <p className="text-slate-100 font-medium">
                        {service.cpu_percent?.toFixed(1) || 0}%
                      </p>
                    </div>
                    <div>
                      <p className="text-slate-400">Memory</p>
                      <p className="text-slate-100 font-medium">
                        {service.memory_mb?.toFixed(0) || 0} MB
                      </p>
                    </div>
                    <div>
                      <p className="text-slate-400">Power</p>
                      <p className="text-slate-100 font-medium">
                        {service.estimated_power_w?.toFixed(1) || 0}W
                      </p>
                    </div>
                  </div>
                </div>
              ))}

            {(!metrics?.services || Object.keys(metrics.services).length === 0) && (
              <p className="text-center text-slate-400 py-4">No services detected</p>
            )}
          </CardContent>
        </Card>

        {/* Idle State Controls */}
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Timer className="w-5 h-5 text-purple-400" />
              Idle State Control
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Current State Info */}
            <div className="p-3 rounded-lg bg-slate-700/50 border border-slate-600/50">
              <div className="flex items-center justify-between mb-2">
                <span className="text-slate-400 text-sm">Current State</span>
                <span className={`font-medium ${idleStyle.text}`}>
                  {idleState.charAt(0).toUpperCase() + idleState.slice(1)}
                </span>
              </div>
              {idleStatus?.next_state_in && (
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">Next: {idleStatus.next_state_in.state}</span>
                  <span className="text-slate-400">
                    in {formatDuration(idleStatus.next_state_in.seconds_remaining)}
                  </span>
                </div>
              )}
              {idleStatus?.keep_awake_remaining && idleStatus.keep_awake_remaining > 0 && (
                <div className="mt-2 p-2 rounded bg-amber-500/20 text-amber-400 text-xs flex items-center gap-2">
                  <Coffee className="w-3 h-3" />
                  Keep awake for {formatDuration(idleStatus.keep_awake_remaining)}
                </div>
              )}
            </div>

            {/* Force State Buttons */}
            <div>
              <p className="text-xs text-slate-400 mb-2">Force State</p>
              <div className="grid grid-cols-5 gap-1">
                {(['active', 'warm', 'cool', 'cold', 'dormant'] as const).map((state) => {
                  const stateStyle = idleStateColors[state];
                  const StateIcon = stateStyle.icon;
                  return (
                    <button
                      key={state}
                      onClick={() => handleForceState(state)}
                      disabled={actionLoading !== null || idleState === state}
                      className={`p-2 rounded-lg flex flex-col items-center gap-1 transition-colors ${
                        idleState === state
                          ? `${stateStyle.bg} ${stateStyle.text}`
                          : 'bg-slate-700/50 text-slate-400 hover:bg-slate-700'
                      }`}
                    >
                      {actionLoading === `force-${state}` ? (
                        <RefreshCw className="w-4 h-4 animate-spin" />
                      ) : (
                        <StateIcon className="w-4 h-4" />
                      )}
                      <span className="text-xs capitalize">{state}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Thresholds Display */}
            <div className="pt-3 border-t border-slate-700">
              <p className="text-xs text-slate-400 mb-2">Current Thresholds</p>
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-slate-500">Warm:</span>
                  <span className="text-slate-300">
                    {formatDuration(idleStatus?.thresholds?.warm || 0)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Cool:</span>
                  <span className="text-slate-300">
                    {formatDuration(idleStatus?.thresholds?.cool || 0)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Cold:</span>
                  <span className="text-slate-300">
                    {formatDuration(idleStatus?.thresholds?.cold || 0)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Dormant:</span>
                  <span className="text-slate-300">
                    {formatDuration(idleStatus?.thresholds?.dormant || 0)}
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* History Summary */}
      {historySummary && (historySummary.today || historySummary.this_week) && (
        <Card className="bg-slate-800/50 border-slate-700/50">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Gauge className="w-5 h-5 text-indigo-400" />
              Historical Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-3 gap-6">
              {historySummary.today && (
                <div>
                  <p className="text-sm font-medium text-slate-300 mb-2">Today</p>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-slate-400">Avg CPU</span>
                      <span className="text-slate-100">
                        {historySummary.today.avg_cpu_percent?.toFixed(1) || 0}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Avg Power</span>
                      <span className="text-slate-100">
                        {historySummary.today.avg_battery_draw_w?.toFixed(1) || 0}W
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Max Thermal</span>
                      <span
                        className={
                          historySummary.today.max_thermal_level > 1
                            ? 'text-amber-400'
                            : 'text-slate-100'
                        }
                      >
                        {['Nominal', 'Fair', 'Serious', 'Critical'][
                          historySummary.today.max_thermal_level
                        ] || 'Unknown'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Requests</span>
                      <span className="text-slate-100">
                        {historySummary.today.total_requests || 0}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {historySummary.yesterday && (
                <div>
                  <p className="text-sm font-medium text-slate-300 mb-2">Yesterday</p>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-slate-400">Avg CPU</span>
                      <span className="text-slate-100">
                        {historySummary.yesterday.avg_cpu_percent?.toFixed(1) || 0}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Avg Power</span>
                      <span className="text-slate-100">
                        {historySummary.yesterday.avg_battery_draw_w?.toFixed(1) || 0}W
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Active Hours</span>
                      <span className="text-slate-100">
                        {historySummary.yesterday.active_hours || 0}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Requests</span>
                      <span className="text-slate-100">
                        {historySummary.yesterday.total_requests || 0}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {historySummary.this_week && (
                <div>
                  <p className="text-sm font-medium text-slate-300 mb-2">This Week</p>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-slate-400">Days Recorded</span>
                      <span className="text-slate-100">
                        {historySummary.this_week.days_recorded || 0}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Avg CPU</span>
                      <span className="text-slate-100">
                        {historySummary.this_week.avg_cpu_percent?.toFixed(1) || 0}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Total Requests</span>
                      <span className="text-slate-100">
                        {historySummary.this_week.total_requests || 0}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400">Max Thermal</span>
                      <span
                        className={
                          historySummary.this_week.max_thermal_level > 1
                            ? 'text-amber-400'
                            : 'text-slate-100'
                        }
                      >
                        {['Nominal', 'Fair', 'Serious', 'Critical'][
                          historySummary.this_week.max_thermal_level
                        ] || 'Unknown'}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {historySummary.total_days_tracked > 0 && (
              <div className="mt-4 pt-3 border-t border-slate-700 flex items-center justify-between text-xs text-slate-400">
                <span>Tracking since {historySummary.oldest_record || 'unknown'}</span>
                <span>
                  {historySummary.total_days_tracked} days, {historySummary.total_hours_tracked}{' '}
                  hours recorded
                </span>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Advanced Power Settings Toggle */}
      <button
        onClick={() => setShowAdvanced(!showAdvanced)}
        className="w-full p-4 bg-slate-800/30 border border-slate-700/50 rounded-lg hover:bg-slate-800/50 transition-colors flex items-center justify-between"
      >
        <div className="flex items-center gap-3">
          <Settings className="w-5 h-5 text-indigo-400" />
          <div className="text-left">
            <p className="font-medium text-slate-200">Advanced Power Settings</p>
            <p className="text-xs text-slate-400">
              Create custom profiles, tune thresholds, manage power modes
            </p>
          </div>
        </div>
        {showAdvanced ? (
          <ChevronUp className="w-5 h-5 text-slate-400" />
        ) : (
          <ChevronDown className="w-5 h-5 text-slate-400" />
        )}
      </button>

      {/* Power Settings Panel */}
      {showAdvanced && <PowerSettingsPanel />}
    </div>
  );
}
